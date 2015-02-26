#!/usr/bin/perl

package NAC::DataResponse::SQL;

use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataResponse;
use strict;

use constant 'SQL_SELECT' => 'SQL_SELECT';
use constant 'SQL_INSERT' => 'SQL_INSERT';
use constant 'SQL_UPDATE' => 'SQL_UPDATE';
use constant 'SQL_DELETE' => 'SQL_DELETE';

my @EXPORT = qw(
  SQL_SELECT
  SQL_INSERT
  SQL_UPDATE
  SQL_DELETE
);

our @ISA = qw(NAC::DataResponse);

sub new {
my ($class,$parms) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    if( defined $parms->{SQL_SELECT} ) {
	$self->{SQL_SELECT} = $parms->{SQL_SELECT};
    }

    $self;
}

1;
