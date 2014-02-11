#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/nac-rel-2.0/db-ib/list-vlans.pl $:
#
#
# Author: Sean McAdam
#
#
# Purpose:
#
#

use FindBin;
use lib "$FindBin::Bin/../lib/perl5";
use NAC::Constants;
use NAC::DBConsts;
use NAC::DBReadOnly;
use NAC::Constants;
use Data::Dumper;
use POSIX;
use Carp;
use strict;


# ActivateDebug;
DeactivateDebug;
ActivateStderr;
ActivateSyslog;

my $mysql;
my %parm = ();

my %vlan     = ();
my %vlanname = ();

#----------------------------------------
# Open Database
#----------------------------------------
$mysql = NAC::DBReadOnly->new();

#----------------------------------------
# VLANs
#----------------------------------------
$parm{$HASH_REF} = \%vlan;
if ( !$mysql->get_vlan( \%parm ) ) {
    confess "No VLANs defined"
}

foreach my $vgid ( keys(%vlan) ) {
    $vlanname{ $vlan{$vgid}->{$DB_COL_VLAN_NAME} } = $vlan{$vgid};
}

foreach my $vname ( sort( keys(%vlanname) ) ) {
    print STDOUT "$vname\n";
}


