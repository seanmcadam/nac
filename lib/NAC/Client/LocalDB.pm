#!/usr/bin/perl

package NAC::Client::LocalDB;

use Data::Dumper;
use Carp;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::Client;
use NAC::DataRequest::SQL;
use NAC::DataRequest::GetLocalSQL;

# use Gearman::XS qw(:constants);
# use Sys::Hostname;
use strict;

our @ISA = qw(NAC::Client);

# ---------------------------------------------
sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
}

sub do {
    my ( $self, $sqlobj ) = @_;
    my $result;

    if ( 'NAC::DataRequest::SQL' ne ref($sqlobj) ) {
        confess __PACKAGE__ . "Found: " . ref($sqlobj) . " as Object\nDumper: " . Dumper @_;
    }

    $result = $self->SUPER::do( GET_LOCAL_SQL_FUNCTION, $sqlobj );

    $result;

}

