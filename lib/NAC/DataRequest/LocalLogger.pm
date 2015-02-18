#!/usr/bin/perl

package NAC::DataRequest::LocalLogger;

use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest::Logger;
use strict;

use constant LOCAL_LOGGER_FUNCTION => 'nac_local_logger';

our @EXPORT = qw(
  %logging_level
  %debugging_level
  LOCAL_LOGGER_FUNCTION
  LOG_PARM_LEVEL
  LOG_PARM_EVENT
  LOG_PARM_MESSAGE
  LOG_PARM_PACKAGE
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
  LOG_MESSAGE
  LOG_PACKAGE
  LOG_FILE
  LOG_LINE
  LOG_PROGRAM
  LOG_HOSTNAME
  LOG_EVENT
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
  LOG_FATAL
  LOG_CRIT
  LOG_ERROR
  LOG_WARN
  LOG_NOTICE
  LOG_INFO
  LOG_DEBUG
  LOG_EVENT
);

our @ISA = qw(NAC::DataRequest::Logger);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

1;
