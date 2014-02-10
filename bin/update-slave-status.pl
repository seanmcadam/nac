#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Data::Dumper;
use Carp;
use NAC::Syslog;
use NAC::Constants;
use NAC::DBBuffer;
use strict;

my $buf = NAC::DBBuffer->new();

EventLog( EVENT_DEBUG, MYNAMELINE() . " running slave update " );

$buf->update_slave_status();


