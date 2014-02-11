#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/nac-rel-2.0/db-ib/list-templates.pl $:
#
#
# Author: Sean McAdam
#
#
# Purpose: Script to list out templates in the system.
#
#
#

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use NAC::Constants;
use NAC::DBConsts;
use NAC::DBReadOnly;
use NAC::Constants;
use NAC::Syslog;
use Data::Dumper;
use POSIX;
use Carp;
use strict;

sub print_usage();

ActivateDebug;

# DeactivateDebug;
ActivateStderr;

# ActivateSyslog;

my $mysql;
my %parm = ();

my %template     = ();
my %templatename = ();

#----------------------------------------
# Open Database
#----------------------------------------
$mysql = NAC::DBReadOnly->new();

#----------------------------------------
# VLANGROUPs
#----------------------------------------
$parm{$HASH_REF} = \%template;
if ( !$mysql->get_template( \%parm ) ) {
    confess "No TEMPLATES defined"
}

foreach my $tid ( keys(%template) ) {
    $templatename{ $template{$tid}->{$DB_COL_TEMP_NAME} } = $template{$tid};
}

foreach my $templatename ( sort( keys(%templatename) ) ) {
    print STDOUT "$templatename\n";
}

