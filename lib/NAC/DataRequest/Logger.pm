#!/usr/bin/perl

package NAC::DataRequest::Logger;

use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest;
use strict;


use constant LOG_PARM_LEVEL    => 'LOG_PARM_LEVEL';
use constant LOG_PARM_EVENT    => 'LOG_PARM_EVENT';
use constant LOG_PARM_MESSAGE  => 'LOG_PARM_MESSAGE';
use constant LOG_PARM_PACKAGE  => 'LOG_PARM_PACKAGE';
use constant LOG_PARM_PROGRAM  => 'LOG_PARM_PROGRAM';
use constant LOG_PARM_HOSTNAME => 'LOG_PARM_HOSTNAME';
use constant LOG_PARM_FILE     => 'LOG_PARM_FILE';
use constant LOG_PARM_LINE     => 'LOG_PARM_LINE';
use constant LOG_LEVEL_EVENT   => 'LOG_EVENT';
use constant LOG_LEVEL_FATAL   => 'LOG_FATAL';
use constant LOG_LEVEL_CRIT    => 'LOG_CRIT';
use constant LOG_LEVEL_ERROR   => 'LOG_ERROR';
use constant LOG_LEVEL_WARN    => 'LOG_WARN';
use constant LOG_LEVEL_NOTICE  => 'LOG_NOTICE';
use constant LOG_LEVEL_INFO    => 'LOG_INFO';
use constant LOG_LEVEL_DEBUG   => 'LOG_DEBUG';
use constant LOG_DEBUG_LEVEL   => 'LOG_DEBUG_LEVEL';
use constant LOG_DEBUG_LEVEL_0 => 'DEBUG_LEVEL_0';       # Tiny Debug
use constant LOG_DEBUG_LEVEL_1 => 'DEBUG_LEVEL_1';       # Sparse Debug
use constant LOG_DEBUG_LEVEL_2 => 'DEBUG_LEVEL_2';       # Light Debug
use constant LOG_DEBUG_LEVEL_3 => 'DEBUG_LEVEL_3';       # Moderate Debug
use constant LOG_DEBUG_LEVEL_4 => 'DEBUG_LEVEL_4';       # Medium Debug
use constant LOG_DEBUG_LEVEL_5 => 'DEBUG_LEVEL_5';       # Verbose Debug
use constant LOG_DEBUG_LEVEL_6 => 'DEBUG_LEVEL_6';       # Very Verbose Debug
use constant LOG_DEBUG_LEVEL_7 => 'DEBUG_LEVEL_7';       # Heavy Debug
use constant LOG_DEBUG_LEVEL_8 => 'DEBUG_LEVEL_8';       # Painful Debug
use constant LOG_DEBUG_LEVEL_9 => 'DEBUG_LEVEL_9';       # So Very Painful Debug

use constant EVENT_START => 'EVENT_START';

use constant LOG_DEFAULT_LEVEL       => LOG_LEVEL_DEBUG;
use constant LOG_DEFAULT_DEBUG_LEVEL => LOG_DEBUG_LEVEL_9;

our %logging_level = (
    LOG_LEVEL_EVENT  => 0,
    LOG_LEVEL_FATAL  => 0,
    LOG_LEVEL_CRIT   => 1,
    LOG_LEVEL_ERROR  => 2,
    LOG_LEVEL_WARN   => 3,
    LOG_LEVEL_NOTICE => 4,
    LOG_LEVEL_INFO   => 5,
    LOG_LEVEL_DEBUG  => 10,
);

our %debugging_level = (
    LOG_DEBUG_LEVEL_0 => 0,
    LOG_DEBUG_LEVEL_1 => 1,
    LOG_DEBUG_LEVEL_2 => 2,
    LOG_DEBUG_LEVEL_3 => 3,
    LOG_DEBUG_LEVEL_4 => 4,
    LOG_DEBUG_LEVEL_5 => 5,
    LOG_DEBUG_LEVEL_6 => 6,
    LOG_DEBUG_LEVEL_7 => 7,
    LOG_DEBUG_LEVEL_8 => 8,
    LOG_DEBUG_LEVEL_9 => 9,
);

our @EXPORT = qw(
  %logging_level
  %debugging_level
  LOG_PARM_LEVEL
  LOG_PARM_EVENT
  LOG_PARM_MESSAGE
  LOG_PARM_PACKAGE
  LOG_PARM_PROGRAM
  LOG_PARM_FILE
  LOG_PARM_LINE
  LOG_LEVEL_EVENT
  LOG_LEVEL_FATAL
  LOG_LEVEL_CRIT
  LOG_LEVEL_ERROR
  LOG_LEVEL_WARN
  LOG_LEVEL_NOTICE
  LOG_LEVEL_INFO
  LOG_LEVEL_DEBUG
  LOG_DEFAULT_LEVEL
  LOG_DEFAULT_DEBUG_LEVEL
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
  EVENT_START
);

our @ISA = qw(NAC::DataRequest);

sub new {
    my ( $class, $parms ) = @_;

    my $level       = $parms->{LOG_PARM_LEVEL};
    my $debug_level = $parms->{LOG_PARM_LEVEL};
    my $event       = $parms->{LOG_PARM_EVENT};
    my $message     = $parms->{LOG_PARM_MESSAGE};
    my $program     = $parms->{LOG_PARM_PROGRAM};
    my $package     = $parms->{LOG_PARM_PACKAGE};
    my $hostname    = $parms->{LOG_PARM_HOSTNAME};
    my $file        = $parms->{LOG_PARM_FILE};
    my $line        = $parms->{LOG_PARM_LINE};

    my $data                 = {};
    $data->{LOG_LEVEL}       = $level;
    $data->{LOG_DEBUG_LEVEL} = $debug_level;
    $data->{LOG_EVENT}       = $event;
    $data->{LOG_MESSAGE}     = $message;
    $data->{LOG_HOSTNAME}    = $hostname;
    $data->{LOG_PROGRAM}     = $program;
    $data->{LOG_PACKAGE}     = $package;
    $data->{LOG_FILE}        = $file;
    $data->{LOG_LINE}        = $line;

    my $self = $class->SUPER::new( $class, $data );
    bless $self, $class;
    $self;
}

# ----------------------------------
sub level {
    my ($self) = @_;
    $self->data->{LOG_LEVEL};
}

# ----------------------------------
sub debug_level {
    my ($self) = @_;
    $self->data->{LOG_DEBUG_LEVEL};
}

# ----------------------------------
sub event {
    my ($self) = @_;
    $self->data->{LOG_EVENT};
}

# ----------------------------------
sub message {
    my ($self) = @_;
    $self->data->{LOG_EVENT};
}

# ----------------------------------
sub hostname {
    my ($self) = @_;
    $self->data->{LOG_HOSTNAME};
}

# ----------------------------------
sub program {
    my ($self) = @_;
    $self->data->{LOG_PROGRAM};
}

# ----------------------------------
sub package {
    my ($self) = @_;
    $self->data->{LOG_PACKAGE};
}

# ----------------------------------
sub subroutine {
    my ($self) = @_;
    $self->data->{LOG_SUBROUTINE};
}

# ----------------------------------
sub file {
    my ($self) = @_;
    $self->data->{LOG_FILE};
}

# ----------------------------------
sub line {
    my ($self) = @_;
    $self->data->{LOG_LINE};
}

1;