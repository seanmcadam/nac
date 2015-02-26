#!/usr/bin/perl

package NAC::LocalLogger;

use Data::Dumper;
use base qw( Exporter );
use Gearman::XS qw(:constants);
use FindBin;
use lib "$FindBin::Bin/..";
use NAC::Client::Logger;
use strict;

our @EXPORT = ( @NAC::Client::Logger::EXPORT );

# print "LocalLogger EXPORTs:\n" . Dumper @NAC::Client::Logger::EXPORT;

our @ISA = qw(NAC::Client::Logger);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

