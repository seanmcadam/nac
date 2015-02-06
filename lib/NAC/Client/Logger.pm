#!/usr/bin/perl

package NAC::Client::Logger;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::Client;
use NAC::DataRequest::LocalLogger;
use Gearman::XS qw(:constants);
use Sys::Hostname;
use strict;

use constant CLIENT          => 'CLIENT';
use constant SET_LOG_LEVEL   => 'SET_LOG_LEVEL';
use constant SET_DEBUG_LEVEL => 'SET_DEBUG_LEVEL';

my $hostname = hostname();
my $program  = $$;

our @EXPORT = qw(
  SET_LOG_LEVEL
  SET_DEBUG_LEVEL
  CLIENT_PARM_SERVER_NAME
  LOG_DEBUG_LEVEL_0
  LOG_DEBUG_LEVEL_1
  LOG_DEBUG_LEVEL_2
  LOG_DEBUG_LEVEL_3
  LOG_DEBUG_LEVEL_4
  LOG_DEBUG_LEVEL_5
  LOG_DEBUG_LEVEL_6
  LOG_DEBUG_LEVEL_7
  LOG_DEBUG_LEVEL_8
  LOG_DEBUG_LEVEL_9
);

our @ISA = qw(NAC::Client);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    $self->{SET_LOG_LEVEL}   = ( defined $parms->{SET_LOG_LEVEL} )   ? $parms->{SET_LOG_LEVEL}   : LOG_LEVEL_INFO;
    $self->{SET_DEBUG_LEVEL} = ( defined $parms->{SET_DEBUG_LEVEL} ) ? $parms->{SET_DEBUG_LEVEL} : LOG_DEFAULT_DEBUG_LEVEL;
    bless $self, $class;
    $self;
}

sub set_log_level {
    my ( $self, $level ) = @_;
    $self->{SET_LOG_LEVEL} = $level;
}

sub set_debug_level {
    my ( $self, $level ) = @_;
    $self->{SET_DEBUG_LEVEL} = $level;
}

sub _log {
    my ( $self, $level, $event, $message, $debug_level ) = @_;
    my $ret        = 0;
    my $job_handle = 0;

    if ( $self->{SET_LOG_LEVEL} <= $logging_level{$level} ) {

        if ( !defined $debug_level ) {
            $debug_level = LOG_DEFAULT_DEBUG_LEVEL;
        }

        if ( $self->{SET_LOG_LEVEL} eq LOG_LEVEL_DEBUG ) {
            if ( $self->{SET_DEBUG_LEVEL} > $debugging_level{$debug_level} ) {
                goto LOG_DONE;
            }
        }

            my ( $package, $filename, $line, $subroutine ) = caller(2);
            ( $ret, $job_handle ) = $self->send_background( LOCAL_LOGGER_FUNCTION, NAC::DataRequest::LocalLogger->new( {
                        LOG_PARM_LEVEL      => $level,
                        LOG_PARM_EVENT      => $event,
                        LOG_PARM_MESSAGE    => $message,
                        LOG_PARM_HOST       => $hostname,
                        LOG_PARM_PROGRAM    => $program,
                        LOG_PARM_PACKAGE    => $package,
                        LOG_PARM_SUBROUTINE => $subroutine,
                        LOG_PARM_FILE       => $filename,
                        LOG_PARM_LINE       => $line,
            } ) );

            $ret = 1;
    }

  LOG_DONE:
    $ret;
}

sub FATAL {
    my $self = shift;
    $self->_log( LOG_LEVEL_FATAL, @_ );
}

sub CRIT {
    my $self = shift;
    $self->_log( LOG_LEVEL_CRIT, @_ );
}

sub ERROR {
    my $self = shift;
    $self->_log( LOG_LEVEL_ERROR, @_ );
}

sub NOTICE {
    my $self = shift;
    $self->_log( LOG_LEVEL_NOTICE, @_ );
}

sub INFO {
    my $self = shift;
    $self->_log( LOG_LEVEL_INFO, @_ );
}

sub DEBUG {
    my $self = shift;
    $self->_log( LOG_LEVEL_DEBUG, @_ );
}

