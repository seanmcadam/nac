#!/usr/bin/perl

package NAC::DataRequest::SQL;

use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

our @ISA = qw(NAC::DataRequest);

sub new {
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
