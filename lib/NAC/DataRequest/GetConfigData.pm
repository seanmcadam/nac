#!/usr/bin/perl

package NAC::DataRequest::GetConfigData;

use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest;
use strict;

use constant GET_CONFIG_DATA_FUNCTION => 'get_config_data';

our @EXPORT = qw(
  GET_CONFIG_DATA_FUNCTION
);

our @ISA = qw(NAC::DataRequest);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new();
    bless $self, $class;
    $self;
}

1;
