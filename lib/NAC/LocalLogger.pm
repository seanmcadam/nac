#!/usr/bin/perl

package NAC::LocalLogger;

use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/..";
use NAC::Client::Logger;
use Gearman::XS qw(:constants);
use strict;

our @EXPORT = qw(
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

our @ISA = qw(NAC::Client::Logger);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

