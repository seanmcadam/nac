#!/usr/bin/perl

package NAC::DataResponse::GetLocalSQL;

use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataResponse::SQL;
use strict;

our @ISA = qw(NAC::DataResponse::SQL);

sub new {
my ($class,$parms) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
