#!/usr/bin/perl

package NAC::Worker::LocalDB;

use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::Worker;
use NAC::Worker::Function::GetLocalSQL;
use strict;

our @ISA = qw(NAC::Worker);

sub new {
my ($class, $parms) = @_;
$class = __PACKAGE__;
    
    if( ! defined $parms ) {
	$parms = {};
	$parms->{ WORKER_PARM_SERVER } = WORKER_SERVER_LOCALHOST; 
	}

    my $self = $class->SUPER::new( $parms );
    $self->add_worker_function( NAC::Worker::Function::GetLocalSQL->new() );

    bless $self, $class;
    $self;
}


1;
