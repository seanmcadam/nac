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

our @export = qw (
  WORKER_PARM_SERVER
  WORKER_SERVER_LOCALHOST
);

our @EXPORT = ( @export, @NAC::LocalLogger::EXPORT );

# ----------------------------------------------
#
# ----------------------------------------------
sub new {
    my ( $class, $parms ) = @_;
    state %servers;
    my $self = {};
    my $s    = '';
    my $p    = '';

    my $server = $parms->{WORKER_PARM_SERVER};
    if ( !defined $server ) {
        $server = WORKER_SERVER_LOCALHOST;
        $s      = '127.0.0.1';
    }
    else {
        $s = $server;
    }

	$LOGGER_DEBUG_9->( " SERVER: " . $s );

    my $port = $parms->{WORKER_PARM_PORT};
    if ( defined $port ) {
        $p = $port;
    }

	$LOGGER_DEBUG_9->( " PORT: " . $p );

    #
    # Only creates on Job server connection per server
    #
    if ( !defined $servers{$server} ) {

        $servers{$server} = Gearman::XS::Worker->new();

        if ( $server eq WORKER_SERVER_LOCALHOST ) {
            $s = '';
            $p = '';
    		$LOGGER_DEBUG_9->( " CONNECT TO LOCALHOST " );
        }

        my $ret = $servers{$server}->add_server( $s, $p );
        if ( $ret != GEARMAN_SUCCESS ) {
	    $LOGGER_FATAL->( EVENT_FATAL, " ADD SERVER FAILED " );
        }

    }

    $self->{_SERVER} = $servers{$server};

    bless $self, $class;

    $LOGGER_DEBUG_9->( EVENT_START, " STARTING WORKER " );

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
	eval {
        my $ret = $self->_server->work();
        if ( $ret != GEARMAN_SUCCESS ) {
	    $LOGGER_CRIT->( " WORKER LOOP FAILED " );
        }
        };
	if( $@ ) {
	    $LOGGER_CRIT->( " EVAL ERROR:" . $@ );
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
	$LOGGER_FATAL->( EVENT_FATAL, " ADD WORKER FUNCTION FAILED:" . $function_obj->function_name );
    }
    $ret;
}

1;

