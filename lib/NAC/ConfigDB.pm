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

#use lib "$ENV{HOME}/lib/perl5";
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Hostname;
use DBD::mysql;
use Data::Dumper;
use Carp qw(confess cluck);
use NAC::Syslog;

use strict;
no strict 'subs';

NAC::Syslog::ActivateDebug();
NAC::Syslog::ActivateSyslog();
NAC::Syslog::ActivateStdout();

Readonly our $CONFIG_NACCONFIGDB => 'nacconfig';
Readonly our $CONFIG_HOST        => 'localhost';
Readonly our $CONFIG_PORT        => 3306;
Readonly our $CONFIG_USERID      => 'nacconfig';
Readonly our $CONFIG_PASSWORD    => '*** some default password ***';

Readonly our $NAC_MASTER_WRITE_HOSTNAME      => 'NAC_MASTER_WRITE_HOSTNAME';
Readonly our $NAC_MASTER_WRITE_PORT          => 'NAC_MASTER_WRITE_PORT';
Readonly our $NAC_MASTER_WRITE_DB            => 'NAC_MASTER_WRITE_DB';
Readonly our $NAC_MASTER_WRITE_USER          => 'NAC_MASTER_WRITE_USER';
Readonly our $NAC_MASTER_WRITE_PASS          => 'NAC_MASTER_WRITE_PASS';
Readonly our $NAC_EVENTLOG_WRITE_HOSTNAME    => 'NAC_EVENTLOG_WRITE_HOSTNAME';
Readonly our $NAC_EVENTLOG_WRITE_PORT        => 'NAC_EVENTLOG_WRITE_PORT';
Readonly our $NAC_EVENTLOG_WRITE_DB          => 'NAC_EVENTLOG_WRITE_DB';
Readonly our $NAC_EVENTLOG_WRITE_USER        => 'NAC_EVENTLOG_WRITE_USER';
Readonly our $NAC_EVENTLOG_WRITE_PASS        => 'NAC_EVENTLOG_WRITE_PASS';
Readonly our $NAC_RADIUSAUDIT_WRITE_HOSTNAME => 'NAC_RADIUSAUDIT_WRITE_HOSTNAME';
Readonly our $NAC_RADIUSAUDIT_WRITE_PORT     => 'NAC_RADIUSAUDIT_WRITE_PORT';
Readonly our $NAC_RADIUSAUDIT_WRITE_DB       => 'NAC_RADIUSAUDIT_WRITE_DB';
Readonly our $NAC_RADIUSAUDIT_WRITE_USER     => 'NAC_RADIUSAUDIT_WRITE_USER';
Readonly our $NAC_RADIUSAUDIT_WRITE_PASS     => 'NAC_RADIUSAUDIT_WRITE_PASS';
Readonly our $NAC_LOCAL_READONLY_HOSTNAME    => 'NAC_LOCAL_READONLY_HOSTNAME';
Readonly our $NAC_LOCAL_READONLY_PORT        => 'NAC_LOCAL_READONLY_PORT';
Readonly our $NAC_LOCAL_READONLY_DB          => 'NAC_LOCAL_READONLY_DB';
Readonly our $NAC_LOCAL_READONLY_USER        => 'NAC_LOCAL_READONLY_USER';
Readonly our $NAC_LOCAL_READONLY_PASS        => 'NAC_LOCAL_READONLY_PASS';
Readonly our $NAC_LOCAL_BUFFER_HOSTNAME      => 'NAC_LOCAL_BUFFER_HOSTNAME';
Readonly our $NAC_LOCAL_BUFFER_PORT          => 'NAC_LOCAL_BUFFER_PORT';
Readonly our $NAC_LOCAL_BUFFER_DB            => 'NAC_LOCAL_BUFFER_DB';
Readonly our $NAC_LOCAL_BUFFER_USER          => 'NAC_LOCAL_BUFFER_USER';
Readonly our $NAC_LOCAL_BUFFER_PASS          => 'NAC_LOCAL_BUFFER_PASS';
Readonly our $NAC_SLAVE_HOSTNAME             => 'NAC_SLAVE_HOSTNAME';
Readonly our $NAC_IB_HOSTNAME                => 'NAC_IB_HOSTNAME';
Readonly our $NAC_IB_USER                    => 'NAC_IB_USER';
Readonly our $NAC_IB_PASS                    => 'NAC_IB_PASS';
Readonly our $NAC_SWITCH_SNMP_STRING         => 'NAC_SWITCH_SNMP_STRING';
Readonly our $NAC_SNMP_HOSTNAME              => 'SNMP_HOSTNAME';
Readonly our $NAC_SNMP_COMMUNITY             => 'SNMP_COMMUNITY';
Readonly our $NAC_SNMP_PORT                  => 'SNMP_PORT';
Readonly our $NAC_SNMP_SESSION               => 'SNMP_SESSION';

our @EXPORT = qw (
  $NAC_MASTER_WRITE_HOSTNAME
  $NAC_MASTER_WRITE_PORT
  $NAC_MASTER_WRITE_DB
  $NAC_MASTER_WRITE_USER
  $NAC_MASTER_WRITE_PASS
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
  $NAC_LOCAL_READONLY_DB
  $NAC_LOCAL_READONLY_USER
  $NAC_LOCAL_READONLY_PASS
  $NAC_LOCAL_BUFFER_HOSTNAME
  $NAC_LOCAL_BUFFER_PORT
  $NAC_LOCAL_BUFFER_DB
  $NAC_LOCAL_BUFFER_USER
  $NAC_LOCAL_BUFFER_PASS
  $NAC_SLAVE_HOSTNAME
  $NAC_IB_HOSTNAME
  $NAC_IB_USER
  $NAC_IB_PASS
  $NAC_SWITCH_SNMP_STRING
  $NAC_SNMP_HOSTNAME
  $NAC_SNMP_COMMUNITY
  $NAC_SNMP_PORT
  $NAC_SNMP_SESSION
);

my $HOSTNAME = hostname;
my $DBH;

sub new {
    my $class = shift;

    my $ret = 0;

    # EventLog( EVENT_INFO, MYNAMELINE . " called" );

    my $self = {};

    eval {
        if ( _connect() ) {
            $self->_read_db;
            _disconnect();
            $ret++;
        }
    };
    if ($@) {
        LOGEVALFAIL();
        return 0;
    }

    if ($ret) {
        bless $self, $class;
        $self;
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
        return;
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

        EventLog( EVENT_DEBUG, 'Local[' . "$hostname" . ']' . " $name: $value " );

        $self->{$name} = $value;
    }

}

sub _disconnect {
}

sub _connect {
    my $ret;

    my $mysql_db   = $CONFIG_NACCONFIGDB;
    my $mysql_host = $CONFIG_HOST;
    my $mysql_port = $CONFIG_PORT;
    my $mysql_user = $CONFIG_USERID;
    my $mysql_pass = $CONFIG_PASSWORD;

    # EventLog( EVENT_DEBUG, ( MYNAMELINE . "() called\n" ) );

    my $db_source = "dbi:mysql:"
      . "dbname=$mysql_db;"
      . "host=$mysql_host;"
      . "port=$mysql_port;"
      ;

    eval {
        if ( !( $DBH = DBI->connect(
                    $db_source,
                    $mysql_user,
                    $mysql_pass,
                    { PrintError => 1, RaiseError => 1, AutoCommit => 1 } ) ) )
        {
            carp "Cannot open DB for config, $DBI::errstr\n"
              . "db:$mysql_db\n"
              . "host:$mysql_host\n"
              . "port:$mysql_port\n"
              . "user:$mysql_user\n"
              . "pass:$mysql_pass\n"
              ;
        }
        else {

            # $DBH->{mysql_auto_reconnect} = $AutoReconnect ? 1 : 0;
            $ret++;
        }

    };
    if ($@) {
        LOGEVALFAIL();
        carp MYNAMELINE . " CONFIG DB UNAVAILABLE...\n$@";
    }

    $ret;
}

1;
