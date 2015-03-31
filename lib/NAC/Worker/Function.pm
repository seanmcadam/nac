#!/usr/bin/perl
#
# Use Gearman
# Register Server
# Register Function
#

package NAC::Worker::Function;

use Data::Dumper;
use Carp;
use JSON;
use Storable qw ( freeze thaw );
use base qw( Exporter );
use Gearman::Task;
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest;
use NAC::LocalLogger;
use strict;

use constant FUNCTION_NAME => 'FUNCTION_NAME';
use constant FUNCTION_REF  => 'FUNCTION_REF';

our @EXPORT = @NAC::LocalLogger::EXPORT;

# --------------------------------------------------------
#
# --------------------------------------------------------
sub new {
    my ( $class, $func_name, $func_ref, $parms ) = @_;

    if ( 'CODE' ne ref($func_ref) ) {
        confess "BAD FUNCTION REF:'" . ref($func_ref) . "'\n";
    }

    my $self = {};
    $self->{FUNCTION_NAME} = $func_name;
    $self->{FUNCTION_REF}  = sub {

        my $json    = thaw( $_[0]->workload() );
        my $jsonref = decode_json($$json);

	if( ! defined $jsonref->{DATAREQUEST_CLASS} ) {
            carp "BAD JSONREF - json:" . Dumper $jsonref;
	    return undef;
	}

        my $myclass = $jsonref->{DATAREQUEST_CLASS};
        if ( !( $myclass =~ /^NAC::DataRequest::/ ) ) {
            carp "BAD CLASS - json:" . Dumper $jsonref;
	    return undef;
        }

        # my $data = NAC::DataRequest->new( {REQUEST_JSON => $json} );
        my $data = $myclass->new( { REQUEST_JSON => $jsonref } );

        my $ret = $func_ref->($data);
        if ( ref($ret) ) {
            return freeze( $ret->get_json() );
        }
        else {
            return $ret;
        }
    };

    bless $self, $class;
    $self;
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub function_name {
    my ($self) = @_;
    $self->{FUNCTION_NAME};
}

# --------------------------------------------------------
#
# --------------------------------------------------------
sub function_ref {
    my ($self) = @_;
    $self->{FUNCTION_REF};
}

1;
