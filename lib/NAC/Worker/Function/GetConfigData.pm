#!/usr/bin/perl

package NAC::Worker::Function::GetConfigData;

use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::GetConfigData;
use NAC::DataResponse::GetConfigData;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( GET_CONFIG_DATA_FUNCTION,  \&function );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;
    my $response = NAC::DataResponse::GetConfigData->new();

    if( ref($request) ne 'NAC::DataRequest::GetConfigData' ) { confess; }


$response;

}

1;
