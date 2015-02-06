#!/usr/bin/perl

package NAC::DataResponse::SQL;

use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

use constant GET_SQL_FUNCTION => 'get_sql';

our @EXPORT = qw(
  GET_SQL_FUNCTION
);

our @ISA = qw(NAC::DataResponse);

sub new {
my ($class,$parms) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
