#!/usr/bin/perl

package NAC::DataResponse::Config;

use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataResponse;
use strict;

our @ISA = qw(NAC::DataResponse);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
