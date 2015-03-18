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
my $program  = $0;

our $LOGGER_EVENT   = sub { confess "*** LOGGER_EVENT UNINITIALIZED ***" };
our $LOGGER_FATAL   = sub { confess "*** LOGGER_FATAL UNINITIALIZED ***" };
our $LOGGER_CRIT    = sub { confess "*** LOGGER_CRIT UNINITIALIZED ***" };
our $LOGGER_ERROR   = sub { confess "*** LOGGER_ERROR UNINITIALIZED ***" };
our $LOGGER_WARN    = sub { confess "*** LOGGER_WARN UNINITIALIZED ***" };
our $LOGGER_NOTICE  = sub { confess "*** LOGGER_NOTICE UNINITIALIZED ***" };
our $LOGGER_INFO    = sub { confess "*** LOGGER_INFO UNINITIALIZED ***" };
our $LOGGER_DEBUG_0 = sub { confess "*** LOGGER_DENUG_0 UNINITIALIZED ***" };
our $LOGGER_DEBUG_1 = sub { confess "*** LOGGER_DENUG_1 UNINITIALIZED ***" };
our $LOGGER_DEBUG_2 = sub { confess "*** LOGGER_DENUG_2 UNINITIALIZED ***" };
our $LOGGER_DEBUG_3 = sub { confess "*** LOGGER_DENUG_3 UNINITIALIZED ***" };
our $LOGGER_DEBUG_4 = sub { confess "*** LOGGER_DENUG_4 UNINITIALIZED ***" };
our $LOGGER_DEBUG_5 = sub { confess "*** LOGGER_DENUG_5 UNINITIALIZED ***" };
our $LOGGER_DEBUG_6 = sub { confess "*** LOGGER_DENUG_6 UNINITIALIZED ***" };
our $LOGGER_DEBUG_7 = sub { confess "*** LOGGER_DENUG_7 UNINITIALIZED ***" };
our $LOGGER_DEBUG_8 = sub { confess "*** LOGGER_DENUG_8 UNINITIALIZED ***" };
our $LOGGER_DEBUG_9 = sub { confess "*** LOGGER_DENUG_9 UNINITIALIZED ***" };

our @export = qw(
  $LOGGER_EVENT
  $LOGGER_FATAL
  $LOGGER_CRIT
  $LOGGER_ERROR
  $LOGGER_WARN
  $LOGGER_NOTICE
  $LOGGER_INFO
  $LOGGER_DEBUG_0
  $LOGGER_DEBUG_1
  $LOGGER_DEBUG_2
  $LOGGER_DEBUG_3
  $LOGGER_DEBUG_4
  $LOGGER_DEBUG_5
  $LOGGER_DEBUG_6
  $LOGGER_DEBUG_7
  $LOGGER_DEBUG_8
  $LOGGER_DEBUG_9
  SET_LOG_LEVEL
  SET_DEBUG_LEVEL
  CLIENT_PARM_SERVER_NAME
);

our @EXPORT = ( @export, @NAC::DataRequest::LocalLogger::EXPORT );

our @ISA = qw(NAC::Client);

# ---------------------------------------------
sub new {
    my ( $class, $parms ) = @_;

    # my $self = $class->SUPER::new($parms);
    my $self = $class->SUPER::new();

    $self->{SET_LOG_LEVEL}   = ( defined $parms->{SET_LOG_LEVEL} )   ? $parms->{SET_LOG_LEVEL}   : LOG_LEVEL_INFO;
    $self->{SET_DEBUG_LEVEL} = ( defined $parms->{SET_DEBUG_LEVEL} ) ? $parms->{SET_DEBUG_LEVEL} : LOG_DEFAULT_DEBUG_LEVEL;

    $LOGGER_FATAL   = sub { $self->_LOG( LOG_LEVEL_FATAL,  LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_FATAL ),  @_ ); confess Dumper @_; };
    $LOGGER_CRIT    = sub { $self->_LOG( LOG_LEVEL_CRIT,   LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_CRIT ),   @_ ); };
    $LOGGER_ERROR   = sub { $self->_LOG( LOG_LEVEL_ERROR,  LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_ERR ),    @_ ); };
    $LOGGER_WARN    = sub { $self->_LOG( LOG_LEVEL_WARN,   LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_WARN ),   @_ ); };
    $LOGGER_NOTICE  = sub { $self->_LOG( LOG_LEVEL_NOTICE, LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_NOTICE ), @_ ); };
    $LOGGER_INFO    = sub { $self->_LOG( LOG_LEVEL_INFO,   LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_INFO ),   @_ ); };
    $LOGGER_EVENT   = sub { $self->_LOG( LOG_LEVEL_EVENT,  LOG_DEBUG_LEVEL_NONE, ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_INFO ),   @_ ); };
    $LOGGER_DEBUG_0 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_0,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_1 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_1,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_2 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_2,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_3 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_3,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_4 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_4,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_5 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_5,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_6 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_6,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_7 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_7,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_8 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_8,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };
    $LOGGER_DEBUG_9 = sub { $self->_LOG( LOG_LEVEL_DEBUG,  LOG_DEBUG_LEVEL_9,    ( ( defined $log_events{ $_[0] } ) ? shift @_ : EVENT_DEBUG ),  @_ ); };

    bless $self, $class;
    $self;
}

# ---------------------------------------------
sub set_log_level {
    my ( $self, $level ) = @_;
    $self->{SET_LOG_LEVEL} = $level;
}

# ---------------------------------------------
sub set_debug_level {
    my ( $self, $level ) = @_;
    $self->{SET_DEBUG_LEVEL} = $level;
}

# ---------------------------------------------
sub _LOG {
    my ( $self, $level, $debug_level, $event, $message ) = @_;
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

        my ( $package, $filename, $line, $subroutine ) = caller(1);
        ( $ret, $job_handle ) = $self->do_background( LOCAL_LOGGER_FUNCTION, NAC::DataRequest::LocalLogger->new( {
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

