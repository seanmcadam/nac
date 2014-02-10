#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use Data::Dumper;
use Carp;
use NAC::Syslog;
use NA::CMisc;
use NA::CConstants;
use NA::CDBBufSync;
use strict;

# NAC::Syslog::DeactivateDebug();
NAC::Syslog::ActivateDebug();
NAC::Syslog::DeactivateStdout();
NAC::Syslog::ActivateStdout();

my $bufsync = NAC::DBBufSync->new();
$bufsync->sync_switchportstate_all();

