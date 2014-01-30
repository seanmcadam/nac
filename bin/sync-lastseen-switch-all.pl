#!/usr/bin/perl

use Data::Dumper;
use Carp;
use NAC::Syslog;
use NAC::Misc;
use NAC::Constants;
use NAC::DBBufSync;
use strict;

# NAC::Syslog::DeactivateDebug();
NAC::Syslog::ActivateDebug();
NAC::Syslog::DeactivateStdout();
NAC::Syslog::ActivateStdout();

my $bufsync = NAC::DBBufSync->new();
$bufsync->sync_lastseen_switch_all();

