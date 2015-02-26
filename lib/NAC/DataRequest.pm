#!/usr/bin/perl

package NAC::DataRequest;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use JSON;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;

use constant DATAREQUEST_DATA => 'DATAREQUEST_DATA';
use constant DATAREQUEST_CLASS => 'DATAREQUEST_CLASS';

our @EXPORT = qw (
);

# ---------------------------------------
sub new {
    my ( $class, $package, $data ) = @_;
    my $self = {};
    $self->{DATAREQUEST_DATA} = $data;
    $self->{DATAREQUEST_CLASS} = $package;
    bless $self, $class;
    $self;
}

# ---------------------------------------
# Used on Send side to create object
# ---------------------------------------
sub get_json {
    my ($self) = @_;

    my $data = {};
    $data->{DATAREQUEST_DATA} = $self->{DATAREQUEST_DATA};
    $data->{DATAREQUEST_CLASS} = $self->{DATAREQUEST_CLASS};

print Dumper $data;

    # my $json = JSON->new->encode_json( $data );
    my $json = JSON->new->allow_nonref->encode($data);

    \$json;
}

# ---------------------------------------
# Used on Recieve side to create object
# ---------------------------------------
sub set_json {
    my ($self,$json) = @_;

    my $arrref = decode_json($$json);

    if( ! defined $arrref->{DATAREQUEST_DATA} ) {
	carp DATAREQUEST_DATA . " not defined\n";;
	}
    elsif( ! defined $arrref->{DATAREQUEST_CLASS} ) {
	carp DATAREQUEST_CLASS . " not defined\n";;
	}

    my $class = $self->{DATAREQUEST_CLASS} = $arrref->{DATAREQUEST_CLASS};
    $self->{DATAREQUEST_DATA} = $arrref->{DATAREQUEST_DATA};

    bless $self, $class;
    $self;

}


# ---------------------------------------
sub data {
    my ($self) = @_;
    $self->{DATAREQUEST_DATA};
}

# ---------------------------------------
sub class {
    my ($self) = @_;
    $self->{DATAREQUEST_CLASS};
}

# ---------------------------------------
#sub add_request_data {
#	my ($self,$name,$var) = @_;
#	$self->{$name} = $var;
#}

# ---------------------------------------
#sub get_request_data {
#	my ($self,$name) = @_;
#	$self->{$name};
#}

1;
