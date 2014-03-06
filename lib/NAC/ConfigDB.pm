#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: 1750 $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/ConfigDB.pm $:
#
#
# Author: Sean McAdam
# Purpose: read in config variables from config file and provide a simple way to read them
#
#

package NAC::ConfigDB;

use FindBin;
use lib "$FindBin::Bin/..";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Hostname;
use DBD::mysql;
use Data::Dumper;
use Carp qw(confess cluck carp);
use Env qw(HOME);
use NAC::Syslog;

use strict;
no strict 'subs';

# NAC::Syslog::ActivateDebug();
NAC::Syslog::DeactivateDebug();
NAC::Syslog::ActivateSyslog();
NAC::Syslog::ActivateStdout();

#
# Used in nacconfig file
#
Readonly our $NACRC_HOST     => 'HOST';
Readonly our $NACRC_PORT     => 'PORT';
Readonly our $NACRC_PASS     => 'PASS';
Readonly our $NACRC_USER     => 'USER';
Readonly our $NACRC_CONFIGDB => 'DB';

#
# Defaults
#
Readonly our $DEFAULT_NACCONFIGDB => 'nacconfig';
Readonly our $DEFAULT_NACHOST     => 'localhost';
Readonly our $DEFAULT_NACPORT     => 3306;
Readonly our $DEFAULT_NACUSER     => 'nacconfig';
Readonly our $DEFAULT_NACPASS     => 'nacconfig';
Readonly our $NACRC_FILENAME      => 'nacconfig';

#
# Used Internally
#
Readonly our $NACCONFIGDB => 'NAC-CONFIG-DB';
Readonly our $NACHOST     => 'NAC-CONFIG-HOST';
Readonly our $NACPORT     => 'NAC-CONFIG-PORT';
Readonly our $NACUSER     => 'NAC-CONFIG-USER';
Readonly our $NACPASS     => 'NAC-CONFIG-PASS';

#
# Exported to other modules
#
Readonly our $NAC_MASTER_WRITE_HOSTNAME       => 'NAC_MASTER_WRITE_HOSTNAME';
Readonly our $NAC_MASTER_WRITE_PORT           => 'NAC_MASTER_WRITE_PORT';
Readonly our $NAC_MASTER_WRITE_USER           => 'NAC_MASTER_WRITE_USER';
Readonly our $NAC_MASTER_WRITE_PASS           => 'NAC_MASTER_WRITE_PASS';
Readonly our $NAC_MASTER_WRITE_DB             => 'NAC_MASTER_WRITE_DB';
Readonly our $NAC_MASTER_WRITE_DB_AUDIT       => 'NAC_MASTER_WRITE_DB_AUDIT';
Readonly our $NAC_MASTER_WRITE_DB_EVENTLOG    => 'NAC_MASTER_WRITE_DB_EVENTLOG';
Readonly our $NAC_MASTER_WRITE_DB_RADIUSAUDIT => 'NAC_MASTER_WRITE_DB_RADIUSAUDIT';
Readonly our $NAC_MASTER_WRITE_DB_STATUS      => 'NAC_MASTER_WRITE_DB_STATUS';
Readonly our $NAC_MASTER_WRITE_DB_USER        => 'NAC_MASTER_WRITE_DB_USER';
Readonly our $NAC_SLAVE_HOSTNAME              => 'NAC_SLAVE_HOSTNAME';
Readonly our $NAC_SLAVE_PORT                  => 'NAC_SLAVE_PORT';
Readonly our $NAC_SLAVE_USER                  => 'NAC_SLAVE_USER';
Readonly our $NAC_SLAVE_PASS                  => 'NAC_SLAVE_PASS';
Readonly our $NAC_SLAVE_DB_AUDIT              => 'NAC_SLAVE_DB_AUDIT';
Readonly our $NAC_SLAVE_DB_CONFIG             => 'NAC_SLAVE_DB_CONFIG';
Readonly our $NAC_SLAVE_DB_EVENTLOG           => 'NAC_SLAVE_DB_EVENTLOG';
Readonly our $NAC_SLAVE_DB_RADIUSAUDIT        => 'NAC_SLAVE_DB_RADIUSAUDIT';
Readonly our $NAC_SLAVE_DB_STATUS             => 'NAC_SLAVE_DB_STATUS';
Readonly our $NAC_SLAVE_DB_USER               => 'NAC_SLAVE_DB_USER';
Readonly our $NAC_EVENTLOG_WRITE_HOSTNAME     => 'NAC_EVENTLOG_WRITE_HOSTNAME';
Readonly our $NAC_EVENTLOG_WRITE_PORT         => 'NAC_EVENTLOG_WRITE_PORT';
Readonly our $NAC_EVENTLOG_WRITE_DB           => 'NAC_EVENTLOG_WRITE_DB';
Readonly our $NAC_EVENTLOG_WRITE_USER         => 'NAC_EVENTLOG_WRITE_USER';
Readonly our $NAC_EVENTLOG_WRITE_PASS         => 'NAC_EVENTLOG_WRITE_PASS';
Readonly our $NAC_RADIUSAUDIT_WRITE_HOSTNAME  => 'NAC_RADIUSAUDIT_WRITE_HOSTNAME';
Readonly our $NAC_RADIUSAUDIT_WRITE_PORT      => 'NAC_RADIUSAUDIT_WRITE_PORT';
Readonly our $NAC_RADIUSAUDIT_WRITE_DB        => 'NAC_RADIUSAUDIT_WRITE_DB';
Readonly our $NAC_RADIUSAUDIT_WRITE_USER      => 'NAC_RADIUSAUDIT_WRITE_USER';
Readonly our $NAC_RADIUSAUDIT_WRITE_PASS      => 'NAC_RADIUSAUDIT_WRITE_PASS';
Readonly our $NAC_LOCAL_READONLY_HOSTNAME     => 'NAC_LOCAL_READONLY_HOSTNAME';
Readonly our $NAC_LOCAL_READONLY_PORT         => 'NAC_LOCAL_READONLY_PORT';
Readonly our $NAC_LOCAL_READONLY_USER         => 'NAC_LOCAL_READONLY_USER';
Readonly our $NAC_LOCAL_READONLY_PASS         => 'NAC_LOCAL_READONLY_PASS';
Readonly our $NAC_LOCAL_READONLY_DB           => 'NAC_LOCAL_READONLY_DB';
Readonly our $NAC_LOCAL_READONLY_DB_AUDIT     => 'NAC_LOCAL_READONLY_DB_AUDIT';
Readonly our $NAC_LOCAL_READONLY_DB_CONFIG    => 'NAC_LOCAL_READONLY_DB_CONFIG';
Readonly our $NAC_LOCAL_BUFFER_HOSTNAME       => 'NAC_LOCAL_BUFFER_HOSTNAME';
Readonly our $NAC_LOCAL_BUFFER_PORT           => 'NAC_LOCAL_BUFFER_PORT';
Readonly our $NAC_LOCAL_BUFFER_DB             => 'NAC_LOCAL_BUFFER_DB';
Readonly our $NAC_LOCAL_BUFFER_USER           => 'NAC_LOCAL_BUFFER_USER';
Readonly our $NAC_LOCAL_BUFFER_PASS           => 'NAC_LOCAL_BUFFER_PASS';
Readonly our $NAC_IB_HOSTNAME                 => 'NAC_IB_HOSTNAME';
Readonly our $NAC_IB_USER                     => 'NAC_IB_USER';
Readonly our $NAC_IB_PASS                     => 'NAC_IB_PASS';
Readonly our $NAC_SWITCH_SNMP_STRING          => 'NAC_SWITCH_SNMP_STRING';
Readonly our $NAC_SNMP_HOSTNAME               => 'NAC_SNMP_HOSTNAME';
Readonly our $NAC_SNMP_COMMUNITY              => 'NAC_SNMP_COMMUNITY';
Readonly our $NAC_SNMP_PORT                   => 'NAC_SNMP_PORT';
Readonly our $NAC_SNMP_SESSION                => 'NAC_SNMP_SESSION';

our @EXPORT = qw (
  $NAC_MASTER_WRITE_HOSTNAME
  $NAC_MASTER_WRITE_PORT
  $NAC_MASTER_WRITE_USER
  $NAC_MASTER_WRITE_PASS
  $NAC_MASTER_WRITE_DB
  $NAC_MASTER_WRITE_DB_AUDIT
  $NAC_MASTER_WRITE_DB_EVENTLOG
  $NAC_MASTER_WRITE_DB_RADIUSAUDIT
  $NAC_MASTER_WRITE_DB_STATUS
  $NAC_MASTER_WRITE_DB_USER
  $NAC_SLAVE_HOSTNAME
  $NAC_SLAVE_PORT
  $NAC_SLAVE_USER
  $NAC_SLAVE_PASS
  $NAC_SLAVE_DB_AUDIT
  $NAC_SLAVE_DB_CONFIG
  $NAC_SLAVE_DB_EVENTLOG
  $NAC_SLAVE_DB_RADIUSAUDIT
  $NAC_SLAVE_DB_STATUS
  $NAC_SLAVE_DB_USER
  $NAC_EVENTLOG_WRITE_HOSTNAME
  $NAC_EVENTLOG_WRITE_PORT
  $NAC_EVENTLOG_WRITE_DB
  $NAC_EVENTLOG_WRITE_USER
  $NAC_EVENTLOG_WRITE_PASS
  $NAC_RADIUSAUDIT_WRITE_HOSTNAME
  $NAC_RADIUSAUDIT_WRITE_PORT
  $NAC_RADIUSAUDIT_WRITE_DB
  $NAC_RADIUSAUDIT_WRITE_USER
  $NAC_RADIUSAUDIT_WRITE_PASS
  $NAC_LOCAL_READONLY_HOSTNAME
  $NAC_LOCAL_READONLY_PORT
  $NAC_LOCAL_READONLY_USER
  $NAC_LOCAL_READONLY_PASS
  $NAC_LOCAL_READONLY_DB
  $NAC_LOCAL_READONLY_DB_AUDIT
  $NAC_LOCAL_READONLY_DB_CONFIG
  $NAC_LOCAL_BUFFER_HOSTNAME
  $NAC_LOCAL_BUFFER_PORT
  $NAC_LOCAL_BUFFER_DB
  $NAC_LOCAL_BUFFER_USER
  $NAC_LOCAL_BUFFER_PASS
  $NAC_IB_HOSTNAME
  $NAC_IB_USER
  $NAC_IB_PASS
  $NAC_SWITCH_SNMP_STRING
  $NAC_SNMP_HOSTNAME
  $NAC_SNMP_COMMUNITY
  $NAC_SNMP_PORT
  $NAC_SNMP_SESSION
);

our %db_values = ();
my $HOSTNAME = hostname;
my $DBH;
my $config_file = $HOME . '/nac/etc/' . $NACRC_FILENAME;

sub new {
    my $class = shift;

    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called" );

    my $self = {};
    bless $self, $class;

    if ( !( keys(%db_values) ) ) {

        # Open nacconfig

        if ( open( NACCONFIG, $config_file ) ) {
            while (<NACCONFIG>) {
                chop;
                my $line = $_;
                my ( $n, $v );
                if ( ( $n, $v ) = split( '=', $line ) ) {
                    $n =~ s/\s//g;
                    $v =~ s/\s//g;
                    if ( $n =~ /^$NACRC_HOST/ ) {
                        $self->{$NACHOST} = $v;
                    }
                    elsif ( $n =~ /^$NACRC_PORT/ ) {
                        $self->{$NACPORT} = $v;
                    }
                    elsif ( $n =~ /^$NACRC_USER/ ) {
                        $self->{$NACUSER} = $v;
                    }
                    elsif ( $n =~ /^$NACRC_PASS/ ) {
                        $self->{$NACPASS} = $v;
                    }
                    elsif ( $n =~ /^$NACRC_CONFIGDB/ ) {
                        $self->{$NACCONFIGDB} = $v;
                    }
                    else {
                        warn "Unknown RC line: '$line'\n";
                    }
                }
                else {
                    warn "Bad RC line FORMAT: '$line'\n";
                }
            }
            close NACCONFIG;
        }
        else {
            warn "No config file: $config_file\n";
        }

        $self->{$NACCONFIGDB} = $DEFAULT_NACCONFIGDB if !defined $self->{$NACCONFIGDB};
        $self->{$NACHOST}     = $DEFAULT_NACHOST     if !defined $self->{$NACHOST};
        $self->{$NACPORT}     = $DEFAULT_NACPORT     if !defined $self->{$NACPORT};
        $self->{$NACUSER}     = $DEFAULT_NACUSER     if !defined $self->{$NACUSER};
        $self->{$NACPASS}     = $DEFAULT_NACPASS     if !defined $self->{$NACPASS};

        eval {
            if ( $self->_connect() )
            {
                $self->_read_db;
                $self->_disconnect();
                $ret++;
            }
        };
        if ($@) {

            # LOGEVALFAIL();
            warn MYNAME . " Cannot Connect to Config DB\n";
            return 0;
        }
    }
    else {

        # warn "ALREAD CALLED DB, REUSING VALUES\n";
        foreach my $k ( keys(%db_values) ) {
            $self->{$k} = $db_values{$k};
        }
        $ret++;
    }

    if ($ret) {
        return $self;
    }

    $ret;
}

sub DESTROY {
    0;
}

use vars '$AUTOLOAD';

sub AUTOLOAD {
    my ( $self, $val ) = @_;

    $AUTOLOAD =~ /.*::(\w+)/;
    my $function = $1;

    # EventLog( EVENT_INFO, MYNAMELINE . " '$function' called" );

    $function =~ tr/a-z/A-Z/;

    if ( !( $function =~ /^NAC_/ ) ) {
        print "SKIPPING: $function\n";
        return undef;
    }

    if ( !defined $self->{$function} ) {
        confess "Unknown Variable called: $function\n" . Dumper $self;
        return undef;
    }

    # EventLog( EVENT_INFO, "Return: " . $self->{$function} );
    return $self->{$function};
}

sub _read_db {
    my ($self) = (@_);
    my $ret;
    my $global_sql = "SELECT configid,hostname,name,value FROM config WHERE hostname IS NULL ";
    my $local_sql  = "SELECT configid,hostname,name,value FROM config WHERE hostname = '$HOSTNAME'";

    EventLog( EVENT_DEBUG, MYNAMELINE . " called" );

    if ( ( keys(%db_values) ) ) {
        EventLog( EVENT_WARN, MYNAMELINE . ' %db_values already setup... reinitalizing' );
    }

    %db_values = ();

    my $sth = $DBH->prepare($global_sql);
    if ( !( $ret = $sth->execute() ) ) {
        confess Carp::longmess( $sth->errstr );
    }

    while ( my @answer = $sth->fetchrow_array() ) {
        my $col      = 0;
        my $id       = $answer[ $col++ ];
        my $hostname = $answer[ $col++ ];
        my $name     = $answer[ $col++ ];
        my $value    = $answer[ $col++ ];

        EventLog( EVENT_DEBUG, 'Global[' . ']' . " $name: $value " );

        $self->{$name} = $value;
        $db_values{$name} = $value;
    }

    $sth = $DBH->prepare($local_sql);
    if ( !( $ret = $sth->execute() ) ) {
        confess Carp::longmess( $sth->errstr );
    }

    while ( my @answer = $sth->fetchrow_array() ) {
        my $col      = 0;
        my $id       = $answer[ $col++ ];
        my $hostname = $answer[ $col++ ];
        my $name     = $answer[ $col++ ];
        my $value    = $answer[ $col++ ];

        EventLog( EVENT_DEBUG,
            'Local[' . "$hostname" . ']' . " $name: $value " );

        $self->{$name} = $value;
    }

}

sub _disconnect {
    my ($self) = (@_);
}

sub _connect {
    my ($self) = (@_);
    my $ret = 0;

    my $mysql_db   = $self->{$NACCONFIGDB};
    my $mysql_host = $self->{$NACHOST};
    my $mysql_port = $self->{$NACPORT};
    my $mysql_user = $self->{$NACUSER};
    my $mysql_pass = $self->{$NACPASS};

    # EventLog( EVENT_DEBUG, ( MYNAMELINE . "() called\n" ) );

    my $db_source =
      "dbi:mysql:"
      . "dbname=$mysql_db;"
      . "host=$mysql_host;"
      . "port=$mysql_port;";

    eval {
        if (
            !(
                $DBH = DBI->connect(
                    $db_source, $mysql_user, $mysql_pass,
                    { PrintError => 1, RaiseError => 1, AutoCommit => 1 }
                )
            )
          )
        {
            carp "Cannot open DB for config, $DBI::errstr\n"
              . "db:$mysql_db\n"
              . "host:$mysql_host\n"
              . "port:$mysql_port\n"
              . "user:$mysql_user\n"
              . "pass:$mysql_pass\n";
        }
        else {

            # $DBH->{mysql_auto_reconnect} = $AutoReconnect ? 1 : 0;
            $ret++;
        }

    };
    if ($@) {

        # LOGEVALFAIL();
        warn MYNAMELINE . " CONFIG DB UNAVAILABLE...\n$@";
        $ret = 0;
    }

    $ret;
}

1;
