#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Data::Dumper;
use Carp;
use NAC::Syslog;
use NAC::Constants;
use NAC::DBBufSync;
use strict;

my $buf = NAC::DBBufSync->new();

EventLog( EVENT_DEBUG, MYNAMELINE() . " running host update " );

$buf->sync_lastseen_host;

