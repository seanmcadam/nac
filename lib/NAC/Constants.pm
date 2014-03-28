#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: 1750 $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/Constants.pm $:
#
#
# Author: Sean McAdam
# Purpose: Provide single place for all readonly variables/constants
#

package NAC::Constants;
use FindBin;
use lib "$FindBin::Bin/..";
use base qw( Exporter );
use Readonly;
use Data::Dumper;

# use NACSyslog;
use strict;

sub site_name_rollup($);

Readonly our $HASH_REF => 'HASH_REF';
Readonly our $YES      => 1;
Readonly our $NO       => 0;

Readonly our $MINIMUM_IDLE_TIMEOUT      => 60 * 5;              # 5  Min
Readonly our $DEFAULT_IDLE_TIMEOUT      => 60 * 60 * 6;         # 6  Hours
Readonly our $MAXIMUM_IDLE_TIMEOUT      => 60 * 60 * 12;        # 12 Hours
Readonly our $MINIMUM_SESSION_TIMEOUT   => 60;                  # 1  Min
Readonly our $DEFAULT_SESSION_TIMEOUT   => 60 * 5;              # 5  Min
Readonly our $MAXIMUM_SESSION_TIMEOUT   => 60 * 60 * 24;        # 1  Day
Readonly our $CLASS_NAME_BLOCK          => 'BLOCKEDMAC';
Readonly our $CLASS_NAME_CHALLENGE      => 'CHALLENGE';
Readonly our $CLASS_NAME_COE            => 'COE';
Readonly our $CLASS_NAME_GUEST          => 'GUEST';
Readonly our $CLASS_NAME_GUESTFALLBACK  => 'GUESTFALLBACK';
Readonly our $CLASS_NAME_GUESTCHALLENGE => 'GUEST_CHALLENGE';
Readonly our $CLASS_NAME_MAC2TEMPLATE   => 'TEMPLATE';
Readonly our $CLASS_NAME_MAC2VLANGROUP  => 'MAC2VLANGROUP';
Readonly our $CLASS_NAME_MAC2VLAN       => 'MAC2VLANID';
Readonly our $CLASS_NAME_PORT2VLAN      => 'FIXEDPORTTYPE';
Readonly our $CLASS_NAME_RESERVEDIP     => 'RESERVEDIP';
Readonly our $CLASS_NAME_REMEDIATION    => 'REMEDIATION';
Readonly our $CLASS_NAME_STATICMACVLAN  => 'STATICMACVLAN';

Readonly our $VG_NAME_CHALLENGE      => 'CHALLENGE';
Readonly our $VG_NAME_GUESTCHALLENGE => 'GUESTCHALLENGE';

Readonly our $VLAN_TYPE_BLOCK     => 'BLOCK';
Readonly our $VLAN_TYPE_CHALLENGE => 'CHALLENGE';
Readonly our $VLAN_TYPE_GUEST     => 'GUEST';
Readonly our $VLAN_TYPE_AUTH      => 'AUTH';

Readonly our %MAC_OUI_CISCO_DEVICE => (
    '00:05:31' => 1,
    '00:07:b4' => 1,
    '00:0f:f7' => 1,
    '00:13:c3' => 1,
    '00:14:6a' => 1,
    '00:18:ba' => 1,
    '00:1a:e2' => 1,
    '00:21:1c' => 1,
    '00:25:b4' => 1,
    '00:30:b6' => 1,
    '00:1e:13' => 1,
    '00:1e:c9' => 1,
    '3c:df:1e' => 1,
    '44:2b:03' => 1,
    'ac:f2:c5' => 1,
    'b0:fa:eb' => 1,
    'd4:8c:b5' => 1,
    'f4:ac:c1' => 1,
);

Readonly our %MAC_OUI_PHONE => (
    '00:0e:d7' => 1,
    '00:11:92' => 1,
    '00:19:aa' => 1,
    '00:19:e7' => 1,
    '00:21:a0' => 1,
    '00:26:0b' => 1,
    '1c:e6:c7' => 1,
    '20:3a:07' => 1,
    '20:bb:c0' => 1,
    'b0:fa:eb' => 1,
    '84:78:ac' => 1,
);

# Move to DATABASE - WORK HERE
# and/or import from IB
Readonly our %NAC_VLAN_TYPES => {
    'AUTH'      => 1,
    'BLOCK'     => 1,
    'CHALLENGE' => 1,
    'CRYPTO'    => 1,
    'DELEGATE'  => 1,
    'GUEST'     => 1,
    'MGMT'      => 1,
    'PRINT'     => 1,
    'RESERVED'  => 1,
    'SERVER'    => 1,
    'TEMP'      => 1,
    'TRANSIT'   => 1,
    'UNUSED'    => 1,
    'USER'      => 1,
    'VERIFY'    => 1,
    'VIDEO'     => 1,
    'VOICE'     => 1,
    'X'         => 1,
};

# VALID Site Names
# Move to DATABASE - WORK HERE
Readonly our %NAC_SITES => {
    'SITE1' => 1,
    'SITE2' => 1,
    'SITE3' => 1,
};

Readonly our @SKIP_DEVICE_NAME_REGEX_ARRAY => (
    '^prefix1',
    '^prefix2',
);

Readonly our %ACCEPTABLE_DEVICE_TYPES => {
    2  => 1,
    6  => 1,
    78 => 1,
};

# Move to DATABASE - WORK HERE
Readonly our %ACCEPTABLE_DEVICE_MODELS => {
    "c1002-x"     => $NO,
    "c1006-rp2"   => $NO,
    "c1841"       => $YES,
    "c2501"       => $NO,
    "c2620"       => $NO,
    "c2650"       => $NO,
    "c2651xm"     => $NO,
    "c2811"       => $NO,
    "c2821"       => $NO,
    "c2912mf-xl"  => $NO,
    "c2916"       => $NO,
    "c2924c-xl"   => $NO,
    "c2924m-xl"   => $NO,
    "c2948"       => $NO,
    "c2950"       => $NO,
    "c2950-12"    => $NO,
    "c2950c"      => $NO,
    "c2950g-12ei" => $NO,
    "c2950g-24ei" => $NO,
    "c2950g-48ei" => $NO,
    "c2950t"      => $NO,
    "c2950t-24"   => $NO,
    "c2951"       => $NO,
    "c2970"       => $NO,
    "c2980"       => $NO,
    "c2980g-a"    => $NO,
    "c3048-nexus" => $NO,
    "c3130x"      => $NO,
    "c3508g-xl"   => $NO,
    "c3512"       => $NO,
    "c3524"       => $NO,
    "c3548"       => $NO,
    "c3550"       => $NO,
    "c3550-12g"   => $NO,
    "c3550-12t"   => $NO,
    "c3550-24"    => $NO,
    "c3550-24-fx" => $NO,
    "c3550-48"    => $NO,
    "c3560-24ps"  => $YES,
    "c3560x-24p"  => $YES,
    "c3560-8pc"   => $YES,
    "c3560cg-8pc" => $YES,
    "c3560g-24ps" => $YES,
    "c3560g-24ts" => $YES,
    "c3560g-48ps" => $YES,
    "c3640"       => $NO,
    "c3745"       => $NO,
    "c3750"       => $YES,
    "c3750-nme"   => $YES,
    "c3845"       => $YES,
    "c3850-24p"   => $YES,
    "c3850-24t"   => $YES,
    "c3850-48t"   => $YES,
    "c3945"       => $YES,
    "c3945e"      => $NO,
    "c4006"       => $NO,
    "c4402-wlc"   => $NO,
    "c4451-x"     => $NO,
    "c4503"       => $NO,
    "c4506"       => $YES,
    "c5000"       => $NO,
    "c5010-nexus" => $NO,
    "c5500"       => $NO,
    "c5505"       => $NO,
    "c5548-nexus" => $NO,
    "c5508-wlc"   => $NO,
    "c5505"       => $NO,
    "c6500-msfc2" => $NO,
    "c6500-vss"   => $YES,
    "c6504"       => $YES,
    "c6506"       => $YES,
    "c6509"       => $YES,
    "c6513"       => $YES,
    "c7201"       => $NO,
    "c7204vxr"    => $NO,
    "c7206vxr"    => $NO,
    "c881"        => $YES,
    "c891"        => $YES,
    "ciscoigesm"  => $NO,
    "cvg202"      => $NO,
    "cvg204"      => $NO,
    "cvg224"      => $NO,
};

# VALID Site Building Names
# Move to DATABASE - WORK HERE
Readonly our %NAC_SITE_NAMES => {
    'SITE1_X'     => 1,
    'SITE1_BLDG1' => 1,
    'SITE1_BLDG2' => 1,
    'SITE2_BLDG1' => 1,
    'SITE2_BLDG2' => 1,
    'SITE3_BLDG1' => 1,
    'SITE3_BLDG2' => 1,
    'SITE3_BLDG3' => 1,
};

# WARNING WARNING WARNING WARNING WARNING WARNING
#
# If you Make changes here you must run the fixup scripts afterwards
#
# WARNING WARNING WARNING WARNING WARNING WARNING
#
# Rolls an entire site up into a single vlan area
#
Readonly our %NAC_SITE_ROLLUP => {
    'SITE1' => 'SITE1_X',
};

# WARNING WARNING WARNING WARNING WARNING WARNING
#
# If you Make changes here you must run the fixup scripts afterwards
#
# WARNING WARNING WARNING WARNING WARNING WARNING
Readonly our %NAC_SITE_NAMES_REPLACEMENT => {
    'SITE2_BLDG2' => 'SITE2_BLDG1',
};

Readonly our $EVENT_PARM_PRIO      => 'EVENT_PARM_PRIO';
Readonly our $EVENT_PARM_LOGLINE   => 'EVENT_PARM_LOGLINE';
Readonly our $EVENT_PARM_USERID    => 'EVENT_PARM_USERID';
Readonly our $EVENT_PARM_TYPE      => 'EVENT_PARM_TYPE';
Readonly our $EVENT_PARM_HOST      => 'EVENT_PARM_HOST';
Readonly our $EVENT_PARM_CLASSID   => 'EVENT_PARM_CLASSID';
Readonly our $EVENT_PARM_LOCID     => 'EVENT_PARM_LOCID';
Readonly our $EVENT_PARM_MACID     => 'EVENT_PARM_MACID';
Readonly our $EVENT_PARM_MAGICID   => 'EVENT_PARM_MAGICID';
Readonly our $EVENT_PARM_M2CID     => 'EVENT_PARM_M2CID';
Readonly our $EVENT_PARM_P2CID     => 'EVENT_PARM_P2CID';
Readonly our $EVENT_PARM_SWID      => 'EVENT_PARM_SWID';
Readonly our $EVENT_PARM_SWPID     => 'EVENT_PARM_SWPID';
Readonly our $EVENT_PARM_SW2VID    => 'EVENT_PARM_SW2VID';
Readonly our $EVENT_PARM_TEMPID    => 'EVENT_PARM_TEMPID';
Readonly our $EVENT_PARM_TEMP2VGID => 'EVENT_PARM_TEMP2VGID';
Readonly our $EVENT_PARM_VGID      => 'EVENT_PARM_VGID';
Readonly our $EVENT_PARM_VG2VID    => 'EVENT_PARM_VG2VID';
Readonly our $EVENT_PARM_VLANID    => 'EVENT_PARM_VLANID';
Readonly our $EVENT_PARM_IP        => 'EVENT_PARM_IP';
Readonly our $EVENT_PARM_DESC      => 'EVENT_PARM_DESC';

use constant {
    EVENT_TYPE                     => 'EVENT_TYPE',
    EVENT_TYPE_TEST                => 'EVENT_TYPE_TEST',
    EVENT_TYPE_BLOCKED             => 'EVENT_TYPE_BLOCKED',
    EVENT_TYPE_CHALLENGE           => 'EVENT_TYPE_CHALLENGE',
    EVENT_TYPE_NOTICE              => 'EVENT_TYPE_NOTICE',
    EVENT_TYPE_WARNING             => 'EVENT_TYPE_WARNING',
    EVENT_TYPE_ERROR               => 'EVENT_TYPE_ERROR',
    EVENT_TYPE_CRIT                => 'EVENT_TYPE_CRIT',
    EVENT_PARM_BLDG                => 'EVENT_PARM_BLDG',
    EVENT_PARM_CLASS               => 'EVENT_PARM_CLASS',
    EVENT_PARM_IP                  => 'EVENT_PARM_IP',
    EVENT_PARM_LOCATION            => 'EVENT_PARM_LOCATION',
    EVENT_PARM_MAC                 => 'EVENT_PARM_MAC',
    EVENT_PARM_MSG                 => 'EVENT_PARM_MSG',
    EVENT_PARM_SITE                => 'EVENT_PARM_SITE',
    EVENT_PARM_SWITCH              => 'EVENT_PARM_SWITCH',
    EVENT_PARM_SWITCHPORT          => 'EVENT_PARM_SWITCHPORT',
    EVENT_PARM_VLAN                => 'EVENT_PARM_VLAN',
    EVENT_PARM_VLANGROUP           => 'EVENT_PARM_VLANGROUP',
    EVENT_PRIO_LOGIC_FAIL          => 'EVENT_PRIO_LOGIC_FAIL',
    EVENT_PRIO_EVAL_FAIL           => 'EVENT_PRIO_EVAL_FAIL',
    EVENT_PRIO_FUNC_FAIL           => 'EVENT_PRIO_FUNC_FAIL',
    EVENT_PRIO_ERR                 => 'EVENT_PRIO_ERR',
    EVENT_PRIO_WARN                => 'EVENT_PRIO_WARN',
    EVENT_PRIO_NOTICE              => 'EVENT_PRIO_NOTICE',
    EVENT_PRIO_INFO                => 'EVENT_PRIO_INFO',
    EVENT_PRIO_DEBUG               => 'EVENT_PRIO_DEBUG',
    EVENT_PRIO_FATAL               => 'EVENT_PRIO_FATAL',
    EVENT_START                    => 'EVENT_START',
    EVENT_STOP                     => 'EVENT_STOP',
    EVENT_ACCT_STOP                => 'EVENT_ACCT_STOP',
    EVENT_ACCT_START               => 'EVENT_ACCT_START',
    EVENT_AUTH_CLEAR               => 'EVENT_AUTH_CLEAR',
    EVENT_AUTH_BLOCK               => 'EVENT_AUTH_BLOCK',
    EVENT_AUTH_CHALLENGE           => 'EVENT_AUTH_CHALLENGE',
    EVENT_AUTH_GUEST               => 'EVENT_AUTH_GUEST',
    EVENT_AUTH_MAC                 => 'EVENT_AUTH_MAC',
    EVENT_AUTH_PORT                => 'EVENT_AUTH_PORT',
    EVENT_AUTH_VOICE               => 'EVENT_AUTH_VOICE',
    EVENT_AUTH_NAK                 => 'EVENT_AUTH_NAK',
    EVENT_CHALLENGE_ERR            => 'EVENT_CHALLENGE_ERR',
    EVENT_CIDR_ADD                 => 'EVENT_CIDR_ADD',
    EVENT_CIDR_DEL                 => 'EVENT_CIDR_DEL',
    EVENT_CLASS_ADD                => 'EVENT_CLASS_ADD',
    EVENT_CLASS_DEL                => 'EVENT_CLASS_DEL',
    EVENT_CLASS_UPD                => 'EVENT_CLASS_UPD',
    EVENT_DB_ERR                   => 'EVENT_DB_ERR',
    EVENT_DB_WARN                  => 'EVENT_DB_WARN',
    EVENT_FIXEDIP_ADD              => 'EVENT_FIXED_IP_ADD',
    EVENT_FIXEDIP_DEL              => 'EVENT_FIXED_IP_DEL',
    EVENT_FIXEDIP_UPD              => 'EVENT_FIXED_IP_UPD',
    EVENT_MAC2CLASS_ADD            => 'EVENT_MAC2CLASS_ADD',
    EVENT_MAC2CLASS_DEL            => 'EVENT_MAC2CLASS_DEL',
    EVENT_MAC2CLASS_UPD            => 'EVENT_MAC2CLASS_UPD',
    EVENT_MAC_ADD                  => 'EVENT_MAC_ADD',
    EVENT_MAC_DEL                  => 'EVENT_MAC_DEL',
    EVENT_MAC_UPD                  => 'EVENT_MAC_UPD',
    EVENT_MAGIC_PORT               => 'EVENT_MAGIC_PORT',
    EVENT_MEMCACHE_ERR             => 'EVENT_MEMCACHE_ERR',
    EVENT_MEMCACHE_WARN            => 'EVENT_MEMCACHE_WARN',
    EVENT_LOC_ADD                  => 'EVENT_LOCATION_ADD',
    EVENT_LOC_DEL                  => 'EVENT_LOCATION_DEL',
    EVENT_LOC_UPD                  => 'EVENT_LOCATION_UPD',
    EVENT_PORT_ADD                 => 'EVENT_PORT_ADD',
    EVENT_PORT_DEL                 => 'EVENT_PORT_DEL',
    EVENT_PORT2CLASS_ADD           => 'EVENT_PORT2CLASS_ADD',
    EVENT_PORT2CLASS_DEL           => 'EVENT_PORT2CLASS_DEL',
    EVENT_PORT2CLASS_UPD           => 'EVENT_PORT2CLASS_UPD',
    EVENT_SWITCH_ADD               => 'EVENT_SWITCH_ADD',
    EVENT_SWITCH_DEL               => 'EVENT_SWITCH_DEL',
    EVENT_SWITCH_UPD               => 'EVENT_SWITCH_UPD',
    EVENT_SWITCHPORT_ADD           => 'EVENT_SWITCHPORT_ADD',
    EVENT_SWITCHPORT_UPD           => 'EVENT_SWITCHPORT_UPD',
    EVENT_SWITCHPORT_DEL           => 'EVENT_SWITCHPORT_DEL',
    EVENT_SWITCH2VLAN_ADD          => 'EVENT_SWITCH2VLAN_ADD',
    EVENT_SWITCH2VLAN_DEL          => 'EVENT_SWITCH2VLAN_DEL',
    EVENT_TEMPLATE_ADD             => 'EVENT_TEMPLATE_ADD',
    EVENT_TEMPLATE_DEL             => 'EVENT_TEMPLATE_DEL',
    EVENT_TEMPLATE2VLANGROUP_ADD   => 'EVENT_TEMPLATE2VLANGROUP_ADD',
    EVENT_TEMPLATE2VLANGROUP_DEL   => 'EVENT_TEMPLATE2VLANGROUP_DEL',
    EVENT_VLAN_ADD                 => 'EVENT_VLAN_ADD',
    EVENT_VLAN_UPD                 => 'EVENT_VLAN_UPD',
    EVENT_VLAN_DEL                 => 'EVENT_VLAN_DEL',
    EVENT_VLANGROUP_ADD            => 'EVENT_VLANGROUP_ADD',
    EVENT_VLANGROUP_UPD            => 'EVENT_VLANGROUP_UPD',
    EVENT_VLANGROUP_DEL            => 'EVENT_VLANGROUP_DEL',
    EVENT_VLANGROUP2VLAN_ADD       => 'EVENT_VLANGROUP2VLAN_ADD',
    EVENT_VLANGROUP2VLAN_DEL       => 'EVENT_VLANGROUP2VLAN_DEL',
    EVENT_NOLOCATION               => 'EVENT_NOLOCATION',
    EVENT_SMTP_FAIL                => 'EVENT_SMTP_FAIL',
    EVENT_LOGIC_FAIL               => 'EVENT_LOGIC_FAIL',
    EVENT_EVAL_FAIL                => 'EVENT_EVAL_FAIL',
    EVENT_FUNC_FAIL                => 'EVENT_FUNC_FAIL',
    EVENT_ERR                      => 'EVENT_ERR',
    EVENT_WARN                     => 'EVENT_WARN',
    EVENT_NOTICE                   => 'EVENT_NOTICE',
    EVENT_INFO                     => 'EVENT_INFO',
    EVENT_DEBUG                    => 'EVENT_DEBUG',
    EVENT_FATAL                    => 'EVENT_FATAL',
    EVENT_DISTRESS                 => 'EVENT_DISTRESS',
    DB_PERM_ADMIN                  => 'DB_PERM_ADMIN',
    DB_PERM_TECH                   => 'DB_PERM_TECH',
    DB_PERM_GUEST                  => 'DB_PERM_GUEST',
    DB_PERM_CLASS_ADD              => 'DB_PERM_CLASS_ADD',
    DB_PERM_CLASSMACPORT_GET       => 'DB_PERM_CLASSMACPORT_GET',
    DB_PERM_CLASS_GET              => 'DB_PERM_CLASS_GET',
    DB_PERM_CLASS_REM              => 'DB_PERM_CLASS_REM',
    DB_PERM_CLASS_UPD              => 'DB_PERM_CLASS_UPD',
    DB_PERM_DHCPS_GET              => 'DB_PERM_DHCPS_GET',
    DB_PERM_EVENTLOG_GET           => 'DB_PERM_EVENTLOG_GET',
    DB_PERM_EVENTLOG_REM           => 'DB_PERM_EVENTLOG_REM',
    DB_PERM_LOCATION_ADD           => 'DB_PERM_LOCATION_ADD',
    DB_PERM_LOCATION_GET           => 'DB_PERM_LOCATION_GET',
    DB_PERM_LOCATION_REM           => 'DB_PERM_LOCATION_REM',
    DB_PERM_LOCATION_UPD           => 'DB_PERM_LOCATION_UPD',
    DB_PERM_MAC2CLASS_ADD          => 'DB_PERM_MAC2CLASS_ADD',
    DB_PERM_MAC2CLASS_GET          => 'DB_PERM_MAC2CLASS_GET',
    DB_PERM_MAC2CLASS_REM          => 'DB_PERM_MAC2CLASS_REM',
    DB_PERM_MAC2CLASS_UPD          => 'DB_PERM_MAC2CLASS_UPD',
    DB_PERM_MAC_ADD                => 'DB_PERM_MAC_ADD',
    DB_PERM_MAC_GET                => 'DB_PERM_MAC_GET',
    DB_PERM_MAC_REM                => 'DB_PERM_MAC_REM',
    DB_PERM_MAC_UPD                => 'DB_PERM_MAC_UPD',
    DB_PERM_PORT2CLASS_ADD         => 'DB_PERM_PORT2CLASS_ADD',
    DB_PERM_PORT2CLASS_GET         => 'DB_PERM_PORT2CLASS_GET',
    DB_PERM_PORT2CLASS_REM         => 'DB_PERM_PORT2CLASS_REM',
    DB_PERM_PORT2CLASS_UPD         => 'DB_PERM_PORT2CLASS_UPD',
    DB_PERM_RADIUSAUDIT_GET        => 'DB_PERM_RADIUSAUDIT_GET',
    DB_PERM_RADIUSAUDIT_REM        => 'DB_PERM_RADIUSAUDIT_REM',
    DB_PERM_SWITCH2VLAN_ADD        => 'DB_PERM_SWITCH2VLAN_ADD',
    DB_PERM_SWITCH2VLAN_GET        => 'DB_PERM_SWITCH2VLAN_GET',
    DB_PERM_SWITCH2VLAN_REM        => 'DB_PERM_SWITCH2VLAN_REM',
    DB_PERM_SWITCH2VLAN_UPD        => 'DB_PERM_SWITCH2VLAN_UPD',
    DB_PERM_SWITCHPORT_ADD         => 'DB_PERM_SWITCHPORT_ADD',
    DB_PERM_SWITCHPORT_GET         => 'DB_PERM_SWITCHPORT_GET',
    DB_PERM_SWITCHPORT_REM         => 'DB_PERM_SWITCHPORT_REM',
    DB_PERM_SWITCHPORT_UPD         => 'DB_PERM_SWITCHPORT_UPD',
    DB_PERM_SWITCHPORTSTATE_GET    => 'DB_PERM_SWITCHPORTSTATE_GET',
    DB_PERM_SWITCH_ADD             => 'DB_PERM_SWITCH_ADD',
    DB_PERM_SWITCH_GET             => 'DB_PERM_SWITCH_GET',
    DB_PERM_SWITCH_REM             => 'DB_PERM_SWITCH_REM',
    DB_PERM_SWITCH_UPD             => 'DB_PERM_SWITCH_UPD',
    DB_PERM_TEMPLATE2VLANGROUP_ADD => 'DB_PERM_TEMPLATE2VLANGROUP_ADD',
    DB_PERM_TEMPLATE2VLANGROUP_GET => 'DB_PERM_TEMPLATE2VLANGROUP_GET',
    DB_PERM_TEMPLATE2VLANGROUP_REM => 'DB_PERM_TEMPLATE2VLANGROUP_REM',
    DB_PERM_TEMPLATE2VLANGROUP_UPD => 'DB_PERM_TEMPLATE2VLANGROUP_UPD',
    DB_PERM_TEMPLATE_ADD           => 'DB_PERM_TEMPLATE_ADD',
    DB_PERM_TEMPLATE_GET           => 'DB_PERM_TEMPLATE_GET',
    DB_PERM_TEMPLATE_REM           => 'DB_PERM_TEMPLATE_REM',
    DB_PERM_TEMPLATE_UPD           => 'DB_PERM_TEMPLATE_UPD',
    DB_PERM_VLANGROUP2VLAN_ADD     => 'DB_PERM_VLANGROUP2VLAN_ADD',
    DB_PERM_VLANGROUP2VLAN_GET     => 'DB_PERM_VLANGROUP2VLAN_GET',
    DB_PERM_VLANGROUP2VLAN_REM     => 'DB_PERM_VLANGROUP2VLAN_REM',
    DB_PERM_VLANGROUP2VLAN_UPD     => 'DB_PERM_VLANGROUP2VLAN_UPD',
    DB_PERM_VLANGROUP_ADD          => 'DB_PERM_VLANGROUP_ADD',
    DB_PERM_VLANGROUP_GET          => 'DB_PERM_VLANGROUP_GET',
    DB_PERM_VLANGROUP_REM          => 'DB_PERM_VLANGROUP_REM',
    DB_PERM_VLANGROUP_UPD          => 'DB_PERM_VLANGROUP_UPD',
    DB_PERM_VLAN_GET               => 'DB_PERM_VLAN_GET',
    DB_PERM_VLAN_REM               => 'DB_PERM_VLAN_REM',
    DB_PERM_VLAN_UPD               => 'DB_PERM_VLAN_UPD',

};

#-------------------------
# Returns a Site_Bldg name substitute if needed
#-------------------------
sub site_name_rollup($) {
    my $sb = shift;

    if ( ( !defined $sb ) || ( !( $sb =~ /_/ ) ) ) {
        NACSyslog::EventLog( EVENT_FATAL, "'$sb' passed in" );
    }

    $sb =~ tr/a-z/A-Z/;
    my ( $rollup_site, $rollup_bldg ) = split( /_/, $sb );

    #
    # Change the Location here
    # Roll up a whole site to one name or an individual building
    # Hard coded for HQ-FS and HQ-FN to be HQ-FOR
    #

    if ( defined $NAC_SITE_NAMES_REPLACEMENT{$sb} ) {
        NACSyslog::EventLog( EVENT_DEBUG, "REMAP SITE BLDG: $sb to " . $NAC_SITE_NAMES_REPLACEMENT{$sb} );
        $sb = $NAC_SITE_NAMES_REPLACEMENT{$sb};
    }
    elsif ( defined $NAC_SITE_ROLLUP{$rollup_site} ) {
        NACSyslog::EventLog( EVENT_DEBUG, "REMAP SITE ROLLUP: $sb to " . $NAC_SITE_ROLLUP{$rollup_site} );
        $sb = $NAC_SITE_ROLLUP{$rollup_site};
    }

    return $sb;
}

# Readonly our $MYSQL_DB => 'MYSQL_DB';

our @EXPORT = qw (
  site_name_rollup
  %NAC_VLAN_TYPES
  %NAC_SITES
  %NAC_SITE_ROLLUP
  %NAC_SITE_NAMES
  %NAC_SITE_NAMES_REPLACEMENT
  @SKIP_DEVICE_NAME_REGEX_ARRAY
  %ACCEPTABLE_DEVICE_TYPES
  %ACCEPTABLE_DEVICE_MODELS
  %MAC_OUI_CISCO_DEVICE
  %MAC_OUI_PHONE
  $YES
  $NO
  $HASH_REF
  $DEFAULT_IDLE_TIMEOUT
  $MINIMUM_IDLE_TIMEOUT
  $DEFAULT_SESSION_TIMEOUT
  $MINIMUM_SESSION_TIMEOUT
  $CLASS_NAME_BLOCK
  $CLASS_NAME_CHALLENGE
  $CLASS_NAME_COE
  $CLASS_NAME_GUEST
  $CLASS_NAME_GUESTFALLBACK
  $CLASS_NAME_GUESTCHALLENGE
  $CLASS_NAME_MAC2TEMPLATE
  $CLASS_NAME_MAC2VLANGROUP
  $CLASS_NAME_MAC2VLAN
  $CLASS_NAME_PORT2VLAN
  $CLASS_NAME_RESERVEDIP
  $CLASS_NAME_REMEDIATION
  $CLASS_NAME_STATICMACVLAN
  $VG_NAME_CHALLENGE
  $VG_NAME_GUESTCHALLENGE
  $VLAN_TYPE_BLOCK
  $VLAN_TYPE_CHALLENGE
  $VLAN_TYPE_GUEST
  $VLAN_TYPE_RESERVED
  EVENT_TYPE
  EVENT_TYPE_TEST
  EVENT_TYPE_BLOCKED
  EVENT_TYPE_CHALLENGE
  EVENT_TYPE_NOTICE
  EVENT_TYPE_WARNING
  EVENT_TYPE_ERROR
  EVENT_TYPE_CRIT
  EVENT_PARM_IP
  EVENT_PARM_MAC
  EVENT_PARM_SITE
  EVENT_PARM_BLDG
  EVENT_PARM_VLAN
  EVENT_PARM_CLASS
  EVENT_PARM_SWITCH
  EVENT_PARM_SWITCHPORT
  EVENT_PARM_VLANGROUP

  $EVENT_PARM_LOGLINE
  $EVENT_PARM_USERID
  $EVENT_PARM_PRIO
  $EVENT_PARM_TYPE
  $EVENT_PARM_HOST
  $EVENT_PARM_CLASSID
  $EVENT_PARM_LOCID
  $EVENT_PARM_MACID
  $EVENT_PARM_MAGICID
  $EVENT_PARM_M2CID
  $EVENT_PARM_P2CID
  $EVENT_PARM_SWID
  $EVENT_PARM_SWPID
  $EVENT_PARM_SW2VID
  $EVENT_PARM_TEMPID
  $EVENT_PARM_TEMP2VGID
  $EVENT_PARM_VGID
  $EVENT_PARM_VG2VID
  $EVENT_PARM_VLANID
  $EVENT_PARM_IP
  $EVENT_PARM_DESC

  EVENT_LEVEL_LOGIC_FAIL
  EVENT_LEVEL_EVAL_FAIL
  EVENT_LEVEL_FUNC_FAIL
  EVENT_LEVEL_ERR
  EVENT_LEVEL_WARN
  EVENT_LEVEL_NOTICE
  EVENT_LEVEL_INFO
  EVENT_LEVEL_DEBUG
  EVENT_LEVEL_FATAL

  EVENT_ACCT_STOP
  EVENT_ACCT_START
  EVENT_AUTH_MAC
  EVENT_AUTH_VOICE
  EVENT_AUTH_CLEAR
  EVENT_AUTH_PORT
  EVENT_AUTH_NAK
  EVENT_AUTH_BLOCK
  EVENT_AUTH_CHALLENGE
  EVENT_AUTH_GUEST
  EVENT_CHALLENGE_ERR
  EVENT_CIDR_ADD
  EVENT_CIDR_DEL
  EVENT_CLASS_ADD
  EVENT_CLASS_DEL
  EVENT_CLASS_UPD
  EVENT_DB_ERR
  EVENT_DB_WARN
  EVENT_COE_ADD
  EVENT_COE_DEL
  EVENT_FIXEDIP_ADD
  EVENT_FIXEDIP_DEL
  EVENT_FIXEDIP_UPD
  EVENT_MAC_ADD
  EVENT_MAC_DEL
  EVENT_MAC_UPD
  EVENT_MAGIC_PORT
  EVENT_MAC2CLASS_ADD
  EVENT_MAC2CLASS_DEL
  EVENT_MAC2CLASS_UPD
  EVENT_MEMCACHE_ERR
  EVENT_MEMCACHE_WARN
  EVENT_NOLOCATION
  EVENT_PORT_ADD
  EVENT_PORT_DEL
  EVENT_PORT2CLASS_ADD
  EVENT_PORT2CLASS_DEL
  EVENT_PORT2CLASS_UPD
  EVENT_LOC_ADD
  EVENT_LOC_DEL
  EVENT_LOC_UPD
  EVENT_STOP
  EVENT_START
  EVENT_SMTP_FAIL
  EVENT_SWITCH_ADD
  EVENT_SWITCH_DEL
  EVENT_SWITCH_UPD
  EVENT_SWITCHPORT_ADD
  EVENT_SWITCHPORT_UPD
  EVENT_SWITCHPORT_DEL
  EVENT_SWITCH2VLAN_ADD
  EVENT_SWITCH2VLAN_DEL
  EVENT_TEMPLATE_ADD
  EVENT_TEMPLATE_DEL
  EVENT_TEMPLATE2VLANGROUP_ADD
  EVENT_TEMPLATE2VLANGROUP_DEL
  EVENT_VLAN_ADD
  EVENT_VLAN_UPD
  EVENT_VLAN_DEL
  EVENT_VLANGROUP_ADD
  EVENT_VLANGROUP_UPD
  EVENT_VLANGROUP_DEL
  EVENT_VLANGROUP2VLAN_ADD
  EVENT_VLANGROUP2VLAN_DEL
  EVENT_LOGIC_FAIL
  EVENT_EVAL_FAIL
  EVENT_FUNC_FAIL
  EVENT_ERR
  EVENT_WARN
  EVENT_NOTICE
  EVENT_INFO
  EVENT_DEBUG
  EVENT_FATAL
  DB_PERM_ADMIN
  DB_PERM_TECH
  DB_PERM_GUEST
  DB_PERM_CLASS_ADD
  DB_PERM_CLASSMACPORT_GET
  DB_PERM_CLASS_GET
  DB_PERM_CLASS_REM
  DB_PERM_CLASS_UPD
  DB_PERM_DHCPS_GET
  DB_PERM_EVENTLOG_GET
  DB_PERM_EVENTLOG_REM
  DB_PERM_LOCATION_ADD
  DB_PERM_LOCATION_GET
  DB_PERM_LOCATION_REM
  DB_PERM_LOCATION_UPD
  DB_PERM_MAC2CLASS_ADD
  DB_PERM_MAC2CLASS_GET
  DB_PERM_MAC2CLASS_REM
  DB_PERM_MAC2CLASS_UPD
  DB_PERM_MAC_ADD
  DB_PERM_MAC_GET
  DB_PERM_MAC_REM
  DB_PERM_MAC_UPD
  DB_PERM_PORT2CLASS_ADD
  DB_PERM_PORT2CLASS_GET
  DB_PERM_PORT2CLASS_REM
  DB_PERM_PORT2CLASS_UPD
  DB_PERM_RADIUSAUDIT_GET
  DB_PERM_RADIUSAUDIT_REM
  DB_PERM_SWITCH2VLAN_ADD
  DB_PERM_SWITCH2VLAN_GET
  DB_PERM_SWITCH2VLAN_REM
  DB_PERM_SWITCH2VLAN_UPD
  DB_PERM_SWITCHPORT_ADD
  DB_PERM_SWITCHPORT_GET
  DB_PERM_SWITCHPORT_REM
  DB_PERM_SWITCHPORT_UPD
  DB_PERM_SWITCHPORTSTATE_GET
  DB_PERM_SWITCH_ADD
  DB_PERM_SWITCH_GET
  DB_PERM_SWITCH_REM
  DB_PERM_SWITCH_UPD
  DB_PERM_TEMPLATE2VLANGROUP_ADD
  DB_PERM_TEMPLATE2VLANGROUP_GET
  DB_PERM_TEMPLATE2VLANGROUP_REM
  DB_PERM_TEMPLATE2VLANGROUP_UPD
  DB_PERM_TEMPLATE_ADD
  DB_PERM_TEMPLATE_GET
  DB_PERM_TEMPLATE_REM
  DB_PERM_TEMPLATE_UPD
  DB_PERM_VLANGROUP2VLAN_ADD
  DB_PERM_VLANGROUP2VLAN_GET
  DB_PERM_VLANGROUP2VLAN_REM
  DB_PERM_VLANGROUP2VLAN_UPD
  DB_PERM_VLANGROUP_ADD
  DB_PERM_VLANGROUP_GET
  DB_PERM_VLANGROUP_REM
  DB_PERM_VLANGROUP_UPD
  DB_PERM_VLAN_GET
  DB_PERM_VLAN_REM
  DB_PERM_VLAN_UPD
);

1;
