#!/usr/bin/perl

package NAC::DataRequest;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use JSON;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;
use 5.010;

use constant DATAREQUEST_COUNT => 'DATAREQUEST_COUNT';
use constant DATAREQUEST_PID   => 'DATAREQUEST_PID';
use constant DATAREQUEST_DATA  => 'DATAREQUEST_DATA';
use constant DATAREQUEST_CLASS => 'DATAREQUEST_CLASS';
use constant REQUEST_DATA      => 'REQUEST_DATA';
use constant REQUEST_JSON      => 'REQUEST_JSON';

our @EXPORT = qw (
  REQUEST_DATA
  REQUEST_JSON
);

state $request_num = 0;

# ---------------------------------------
sub new {
    my ( $class, $ref ) = @_;
    my $self = {};

    if ( 'HASH' ne ref($ref) ) {
        confess " NON HASH REF PASSED IN " . Dumper @_;
    }

    if ( defined $ref->{REQUEST_DATA} ) {
        my $data = $ref->{REQUEST_DATA};
        $self->{DATAREQUEST_PID}   = $$;
        $self->{DATAREQUEST_COUNT} = $request_num++;
        $self->{DATAREQUEST_DATA}  = $data;
        $self->{DATAREQUEST_CLASS} = $class;
    }
    elsif ( defined $ref->{REQUEST_JSON} ) {
        my $json = $ref->{REQUEST_JSON};

        my $arrref = decode_json($$json);

        if ( !defined $arrref->{DATAREQUEST_DATA} ) {
            confess DATAREQUEST_DATA . " not defined\n";
        }
        elsif ( !defined $arrref->{DATAREQUEST_CLASS} ) {
            confess DATAREQUEST_CLASS . " not defined\n";
        }
        else {
            $class = $self->{DATAREQUEST_CLASS} = $arrref->{DATAREQUEST_CLASS};
            $self->{DATAREQUEST_DATA}  = $arrref->{DATAREQUEST_DATA};
            $self->{DATAREQUEST_COUNT} = ( defined $arrref->{DATAREQUEST_COUNT} ) ? $arrref->{DATAREQUEST_COUNT} : 0;
            $self->{DATAREQUEST_PID}   = ( defined $arrref->{DATAREQUEST_PID} ) ? $arrref->{DATAREQUEST_PID} : 0;

        }
    }

    bless $self, $class;
    $self;
}

# ---------------------------------------
# Used on Send side to create object
# ---------------------------------------
sub get_json {
    my ($self) = @_;

    my $data = {};
    $data->{DATAREQUEST_DATA}  = $self->{DATAREQUEST_DATA};
    $data->{DATAREQUEST_CLASS} = $self->{DATAREQUEST_CLASS};
    $data->{DATAREQUEST_COUNT} = $self->{DATAREQUEST_COUNT};
    $data->{DATAREQUEST_PID}   = $self->{DATAREQUEST_PID};

    # my $json = JSON->new->encode_json( $data );
    my $json = JSON->new->allow_nonref->encode($data);

    \$json;
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
sub pid {
    my ($self) = @_;
    $self->{DATAREQUEST_PID};
}

# ---------------------------------------
sub count {
    my ($self) = @_;
    $self->{DATAREQUEST_COUNT};
}

1;
