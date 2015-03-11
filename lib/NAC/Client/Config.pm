#!/usr/bin/perl

package NAC::Client::Config;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::Client;
use NAC::DB;
use NAC::DataRequest::Config;

use strict;

our @ISA = qw(NAC::Client);

my $RESULT = 0;

# ---------------------------------------------
sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    $self->do();

    $self;
}

# ---------------------------------------------
sub do {
    my ($self) = @_;

    my $sqlobj = NAC::DataRequest::Config->new( {
            GET_DATA => [
                { DATA_COLUMN => NACCONFIG_CONFIG_CONFIGID_COLUMN, },
                { DATA_COLUMN => NACCONFIG_CONFIG_HOSTNAME_COLUMN, },
                { DATA_COLUMN => NACCONFIG_CONFIG_NAME_COLUMN, },
                { DATA_COLUMN => NACCONFIG_CONFIG_VALUE_COLUMN, },
            ],
    } );

    $RESULT = $self->SUPER::do( GET_CONFIG_DATA_FUNCTION, $sqlobj );

    # DO ERROR CHECKING HERE

    $RESULT;

}

# ---------------------------------------------
sub get {
    my ($self) = @_;

    if( ! $RESULT ) {
	    $RESULT = $self->do();
	}

$RESULT;
}

1;
