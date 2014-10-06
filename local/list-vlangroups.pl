#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/nac-rel-2.0/db-ib/list-vlangroups.pl $:
#
#
# Author: Sean McAdam
#
#
# Purpose:
#
# Perl Rocks!
#
#------------------------------------------------------
#
#
#

$| = 1;

use FindBin;
use lib "$FindBin::Bin/../lib";
use NAC::Constants;
use NAC::DBConsts;
use NAC::DBReadOnly;
use NAC::Constants;
use NAC::Syslog;
use Data::Dumper;
use POSIX;
use Carp;
use strict;

#ActivateDebug;
DeactivateDebug;
ActivateStderr;
ActivateSyslog;

my $mysql;
my %parm = ();

my %vlangroup     = ();
my %vlangroupname = ();

#----------------------------------------
# Open Database
#----------------------------------------
$mysql = NAC::DBReadOnly->new();

#----------------------------------------
# VLANGROUPs
#----------------------------------------
$parm{$HASH_REF} = \%vlangroup;
if ( !$mysql->get_vlangroup( \%parm ) ) {
    confess "No VLANGROUPs defined"
}

foreach my $vgid ( keys(%vlangroup) ) {
    $vlangroupname{ $vlangroup{$vgid}->{$DB_COL_VG_NAME} } = $vlangroup{$vgid};
}

foreach my $vgname ( sort( keys(%vlangroupname) ) ) {
    print STDOUT "$vgname\n";
}

