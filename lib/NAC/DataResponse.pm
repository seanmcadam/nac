#!/usr/bin/perl

package NAC::DataResponse;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use JSON;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;
use 5.010;

use constant DATARESPONSE_COUNT => 'DATARESPONSE_COUNT';
use constant DATARESPONSE_PID   => 'DATARESPONSE_PID';
use constant DATARESPONSE_DATA  => 'DATARESPONSE_DATA';
use constant DATARESPONSE_CLASS => 'DATARESPONSE_CLASS';
use constant RESPONSE_DATA      => 'RESPONSE_DATA';
use constant RESPONSE_JSON      => 'RESPONSE_JSON';

our @EXPORT = qw (
  RESPONSE_ERROR
  RESPONSE_DATA
  RESPONSE_JSON
);

state $request_num = 0;

# ---------------------------------------
sub new {
    my ( $class, $ref ) = @_;
    my $self = {};

    if ( 'HASH' ne ref($ref) ) {
        confess " NON HASH REF PASSED IN " . Dumper @_;
    }

    if ( defined $ref->{RESPONSE_ERROR} ) {
	}
    elsif ( defined $ref->{RESPONSE_DATA} ) {
        my $data = $ref->{RESPONSE_DATA};
        $self->{DATARESPONSE_PID}   = $$;
        $self->{DATARESPONSE_COUNT} = $request_num++;
        $self->{DATARESPONSE_DATA}  = $data;
        $self->{DATARESPONSE_CLASS} = $class;
    }
    elsif ( defined $ref->{RESPONSE_JSON} ) {
        my $json = $ref->{RESPONSE_JSON};

        my $arrref = decode_json($$json);

        if ( !defined $arrref->{DATARESPONSE_DATA} ) {
            confess DATARESPONSE_DATA . " not defined\n";
        }
        elsif ( !defined $arrref->{DATARESPONSE_CLASS} ) {
            confess DATARESPONSE_CLASS . " not defined\n";
        }
        else {
        #    $class = $self->{DATARESPONSE_CLASS} = $arrref->{DATARESPONSE_CLASS};
            $self->{DATARESPONSE_DATA}  = $arrref->{DATARESPONSE_DATA};
            $self->{DATARESPONSE_COUNT} = ( defined $arrref->{DATARESPONSE_COUNT} ) ? $arrref->{DATARESPONSE_COUNT} : 0;
            $self->{DATARESPONSE_PID}   = ( defined $arrref->{DATARESPONSE_PID} ) ? $arrref->{DATARESPONSE_PID} : 0;
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
    $data->{DATARESPONSE_DATA}  = $self->{DATARESPONSE_DATA};
    $data->{DATARESPONSE_CLASS} = $self->{DATARESPONSE_CLASS};
    $data->{DATARESPONSE_COUNT} = $self->{DATARESPONSE_COUNT};
    $data->{DATARESPONSE_PID}   = $self->{DATARESPONSE_PID};

    my $json = JSON->new->allow_nonref->encode($data);

    \$json;
}

# ---------------------------------------
sub data {
    my ($self) = @_;
    $self->{DATARESPONSE_DATA};
}

# ---------------------------------------
sub class {
    my ($self) = @_;
    $self->{DATARESPONSE_CLASS};
}

# ---------------------------------------
sub pid {
    my ($self) = @_;
    $self->{DATARESPONSE_PID};
}

# ---------------------------------------
sub count {
    my ($self) = @_;
    $self->{DATARESPONSE_COUNT};
}

1;
