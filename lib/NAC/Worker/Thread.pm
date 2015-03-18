#!/usr/bin/perl
#
#

package NAC::Worker::Thread;

use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use threads;
use strict;
use 5.010;

#my $logger = undef;

use constant THREAD_PARM_NOLOG       => 'THREAD_PARM_NOLOG';
use constant TID => 'TID';

our @EXPORT = qw(
);


# ------------------------------------------------
#
# ------------------------------------------------
sub new {
    my ($class,$parms) = @_;
    my $self = {};
    $self->{TID} = {};

    bless $self, $class;
    $self;
}

# ------------------------------------------------
#
# ------------------------------------------------
sub create {
    my ( $self, $worker_ref, $parms ) = @_;

    # print "REF:" . ref($worker_ref) . "\n";

    my $thr = threads->create( sub { 
	$worker_ref->($parms)->work() 
	} );

    $self->{TID}->{ $thr->tid } = $thr;
}

# ------------------------------------------------
# ------------------------------------------------
#
# ------------------------------------------------
sub create_localdb {
    my ( $self, $parms ) = @_;
    my $thr = threads->create( sub { NAC::Worker::LocalDB->new($parms)->work() } );
    $self->{TID}->{ $thr->tid } = $thr;

}

# ------------------------------------------------
#
# ------------------------------------------------
sub run {
    my ($self) = @_;

    while ( my ($running) = threads->list(threads::running) ) {
        $running->join();
    }

}

1;

