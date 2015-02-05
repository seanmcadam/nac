#!/usr/bin/perl

package NAC::Worker::LocalDB;

use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::Worker;
use NAC::Worker::Function::GetSQL;
use strict;

my %functions = ();


sub new {
my ($class, $parms) = @_;
my $config = NAC::Worker::Function::SQL->new();

}




1;

