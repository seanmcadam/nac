#!/usr/bin/perl

package NAC::DataRequest;

use base qw( Exporter );
use JSON;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;

use constant DATAREQUEST_PACKAGE_NAME => 'DATAREQUEST_PACKAGE_NAME';
use constant DATAREQUEST_DATA => 'DATAREQUEST_DATA';

our @EXPORT = qw (
);

sub new {
    my ( $class, $parms ) = @_;
    my $self = {};
    $self->{DATAREQUEST_DATA} = {};
    bless $self, $class;
    $self;
}

sub json {
    my ($self) = @_;
    encode_json({ 
	DATAREQUEST_PACKAGE_NAME => (split( /::/, ref($self) ))[-1],
	DATAREQUEST_DATA => $self->{DATAREQUEST_DATA},
	});
}

sub add_request_data {
	my ($self,$name,$var) = @_;
	$self->{$name} = $var;
}

sub get_request_data {
	my ($self,$name) = @_;
	$self->{$name};
}

1;
