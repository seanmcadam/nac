#!/usr/bin/perl

package NAC::DataRequest::SQL;

use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

use constant SQL_FUNCTION => 'nac_sql_function';

our @EXPORT = qw(
  SQL_FUNCTION
);

our @ISA = qw(NAC::DataRequest);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

1;
