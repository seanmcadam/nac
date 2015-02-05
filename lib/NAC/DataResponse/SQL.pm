#!/usr/bin/perl

package NAC::DataResponse::SQL;

use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

our @ISA = qw(NAC::DataResponse);

sub new {
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
