#!/usr/bin/perl

package NAC::DataResponse::Config;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataResponse::Get;
use strict;

our @ISA = qw(NAC::DataResponse::Get);

our @EXPORT = @NAC::DataResponse::Get::EXPORT;

sub new {
    my ( $class, $parms ) = @_;

    if ( 'HASH' ne ref($parms) ) {
        confess " NON HASH REF PASSED IN " . Dumper @_;
    }

    my $self = $class->SUPER::new( $parms );
    bless $self, $class;
    $self;
}

1;
