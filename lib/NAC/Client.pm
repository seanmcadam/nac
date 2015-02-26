#!/usr/bin/perl

package NAC::Client;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use Storable qw(freeze thaw);
use Gearman::XS qw(:constants);
use Gearman::XS::Client;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;
use 5.010;

# $Storable::forgive_me = 1;

use constant CLIENT                  => 'CLIENT';
use constant CLIENT_PARM_SERVER_NAME => 'CLIENT_PARM_SERVER_NAME';

our @EXPORT = qw(
  CLIENT_PARM_SERVER_NAME
);

# ---------------------------------------------------------------------------
sub new {
    my ( $class, $parms ) = @_;
    my $self = {};
    $self->{CLIENT} = Gearman::XS::Client->new();

    my $ret = $self->{CLIENT}->add_server();
    if ( $ret != GEARMAN_SUCCESS ) {
        confess "Cannot Attach to local GEARMAN Server\n";
    }

    bless $self, $class;

    $self;
}

# ---------------------------------------------------------------------------
sub do_background {
    my ( $self, $function, $data_obj ) = @_;
    my ( $ret, $handle ) = $self->{CLIENT}->do_background( $function, freeze( $data_obj->get_json ) );
    if ( $ret != GEARMAN_SUCCESS ) {
        carp "Failure sending to Server\n";
    }
}

# ---------------------------------------------------------------------------
sub do {
    my ( $self, $function, $data_obj ) = @_;
    my ( $ret, $result ) = $self->{CLIENT}->do( $function, freeze( $data_obj->get_json ) );
    if ( $ret != GEARMAN_SUCCESS ) {
        carp "Failure sending to Server\n";
    }
    return $result;
}

# ---------------------------------------------------------------------------
sub send {
    my ($self) = @_;
}

1;

