#!/usr/bin/perl
#
# Use Gearman
# Register Server
# Register Function
#

package NAC::Worker::Function;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use Gearman::Task;
use Storable qw ( freeze thaw );
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

    my $self = {};
    $self->{FUNCTION_NAME} = $func_name;
    $self->{FUNCTION_REF}  = sub {
        my $json = thaw( $_[0]->workload() );

        my $data = NAC::DataRequest->new();
        $data->set_json($json);

        my $ret = $func_ref->( $data->set_json($json) );
        if ( ref($ret) ) {
            return freeze($ret);
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
