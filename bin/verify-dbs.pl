#!/usr/bin/perl

use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Carp;
use NAC::Syslog;
use NAC::Misc;
use NAC::Constants;
use NAC::DBAudit;
use NAC::DBBuffer;
use NAC::DBEventlog;
use NAC::DBRadiusAudit;
use NAC::DBReadOnly;
use NAC::DBStatus;
use strict;

#NAC::Syslog::DeactivateDebug();
NAC::Syslog::ActivateDebug();
NAC::Syslog::DeactivateSyslog();
NAC::Syslog::ActivateStdout();

my $audit = NAC::DBAudit->new();
my $buffer = NAC::DBBuffer->new();
my $eventlog = NAC::DBEventlog->new();
my $radiusaudit = NAC::DBRadiusAudit->new();
my $readonly = NAC::DBReadOnly->new();
my $status = NAC::DBStatus->new();

$audit->connect();
$buffer->connect();
$eventlog->connect();
$radiusaudit->connect();
$readonly->connect();
$status->connect();

