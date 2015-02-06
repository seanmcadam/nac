#!/usr/bin/perl
#
# Establish local connection to GM server
# Register Functions
#
#

package NAC::Worker;

use base qw( Exporter );
use JSON;
use FindBin;
use lib "$FindBin::Bin/..";
use strict;
use 5.010;

use constant SERVER   => 'SERVER';
use constant FUNCTION => 'FUNCTION';
use constant RESULT   => 'RESULT';
use constant REQUEST  => 'REQUEST';

our @EXPORT = qw (
);

sub new {
    my ( $class, $server, $function_obj ) = @_;
    my $self = {};

    state %servers;
    if ( !defined $servers{$server} ) {
    }

    $self->{SERVER}   = $servers{$server};
    $self->{FUNCTION} = $function_obj;

    # Load Logger
    # join_server
    # load_function(s)

    bless $self, $class;
    $self;
}

sub work {

}



1;

