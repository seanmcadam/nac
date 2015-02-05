#!/usr/bin/perl

package NAC::Worker::LocalConfig;

use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::Worker;
use NAC::Worker::Function::GetConfigData;
use strict;

my %functions = ();


sub new {
my ($class, $parms) = @_;
my $config = NAC::Worker::Function::GetConfigData->new();

}




1;

