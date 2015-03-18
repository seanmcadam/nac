#!/usr/bin/perl

package NAC::DataResponse::Config;

use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataResponse::Get;
use strict;

our @ISA = qw(NAC::DataResponse::Get);

our @EXPORT = @NAC::DataResponse::Get::EXPORT;

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( $parms );
    bless $self, $class;
    $self;
}

1;
