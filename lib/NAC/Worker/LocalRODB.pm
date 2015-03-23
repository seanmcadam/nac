#!/usr/bin/perl

package NAC::Worker::LocalRODB;

use Data::Dumper;
use FindBin;
use Sys::Hostname;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::Client::Config;
use NAC::Worker;
use NAC::Worker::DB;
use NAC::Worker::Function::GetLocalRODB;
use strict;

our @ISA = qw(NAC::Worker);

my $hostname = hostname();

sub new {
    my ( $class, $parms ) = @_;
    $class = __PACKAGE__;

$LOGGER_DEBUG_2->(EVENT_START);

    if ( !defined $parms ) {
        $parms = {};
        $parms->{WORKER_PARM_SERVER} = WORKER_SERVER_LOCALHOST;
    }

    my $config  = NAC::Client::Config->new();
    my $db_host = 0;
    my $db_port = 0;
    my $db_user = 0;
    my $db_pass = 0;
    my $db_name = 0;

    $db_host = $config->get_value( { CONFIG_HOSTNAME => $hostname, CONFIG_NAME => NAC_LOCAL_READONLY_HOSTNAME, } );
    $db_port = $config->get_value( { CONFIG_HOSTNAME => $hostname, CONFIG_NAME => NAC_LOCAL_READONLY_PORT, } );
    $db_user = $config->get_value( { CONFIG_HOSTNAME => $hostname, CONFIG_NAME => NAC_LOCAL_READONLY_USER, } );
    $db_pass = $config->get_value( { CONFIG_HOSTNAME => $hostname, CONFIG_NAME => NAC_LOCAL_READONLY_PASS, } );
    $db_name = $config->get_value( { CONFIG_HOSTNAME => $hostname, CONFIG_NAME => NAC_LOCAL_READONLY_DB, } );

    if ( !defined $db_host ) {
        $db_host = $config->get_value( { CONFIG_HOSTNAME => HOSTNAME_BLANK, CONFIG_NAME => NAC_LOCAL_READONLY_HOSTNAME, } );
    }
    if ( !defined $db_host ) {
        $db_port = $config->get_value( { CONFIG_HOSTNAME => HOSTNAME_BLANK, CONFIG_NAME => NAC_LOCAL_READONLY_PORT, } );
    }
    if ( !defined $db_host ) {
        $db_user = $config->get_value( { CONFIG_HOSTNAME => HOSTNAME_BLANK, CONFIG_NAME => NAC_LOCAL_READONLY_USER, } );
    }
    if ( !defined $db_host ) {
        $db_pass = $config->get_value( { CONFIG_HOSTNAME => HOSTNAME_BLANK, CONFIG_NAME => NAC_LOCAL_READONLY_PASS, } );
    }
    if ( !defined $db_host ) {
        $db_name = $config->get_value( { CONFIG_HOSTNAME => HOSTNAME_BLANK, CONFIG_NAME => NAC_LOCAL_READONLY_DB, } );
    }

    #
    # Replace with Get Config
    #
    NAC::Worker::DB::dbh_init( {
            DB_SERVER => $db_host,
            DB_PORT   => $db_port,
            DB_USER   => $db_user,
            DB_PASS   => $db_pass,
            DB_NAME   => $db_name,
    } );

    my $self = $class->SUPER::new($parms);
    $self->add_worker_function( NAC::Worker::Function::GetLocalRODB->new() );

    bless $self, $class;
    $self;
}

1;

