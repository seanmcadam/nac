#!/usr/bin/perl
#
#
#
#
#

use FindBin;
use lib "$FindBin::Bin/../lib";
use Data::Dumper;
use Carp;
use NAC::Constants;
use NAC::DBConsts;
use NAC::DBReadOnly;
use NAC::Syslog;
use strict;


NAC::Syslog::ActivateDebug();

my $ro = NAC::DBReadOnly->new();

my %parms         = ();
my %vlans         = ();
my %vlans_by_name = ();

$parms{$HASH_REF} = \%vlans;

if ( !$ro->get_vlan( \%parms ) ) {
    die "No VLANs Found\n";
}

foreach my $v ( keys(%vlans) ) {
    $vlans_by_name{ $vlans{$v}->{$DB_COL_VLAN_NAME} } = $vlans{$v};
}

foreach my $v ( sort( keys(%vlans_by_name) ) ) {
    my $name = $v;
    my $vlan = $vlans_by_name{$v}->{$DB_COL_VLAN_VLAN};
    my $cidr = $vlans_by_name{$v}->{$DB_COL_VLAN_CIDR};
    my $type = $vlans_by_name{$v}->{$DB_COL_VLAN_TYPE};
    my $coe  = $vlans_by_name{$v}->{$DB_COL_VLAN_COE};
    print Dumper $vlans_by_name{$v};
    print "$name,$vlan,$cidr,$type," . (($coe)?"1":"0") . "\n";
}

