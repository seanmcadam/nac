#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";
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

become_daemon();

my $bufsync = NAC::DBBufSync->new();

$bufsync->server_buf_loop();
EventLog( EVENT_INFO, "$0 Exiting" );

