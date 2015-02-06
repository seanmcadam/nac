#!/usr/bin/perl

package NAC::Worker::Function::GetSQL;

use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::GetSQL;
use NAC::DataResponse::GetSQL;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( GET_SQL_FUNCTION,  \&function );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;
    my $response = NAC::DataResponse::GetSQL->new();

    if( ref($request) ne 'NAC::DataRequest::GetSQL' ) { confess; }


$response;

}

1;
