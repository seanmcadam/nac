#!/usr/bin/perl

package NAC::DataRequest::LocalLogger;

use Data::Dumper;
use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest::Logger;
use strict;

use constant LOCAL_LOGGER_FUNCTION => 'nac_local_logger';

our @export = qw(
    LOCAL_LOGGER_FUNCTION
);

our @EXPORT = ( @export, @NAC::DataRequest::Logger::EXPORT );

# print "DataRequest::LocalLogger EXPORTs:\n" . Dumper @NAC::DataRequest::Logger::EXPORT;

our @ISA = qw(NAC::DataRequest::Logger);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);
    bless $self, $class;
    $self;
}

1;
