#!/usr/bin/perl
#
# Use Gearman
# Register Server
# Register Function
#

package NAC::Worker::Function;

use Data::Dumper;
use Carp;
use Gearman::Task;
use Storable qw ( freeze thaw );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use strict;

use constant FUNCTION_NAME => 'FUNCTION_NAME';
use constant FUNCTION_REF  => 'FUNCTION_REF';

# --------------------------------------------------------
#
# --------------------------------------------------------
sub new {
    my ( $class, $func_name, $func_ref, $parms ) = @_;

    my $self = {};
    $self->{FUNCTION_NAME} = $func_name;
    $self->{FUNCTION_REF}  = sub {
        my $arg = thaw( $_[0]->workload() );
        my $ret = $func_ref->($arg);
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
