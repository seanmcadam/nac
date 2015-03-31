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
	confess;
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

        if ( !defined $json->{DATARESPONSE_DATA} ) {
            confess DATARESPONSE_DATA . " not defined\n";
        }
        elsif ( !defined $json->{DATARESPONSE_CLASS} ) {
            confess DATARESPONSE_CLASS . " not defined\n";
        }
        else {
            $class = $json->{DATARESPONSE_CLASS};
            $self->{DATARESPONSE_CLASS} = $json->{DATARESPONSE_CLASS};
            $self->{DATARESPONSE_DATA}  = $json->{DATARESPONSE_DATA};
            $self->{DATARESPONSE_COUNT} = ( defined $json->{DATARESPONSE_COUNT} ) ? $json->{DATARESPONSE_COUNT} : 0;
            $self->{DATARESPONSE_PID}   = ( defined $json->{DATARESPONSE_PID} ) ? $json->{DATARESPONSE_PID} : 0;
        }
    }
    else {
	confess;
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
