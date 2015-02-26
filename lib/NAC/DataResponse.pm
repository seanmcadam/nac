#!/usr/bin/perl

package NAC::DataResponse;

use base qw( Exporter );
use JSON;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;

use constant DATARESPONSE_PACKAGE_NAME => 'DATARESPONSE_PACKAGE_NAME';
use constant DATARESPONSE_DATA => 'DATARESPONSE_DATA';

our @EXPORT = qw (
);

sub new {
    my ($class, $parms) = @_;
    my $self = {};
    $self->{DATARESPONSE_DATA} = {};
    bless $self, $class;
    $self;
}

sub json {
    my ($self) = @_;
    encode_json({ 
        DATARESPONSE_PACKAGE_NAME => (split( /::/, ref($self) ))[-1],
        DATARESPONSE_DATA => $self->{DATARESPONSE_DATA},
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
