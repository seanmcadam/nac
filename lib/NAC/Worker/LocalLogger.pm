#!/usr/bin/perl

package NAC::Worker::LocalLogger;

use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LogConsts;
use NAC::Worker;
use NAC::Worker::Function::LocalLogger;
use strict;

our @ISA = qw(NAC::Worker);

sub new {
    my ( $class, $parms ) = @_;
    $class = __PACKAGE__;

    if ( !defined $parms ) {
        $parms = {};
    }

    # This is a LOGGING worker, dont setup logging
    $parms->{WORKER_PARM_NOLOG}  = 1;                         
    $parms->{WORKER_PARM_SERVER} = WORKER_SERVER_LOCALHOST;

    my $self = $class->SUPER::new($parms);
    $self->add_worker_function( NAC::Worker::Function::LocalLogger->new() );

    bless $self, $class;
    $self;
}

1;

