#!/usr/bin/perl

package NAC::DataRequest::SQL;

# use base qw( Exporter );
use Exporter qw(import);
use Data::Dumper;
use Carp;
use POSIX;
use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

use constant 'SQL_STMT' => 'SQL_STMT';
use constant 'SQL_BIND' => 'SQL_BIND';
use constant 'SQL_TYPE' => 'SQL_TYPE';

my @EXPORT = qw(
  SQL_STMT
  SQL_BIND
  SQL_TYPE
);

our @ISA = qw(NAC::DataRequest);

# ----------------------------------------------------------------
#
#
# ----------------------------------------------------------------
sub new {
    my ( $class, $stmt, $bind ) = @_;

    my $data = {};

    my ($type) = split( / /, $stmt );
    $type =~ tr/a-z/A-Z/;

    $data->{SQL_STMT} = $stmt;
    $data->{SQL_BIND} = $bind;
    $data->{SQL_TYPE} = $type;

    my $self = $class->SUPER::new( $class, $data );
    bless $self, $class;
    $self;
}

1;

