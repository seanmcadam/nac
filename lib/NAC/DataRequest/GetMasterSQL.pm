#!/usr/bin/perl

package NAC::DataRequest::GetMasterSQL;

use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest::SQL;
use strict;

use constant GET_MASTER_SQL_FUNCTION => 'get_master_sql';

our @EXPORT = qw(
  GET_MASTER_SQL_FUNCTION
);


our @ISA = qw(NAC::DataRequest::SQL);

sub new {
my ($class,$parms) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
