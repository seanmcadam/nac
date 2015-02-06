#!/usr/bin/perl

package NAC::Worker::Function::GetLocalSQL;

use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::GetLocalSQL;
use NAC::DataResponse::GetLocalSQL;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( GET_LOCAL_SQL_FUNCTION, \&function );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;
    my $response = NAC::DataResponse::GetLocalSQL->new();

    if( ref($request) ne 'NAC::DataRequest::GetLocalSQL' ) { confess; }


$response;

}

1;
