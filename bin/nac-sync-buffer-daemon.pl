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

NAC::Syslog::DeactivateDebug();
# NAC::Syslog::ActivateDebug();
NAC::Syslog::DeactivateStdout();
# NAC::Syslog::ActivateStdout();

my $bufsync;

if(!( $bufsync = NAC::DBBufSync->new() )){
	EventLog( EVENT_ERR, "No DBBufSync Object, $0 Exiting" );
	exit;
}
	
if( ! ($bufsync->BUF) ) {
	EventLog( EVENT_WARN, "DBBufSync DB not available, $0 Exiting" );
	exit;
	}

$bufsync->server_setup();
become_daemon();
$bufsync->server_buf_loop();

EventLog( EVENT_INFO, "$0 Exiting" );

