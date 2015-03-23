#!/usr/bin/perl
#
#
# Used as a base class to connect to a Database
# and provide common DB access routines and error handling
#
package NAC::Worker::DB;

use Data::Dumper;
use base qw( Exporter );
use DBI;
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DB;
use NAC::LocalLogger;
use strict;

use constant 'DB_SERVER' => 'DB_SERVER';
use constant 'DB_PORT'   => 'DB_PORT';
use constant 'DB_USER'   => 'DB_USER';
use constant 'DB_PASS'   => 'DB_PASS';
use constant 'DB_NAME'   => 'DB_NAME';

sub dbh_init;
sub DBH;

my $INIT = 0;
our $DBH = 0;

my @export = qw (
  DB_SERVER
  DB_PORT
  DB_USER
  DB_PASS
  DB_NAME
  dbh_init
  DBH
);

our @EXPORT = ( @export, @NAC::DB::EXPORT );

#
# Some default Values
#
my $db_source;
my $server = 'localhost';
my $port   = '3306';
my $user   = 'userid';
my $pass   = 'password';
my $db     = 'mysql';

sub dbh_init {
    my ($parms) = @_;


    if ($DBH) { return; }

    $LOGGER_DEBUG_2->( EVENT_START, "INIT DB" );

    $INIT = 1;


    if ( 'HASH' eq ref($parms) ) {
        $server = $parms->{DB_SERVER} if ( defined $parms->{DB_SERVER} );
        $port   = $parms->{DB_PORT}   if ( defined $parms->{DB_PORT} );
        $user   = $parms->{DB_USER}   if ( defined $parms->{DB_USER} );
        $pass   = $parms->{DB_PASS}   if ( defined $parms->{DB_PASS} );
        $db     = $parms->{DB_NAME}   if ( defined $parms->{DB_NAME} );
    }

    $LOGGER_DEBUG_9->( "DB Settings: $server, $port, $user, $db" );

    $db_source = "dbi:mysql:"
      . "dbname=$db;"
      . "host=$server;"
      . "port=$port;"
      ;

}

sub mysql_HandleError {
    my ( $errstr, $dbh ) = @_;

    $LOGGER_WARN->( "MYSQL ERROR HANDLE CALLED" . $dbh::errstr );
    $LOGGER_FATAL->( "MYSQL ERROR HANDLE CALLED" . Dumper @_ );

    # Need to fill in here
    # Catch DB disconnect.

}

sub db_connect {

    if ( !( $DBH = DBI->connect(
                $db_source,
                $user,
                $pass,
                {
                    PrintError           => 1,
                    RaiseError           => 1,
                    AutoCommit           => 1,
                    mysql_auto_reconnect => 1,
                    mysql_HandleError    => \&mysql_HandleError,
                },
            ) ) ) {
        $LOGGER_FATAL->( " CONNECT DB FAILED " . $DBI::errstr );
    }

    $LOGGER_DEBUG_2->( "DB Connected" );
}

sub DBH {

    if ( !$INIT ) {
        $LOGGER_FATAL->(" CALLED DBH BEFORE INIT ");
    }

    $LOGGER_DEBUG_9->(" CALLED DBH ");

    if ( !$DBH ) {
        db_connect();
    }

    $DBH;
}

1;

