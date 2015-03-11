#!/usr/bin/perl

package NAC::LocalLogger;

use Data::Dumper;
use base qw( Exporter );
use Gearman::XS qw(:constants);
use FindBin;
use lib "$FindBin::Bin/..";
use NAC::Client::Logger;
use strict;
use 5.010;

#
# sets up Logging Client once
#

our $nac_local_logger = undef;

our @EXPORT = @NAC::Client::Logger::EXPORT;

our @ISA = qw(NAC::Client::Logger);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

if( ! defined $nac_local_logger ) {
	$nac_local_logger = NAC::LocalLogger->new();
}

