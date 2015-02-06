#!/usr/bin/perl
#
#

package NAC::Worker::Thread;

use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
# use NAC::Worker::HTTP;
# use NAC::Worker::LocalCMPAuth;
# use NAC::Worker::LocalConfig;
use NAC::Worker::LocalDB;
# use NAC::Worker::LocalGateway;
# use NAC::Worker::LocalLogger;
# use NAC::Worker::Logger;
# use NAC::Worker::Master;
# use NAC::Worker::SNMP;
use threads;
use strict;
use 5.010;

use constatnt TID => 'TID';

sub new {
    my ($class) = @_;
    my $self = {};
    my $self->{TID} = {};
    bless $self, $class;
    $self;
}

sub add_worker {
    my ( $self, $worker_name, $parms ) = @_;

    my $thr = thread->create( sub { "$worker_name"->new($parms)->work() } );

    $self->{TID}->{ $thr->tid } = $thr;

}

sub run {
    my ($self) = @_;

    while ( my ($running) = threads->list(threads::running) ) {
        $running->join();
    }

}

1;

