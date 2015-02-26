#!/usr/bin/perl

package NAC::Worker::Function::GetSQL;

use Data::Dumper;
use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DB;
use NAC::DataRequest::SQL;
use NAC::DataResponse::SQL;
use NAC::Worker::Function;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( SQL_FUNCTION, \&function, $parms );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;

    if ( ref($request) ne 'NAC::DataRequest::SQL' ) { confess; }

    my $response = NAC::DataResponse::SQL->new( );

    $response;

}

1;
