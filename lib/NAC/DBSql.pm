#!/usr/bin/perl
# SVN: $Id: NACDBBuffer.pm 1538 2012-10-16 14:11:02Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-16 10:11:02 -0400 (Tue, 16 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBSql.pm $:
#
#
#
# Author: Sean McAdam
# Purpose: Provide a set or routines to access a SQL database
#
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBSql;
use FindBin;
use lib "$FindBin::Bin/..";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck carp);
use DBD::mysql;
use POSIX;
use Readonly;

# use IO::Socket::INET;
use NAC::Syslog;
use NAC::Constants;
use NAC::DBConsts;
use strict;

sub reseterr;

Readonly our $RAISE_ERROR         => 0;
Readonly our $PRINT_ERROR         => 1;
Readonly our $AUTOCOMMIT          => 1;
Readonly our $SQL_CONNECT_TIMEOUT => 4;
Readonly our $SQL_ERR             => '_err';
Readonly our $SQL_ERRSTR          => '_errstr';
Readonly our $SQL_VERSION         => '_version';
Readonly our $SQL_DBH             => '_SQL_DBH';
Readonly our $SQL_STH             => '_SQL_STH';
Readonly our $SQL_RECONTIME       => '_SQL_RECONTIME';
Readonly our $SQL_CONNECTED       => '_SQL_CONNECTED';
Readonly our $SQL_DB              => 'SQL_DB_NAME';
Readonly our $SQL_HOST            => 'SQL_DB_HOST';
Readonly our $SQL_PORT            => 'SQL_DB_PORT';
Readonly our $SQL_USER            => 'SQL_DB_USER';
Readonly our $SQL_PASS            => 'SQL_DB_PASS';
Readonly our $SQL_NO_CONNECT_FAIL => 'SQL_NO_CONNECT_FAIL';
Readonly our $SQL_READ_ONLY       => 'SQL_READ_ONLY';
Readonly our $SQL_CLASS           => 'SQL_CLASS';

Readonly our $SQL_HASH_REF => 'SQL-HASH-REF';

our @EXPORT = qw (
  $SQL_DB
  $SQL_HOST
  $SQL_PORT
  $SQL_USER
  $SQL_PASS
  $SQL_CLASS
  $SQL_NO_CONNECT_FAIL
  $SQL_READ_ONLY
  $SQL_HASH_REF
);

my $AutoReconnect = 1;
my $DEBUG         = 1;

my $DB_MAX_RECONNECT_TRY = 3;
my $DB_RECONNECT_TIME    = 60;

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;

# my $hostname = NACSyslog::hostname;

#---------------------------------------------------------------------------
# Database Connections
#
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub new {
    my ( $class, $sql_parm_ref ) = @_;
    my $self;

    if ( ( defined $sql_parm_ref ) && ( ref($sql_parm_ref) ne 'HASH' ) ) { confess; }
    if ( !defined $sql_parm_ref->{$SQL_DB} )    { confess; }
    if ( !defined $sql_parm_ref->{$SQL_HOST} )  { confess; }
    if ( !defined $sql_parm_ref->{$SQL_PORT} )  { confess; }
    if ( !defined $sql_parm_ref->{$SQL_USER} )  { confess; }
    if ( !defined $sql_parm_ref->{$SQL_PASS} )  { confess; }
    if ( !defined $sql_parm_ref->{$SQL_CLASS} ) { confess; }

    EventLog( EVENT_START, MYNAME . "() started" );

    my $db      = $sql_parm_ref->{$SQL_DB};
    my $host    = $sql_parm_ref->{$SQL_HOST};
    my $port    = $sql_parm_ref->{$SQL_PORT};
    my $user    = $sql_parm_ref->{$SQL_USER};
    my $pass    = $sql_parm_ref->{$SQL_PASS};
    my $fail    = $sql_parm_ref->{$SQL_NO_CONNECT_FAIL};
    my $ro      = $sql_parm_ref->{$SQL_READ_ONLY};
    my $myclass = $sql_parm_ref->{$SQL_CLASS};

    $self = {
        $SQL_NO_CONNECT_FAIL => ( defined $fail ) ? 1 : 0,
        $SQL_READ_ONLY => ( defined $ro && $ro ) ? 1 : 0,
        $SQL_VERSION   => $VERSION,
        $SQL_ERR       => 0,
        $SQL_ERRSTR    => '',
        $SQL_DBH       => undef,
        $SQL_STH       => undef,
        $SQL_CONNECTED => 0,
        $SQL_RECONTIME => 0,
        $SQL_DB        => $db,
        $SQL_HOST      => $host,
        $SQL_PORT      => $port,
        $SQL_USER      => $user,
        $SQL_PASS      => $pass,
        $SQL_CLASS     => $myclass,
    };

    bless $self, $class;

    $self;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub version {
    my ($self) = @_;
    return $self->{$SQL_VERSION};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub err {
    my ($self) = @_;
    return $self->{$SQL_ERR};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub errstr {
    my ($self) = @_;
    return $self->{$SQL_ERRSTR};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub seterr {
    my ( $self, $errstr ) = @_;
    $self->{$SQL_ERR}    = 1;
    $self->{$SQL_ERRSTR} = $errstr;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub reseterr {
    my ($self) = @_;
    $self->{$SQL_ERR}    = 0;
    $self->{$SQL_ERRSTR} = '';
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub host {
    my ($self) = @_;
    $self->{$SQL_HOST};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub db {
    my ($self) = @_;
    $self->{$SQL_DB};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub log_db_error {
    my ( $self, $optmessage ) = @_;

    EventLog( EVENT_ERR, MYNAMELINE . $optmessage . carp );

    # EventLog( EVENT_DB_ERR,
    # EventLog( EVENT_ERR,
    #     Carp::longmess( 'ERR:' . ( ( defined $self->dbh ) ? $self->dbh->err : '' ) . ": " . $self->dbh->errstr . " : " )
    #       . ( ( defined $optmessage ) ? "::$optmessage" : '' )
    # );
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub log_db_warn {
    my ( $self, $optmessage ) = @_;

    EventLog( EVENT_WARN, MYNAMELINE . $optmessage . carp );

    # EventLog( EVENT_DB_WARN,
    # EventLog( EVENT_WARN,
    # 	Carp::longmess( $self->dbh->err . ":" . ": warn() " )
    #       . ( ( defined $optmessage ) ? "::$optmessage" : '' ) );
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub sqldo {
    my ( $self, $sql ) = @_;
    my $ret = 0;
    my $try = 0;

    $self->reseterr;

    if ( ( defined $self->{$SQL_READ_ONLY} ) && ( $self->{$SQL_READ_ONLY} ) ) {
        EventLog( EVENT_ERR, MYNAMELINE() . " called for a read only DB " . Dumper $self );
        confess( MYNAMELINE() . " READONLY DB " . Dumper $self );
    }

    if ( ( !defined $sql ) || ( $sql eq '' ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAME() . "CLASS: $self->{$SQL_CLASS} SQL:$sql" );

    if ( !( $self->{$SQL_CONNECTED} ) ) {
        if ( ( $self->{$SQL_RECONTIME} ) < time() ) {
            if ( !( $self->connect ) ) {
                $self->{$SQL_RECONTIME} += $DB_RECONNECT_TIME;

                # Connect failed
                EventLog( EVENT_WARN, MYNAMELINE() . "RECONNECT FAILED $self->{$SQL_CLASS} " . $self->host . ', ' . $self->db );
                return 0;
            }
            else {
                $self->{$SQL_CONNECTED} = 1;
                $self->{$SQL_RECONTIME} = 0;
                EventLog( EVENT_WARN, MYNAMELINE() . "RECONNECT Succedded $self->{$SQL_CLASS} " . $self->host . ', ' . $self->db );
            }
        }
        else {

            # Not Connected, and waiting to time out
            EventLog( EVENT_WARN, MYNAMELINE() . "TOO SOON to reconnect $self->{$SQL_CLASS} " . $self->host . ', ' . $self->db );
            return 0;
        }
    }

    eval {
        while ( ( !$ret ) && ( $try < $DB_MAX_RECONNECT_TRY ) ) {
            $try++;

            EventLog( EVENT_DEBUG, MYNAMELINE() . "SQLDO():$sql" );

            if ( !$self->dbh->do($sql) ) {

                # EventLog( EVENT_DEBUG, MYNAMELINE() . " problem: " . $DBI::errstr );

                # Catch the server going away, and try to reconnect
                if ( ( $self->dbh->err eq 'CR_SERVER_GONE_ERROR' ) || ( $self->dbh->err == 2006 ) ) {
                    EventLog( EVENT_WARN, MYNAMELINE() . "RECONNECT FOR " . $self->host . ', ' . $self->db . ':' . $DBI::errstr );
                    if ( $self->connect ) {
                        EventLog( EVENT_WARN, MYNAMELINE() . "RECONNECT FAILED " . $self->host . ', ' . $self->db . ':' . $DBI::errstr );
                        last;
                    }
                }
                else {
                    EventLog( EVENT_WARN, MYNAMELINE() . "SQLDO ERROR CLASS: $self->{$SQL_CLASS} " . $self->host . ', ' . $self->db . ':' . $DBI::errstr );
                    last;
                }
            }
            else {
                $ret = 1;
                $try = 0;
            }
        }

    };
    LOGEVALFAIL() if ($@);

    $ret;
}

#-------------------------------------------------------
# Can use READ ONLY connection, or the READ/WRITE connection.
#-------------------------------------------------------
sub sqlexecute {
    my ( $self, $s ) = @_;
    my $sth;
    my $sql;
    my $ret = 0;
    my $try = 0;

    # $self->reseterr;

    if ( ref($s) eq 'DBI::st' ) {
        $sth            = $s;
        $self->{'_sth'} = $s;
        $sql            = 0;
    }
    else {
        $sql = $s;
        $sth = 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . "CLASS: $self->{$SQL_CLASS} SQL:$sql" );

    eval {
        if ($sql) {
            $sth = $self->{'_sth'} = $self->dbh->prepare($sql) || confess $self->dbh->errstr;
        }

        while ( ( !$ret ) && ( $try < $DB_MAX_RECONNECT_TRY ) ) {

            if ( !( $ret = $sth->execute() ) ) {

                #
                # Changed from $$self to $self, was boming out with Not a Scalar Reference - 2011-09-04
                #
                if ( ( $self->dbh->err eq 'CR_SERVER_GONE_ERROR' )
                    || ( $self->dbh->err == 2006 )
                    || ( $self->dbh->err == 2013 )    # Lost Connection
                  ) {
                    $self->log_db_warn();
                    if ( !$self->connect ) {
                        $try++;
                    }
                    else {
                        EventLog( EVENT_ERR, " DB Err:" . $self->dbh->err . ":" . $self->dbh->errstr . " Try:" . $try );
                        $self->log_db_error();

                        #confess Carp::longmess( $sth->errstr );
                    }
                }
                else {
                    $self->log_db_error();

                    confess Carp::longmess( $sth->errstr );
                }
            }
            else {
                $ret++;
                $try = 0;
            }
        }
    };
    LOGEVALFAIL() if ($@);

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub sth {
    my ($self) = @_;
    $self->{'_sth'};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub dbh {
    my ($self) = @_;

    if ( !defined $self->{$SQL_DBH} ) {
        $self->connect;
    }

    $self->{$SQL_DBH};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub disconnect {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called for " . $self->{$SQL_DB} );

    if ( defined $self->{$SQL_DBH} ) {
        undef $self->{$SQL_DBH};
    }
    $self->{$SQL_CONNECTED} = 0;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub sql_connected {
    my ($self) = @_;
    my $ret = 0;

    if ( ( $self->{$SQL_CONNECTED} ) && ( defined $self->{$SQL_DBH} ) && ( $self->{$SQL_DBH}->ping ) ) {
        return 1;
    }
    elsif ( $self->{$SQL_CONNECTED} ) {
        $self->{$SQL_CONNECTED} = 0;
        $self->{$SQL_RECONTIME} = time() + $DB_RECONNECT_TIME;
        return 0;
    }
    elsif ( !defined $self->{$SQL_DBH} ) {
        EventLog( EVENT_DEBUG, MYNAMELINE() . " Missing DBH" );
        return 0;
    }
    elsif ( !$self->{$SQL_DBH}->ping ) {
        EventLog( EVENT_DEBUG, MYNAMELINE() . " DB Not Pingable " );
        return 0;
    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . " Should not be here" );
        return 0;
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub reconnect {
    my ($self) = @_;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE() );

    $self->disconnect;

    if ( ( !$self->{$SQL_RECONTIME} ) || ( $self->{$SQL_RECONTIME} < time() ) ) {
        $ret = $self->connect;
    }

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub force_reconnect {
    my ($self) = @_;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE() );

    $self->disconnect;
    $self->{$SQL_RECONTIME} = 0;
    $ret = $self->connect;
    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub connect {
    my ($self) = @_;
    my $ret = 0;
    my $newdbh;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called for " . $self->{$SQL_DB} );

    if ( $self->sql_connected ) {
        return 1;
    }

    if ( $self->{$SQL_RECONTIME} > time() ) {
        EventLog( EVENT_WARN, MYNAMELINE
              . " Too soon to connect to " . $self->{$SQL_DB}
              . " Waiting " . ( $self->{$SQL_RECONTIME} - time() )
              . " Seconds" );

    }
    else {

        my $db   = $self->{$SQL_DB};
        my $host = $self->{$SQL_HOST};
        my $port = $self->{$SQL_PORT};
        my $user = $self->{$SQL_USER};
        my $pass = $self->{$SQL_PASS};

        $self->disconnect;

        my $db_source = "dbi:mysql:"
          . "dbname=$db;"
          . "host=$host;"
          . "port=$port;"
          . "mysql_connect_timeout=$SQL_CONNECT_TIMEOUT;"
          ;

        EventLog( EVENT_DEBUG, MYNAMELINE . "Preparing to connect to DB: '" . $self->{$SQL_DB} . "'" );

        eval {
            $newdbh = DBI->connect(
                $db_source,
                $user,
                $pass,
                {
                    PrintError => $PRINT_ERROR,
                    RaiseError => $RAISE_ERROR,
                    AutoCommit => $AUTOCOMMIT,
                },
            );
        };

        if ( ($@) || ( !defined $newdbh ) ) {
            EventLog( EVENT_WARN, MYNAMELINE
                  . "Cannot open DB server, $DBI::errstr "
                  . "db:$db "
                  . "host:$host "
                  . "port:$port "
                  . "user:$user "
                  . "pass:$pass " );

            if ( $self->{$SQL_NO_CONNECT_FAIL} ) {
                confess MYNAMELINE . "SQL Connect to DB: " . $self->{$SQL_DB} . " Failed...";
            }
            else {
                $self->{$SQL_CONNECTED} = 0;
                $self->{$SQL_RECONTIME} = time() + $DB_RECONNECT_TIME;
                EventLog( EVENT_DEBUG, MYNAMELINE() . "DELAYED CONNECTION TO " . $self->{$SQL_DB} . " For " . $DB_RECONNECT_TIME . "s" );
            }
        }
        else {

            if ( !( ref($newdbh) =~ /DBI::/ ) ) {
                confess Dumper \$newdbh;
            }

            $newdbh->{mysql_auto_reconnect} = $AutoReconnect ? 1 : 0;

            EventLog( EVENT_DEBUG, MYNAMELINE() . "NEW CONNECTION TO " . $self->{$SQL_DB} );

            #
            # Check for Errors here
            #

            $self->{$SQL_DBH}       = $newdbh;
            $self->{$SQL_CONNECTED} = 1;
            $self->{$SQL_RECONTIME} = 0;
            $ret++;
        }

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub __delete_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_TABLE_NAME} || $parm_ref->{$DB_TABLE_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_NAME}   || $parm_ref->{$DB_KEY_NAME}   eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_VALUE}  || $parm_ref->{$DB_KEY_VALUE}  eq '' ) { confess Dumper $parm_ref; }
    my $table   = $parm_ref->{$DB_TABLE_NAME};
    my $keyname = $parm_ref->{$DB_KEY_NAME};
    my $keyval  = $parm_ref->{$DB_KEY_VALUE};

    if ( !defined $tablenames{$table} ) { confess "NO TABLE $table\n" . Dumper $parm_ref; }

    my $sql = "DELETE FROM $table "
      . " WHERE $keyname = "
      . ( ( $keyval =~ /[^\d+]/ ) ? " '$keyval' " : " $keyval " );

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    $ret;
}

#-------------------------------------------------------
#
#            {$DB_COL_NAME} => value
# Translate DB_COL to use update_record()
#-------------------------------------------------------
sub __update_record_db_col($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . Dumper $parm_ref );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    foreach my $k ( keys(%$parm_ref) ) {
        my $n;
        if ( $k eq $DB_TABLE_NAME ) { next; }
        if ( $k eq $DB_KEY_NAME )   { next; }
        if ( $k eq $DB_KEY_VALUE )  { next; }
        $n = $column_names{$k};
        if ( !defined $n ) {
            EventLog( EVENT_DEBUG, MYNAMELINE() . "Undefined column name $k, skipping" );
            next;
        }
        my $value = $parm_ref->{$k};
        $parm_ref->{ 'UPDATE_' . $n } = $value;
    }

    return $self->__update_record($parm_ref);

}

#-------------------------------------------------------
#	Hard coded column names being passed in.
#            {UPDATE_columnname} => value
#-------------------------------------------------------
sub __update_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_TABLE_NAME} || $parm_ref->{$DB_TABLE_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_NAME}   || $parm_ref->{$DB_KEY_NAME}   eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_VALUE}  || $parm_ref->{$DB_KEY_VALUE}  eq '' ) { confess Dumper $parm_ref; }
    my $table   = $parm_ref->{$DB_TABLE_NAME};
    my $keyname = $parm_ref->{$DB_KEY_NAME};
    my $keyval  = $parm_ref->{$DB_KEY_VALUE};

    if ( 3 >= keys(%$parm_ref) ) { confess Dumper $parm_ref; }

    # if ( !defined $tablenames{$table} ) { confess "No Table $table\n" . Dumper $parm_ref; }
    # if ( !defined $keynames{$keyname} ) { confess "No Key $keyname\n" . Dumper $parm_ref; }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . Dumper $parm_ref );

    foreach my $s ( keys(%$parm_ref) ) {
        if ( $s =~ /^UPDATE_/ ) {
            my $value = $parm_ref->{$s};
            $s =~ s/^UPDATE_//;
            my $name = $s;

            if ( !defined $value ) {
                cluck MYNAMELINE() . " undefined variables passed in" . Dumper $parm_ref;
            }

            my $sql = "UPDATE $table SET $name = "
              . ( ( $value ne '' ) && ( isdigit($value) || $value eq 'NULL' || $value eq 'true' || $value eq 'false' )
                ? " $value " : " '$value' " )
              . " WHERE $keyname = "
              . ( ( isdigit($keyval) ) ? " $keyval " : " '$keyval' " );

            EventLog( EVENT_DEBUG, MYNAMELINE() . "sql:" . $sql );

            if ( $self->sqldo($sql) ) {
                $ret++;
            }
            else {
                EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
            }
        }
    }
    $ret;
}

1;

