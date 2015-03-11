#!/usr/bin/perl

package NAC::DataRequest::Config;

use Data::Dumper;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest::Get;
use strict;

use constant GET_CONFIG_DATA_FUNCTION => 'get_config_data';

our @export = qw(
  GET_CONFIG_DATA_FUNCTION
);

our @EXPORT = ( @export, @NAC::DataRequest::Get::EXPORT );

our @ISA = qw(NAC::DataRequest::Get);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

1;

