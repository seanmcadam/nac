#!/usr/bin/perl

package NAC::Worker::Function::LocalLogger;

use Data::Dumper;
use Carp;
use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::LocalLogger;
use NAC::Worker::Function;
use strict;

our @EXPORT = qw(
  EVENT_START
);

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
print Dumper $request->data();
print $request->level();
print ":";
print $request->hostname();
print "\nEVENT: ";
print $request->event();
print "\nPROGRAM: ";
print $request->program();
print "\nPACK: ";
print $request->package();
print "\nSUB: ";
print $request->subroutine();
print "\nFILE: ";
print $request->file();
print " LINE: ";
print $request->line();
print "\nMESSAGE:";
print $request->message();
print "\n";

1;
}

1;
