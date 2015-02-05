#!/usr/bin/perl

package NAC::DataResponse;

use FindBin;
use lib "$FindBin::Bin/..";
use strict;

sub new {
    my ($class, $parms) = @_;
    my $self = {};
    bless $self, $class;
    $self;
}

1;
