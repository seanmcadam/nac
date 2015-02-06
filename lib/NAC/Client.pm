#!/usr/bin/perl

package NAC::Client;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/..";
use Storable qw(freeze thaw);
use Gearman::XS qw(:constants);
use Gearman::XS::Client;
use strict;

use constant CLIENT                  => 'CLIENT';
use constant CLIENT_PARM_SERVER_NAME => 'CLIENT_PARM_SERVER_NAME';

our @EXPORT = qw(
  CLIENT_PARM_SERVER_NAME
);

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

sub send_background {
    my ( $self, $function, $data_obj ) = @_;
    my ( $ret, $handle ) = $self->{CLIENT}->do_background( $function, freeze($data_obj) );
    if ( $ret != GEARMAN_SUCCESS ) {
        carp "Failure sending to Server\n";
    }
}

sub send {
    my ($self) = @_;
}

1;

