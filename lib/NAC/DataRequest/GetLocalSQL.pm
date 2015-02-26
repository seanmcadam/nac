#!/usr/bin/perl

package NAC::DataRequest::GetLocalSQL;

use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest::ParseSQL;
use strict;

use constant GET_LOCAL_SQL_FUNCTION => 'get_local_sql';

my @export = qw(
  GET_LOCAL_SQL_FUNCTION
);

our @EXPORT = ( @export, @NAC::DataRequest::ParseSQL::EXPORT );

our @ISA = qw(NAC::DataRequest::ParseSQL);

sub new {
    my ($class,$parms) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
