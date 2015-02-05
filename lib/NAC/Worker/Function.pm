#!/usr/bin/perl
#
# Use Gearman
# Register Server
# Register Function
#

package NAC::Worker::Function;

use Gearman::Task;
use Storable qw ( freeze thaw );
use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

use constant TASK => 'TASK';

sub new {
    my ($class,$func,$code_ref) = @_;

print "Need Error checking here\n";

    my $self = {};
    $self->{TASK} = Gearman::Task->new(
	$func,
        sub {
            freeze( $code_ref->( thaw( $_[0]->arg ) ) );
        }, 
	);

    bless $self, $class;
    $self;
}


1;
