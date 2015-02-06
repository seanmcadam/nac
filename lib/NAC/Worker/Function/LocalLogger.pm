#!/usr/bin/perl

package NAC::Worker::Function::LocalLogger;

use Data::Dumper;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::LocalLogger;
use NAC::Worker::Function;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( LOCAL_LOGGER_FUNCTION, \&function, $parms );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;


    if( ref($request) ne 'NAC::DataRequest::LocalLogger' ) { 
	confess; 
	}

my $time = localtime(time);
print "$time:";
print $request->level();
print ":";
print $request->event();
print " EVENT:";
print $request->hostname();
print " PACK:";
print $request->package();
print " SUB:";
print $request->subroutine();
print " FILE:";
print $request->file();
print " LINE:";
print $request->line();
print "\n\tMESSAGE:";
print $request->message();
print "\n";

1;
}

1;
