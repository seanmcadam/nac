#!/usr/bin/perl

package NAC::Worker::Function::GetLocalSQL;

use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::GetLocalSQL;
use NAC::DataResponse::GetLocalSQL;
use NAC::Worker::Function;
use strict;

our @ISA = qw(NAC::Worker::Function);

use constant GET_LOCAL_SQL_FUNCTION => 'get_local_sql';

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

#
# Parse SQL and make DB Request
#

$response;

}

1;
