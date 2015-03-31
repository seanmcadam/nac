#!/usr/bin/perl

package NAC::Client;

use Data::Dumper;
use Carp;
use JSON;
use base qw( Exporter );
use Storable qw(freeze thaw);
use Gearman::XS qw(:constants);
use Gearman::XS::Client;
use FindBin;
use lib "$FindBin::Bin/..";
use NAC::LocalLogger;
use NAC::DataResponse::Config;
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
# No Return
# ---------------------------------------------------------------------------
sub do_background {
    my ( $self, $function, $data_obj ) = @_;
    my ( $ret, $handle ) = $self->{CLIENT}->do_background( $function, freeze( $data_obj->get_json ) );
    if ( $ret != GEARMAN_SUCCESS ) {
        carp "Failure background sending to Server: $ret\n";

        # $LOGGER_ERROR->( " FAILED TO SEND TO SERVER in BACKGROUND " );
    }
}

# ---------------------------------------------------------------------------
# Return Data
# ---------------------------------------------------------------------------
sub do {
    my ( $self, $function, $data_obj ) = @_;

    my ( $ret, $result ) = $self->{CLIENT}->do( $function, freeze( $data_obj->get_json ) );

    if ( $ret != GEARMAN_SUCCESS ) {
        carp "Failure sending to Server $ret\n";
        # $LOGGER_ERROR->( " FAILED TO SEND TO SERVER " );
        return undef;
    }

    my $json    = thaw($result);
    my $jsonref = decode_json($$json);

	#
	# Check for Error Response Here
	#

    if ( !defined $jsonref->{DATARESPONSE_CLASS} ) {
        carp "BAD DATARESPONSE JSONREF";
        return undef;
    }

    my $myclass = $jsonref->{DATARESPONSE_CLASS};

    if ( !( $myclass =~ /^NAC::DataResponse::/ ) ) {
        carp "BAD CLASS '" . $myclass . "'\n";
        return undef;
    }

    my $data = $myclass->new( { RESPONSE_JSON => $jsonref } );

    return $data;
}

# ---------------------------------------------------------------------------
sub send {
    my ($self) = @_;
}

1;

