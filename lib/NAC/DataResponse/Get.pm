#!/usr/bin/perl

package NAC::DataResponse::Get;

use Data::Dumper;
use Carp;
use POSIX;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::DataResponse;
use strict;

use constant 'GET_ERROR'   => 'GET_ERROR';
use constant 'GET_COUNT'   => 'GET_COUNT';
use constant 'GET_COLUMNS' => 'GET_COLUMNS';
use constant 'GET_DATA'    => 'GET_DATA';
use constant 'GET_PID'     => 'GET_PID';
use constant 'GET_REQUEST' => 'GET_REQUEST';

use constant '_CURRENT_ROW' => '_CURRENT_ROW';

my @EXPORT = qw(
  GET_ERROR
  GET_COUNT
  GET_COLUMNS
  GET_DATA
  GET_PID
  GET_REQUEST
  GET_SQL
);

our @ISA = qw(NAC::DataResponse);

sub new {
    my ( $class, $parms ) = @_;
    my %data;
    my $self;

    if ( 'HASH' ne ref($parms) ) {
        confess " NON HASH REF PASSED IN " . Dumper @_;
    }

    if ( defined $parms->{RESPONSE_JSON} ) {
        $self = $class->SUPER::new( { RESPONSE_JSON => $parms->{RESPONSE_JSON} } );
    }
    else {

        $data{GET_REQUEST} = ( defined $parms->{GET_REQUEST} ) ? $parms->{GET_REQUEST} : 0;
        $data{GET_PID}     = ( defined $parms->{GET_PID} )     ? $parms->{GET_PID}     : 0;
        $data{GET_SQL}     = ( defined $parms->{GET_SQL} )     ? $parms->{GET_SQL}     : 'NO SQL';

        if ( defined $parms->{GET_ERROR} ) {
            $data{GET_ERROR} = $parms->{GET_ERROR};

        }
        else {
            if ( !defined $parms->{GET_COUNT} )   { confess; }
            if ( !defined $parms->{GET_COLUMNS} ) { confess; }
            if ( !defined $parms->{GET_DATA} )    { confess; }

            $data{GET_COUNT}   = $parms->{GET_COUNT};
            $data{GET_DATA}    = $parms->{GET_DATA};
            $data{GET_COLUMNS} = $parms->{GET_COLUMNS};
        }

        $self = $class->SUPER::new( { RESPONSE_DATA => \%data } );
    }

    bless $self, $class;
    $self;

}

# ---------------------------------
sub error {
    my ($self) = @_;
    return ( ( defined $self->data->{GET_ERROR} ) ? $self->data->{GET_ERROR} : undef );
}

# ---------------------------------
sub count {
    my ($self) = @_;
    $self->data->{GET_COUNT};
}

# ---------------------------------
sub set_first_row {
    my ($self) = @_;
    $self->data->{_CURRENT_ROW} = 0;
}

# ---------------------------------
sub set_last_row {
    my ($self) = @_;
    $self->data->{_CURRENT_ROW} = ( $self->data->{GET_COUNT} ) ? ( $self->data->{GET_COUNT} - 1 ) : 0;
}

# ---------------------------------
sub first_row {
    my ($self) = @_;
    $self->set_first_row;
    $self->data->{GET_DATA}->[ $self->data->{_CURRENT_ROW}++ ];
}

# ---------------------------------
sub last_row {
    my ($self) = @_;
    $self->set_last_row;
    $self->data->{GET_DATA}->[ $self->data->{_CURRENT_ROW}++ ];
}

# ---------------------------------
sub next_row {
    my ($self) = @_;
    if ( $self->data->{_CURRENT_ROW} < $self->data->{GET_COUNT} ) {
        return $self->data->{GET_DATA}->[ $self->data->{_CURRENT_ROW}++ ];
    }
    0;
}

1;
