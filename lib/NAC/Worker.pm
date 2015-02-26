#!/usr/bin/perl
#
# Establish local connection to GM server
# Register Functions
#
#

package NAC::Worker;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use Gearman::XS qw(:constants);
use Gearman::XS::Worker;
use FindBin;
use lib "$FindBin::Bin/..";
use NAC::LocalLogger;
use strict;
use 5.010;

use constant WORKER_SERVER_LOCALHOST => 'WORKER_SERVER_LOCALHOST';
use constant WORKER_SERVER_PORT      => 'WORKER_SERVER_PORT';
use constant WORKER_PARM_SERVER      => 'WORKER_PARM_SERVER';
use constant WORKER_PARM_NOLOG       => 'WORKER_PARM_NOLOG';
use constant _SERVER                 => 'SERVER';
use constant _LOGGER                 => 'LOGGER_CLIENT';

our @EXPORT = qw (
  WORKER_PARM_SERVER
  WORKER_SERVER_LOCALHOST
);

# ----------------------------------------------
#
# ----------------------------------------------
sub new {
    my ( $class, $parms ) = @_;
    state %servers;
    my $self = {};
    my $s    = '';
    my $p    = '';

    if ( !defined $parms || !defined $parms->{WORKER_PARM_NOLOG} ) {
        NAC::LocalLogger->new();
    }
    else {

        # place holders if the system does not have logging in place
        $NAC::LOG_EVENT   = sub { };
        $NAC::LOG_FATAL   = sub { };
        $NAC::LOG_CRIT    = sub { };
        $NAC::LOG_ERROR   = sub { };
        $NAC::LOG_NOTICE  = sub { };
        $NAC::LOG_INFO    = sub { };
        $NAC::LOG_DEBUG_0 = sub { };
        $NAC::LOG_DEBUG_1 = sub { };
        $NAC::LOG_DEBUG_2 = sub { };
        $NAC::LOG_DEBUG_3 = sub { };
        $NAC::LOG_DEBUG_4 = sub { };
        $NAC::LOG_DEBUG_5 = sub { };
        $NAC::LOG_DEBUG_6 = sub { };
        $NAC::LOG_DEBUG_7 = sub { };
        $NAC::LOG_DEBUG_8 = sub { };
        $NAC::LOG_DEBUG_9 = sub { };
    }

    my $server = $parms->{WORKER_PARM_SERVER};
    if ( !defined $server ) {
        $server = WORKER_SERVER_LOCALHOST;
        $s      = '127.0.0.1';
    }
    else {
        $s = $server;
    }

    my $port = $parms->{WORKER_PARM_PORT};
    if ( defined $port ) {
        $p = $port;
    }

    #
    # Only creates on Job server connection per server
    #
    if ( !defined $servers{$server} ) {

        $servers{$server} = Gearman::XS::Worker->new();

        if ( $server eq WORKER_SERVER_LOCALHOST ) {
            $s = '';
            $p = '';
        }

        my $ret = $servers{$server}->add_server( $s, $p );
        if ( $ret != GEARMAN_SUCCESS ) {
            confess;
        }

    }

    $self->{_SERVER} = $servers{$server};

    bless $self, $class;

    $NAC::LOG_DEBUG_5->( EVENT_START, " STARTING WORKER " );

    $self;
}

# ----------------------------------------------
#
# ----------------------------------------------
sub _server {
    my ($self) = @_;
    $self->{_SERVER};
}

# ----------------------------------------------
#
# ----------------------------------------------
sub work {
    my ($self) = @_;
    while (1) {
        my $ret = $self->_server->work();
        if ( $ret != GEARMAN_SUCCESS ) {
            confess;
        }
    }
}

# ----------------------------------------------
#
# ----------------------------------------------
sub add_worker_function {
    my ( $self, $function_obj, $options ) = @_;

    confess if ( !( ref($function_obj) =~ /^NAC::Worker::Function::/ ) );

    # $function_obj->add_logger( $self->{_LOGGER} );

    my $ret = $self->_server->add_function( $function_obj->function_name, 0, $function_obj->function_ref, $options );
    if ( $ret != GEARMAN_SUCCESS ) {
        warn;
    }
    $ret;
}

1;

