#!/usr/bin/perl
# SVN: $Id: NACDBConsts.pm 1538 2012-10-16 14:11:02Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-16 10:11:02 -0400 (Tue, 16 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBConsts.pm $:
#
#
# Author: Sean McAdam
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBConsts;
#use lib "$ENV{HOME}/lib/perl5";
use FindBin;
use lib "$FindBin::Bin/../lib";


use base qw( Exporter );
use Readonly;
use NAC::Constants;
use strict;

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;

Readonly our $MAGICPORT_ADD     => 'ADD';
Readonly our $MAGICPORT_REPLACE => 'REPLACE';

Readonly our $DB_BUF_TABLE_ADD_MAC                    => 'add_mac';
Readonly our $DB_BUF_TABLE_ADD_SWITCH                 => 'add_switch';
Readonly our $DB_BUF_TABLE_ADD_SWITCHPORT             => 'add_switchport';
Readonly our $DB_BUF_TABLE_ADD_RADIUSAUDIT            => 'add_radiusaudit';
Readonly our $DB_BUF_TABLE_EVENTLOG                   => 'eventlog';
Readonly our $DB_BUF_TABLE_LASTSEEN_LOCATION          => 'lastseen_location';
Readonly our $DB_BUF_TABLE_LASTSEEN_MAC               => 'lastseen_mac';
Readonly our $DB_BUF_TABLE_LASTSEEN_SWITCH            => 'lastseen_switch';
Readonly our $DB_BUF_TABLE_LASTSEEN_SWITCHPORT        => 'lastseen_switchport';
Readonly our $DB_BUF_TABLE_SWITCHPORTSTATE            => 'switchportstate';
Readonly our $DB_TABLE_CLASS                          => 'class';
Readonly our $DB_TABLE_CLASSMACPORT                   => 'classmacport-pusdo-table';
Readonly our $DB_TABLE_DHCPSTATE                      => 'dhcpstate';
Readonly our $DB_TABLE_COE_MAC_EXCEPTION              => 'coe_mac_exception';
Readonly our $DB_TABLE_EVENTLOG                       => 'eventlog';
Readonly our $DB_TABLE_LOCATION                       => 'location';
Readonly our $DB_TABLE_LOOPCIDR2LOC                   => 'loopcidr2loc';
Readonly our $DB_TABLE_MAC                            => 'mac';
Readonly our $DB_TABLE_MAC2CLASS                      => 'mac2class';
Readonly our $DB_TABLE_MAGICPORT                      => 'magicport';
Readonly our $DB_TABLE_PORT2CLASS                     => 'port2class';
Readonly our $DB_TABLE_RADIUSAUDIT                    => 'radiusaudit';
Readonly our $DB_TABLE_SWITCH                         => 'switch';
Readonly our $DB_TABLE_SWITCH2VLAN                    => 'switch2vlan';
Readonly our $DB_TABLE_SWITCHPORT                     => 'switchport';
Readonly our $DB_TABLE_SWITCHPORTSTATE                => 'switchportstate';
Readonly our $DB_TABLE_TEMPLATE                       => 'template';
Readonly our $DB_TABLE_TEMPLATE2VLANGROUP             => 'template2vlangroup';
Readonly our $DB_TABLE_VLAN                           => 'vlan';
Readonly our $DB_TABLE_VLANGROUP                      => 'vlangroup';
Readonly our $DB_TABLE_VLANGROUP2VLAN                 => 'vlangroup2vlan';
Readonly our $DB_STATUS_TABLE_HOST                    => 'host';
Readonly our $DB_STATUS_TABLE_LOCATION                => 'location';
Readonly our $DB_STATUS_TABLE_MAC                     => 'mac';
Readonly our $DB_STATUS_TABLE_SWITCH                  => 'switch';
Readonly our $DB_STATUS_TABLE_SWITCHPORT              => 'switchport';
Readonly our $DB_STATUS_TABLE_SWITCHPORTSTATUS        => 'switchportstatus';
Readonly our $DB_KEY_CLASSID                          => 'classid';
Readonly our $DB_KEY_EVENTLOGID                       => 'eventlogid';
Readonly our $DB_KEY_LOCATIONID                       => 'locationid';
Readonly our $DB_KEY_LOCATIONSHORTNAME                => 'site';                                   # Kludge....
Readonly our $DB_KEY_LOCATIONNAME                     => 'locationname';                           # Kludge....
Readonly our $DB_KEY_LOOPCIDR2LOCID                   => 'loopcidr2locid';
Readonly our $DB_KEY_MACID                            => 'macid';
Readonly our $DB_KEY_MAC2CLASSID                      => 'mac2classid';
Readonly our $DB_KEY_MAGICPORTID                      => 'magicportid';
Readonly our $DB_KEY_PORT2CLASSID                     => 'port2classid';
Readonly our $DB_KEY_PORTSWITCHID                     => 'switchid';
Readonly our $DB_KEY_RADIUSAUDITID                    => 'radiusauditid';
Readonly our $DB_KEY_RADIUSAUDITMACID                 => 'macid';
Readonly our $DB_KEY_RADIUSAUDITSWITCHPORTID          => 'switchportid';
Readonly our $DB_KEY_RADIUSAUDITTIME                  => 'audittime';
Readonly our $DB_KEY_SWITCHID                         => 'switchid';
Readonly our $DB_KEY_SWITCHNAME                       => 'switchname';
Readonly our $DB_KEY_SWITCH2VLANID                    => 'switch2vlanid';
Readonly our $DB_KEY_SWITCHPORTID                     => 'switchportid';
Readonly our $DB_KEY_SWITCHPORTNAME                   => 'portname';
Readonly our $DB_KEY_SWITCHPORTSTATEID                => 'switchportid';
Readonly our $DB_KEY_SWITCHPORTSTATEMACID             => 'macid';
Readonly our $DB_KEY_SWITCHPORTSTATEVMACID            => 'vmacid';
Readonly our $DB_KEY_SWITCHPORTSTATECLASSID           => 'classid';
Readonly our $DB_KEY_SWITCHPORTSTATEVCLASSID          => 'vclassid';
Readonly our $DB_KEY_SWITCHPORTSTATEVLANGROUPID       => 'vlangroupid';
Readonly our $DB_KEY_SWITCHPORTSTATEVVLANGROUPID      => 'vvlangroupid';
Readonly our $DB_KEY_SWITCHPORTSTATEVLANID            => 'vlanid';
Readonly our $DB_KEY_SWITCHPORTSTATEVVLANID           => 'vvlanid';
Readonly our $DB_KEY_SWITCHPORTSTATEIP                => 'ip';
Readonly our $DB_KEY_SWITCHPORTSTATEVIP               => 'vip';
Readonly our $DB_KEY_TEMPLATEID                       => 'templateid';
Readonly our $DB_KEY_TEMPLATE2VLANGROUPID             => 'template2vlangroupid';
Readonly our $DB_KEY_VLANID                           => 'vlanid';
Readonly our $DB_KEY_VLANGROUPID                      => 'vlangroupid';
Readonly our $DB_KEY_VLANGROUP2VLANID                 => 'vlangroup2vlanid';
Readonly our $DB_COL_BUF_ADD_MAC_ID                   => 'ADD-MAC-BUF-ID';
Readonly our $DB_COL_BUF_ADD_MAC_MAC                  => 'ADD-MAC-BUF-MAC';
Readonly our $DB_COL_BUF_ADD_MAC_LASTSEEN             => 'ADD-MAC-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_ADD_RA_ID                    => 'ADD-RA-BUF-ID';
Readonly our $DB_COL_BUF_ADD_RA_MACID                 => 'ADD-RA-BUF-MACID';
Readonly our $DB_COL_BUF_ADD_RA_SWPID                 => 'ADD-RA-BUF-SWPID';
Readonly our $DB_COL_BUF_ADD_RA_TYPE                  => 'ADD-RA-BUF-TYPE';
Readonly our $DB_COL_BUF_ADD_RA_CAUSE                 => 'ADD-RA-BUF-CAUSE';
Readonly our $DB_COL_BUF_ADD_RA_OCTIN                 => 'ADD-RA-BUF-OCTETSIN';
Readonly our $DB_COL_BUF_ADD_RA_OCTOUT                => 'ADD-RA-BUF-OCTETSOUT';
Readonly our $DB_COL_BUF_ADD_RA_PACIN                 => 'ADD-RA-BUF-PACKETSIN';
Readonly our $DB_COL_BUF_ADD_RA_PACOUT                => 'ADD-RA-BUF-PACKETSOUT';
Readonly our $DB_COL_BUF_ADD_RA_AUDITTIME             => 'ADD-RA-BUF-AUDITTIME';
Readonly our $DB_COL_BUF_ADD_SWITCH_ID                => 'ADD-SWITCH-BUF-ID';
Readonly our $DB_COL_BUF_ADD_SWITCH_IP                => 'ADD-SWITCH-BUF-IP';
Readonly our $DB_COL_BUF_ADD_SWITCH_LASTSEEN          => 'ADD-SWITCH-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_ADD_SWITCHPORT_ID            => 'ADD-SWITCHPORT-BUF-ID';
Readonly our $DB_COL_BUF_ADD_SWITCHPORT_SWITCHID      => 'ADD-SWITCHPORT-BUF-SWITCHID';
Readonly our $DB_COL_BUF_ADD_SWITCHPORT_PORTNAME      => 'ADD-SWITCHPORT-BUF-PORTNAME';
Readonly our $DB_COL_BUF_ADD_SWITCHPORT_LASTSEEN      => 'ADD-SWITCHPORT-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_EVENTLOG_ID                  => 'EVENTLOG-BUF-ID';
Readonly our $DB_COL_BUF_EVENTLOG_TIME                => 'EVENTLOG-BUF-TIME';
Readonly our $DB_COL_BUF_EVENTLOG_TYPE                => 'EVENTLOG-BUF-TYPE';
Readonly our $DB_COL_BUF_EVENTLOG_CLASSID             => 'EVENTLOG-BUF-CLASSID';
Readonly our $DB_COL_BUF_EVENTLOG_LOCID               => 'EVENTLOG-BUF-LOCID';
Readonly our $DB_COL_BUF_EVENTLOG_MACID               => 'EVENTLOG-BUF-MACID';
Readonly our $DB_COL_BUF_EVENTLOG_M2CID               => 'EVENTLOG-BUF-M2CID';
Readonly our $DB_COL_BUF_EVENTLOG_P2CID               => 'EVENTLOG-BUF-P2CID';
Readonly our $DB_COL_BUF_EVENTLOG_SWID                => 'EVENTLOG-BUF-SWID';
Readonly our $DB_COL_BUF_EVENTLOG_SWPID               => 'EVENTLOG-BUF-SWPID';
Readonly our $DB_COL_BUF_EVENTLOG_SW2VID              => 'EVENTLOG-BUF-S2VID';
Readonly our $DB_COL_BUF_EVENTLOG_TEMPID              => 'EVENTLOG-BUF-TEMPID';
Readonly our $DB_COL_BUF_EVENTLOG_TEMP2VGID           => 'EVENTLOG-BUF-TEMP2VGID';
Readonly our $DB_COL_BUF_EVENTLOG_VGID                => 'EVENTLOG-BUF-VGID';
Readonly our $DB_COL_BUF_EVENTLOG_VG2VID              => 'EVENTLOG-BUF-VG2VID';
Readonly our $DB_COL_BUF_EVENTLOG_VLANID              => 'EVENTLOG-BUF-VLANID';
Readonly our $DB_COL_BUF_EVENTLOG_IP                  => 'EVENTLOG-BUF-IP';
Readonly our $DB_COL_BUF_EVENTLOG_DESC                => 'EVENTLOG-BUF-DESC';
Readonly our $DB_COL_BUF_LASTSEEN_LOCATION_ID         => 'LASTSEEN-LOCATION-BUF-ID';
Readonly our $DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN   => 'LASTSEEN-LOCATION-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_LASTSEEN_MAC_ID              => 'LASTSEEN-MAC-BUF-ID';
Readonly our $DB_COL_BUF_LASTSEEN_MAC_LASTSEEN        => 'LASTSEEN-MAC-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_LASTSEEN_SWITCH_ID           => 'LASTSEEN-SWITCH-BUF-ID';
Readonly our $DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN     => 'LASTSEEN-SWITCH-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_LASTSEEN_SWITCHPORT_ID       => 'LASTSEEN-SWITCHPORT-BUF-ID';
Readonly our $DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN => 'LASTSEEN-SWITCHPORT-BUF-LASTSEEN';
Readonly our $DB_COL_BUF_SWPS_SWPID                   => 'SWITCH-PORT-STATE-BUF-SWPID';
Readonly our $DB_COL_BUF_SWPS_LASTUPDATE              => 'SWITCH-PORT-STATE-BUF-LASTUPDATE';
Readonly our $DB_COL_BUF_SWPS_MACID                   => 'SWITCH-PORT-STATE-BUF-MACID';
Readonly our $DB_COL_BUF_SWPS_MAC                     => 'SWITCH-PORT-STATE-BUF-MAC';
Readonly our $DB_COL_BUF_SWPS_MACID_GT_ZERO           => 'SWITCH-PORT-STATE-BUF-MACID-GT-ZERO';
Readonly our $DB_COL_BUF_SWPS_CLASSID                 => 'SWITCH-PORT-STATE-BUF-CLASSID';
Readonly our $DB_COL_BUF_SWPS_VGID                    => 'SWITCH-PORT-STATE-BUF-VGID';
Readonly our $DB_COL_BUF_SWPS_VLANID                  => 'SWITCH-PORT-STATE-BUF-VLANID';
Readonly our $DB_COL_BUF_SWPS_TEMPID                  => 'SWITCH-PORT-STATE-BUF-TEMPID';
Readonly our $DB_COL_BUF_SWPS_VMACID                  => 'SWITCH-PORT-STATE-BUF-VMACID';
Readonly our $DB_COL_BUF_SWPS_VMAC                    => 'SWITCH-PORT-STATE-BUF-VMAC';
Readonly our $DB_COL_BUF_SWPS_VMACID_GT_ZERO          => 'SWITCH-PORT-STATE-BUF-VMACID-GT-ZERO';
Readonly our $DB_COL_BUF_SWPS_VCLASSID                => 'SWITCH-PORT-STATE-BUF-VCLASSID';
Readonly our $DB_COL_BUF_SWPS_VVGID                   => 'SWITCH-PORT-STATE-BUF-VVGID';
Readonly our $DB_COL_BUF_SWPS_VVLANID                 => 'SWITCH-PORT-STATE-BUF-VVLANID';
Readonly our $DB_COL_BUF_SWPS_VTEMPID                 => 'SWITCH-PORT-STATE-BUF-VTEMPID';
Readonly our $DB_COL_CLASS_ID                         => 'CLASS-ID';
Readonly our $DB_COL_CLASS_NAME                       => 'CLASS-NAME';
Readonly our $DB_COL_CLASS_PRI                        => 'CLASS-PRIORITY';
Readonly our $DB_COL_CLASS_REAUTH                     => 'CLASS-REAUTH';
Readonly our $DB_COL_CLASS_IDLE                       => 'CLASS-IDLE';
Readonly our $DB_COL_CLASS_VGID                       => 'CLASS-VLANGROUPID';
Readonly our $DB_COL_CLASS_ACT                        => 'CLASS-ACTIVE';
Readonly our $DB_COL_CLASS_LOCKED                     => 'CLASS-LOCKED';
Readonly our $DB_COL_CLASS_COM                        => 'CLASS-COMMENT';
Readonly our $DB_SORT_CLASS_ID                        => 'CLASS-SORT-ID';
Readonly our $DB_SORT_CLASS_NAME                      => 'CLASS-SORT-NAME';
Readonly our $DB_SORT_CLASS_PRI                       => 'CLASS-SORT-PRI';
Readonly our $DB_SORT_CLASS_ACT                       => 'CLASS-SORT-ACT';
Readonly our $DB_SORT_CLASS_LOCKED                    => 'CLASS-SORT-LOCKED';
Readonly our $DB_SORT_CLASS_VGID                      => 'CLASS-SORT-VGID';
Readonly our $DB_COL_EVENTLOG_ID                      => 'EVENTLOG-ID';
Readonly our $DB_COL_EVENTLOG_USERID                  => 'EVENTLOG-USERID';
Readonly our $DB_COL_EVENTLOG_TIME                    => 'EVENTLOG-TIME';
Readonly our $DB_COL_EVENTLOG_TIME_LT                 => 'EVENTLOG-TIME-LT';
Readonly our $DB_COL_EVENTLOG_TIME_GT                 => 'EVENTLOG-TIME-GT';
Readonly our $DB_COL_EVENTLOG_TYPE                    => 'EVENTLOG-TYPE';
Readonly our $DB_COL_EVENTLOG_HOST                    => 'EVENTLOG-HOST';
Readonly our $DB_COL_EVENTLOG_CLASSID                 => 'EVENTLOG-CLASSID';
Readonly our $DB_COL_EVENTLOG_LOCID                   => 'EVENTLOG-LOCID';
Readonly our $DB_COL_EVENTLOG_MACID                   => 'EVENTLOG-MACID';
Readonly our $DB_COL_EVENTLOG_M2CID                   => 'EVENTLOG-M2CID';
Readonly our $DB_COL_EVENTLOG_P2CID                   => 'EVENTLOG-P2CID';
Readonly our $DB_COL_EVENTLOG_SWID                    => 'EVENTLOG-SWID';
Readonly our $DB_COL_EVENTLOG_SWPID                   => 'EVENTLOG-SWPID';
Readonly our $DB_COL_EVENTLOG_SW2VID                  => 'EVENTLOG-S2VID';
Readonly our $DB_COL_EVENTLOG_TEMPID                  => 'EVENTLOG-TEMPID';
Readonly our $DB_COL_EVENTLOG_TEMP2VGID               => 'EVENTLOG-TEMP2VGID';
Readonly our $DB_COL_EVENTLOG_VGID                    => 'EVENTLOG-VGID';
Readonly our $DB_COL_EVENTLOG_VG2VID                  => 'EVENTLOG-VG2VID';
Readonly our $DB_COL_EVENTLOG_VLANID                  => 'EVENTLOG-VLANID';
Readonly our $DB_COL_EVENTLOG_IP                      => 'EVENTLOG-IP';
Readonly our $DB_COL_EVENTLOG_DESC                    => 'EVENTLOG-DESC';
Readonly our $DB_COL_CMP_COE                          => 'CLASS-MAC-PORT-COE';
Readonly our $DB_COL_CMP_VLAN                         => 'CLASS-MAC-PORT-VLAN';
Readonly our $DB_COL_CMP_VLANID                       => 'CLASS-MAC-PORT-VLAN-ID';
Readonly our $DB_COL_CMP_VLANNAME                     => 'CLASS-MAC-PORT-VLAN-NAME';
Readonly our $DB_COL_CMP_VLANTYPE                     => 'CLASS-MAC-PORT-VLAN-TYPE';
Readonly our $DB_COL_CMP_VGNAME                       => 'CLASS-MAC-PORT-VLANGROUP-NAME';
Readonly our $DB_COL_CMP_VGID                         => 'CLASS-MAC-PORT-VLANGROUP-ID';
Readonly our $DB_COL_CMP_TEMPNAME                     => 'CLASS-MAC-PORT-TEMPLATE-NAME';
Readonly our $DB_COL_CMP_TEMPID                       => 'CLASS-MAC-PORT-TEMPLATE-ID';
Readonly our $DB_COL_CMP_AUTHTYPE                     => 'CLASS-MAC-PORT-AUTHTYPE';
Readonly our $DB_COL_CMP_PRI                          => 'CLASS-MAC-PORT-PRI';
Readonly our $DB_COL_CMP_SUBPRI                       => 'CLASS-MAC-PORT-SUBPRI';
Readonly our $DB_COL_CMP_RANDPRI                      => 'CLASS-MAC-PORT-RANDPRI';
Readonly our $DB_COL_CMP_HASHPRI                      => 'CLASS-MAC-PORT-HASHPRI';
Readonly our $DB_COL_CMP_SWPID                        => 'CLASS-MAC-PORT-SWPID';
Readonly our $DB_COL_CMP_SWID                         => 'CLASS-MAC-PORT-SWID';
Readonly our $DB_COL_CMP_MACID                        => 'CLASS-MAC-PORT-MACID';
Readonly our $DB_COL_CMP_RECID                        => 'CLASS-MAC-PORT-RECID';
Readonly our $DB_COL_CMP_CLASSID                      => 'CLASS-MAC-PORT-CLASSID';
Readonly our $DB_COL_CMP_CLASSNAME                    => 'CLASS-MAC-PORT-CLASS-NAME';
Readonly our $DB_COL_CMP_COM                          => 'CLASS-MAC-PORT-COMMENT';
Readonly our $DB_COL_CMP_LOCKED                       => 'CLASS-MAC-PORT-LOCKED';
Readonly our $DB_COL_CMP_LOCID                        => 'CLASS-MAC-PORT-LOCID';
Readonly our $DB_COL_CMP_REAUTH                       => 'CLASS-MAC-PORT-REAUTH';
Readonly our $DB_COL_CMP_IDLE                         => 'CLASS-MAC-PORT-IDLE';
Readonly our $DB_COL_DME_MACID                        => 'COE-MAC-EXCEPTION-MACID';
Readonly our $DB_COL_DME_TICKETREF                    => 'COE-MAC-EXCEPTION-TICKETREF';
Readonly our $DB_COL_DME_CREATED                      => 'COE-MAC-EXCEPTION-CREATED';
Readonly our $DB_COL_DME_COMMENT                      => 'COE-MAC-EXCEPTION-COMMENT';
Readonly our $DB_COL_DHCPS_MACID                      => 'DHCP-STATE-MACID';
Readonly our $DB_COL_DHCPS_LASTUPDATE                 => 'DHCP-STATE-LASTUPDATE';
Readonly our $DB_COL_DHCPS_STATE                      => 'DHCP-STATE-STATE';
Readonly our $DB_COL_DHCPS_IP                         => 'DHCP-STATE-IP';
Readonly our $DB_COL_LOC_ID                           => 'LOCATION-ID';
Readonly our $DB_COL_LOC_SITE                         => 'LOCATION-SITE';
Readonly our $DB_COL_LOC_BLDG                         => 'LOCATION-BLDG';
Readonly our $DB_COL_LOC_NAME                         => 'LOCATION-NAME';
Readonly our $DB_COL_LOC_DESC                         => 'LOCATION-DESC';
Readonly our $DB_COL_LOC_ACT                          => 'LOCATION-ACTIVE';
Readonly our $DB_COL_LOC_COM                          => 'LOCATION-COMMENT';
Readonly our $DB_COL_LOC_SHORTNAME                    => 'LOCATION-SHORTNAME';
Readonly our $DB_COL_LOOP_ID                          => 'LOOPCIDR2LOCID-ID';
Readonly our $DB_COL_LOOP_CIDR                        => 'LOOPCIDR2LOCID-CIDR';
Readonly our $DB_COL_LOOP_LOCID                       => 'LOOPCIDR2LOCID-LOCID';
Readonly our $DB_COL_MAC_ID                           => 'MAC-ID';
Readonly our $DB_COL_MAC_MAC                          => 'MAC-MAC';
Readonly our $DB_COL_MAC_FS                           => 'MAC-FIRSTSEEN';
Readonly our $DB_COL_MAC_LS                           => 'MAC-LASTSEEN';
Readonly our $DB_COL_MAC_LSC                          => 'MAC-LASTSTATECHANGE';
Readonly our $DB_COL_MAC_DESC                         => 'MAC-DESC';
Readonly our $DB_COL_MAC_AT                           => 'MAC-ASSET-TAG';
Readonly our $DB_COL_MAC_ACT                          => 'MAC-ACTIVE';
Readonly our $DB_COL_MAC_COE                          => 'MAC-COE';
Readonly our $DB_COL_MAC_LOCKED                       => 'MAC-LOCKED';
Readonly our $DB_COL_MAC_COM                          => 'MAC-COMMENT';
Readonly our $DB_SORT_MAC_ID                          => 'MAC-SORT-ID';
Readonly our $DB_SORT_MAC_MAC                         => 'MAC-SORT-MAC';
Readonly our $DB_COL_MAGIC_ID                         => 'MAGIC-ID';
Readonly our $DB_COL_MAGIC_SWPID                      => 'MAGIC-SWITCHPORTID';
Readonly our $DB_COL_MAGIC_CLASSID                    => 'MAGIC-CLASSID';
Readonly our $DB_COL_MAGIC_VLANID                     => 'MAGIC-VLANID';
Readonly our $DB_COL_MAGIC_VGID                       => 'MAGIC-VLANGROUPID';
Readonly our $DB_COL_MAGIC_TEMPID                     => 'MAGIC-TEMPLATEID';
Readonly our $DB_COL_MAGIC_PRI                        => 'MAGIC-PRIORITY';
Readonly our $DB_COL_MAGIC_COM                        => 'MAGIC-COMMENT';
Readonly our $DB_COL_MAGIC_TYPE                       => 'MAGIC-TYPE';
Readonly our $DB_COL_M2C_CLASSID                      => 'MAC2CLASS-CLASSID';
Readonly our $DB_COL_M2C_ID                           => 'MAC2CLASS-ID';
Readonly our $DB_COL_M2C_MACID                        => 'MAC2CLASS-MACID';
Readonly our $DB_COL_M2C_PRI                          => 'MAC2CLASS-PRI';
Readonly our $DB_COL_M2C_VLANID                       => 'MAC2CLASS-VLANID';
Readonly our $DB_COL_M2C_VGID                         => 'MAC2CLASS-VGID';
Readonly our $DB_COL_M2C_TEMPID                       => 'MAC2CLASS-TEMPID';
Readonly our $DB_COL_M2C_EXPIRE                       => 'MAC2CLASS-EXPIRE';
Readonly our $DB_COL_M2C_LOCKED                       => 'MAC2CLASS-LOCKED';
Readonly our $DB_COL_M2C_ACT                          => 'MAC2CLASS-COMMENT';
Readonly our $DB_COL_M2C_COM                          => 'MAC2CLASS-COMMENT';
Readonly our $DB_M2C_IN_HASH_REF                      => 'MAC2CLASS-IN-HASH-REF';
Readonly our $DB_M2C_REMOVE_FLAG                      => 'MAC2CLASS-REMOVE-FLAG';
Readonly our $DB_M2C_UPDATE_FLAG                      => 'MAC2CLASS-UPDATE-FLAG';
Readonly our $DB_SORT_M2C_ID                          => 'MAC2CLASS-SORT-ID';
Readonly our $DB_COL_P2C_ID                           => 'PORT2CLASS-ID';
Readonly our $DB_COL_P2C_SWPID                        => 'PORT2CLASS-SWITCHPORTID';
Readonly our $DB_COL_P2C_CLASSID                      => 'PORT2CLASS-CLASSID';
Readonly our $DB_COL_P2C_VLANID                       => 'PORT2CLASS-VLANID';
Readonly our $DB_COL_P2C_VGID                         => 'PORT2CLASS-VGID';
Readonly our $DB_COL_P2C_LOCKED                       => 'PORT2CLASS-LOCKED';
Readonly our $DB_COL_P2C_COM                          => 'PORT2CLASS-COMMENT';
Readonly our $DB_COL_P2C_PRI                          => 'PORT2CLASS-PRIORITY';
Readonly our $DB_COL_RA_ID                            => 'RADIUSAUDIT-ID';
Readonly our $DB_COL_RA_MACID                         => 'RADIUSAUDIT-MACID';
Readonly our $DB_COL_RA_SWPID                         => 'RADIUSAUDIT-SWITCHPORTID';
Readonly our $DB_COL_RA_AUDIT_TIME                    => 'RADIUSAUDIT-AUDITTIME';
Readonly our $DB_COL_RA_AUDIT_TIME_LT                 => 'RADIUSAUDIT-AUDITTIME-LT';
Readonly our $DB_COL_RA_AUDIT_TIME_GT                 => 'RADIUSAUDIT-AUDITTIME-GT';
Readonly our $DB_COL_RA_AUDIT_SRV                     => 'RADIUSAUDIT-AUDITSERVER';
Readonly our $DB_COL_RA_TYPE                          => 'RADIUS-TYPE';
Readonly our $DB_COL_RA_CAUSE                         => 'RADIUS-CAUSE';
Readonly our $DB_COL_RA_OCTIN                         => 'RADIUS-OCTIN';
Readonly our $DB_COL_RA_OCTOUT                        => 'RADIUS-OCTOUT';
Readonly our $DB_COL_RA_PACIN                         => 'RADIUS-PACKETSIN';
Readonly our $DB_COL_RA_PACOUT                        => 'RADIUS-PACKETSOUT';
Readonly our $DB_COL_SW_ID                            => 'SWITCH-ID';
Readonly our $DB_COL_SW_NAME                          => 'SWITCH-NAME';
Readonly our $DB_COL_SW_LOCID                         => 'SWITCH-LOCID';
Readonly our $DB_COL_SW_DESC                          => 'SWITCH-DESC';
Readonly our $DB_COL_SW_IP                            => 'SWITCH-IP';
Readonly our $DB_COL_SW_COM                           => 'SWITCH-COMMENT';
Readonly our $DB_COL_SW_LS                            => 'SWITCH-LASTSEEN';
Readonly our $DB_COL_SWP_ID                           => 'SWITCH-PORT-ID';
Readonly our $DB_COL_SWP_SWID                         => 'SWITCH-PORT-SWITCHID';
Readonly our $DB_COL_SWP_NAME                         => 'SWITCH-PORT-PORTNAME';
Readonly our $DB_COL_SWP_IFINDEX                      => 'SWITCH-PORT-IFINDEX';
Readonly our $DB_COL_SWP_DESC                         => 'SWITCH-PORT-DESC';
Readonly our $DB_COL_SWP_COM                          => 'SWITCH-PORT-COMMENT';
Readonly our $DB_COL_SWP_LS                           => 'SWITCH-PORT-LASTSEEN';
Readonly our $DB_COL_SW2V_ID                          => 'SWITCH2VLAN-ID';
Readonly our $DB_COL_SW2V_SWID                        => 'SWITCH2VLAN-SWITCHID';
Readonly our $DB_COL_SW2V_VLANID                      => 'SWITCH2VLAN-VLANID';
Readonly our $DB_COL_SWPS_SWPID                       => 'SWITCH-PORT-STATE-SWPID';
Readonly our $DB_COL_SWPS_LASTUPDATE                  => 'SWITCH-PORT-STATE-LASTUPDATE';
Readonly our $DB_COL_SWPS_STATEUPDATE                 => 'SWITCH-PORT-STATE-STATUPDATE';
Readonly our $DB_COL_SWPS_HOSTNAME                    => 'SWITCH-PORT-STATE-HOSTNAME';
Readonly our $DB_COL_SWPS_MACID                       => 'SWITCH-PORT-STATE-MACID';
Readonly our $DB_COL_SWPS_IP                          => 'SWITCH-PORT-STATE-IP';
Readonly our $DB_COL_SWPS_MACID_GT_ZERO               => 'SWITCH-PORT-STATE-MACID-GT-ZERO';
Readonly our $DB_COL_SWPS_CLASSID                     => 'SWITCH-PORT-STATE-CLASSID';
Readonly our $DB_COL_SWPS_VGID                        => 'SWITCH-PORT-STATE-VGID';
Readonly our $DB_COL_SWPS_VLANID                      => 'SWITCH-PORT-STATE-VLANID';
Readonly our $DB_COL_SWPS_TEMPID                      => 'SWITCH-PORT-STATE-TEMPID';
Readonly our $DB_COL_SWPS_VHOSTNAME                   => 'SWITCH-PORT-STATE-VHOSTNAME';
Readonly our $DB_COL_SWPS_VMACID                      => 'SWITCH-PORT-STATE-VMACID';
Readonly our $DB_COL_SWPS_VIP                         => 'SWITCH-PORT-STATE-IP';
Readonly our $DB_COL_SWPS_VMACID_GT_ZERO              => 'SWITCH-PORT-STATE-VMACID-GT-ZERO';
Readonly our $DB_COL_SWPS_VCLASSID                    => 'SWITCH-PORT-STATE-VCLASSID';
Readonly our $DB_COL_SWPS_VVGID                       => 'SWITCH-PORT-STATE-VVGID';
Readonly our $DB_COL_SWPS_VVLANID                     => 'SWITCH-PORT-STATE-VVLANID';
Readonly our $DB_COL_SWPS_VTEMPID                     => 'SWITCH-PORT-STATE-VTEMPID';
Readonly our $DB_COL_TEMP2VG_ID                       => 'TEMPLATE2VLANGROUP-ID';
Readonly our $DB_COL_TEMP2VG_TEMPID                   => 'TEMPLATE2VLANGROUP-TEMPLATEID';
Readonly our $DB_COL_TEMP2VG_VGID                     => 'TEMPLATE2VLANGROUP-VLANGROUPID';
Readonly our $DB_COL_TEMP2VG_PRI                      => 'TEMPLATE2VLANGROUP-PRIORITY';
Readonly our $DB_COL_TEMP_ID                          => 'TEMPLATE-ID';
Readonly our $DB_COL_TEMP_NAME                        => 'TEMPLATE-NAME';
Readonly our $DB_COL_TEMP_DESC                        => 'TEMPLATE-DESCRIPTION';
Readonly our $DB_COL_TEMP_ACT                         => 'TEMPLATE-ACTIVE';
Readonly our $DB_COL_TEMP_COM                         => 'TEMPLATE-COMMENT';
Readonly our $DB_SORT_TEMP_ID                         => 'TEMPLATE-SORT-ID';
Readonly our $DB_SORT_TEMP_NAME                       => 'TEMPLATE-SORT-NAME';
Readonly our $DB_SORT_TEMP_ACT                        => 'TEMPLATE-SORT-ACT';
Readonly our $DB_SORT_TEMP_PRI                        => 'TEMPLATE-SORT_PRIORITY';
Readonly our $DB_COL_VG_ID                            => 'VLANGROUP-ID';
Readonly our $DB_COL_VG_NAME                          => 'VLANGROUP-NAME';
Readonly our $DB_COL_VG_DESC                          => 'VLANGROUP-DESCRIPTION';
Readonly our $DB_COL_VG_ACT                           => 'VLANGROUP-ACTIVE';
Readonly our $DB_COL_VG_COM                           => 'VLANGROUP-COMMENT';
Readonly our $DB_SORT_VG_ID                           => 'VLANGROUP-SORT-ID';
Readonly our $DB_SORT_VG_NAME                         => 'VLANGROUP-SORT-NAME';
Readonly our $DB_SORT_VG_ACT                          => 'VLANGROUP-SORT-ACT';
Readonly our $DB_SORT_VG_PRI                          => 'VLANGROUP-SORT_PRIORITY';
Readonly our $DB_COL_VG2V_ID                          => 'VLANGROUP2VLAN-ID';
Readonly our $DB_COL_VG2V_VGID                        => 'VLANGROUP2VLAN-VLANGROUPID';
Readonly our $DB_COL_VG2V_VLANID                      => 'VLANGROUP2VLAN-VLANID';
Readonly our $DB_COL_VG2V_PRI                         => 'VLANGROUP2VLAN-PRIORITY';
Readonly our $DB_COL_VLAN_ID                          => 'VLAN-ID';
Readonly our $DB_COL_VLAN_LOCID                       => 'VLAN-LOCID';
Readonly our $DB_COL_VLAN_VLAN                        => 'VLAN-VLAN';
Readonly our $DB_COL_VLAN_TYPE                        => 'VLAN-TYPE';
Readonly our $DB_COL_VLAN_CIDR                        => 'VLAN-CIDR';
Readonly our $DB_COL_VLAN_NACIP                       => 'VLAN-NACIP';
Readonly our $DB_COL_VLAN_NAME                        => 'VLAN-NAME';
Readonly our $DB_COL_VLAN_DESC                        => 'VLAN-DESC';
Readonly our $DB_COL_VLAN_ACT                         => 'VLAN-ACTIVE';
Readonly our $DB_COL_VLAN_COE                         => 'VLAN-COE';
Readonly our $DB_COL_VLAN_COM                         => 'VLAN-COMMENT';
Readonly our $DB_COL_VLAN2SWP_VLANID                  => 'VLAN2SWP-VLANID';
Readonly our $DB_COL_VLAN2SWP_SWPID                   => 'VLAN2SWP-SWPID';
Readonly our $DB_COL_VLAN2SWP_VLAN                    => 'VLAN2SWP-VLAN';
Readonly our $DB_COL_VLAN2SWP_NAME                    => 'VLAN2SWP-NAME';
Readonly our $DB_COL_VG2SWP_VGID                      => 'VG2SWP-VGID';
Readonly our $DB_COL_VG2SWP_SWPID                     => 'VG2SWP-SWPID';
Readonly our $DB_COL_VG2SWP_VLAN                      => 'VG2SWP-VLAN';
Readonly our $DB_COL_VG2SWP_NAME                      => 'VG2SWP-NAME';
Readonly our $DB_COL_VG2SWP_VGNAME                    => 'VG2SWP-VGNAME';
Readonly our $DB_COL_STATUS_HOST_HOSTNAME             => 'HOST-HOSTNAME';
Readonly our $DB_COL_STATUS_HOST_LASTSEEN             => 'HOST-LASTSEEN';
Readonly our $DB_COL_STATUS_HOST_SLAVECHECKIN         => 'HOST-SLAVECHECKIN';
Readonly our $DB_COL_STATUS_HOST_SLAVESTATUS          => 'HOST-SLAVESTATUS';
Readonly our $DB_COL_STATUS_LOCATION_LOCATIONID       => 'LOCATION-LOCATIOID';
Readonly our $DB_COL_STATUS_LOCATION_SITE             => 'LOCATION-SITE';
Readonly our $DB_COL_STATUS_LOCATION_BLDG             => 'LOCATION-BLDG';
Readonly our $DB_COL_STATUS_LOCATION_LASTSEEN         => 'LOCATION-LASTSEEN';
Readonly our $DB_COL_STATUS_LOCATION_HOSTNAME         => 'LOCATION-HOSTNAME';
Readonly our $DB_COL_STATUS_MAC_MACID                 => 'STATUS-MAC-MACID';
Readonly our $DB_COL_STATUS_MAC_MAC                   => 'STATUS-MAC-MAC';
Readonly our $DB_COL_STATUS_MAC_LASTSEEN              => 'STATUS-MAC-LASTSEEN';
Readonly our $DB_COL_STATUS_MAC_HOSTNAME              => 'STATUS-MAC-HOSTNAME';
Readonly our $DB_COL_STATUS_SWITCH_SWITCHID           => 'STATUS-SWITCH-SWITCHID';
Readonly our $DB_COL_STATUS_SWITCH_SWITCHNAME         => 'STATUS-SWITCH-SWITCHNAME';
Readonly our $DB_COL_STATUS_SWITCH_LOCATIONID         => 'STATUS-SWITCH-LOCATIONID';
Readonly our $DB_COL_STATUS_SWITCH_LASTSEEN           => 'STATUS-SWITCH-LASTSEEN';
Readonly our $DB_COL_STATUS_SWITCH_HOSTNAME           => 'STATUS-SWITCH-HOSTNAME';
Readonly our $DB_COL_STATUS_SWITCHPORT_SWITCHPORTID   => 'STATUS-SWITCHPORT-SWITCHPORTID';
Readonly our $DB_COL_STATUS_SWITCHPORT_LASTSEEN       => 'STATUS-SWITCHPORT-LASTSEEN';
Readonly our $DB_COL_STATUS_SWITCHPORT_HOSTNAME       => 'STATUS-SWITCHPORT-HOSTNAME';
Readonly our $DB_COL_STATUS_SWITCHPORT_LASTUPDATED    => 'STATUS-SWITCHPORT-LASTUPDATED';
Readonly our $DB_COL_STATUS_SWITCHPORT_LOCID          => 'STATUS-SWITCHPORT-LOCID';
Readonly our $DB_COL_STATUS_SWITCHPORT_SITE           => 'STATUS-SWITCHPORT-SITE';
Readonly our $DB_COL_STATUS_SWITCHPORT_BLDG           => 'STATUS-SWITCHPORT-BLDG';
Readonly our $DB_COL_STATUS_SWITCHPORT_SWITCHID       => 'STATUS-SWITCHPORT-SWITCHID';
Readonly our $DB_COL_STATUS_SWITCHPORT_SWITCHNAME     => 'STATUS-SWITCHPORT-SWITCHNAME';
Readonly our $DB_COL_STATUS_SWITCHPORT_PORTNAME       => 'STATUS-SWITCHPORT-PORTNAME';
Readonly our $DB_COL_STATUS_SWITCHPORT_IFINDEX        => 'STATUS-SWITCHPORT-IFINDEX';
Readonly our $DB_COL_STATUS_SWITCHPORT_DESCRIPTION    => 'STATUS-SWITCHPORT-DESCRIPTION';
Readonly our $DB_COL_STATUS_SWITCHPORT_OPERSTATUS     => 'STATUS-SWITCHPORT-OPERSTATUS';
Readonly our $DB_COL_STATUS_SWITCHPORT_ADMINSTATUS    => 'STATUS-SWITCHPORT-ADMINSTATUS';
Readonly our $DB_COL_STATUS_SWITCHPORT_MABENABLED     => 'STATUS-SWITCHPORT-MABENABLED';
Readonly our $DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD  => 'STATUS-SWITCHPORT-MABAUTHMETHOD';
Readonly our $DB_COL_STATUS_SWITCHPORT_MABSTATE       => 'STATUS-SWITCHPORT-MABSTATE';
Readonly our $DB_COL_STATUS_SWITCHPORT_MABAUTH        => 'STATUS-SWITCHPORT-MABAUTH';

Readonly our $SLAVE_STATE_UNKNOWN => 'UNKNOWN';
Readonly our $SLAVE_STATE_OK      => 'OK';
Readonly our $SLAVE_STATE_OFFLINE => 'OFFLINE';
Readonly our $SLAVE_STATE_DELAYED => 'DELAYED';

# Readonly our $DB_STARTTIME => 'DB-STARTTIME';
# Readonly our $DB_ENDTIME   => 'DB-ENDTIME';

Readonly our $DB_TABLE_NAME => 'DB-TABLE-NAME';
Readonly our $DB_KEY_NAME   => 'DB-KEY-NAME';
Readonly our $DB_KEY_VALUE  => 'DB-KEY-VALUE';

Readonly our %column_names => (
    $DB_COL_BUF_ADD_MAC_ID                   => 'id',
    $DB_COL_BUF_ADD_MAC_MAC                  => 'mac',
    $DB_COL_BUF_ADD_MAC_LASTSEEN             => 'lastseen',
    $DB_COL_BUF_ADD_SWITCH_ID                => 'id',
    $DB_COL_BUF_ADD_SWITCH_IP                => 'ip',
    $DB_COL_BUF_ADD_SWITCH_LASTSEEN          => 'lastseen',
    $DB_COL_BUF_ADD_RA_ID                    => 'id',
    $DB_COL_BUF_ADD_RA_MACID                 => 'macid',
    $DB_COL_BUF_ADD_RA_SWPID                 => 'swpid',
    $DB_COL_BUF_ADD_RA_TYPE                  => 'type',
    $DB_COL_BUF_ADD_RA_CAUSE                 => 'cause',
    $DB_COL_BUF_ADD_RA_OCTIN                 => 'octetsin',
    $DB_COL_BUF_ADD_RA_OCTOUT                => 'octetsout',
    $DB_COL_BUF_ADD_RA_PACIN                 => 'packetsin',
    $DB_COL_BUF_ADD_RA_PACOUT                => 'packetsout',
    $DB_COL_BUF_ADD_RA_AUDITTIME             => 'audittime',
    $DB_COL_BUF_ADD_SWITCHPORT_ID            => 'id',
    $DB_COL_BUF_ADD_SWITCHPORT_SWITCHID      => 'switchid',
    $DB_COL_BUF_ADD_SWITCHPORT_PORTNAME      => 'portname',
    $DB_COL_BUF_ADD_SWITCHPORT_LASTSEEN      => 'lastseen',
    $DB_COL_BUF_EVENTLOG_ID                  => 'eventlogid',
    $DB_COL_BUF_EVENTLOG_TIME                => 'eventtime',
    $DB_COL_BUF_EVENTLOG_TYPE                => 'eventtype',
    $DB_COL_BUF_EVENTLOG_CLASSID             => 'classid',
    $DB_COL_BUF_EVENTLOG_LOCID               => 'locationid',
    $DB_COL_BUF_EVENTLOG_MACID               => 'macid',
    $DB_COL_BUF_EVENTLOG_M2CID               => 'mac2classid',
    $DB_COL_BUF_EVENTLOG_P2CID               => 'port2classid',
    $DB_COL_BUF_EVENTLOG_SWID                => 'switchid',
    $DB_COL_BUF_EVENTLOG_SWPID               => 'switchportid',
    $DB_COL_BUF_EVENTLOG_SW2VID              => 'switch2vlanid',
    $DB_COL_BUF_EVENTLOG_TEMPID              => 'templateid',
    $DB_COL_BUF_EVENTLOG_TEMP2VGID           => 'template2vlangroupid',
    $DB_COL_BUF_EVENTLOG_VGID                => 'vlangroupid',
    $DB_COL_BUF_EVENTLOG_VG2VID              => 'vlangroup2vlanid',
    $DB_COL_BUF_EVENTLOG_VLANID              => 'vlanid',
    $DB_COL_BUF_EVENTLOG_IP                  => 'ip',
    $DB_COL_BUF_EVENTLOG_DESC                => 'eventtext',
    $DB_COL_BUF_LASTSEEN_LOCATION_ID         => 'locid',
    $DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN   => 'lastseen',
    $DB_COL_BUF_LASTSEEN_MAC_ID              => 'macid',
    $DB_COL_BUF_LASTSEEN_MAC_LASTSEEN        => 'lastseen',
    $DB_COL_BUF_LASTSEEN_SWITCH_ID           => 'switchid',
    $DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN     => 'lastseen',
    $DB_COL_BUF_LASTSEEN_SWITCHPORT_ID       => 'switchportid',
    $DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN => 'lastseen',
    $DB_COL_BUF_SWPS_SWPID                   => 'switchportid',
    $DB_COL_BUF_SWPS_LASTUPDATE              => 'lastupdate',
    $DB_COL_BUF_SWPS_MACID                   => 'macid',
    $DB_COL_BUF_SWPS_MAC                     => 'mac',
    $DB_COL_BUF_SWPS_CLASSID                 => 'classid',
    $DB_COL_BUF_SWPS_TEMPID                  => 'templateid',
    $DB_COL_BUF_SWPS_VGID                    => 'vlangroupid',
    $DB_COL_BUF_SWPS_VLANID                  => 'vlanid',
    $DB_COL_BUF_SWPS_VMACID                  => 'vmacid',
    $DB_COL_BUF_SWPS_VMAC                    => 'vmac',
    $DB_COL_BUF_SWPS_VCLASSID                => 'vclassid',
    $DB_COL_BUF_SWPS_VTEMPID                 => 'vtemplateid',
    $DB_COL_BUF_SWPS_VVGID                   => 'vvlangroupid',
    $DB_COL_BUF_SWPS_VVLANID                 => 'vvlanid',
    $DB_COL_CLASS_ID                         => 'classid',
    $DB_COL_CLASS_NAME                       => 'name',
    $DB_COL_CLASS_PRI                        => 'priority',
    $DB_COL_CLASS_REAUTH                     => 'reauthtime',
    $DB_COL_CLASS_IDLE                       => 'idletimeout',
    $DB_COL_CLASS_VGID                       => 'vlangroupid',
    $DB_COL_CLASS_ACT                        => 'active',
    $DB_COL_CLASS_LOCKED                     => 'locked',
    $DB_COL_CLASS_COM                        => 'comment',
    $DB_COL_CMP_COE                          => 'coe',
    $DB_COL_CMP_VLAN                         => 'vlan',
    $DB_COL_CMP_VLANID                       => 'vlanid',
    $DB_COL_CMP_VLANNAME                     => 'vlanname',
    $DB_COL_CMP_VLANTYPE                     => 'vlantype',
    $DB_COL_CMP_VGNAME                       => 'vlangroupname',
    $DB_COL_CMP_VGID                         => 'vlangroupid',
    $DB_COL_CMP_TEMPNAME                     => 'templatename',
    $DB_COL_CMP_TEMPID                       => 'templateid',
    $DB_COL_CMP_AUTHTYPE                     => 'authtype',
    $DB_COL_CMP_PRI                          => 'priority',
    $DB_COL_CMP_SUBPRI                       => 'subprio',
    $DB_COL_CMP_RANDPRI                      => 'randprio',
    $DB_COL_CMP_HASHPRI                      => 'hashprio',
    $DB_COL_CMP_SWPID                        => 'switchportid',
    $DB_COL_CMP_SWID                         => 'switchid',
    $DB_COL_CMP_MACID                        => 'macid',
    $DB_COL_CMP_RECID                        => 'recordid',
    $DB_COL_CMP_CLASSID                      => 'classid',
    $DB_COL_CMP_CLASSNAME                    => 'classname',
    $DB_COL_CMP_COM                          => 'comment',
    $DB_COL_CMP_LOCKED                       => 'locked',
    $DB_COL_CMP_LOCID                        => 'locid',
    $DB_COL_CMP_REAUTH                       => 'reauthtime',
    $DB_COL_CMP_IDLE                         => 'idletimeout',
    $DB_COL_DHCPS_MACID                      => 'macid',
    $DB_COL_DHCPS_LASTUPDATE                 => 'lastupdate',
    $DB_COL_DHCPS_STATE                      => 'state',
    $DB_COL_DHCPS_IP                         => 'ip',
    $DB_COL_EVENTLOG_ID                      => 'eventlogid',
    $DB_COL_EVENTLOG_USERID                  => 'userid',
    $DB_COL_EVENTLOG_TIME                    => 'eventtime',
    $DB_COL_EVENTLOG_TYPE                    => 'eventtype',
    $DB_COL_EVENTLOG_HOST                    => 'hostname',
    $DB_COL_EVENTLOG_CLASSID                 => 'classid',
    $DB_COL_EVENTLOG_LOCID                   => 'locationid',
    $DB_COL_EVENTLOG_MACID                   => 'macid',
    $DB_COL_EVENTLOG_M2CID                   => 'mac2classid',
    $DB_COL_EVENTLOG_P2CID                   => 'port2classid',
    $DB_COL_EVENTLOG_SWID                    => 'switchid',
    $DB_COL_EVENTLOG_SWPID                   => 'switchportid',
    $DB_COL_EVENTLOG_SW2VID                  => 'switch2vlanid',
    $DB_COL_EVENTLOG_TEMPID                  => 'templateid',
    $DB_COL_EVENTLOG_TEMP2VGID               => 'template2vlangroupid',
    $DB_COL_EVENTLOG_VGID                    => 'vlangroupid',
    $DB_COL_EVENTLOG_VG2VID                  => 'vlangroup2vlanid',
    $DB_COL_EVENTLOG_VLANID                  => 'vlanid',
    $DB_COL_EVENTLOG_IP                      => 'ip',
    $DB_COL_EVENTLOG_DESC                    => 'eventtext',
    $DB_COL_LOC_ID                           => 'locationid',
    $DB_COL_LOC_SITE                         => 'site',
    $DB_COL_LOC_BLDG                         => 'bldg',
    $DB_COL_LOC_NAME                         => 'locationname',
    $DB_COL_LOC_DESC                         => 'locationdescription',
    $DB_COL_LOC_ACT                          => 'active',
    $DB_COL_LOC_COM                          => 'comment',
    $DB_COL_LOC_SHORTNAME                    => 'shortname',
    $DB_COL_LOOP_ID                          => 'loopcidr2locid',
    $DB_COL_LOOP_CIDR                        => 'cidr',
    $DB_COL_LOOP_LOCID                       => 'locid',
    $DB_COL_MAC_ID                           => 'macid',
    $DB_COL_MAC_MAC                          => 'mac',
    $DB_COL_MAC_FS                           => 'firstseen',
    $DB_COL_MAC_LS                           => 'lastseen',
    $DB_COL_MAC_LSC                          => 'laststatechange',
    $DB_COL_MAC_DESC                         => 'description',
    $DB_COL_MAC_AT                           => 'assettag',
    $DB_COL_MAC_ACT                          => 'active',
    $DB_COL_MAC_COE                          => 'coe',
    $DB_COL_MAC_LOCKED                       => 'locked',
    $DB_COL_MAC_COM                          => 'comment',
    $DB_COL_MAGIC_ID                         => 'magicportid',
    $DB_COL_MAGIC_SWPID                      => 'switchportid',
    $DB_COL_MAGIC_CLASSID                    => 'classid',
    $DB_COL_MAGIC_VLANID                     => 'vlanid',
    $DB_COL_MAGIC_VGID                       => 'vlangroupid',
    $DB_COL_MAGIC_TEMPID                     => 'templateid',
    $DB_COL_MAGIC_PRI                        => 'priority',
    $DB_COL_MAGIC_COM                        => 'comment',
    $DB_COL_MAGIC_TYPE                       => 'magicporttype',
    $DB_COL_M2C_CLASSID                      => 'classid',
    $DB_COL_M2C_ID                           => 'mac2classid',
    $DB_COL_M2C_MACID                        => 'macid',
    $DB_COL_M2C_PRI                          => 'priority',
    $DB_COL_M2C_VLANID                       => 'vlanid',
    $DB_COL_M2C_VGID                         => 'vlangroupid',
    $DB_COL_M2C_TEMPID                       => 'templateid',
    $DB_COL_M2C_EXPIRE                       => 'expiretime',
    $DB_COL_M2C_LOCKED                       => 'locked',
    $DB_COL_M2C_ACT                          => 'active',
    $DB_COL_M2C_COM                          => 'comment',
    $DB_COL_P2C_ID                           => 'port2classid',
    $DB_COL_P2C_SWPID                        => 'switchportid',
    $DB_COL_P2C_CLASSID                      => 'classid',
    $DB_COL_P2C_VLANID                       => 'vlanid',
    $DB_COL_P2C_VGID                         => 'vlangroupid',
    $DB_COL_P2C_LOCKED                       => 'locked',
    $DB_COL_P2C_COM                          => 'comment',
    $DB_COL_P2C_PRI                          => 'priority',
    $DB_COL_RA_ID                            => 'radiusauditid',
    $DB_COL_RA_MACID                         => 'macid',
    $DB_COL_RA_SWPID                         => 'switchportid',
    $DB_COL_RA_AUDIT_TIME                    => 'audittime',
    $DB_COL_RA_TYPE                          => 'type',
    $DB_COL_RA_CAUSE                         => 'cause',
    $DB_COL_RA_OCTIN                         => 'octetsin',
    $DB_COL_RA_OCTOUT                        => 'octetsout',
    $DB_COL_RA_PACIN                         => 'packetsin',
    $DB_COL_RA_PACOUT                        => 'packetsout',
    $DB_COL_SW_ID                            => 'switchid',
    $DB_COL_SW_NAME                          => 'switchname',
    $DB_COL_SW_LOCID                         => 'locationid',
    $DB_COL_SW_DESC                          => 'portdescription',
    $DB_COL_SW_IP                            => 'ip',
    $DB_COL_SW_COM                           => 'comment',
    $DB_COL_SW_LS                            => 'lastseen',
    $DB_COL_SWP_ID                           => 'switchportid',
    $DB_COL_SWP_SWID                         => 'switchid',
    $DB_COL_SWP_NAME                         => 'portname',
    $DB_COL_SWP_IFINDEX                      => 'ifindex',
    $DB_COL_SWP_DESC                         => 'portdescription',
    $DB_COL_SWP_COM                          => 'comment',
    $DB_COL_SWP_LS                           => 'lastseen',
    $DB_COL_SWPS_SWPID                       => 'switchportid',
    $DB_COL_SWPS_LASTUPDATE                  => 'lastupdate',
    $DB_COL_SWPS_STATEUPDATE                 => 'stateupdate',
    $DB_COL_SWPS_MACID                       => 'macid',
    $DB_COL_SWPS_IP                          => 'ip',
    $DB_COL_SWPS_CLASSID                     => 'classid',
    $DB_COL_SWPS_TEMPID                      => 'templateid',
    $DB_COL_SWPS_VGID                        => 'vlangroupid',
    $DB_COL_SWPS_VLANID                      => 'vlanid',
    $DB_COL_SWPS_HOSTNAME                    => 'hostname',
    $DB_COL_SWPS_VMACID                      => 'vmacid',
    $DB_COL_SWPS_VIP                         => 'vip',
    $DB_COL_SWPS_VCLASSID                    => 'vclassid',
    $DB_COL_SWPS_VTEMPID                     => 'vtemplateid',
    $DB_COL_SWPS_VVGID                       => 'vvlangroupid',
    $DB_COL_SWPS_VVLANID                     => 'vvlanid',
    $DB_COL_SWPS_VHOSTNAME                   => 'vhostname',
    $DB_COL_SW2V_ID                          => 'switch2vlanid',
    $DB_COL_SW2V_SWID                        => 'switchid',
    $DB_COL_SW2V_VLANID                      => 'vlanid',
    $DB_COL_TEMP_ID                          => 'templateid',
    $DB_COL_TEMP_NAME                        => 'templatename',
    $DB_COL_TEMP_DESC                        => 'templatedescription',
    $DB_COL_TEMP_ACT                         => 'active',
    $DB_COL_TEMP_COM                         => 'comment',
    $DB_COL_TEMP2VG_ID                       => 'template2vlangroupid',
    $DB_COL_TEMP2VG_TEMPID                   => 'templateid',
    $DB_COL_TEMP2VG_VGID                     => 'vlangroupid',
    $DB_COL_TEMP2VG_PRI                      => 'priority',
    $DB_COL_VG_ID                            => 'vlangroupid',
    $DB_COL_VG_NAME                          => 'vlangroupname',
    $DB_COL_VG_DESC                          => 'vlangroupdescription',
    $DB_COL_VG_ACT                           => 'active',
    $DB_COL_VG_COM                           => 'comment',
    $DB_COL_VG2V_ID                          => 'vlangroupid2vlan',
    $DB_COL_VG2V_VGID                        => 'vlangroupid',
    $DB_COL_VG2V_VLANID                      => 'vlanid',
    $DB_COL_VG2V_PRI                         => 'priority',
    $DB_COL_VLAN_ID                          => 'vlanid',
    $DB_COL_VLAN_LOCID                       => 'locid',
    $DB_COL_VLAN_VLAN                        => 'vlan',
    $DB_COL_VLAN_TYPE                        => 'type',
    $DB_COL_VLAN_CIDR                        => 'cidr',
    $DB_COL_VLAN_NACIP                       => 'nacip',
    $DB_COL_VLAN_NAME                        => 'vlanname',
    $DB_COL_VLAN_DESC                        => 'vlandescription',
    $DB_COL_VLAN_ACT                         => 'active',
    $DB_COL_VLAN_COE                         => 'coe',
    $DB_COL_VLAN_COM                         => 'comment',
    $DB_COL_STATUS_HOST_HOSTNAME             => 'hostname',
    $DB_COL_STATUS_HOST_LASTSEEN             => 'lastseen',
    $DB_COL_STATUS_HOST_SLAVECHECKIN         => 'slavecheckin',
    $DB_COL_STATUS_HOST_SLAVESTATUS          => 'slavestatus',
    $DB_COL_STATUS_LOCATION_LOCATIONID       => 'locationid',
    $DB_COL_STATUS_LOCATION_SITE             => 'site',
    $DB_COL_STATUS_LOCATION_BLDG             => 'bldg',
    $DB_COL_STATUS_LOCATION_LASTSEEN         => 'lastseen',
    $DB_COL_STATUS_LOCATION_HOSTNAME         => 'hostname',
    $DB_COL_STATUS_MAC_MACID                 => 'macid',
    $DB_COL_STATUS_MAC_MAC                   => 'mac',
    $DB_COL_STATUS_MAC_LASTSEEN              => 'lastseen',
    $DB_COL_STATUS_MAC_HOSTNAME              => 'hostname',
    $DB_COL_STATUS_SWITCH_SWITCHID           => 'switchid',
    $DB_COL_STATUS_SWITCH_SWITCHNAME         => 'switchname',
    $DB_COL_STATUS_SWITCH_LOCATIONID         => 'locationid',
    $DB_COL_STATUS_SWITCH_LASTSEEN           => 'lastseen',
    $DB_COL_STATUS_SWITCH_HOSTNAME           => 'hostname',
    $DB_COL_STATUS_SWITCHPORT_SWITCHPORTID   => 'switchportid',
    $DB_COL_STATUS_SWITCHPORT_LASTSEEN       => 'lastseen',
    $DB_COL_STATUS_SWITCHPORT_HOSTNAME       => 'hostname',
    $DB_COL_STATUS_SWITCHPORT_LOCID          => 'locid',
    $DB_COL_STATUS_SWITCHPORT_SITE           => 'site',
    $DB_COL_STATUS_SWITCHPORT_BLDG           => 'bldg',
    $DB_COL_STATUS_SWITCHPORT_SWITCHID       => 'switchid',
    $DB_COL_STATUS_SWITCHPORT_SWITCHNAME     => 'switchname',
    $DB_COL_STATUS_SWITCHPORT_PORTNAME       => 'portname',
    $DB_COL_STATUS_SWITCHPORT_IFINDEX        => 'ifindex',
    $DB_COL_STATUS_SWITCHPORT_DESCRIPTION    => 'description',
    $DB_COL_STATUS_SWITCHPORT_OPERSTATUS     => 'operstatus',
    $DB_COL_STATUS_SWITCHPORT_ADMINSTATUS    => 'adminstatus',
    $DB_COL_STATUS_SWITCHPORT_MABENABLED     => 'mabenabled',
    $DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD  => 'mabauthmethod',
    $DB_COL_STATUS_SWITCHPORT_MABSTATE       => 'mabstate',
    $DB_COL_STATUS_SWITCHPORT_MABAUTH        => 'mabauth',
);

Readonly our %tablenames => (
    $DB_BUF_TABLE_ADD_MAC             => 1,
    $DB_BUF_TABLE_ADD_SWITCH          => 1,
    $DB_BUF_TABLE_ADD_SWITCHPORT      => 1,
    $DB_BUF_TABLE_ADD_RADIUSAUDIT     => 1,
    $DB_BUF_TABLE_EVENTLOG            => 1,
    $DB_BUF_TABLE_LASTSEEN_LOCATION   => 1,
    $DB_BUF_TABLE_LASTSEEN_MAC        => 1,
    $DB_BUF_TABLE_LASTSEEN_SWITCH     => 1,
    $DB_BUF_TABLE_LASTSEEN_SWITCHPORT => 1,
    $DB_BUF_TABLE_SWITCHPORTSTATE     => 1,
    $DB_TABLE_CLASS                   => 1,
    $DB_TABLE_DHCPSTATE               => 1,
    $DB_TABLE_COE_MAC_EXCEPTION       => 1,
    $DB_TABLE_EVENTLOG                => 1,
    $DB_TABLE_LOCATION                => 1,
    $DB_TABLE_LOOPCIDR2LOC            => 1,
    $DB_TABLE_MAC                     => 1,
    $DB_TABLE_MAC2CLASS               => 1,
    $DB_TABLE_MAGICPORT               => 1,
    $DB_TABLE_PORT2CLASS              => 1,
    $DB_TABLE_RADIUSAUDIT             => 1,
    $DB_TABLE_SWITCH                  => 1,
    $DB_TABLE_SWITCH2VLAN             => 1,
    $DB_TABLE_SWITCHPORT              => 1,
    $DB_TABLE_SWITCHPORTSTATE         => 1,
    $DB_TABLE_TEMPLATE                => 1,
    $DB_TABLE_TEMPLATE2VLANGROUP      => 1,
    $DB_TABLE_VLAN                    => 1,
    $DB_TABLE_VLANGROUP               => 1,
    $DB_TABLE_VLANGROUP2VLAN          => 1,
    $DB_STATUS_TABLE_HOST             => 1,
    $DB_STATUS_TABLE_LOCATION         => 1,
    $DB_STATUS_TABLE_MAC              => 1,
    $DB_STATUS_TABLE_SWITCH           => 1,
    $DB_STATUS_TABLE_SWITCHPORT       => 1,
    $DB_STATUS_TABLE_SWITCHPORTSTATUS => 1,
);

Readonly our %keynames => (
    $DB_KEY_CLASSID                 => 1,
    $DB_KEY_EVENTLOGID              => 1,
    $DB_KEY_LOCATIONID              => 1,
    $DB_KEY_LOCATIONSHORTNAME       => 1,
    $DB_KEY_LOCATIONNAME            => 1,
    $DB_KEY_LOOPCIDR2LOCID          => 1,
    $DB_KEY_MACID                   => 1,
    $DB_KEY_MAC2CLASSID             => 1,
    $DB_KEY_MAGICPORTID             => 1,
    $DB_KEY_PORT2CLASSID            => 1,
    $DB_KEY_RADIUSAUDITID           => 1,
    $DB_KEY_RADIUSAUDITMACID        => 1,
    $DB_KEY_RADIUSAUDITSWITCHPORTID => 1,
    $DB_KEY_RADIUSAUDITTIME         => 1,
    $DB_KEY_SWITCHID                => 1,
    $DB_KEY_SWITCHNAME              => 1,
    $DB_KEY_SWITCH2VLANID           => 1,
    $DB_KEY_SWITCHPORTID            => 1,
    $DB_KEY_SWITCHPORTNAME          => 1,
    $DB_KEY_VLANID                  => 1,
    $DB_KEY_VLANGROUPID             => 1,
    $DB_KEY_VLANGROUP2VLANID        => 1,
);

Readonly our %tableswithlocks => (
    $DB_TABLE_CLASS      => 1,
    $DB_TABLE_MAC        => 1,
    $DB_TABLE_MAC2CLASS  => 1,
    $DB_TABLE_PORT2CLASS => 1,
);

Readonly our %tableswithactive => (
    $DB_TABLE_CLASS     => 1,
    $DB_TABLE_LOCATION  => 1,
    $DB_TABLE_MAC       => 1,
    $DB_TABLE_VLAN      => 1,
    $DB_TABLE_VLANGROUP => 1,
);

Readonly our %key2table => (
    $DB_COL_CLASS_ID    => $DB_TABLE_CLASS,
    $DB_COL_DME_MACID   => $DB_TABLE_COE_MAC_EXCEPTION,
    $DB_COL_DHCPS_MACID => $DB_TABLE_DHCPSTATE,
    $DB_COL_EVENTLOG_ID => $DB_TABLE_EVENTLOG,
    $DB_COL_LOC_ID      => $DB_TABLE_LOCATION,
    $DB_COL_LOOP_ID     => $DB_TABLE_LOOPCIDR2LOC,
    $DB_COL_MAC_ID      => $DB_TABLE_MAC,
    $DB_COL_M2C_ID      => $DB_TABLE_MAC2CLASS,
    $DB_COL_P2C_ID      => $DB_TABLE_PORT2CLASS,
    $DB_COL_RA_ID       => $DB_TABLE_RADIUSAUDIT,
    $DB_COL_SW_ID       => $DB_TABLE_SWITCH,
    $DB_COL_SW2V_ID     => $DB_TABLE_SWITCH2VLAN,
    $DB_COL_SWP_ID      => $DB_TABLE_SWITCHPORT,
    $DB_COL_VLAN_ID     => $DB_TABLE_VLAN,
    $DB_COL_VG_ID       => $DB_TABLE_VLANGROUP,
    $DB_COL_VG2V_ID     => $DB_TABLE_VLANGROUP2VLAN,
);

Readonly our %key2keyid => (
    $DB_COL_CLASS_ID      => $DB_KEY_CLASSID,
    $DB_COL_EVENTLOG_ID   => $DB_KEY_EVENTLOGID,
    $DB_COL_LOC_ID        => $DB_KEY_LOCATIONID,
    $DB_COL_LOC_NAME      => $DB_KEY_LOCATIONNAME,
    $DB_COL_LOC_SITE      => $DB_KEY_LOCATIONSHORTNAME,         # Kludge
    $DB_COL_LOOP_ID       => $DB_KEY_LOOPCIDR2LOCID,
    $DB_COL_MAC_ID        => $DB_KEY_MACID,
    $DB_COL_M2C_ID        => $DB_KEY_MAC2CLASSID,
    $DB_COL_P2C_ID        => $DB_KEY_PORT2CLASSID,
    $DB_COL_RA_ID         => $DB_KEY_RADIUSAUDITID,
    $DB_COL_RA_MACID      => $DB_KEY_RADIUSAUDITMACID,
    $DB_COL_RA_SWPID      => $DB_KEY_RADIUSAUDITSWITCHPORTID,
    $DB_COL_RA_AUDIT_TIME => $DB_KEY_RADIUSAUDITTIME,
    $DB_COL_SW_ID         => $DB_KEY_SWITCHID,
    $DB_COL_SW_NAME       => $DB_KEY_SWITCHNAME,
    $DB_COL_SW2V_ID       => $DB_KEY_SWITCH2VLANID,
    $DB_COL_SWP_ID        => $DB_KEY_SWITCHPORTID,
    $DB_COL_SWP_NAME      => $DB_KEY_SWITCHPORTNAME,
    $DB_COL_VLAN_ID       => $DB_KEY_VLANID,
    $DB_COL_VG_ID         => $DB_KEY_VLANGROUPID,
    $DB_COL_VG2V_ID       => $DB_KEY_VLANGROUP2VLANID,
);

Readonly our %key2table_event_update => (
    $DB_COL_CLASS_ID => EVENT_CLASS_UPD,
    $DB_COL_MAC_ID   => EVENT_MAC_UPD,
    $DB_COL_SW_ID    => EVENT_SWITCH_UPD,
    $DB_COL_SWP_ID   => EVENT_SWITCHPORT_UPD,
    $DB_COL_VLAN_ID  => EVENT_VLAN_UPD,
    $DB_COL_VG_ID    => EVENT_VLANGROUP_UPD,
    $DB_COL_LOC_ID   => EVENT_LOC_UPD,
);

our @EXPORT = qw (
  %column_names
  %tablenames
  %keynames
  %tableswithlocks
  %tableswithactive
  %key2table
  %key2keyid
  %key2table_event_update
  $MAGICPORT_ADD
  $MAGICPORT_REPLACE
  $MYSQL_DB
  $MYSQL_USER
  $MYSQL_PASS
  $MYSQL_HOST
  $MYSQL_PORT
  $MYSQL_BUF_DB
  $MYSQL_BUF_USER
  $MYSQL_BUF_PASS
  $MYSQL_BUF_HOST
  $MYSQL_BUF_PORT
  $DB_COL_BUF_ADD_MAC_ID
  $DB_COL_BUF_ADD_MAC_MAC
  $DB_COL_BUF_ADD_MAC_LASTSEEN
  $DB_COL_BUF_ADD_SWITCH_ID
  $DB_COL_BUF_ADD_SWITCH_IP
  $DB_COL_BUF_ADD_SWITCH_LASTSEEN
  $DB_COL_BUF_ADD_RA_ID
  $DB_COL_BUF_ADD_RA_MACID
  $DB_COL_BUF_ADD_RA_SWPID
  $DB_COL_BUF_ADD_RA_TYPE
  $DB_COL_BUF_ADD_RA_CAUSE
  $DB_COL_BUF_ADD_RA_OCTIN
  $DB_COL_BUF_ADD_RA_OCTOUT
  $DB_COL_BUF_ADD_RA_PACIN
  $DB_COL_BUF_ADD_RA_PACOUT
  $DB_COL_BUF_ADD_RA_AUDITTIME
  $DB_COL_BUF_ADD_SWITCHPORT_ID
  $DB_COL_BUF_ADD_SWITCHPORT_SWITCHID
  $DB_COL_BUF_ADD_SWITCHPORT_PORTNAME
  $DB_COL_BUF_ADD_SWITCHPORT_LASTSEEN
  $DB_COL_BUF_EVENTLOG_IP
  $DB_COL_BUF_EVENTLOG_DESC
  $DB_COL_BUF_EVENTLOG_ID
  $DB_COL_BUF_EVENTLOG_TIME
  $DB_COL_BUF_EVENTLOG_TYPE
  $DB_COL_BUF_EVENTLOG_CLASSID
  $DB_COL_BUF_EVENTLOG_LOCID
  $DB_COL_BUF_EVENTLOG_MACID
  $DB_COL_BUF_EVENTLOG_M2CID
  $DB_COL_BUF_EVENTLOG_P2CID
  $DB_COL_BUF_EVENTLOG_SWID
  $DB_COL_BUF_EVENTLOG_SWPID
  $DB_COL_BUF_EVENTLOG_SW2VID
  $DB_COL_BUF_EVENTLOG_TEMPID
  $DB_COL_BUF_EVENTLOG_TEMP2VGID
  $DB_COL_BUF_EVENTLOG_VGID
  $DB_COL_BUF_EVENTLOG_VG2VID
  $DB_COL_BUF_EVENTLOG_VLANID
  $DB_COL_BUF_EVENTLOG_IP
  $DB_COL_BUF_EVENTLOG_DESC
  $DB_COL_BUF_LASTSEEN_LOCATION_ID
  $DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN
  $DB_COL_BUF_LASTSEEN_MAC_ID
  $DB_COL_BUF_LASTSEEN_MAC_LASTSEEN
  $DB_COL_BUF_LASTSEEN_SWITCH_ID
  $DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN
  $DB_COL_BUF_LASTSEEN_SWITCHPORT_ID
  $DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN
  $DB_COL_BUF_SWPS_SWPID
  $DB_COL_BUF_SWPS_LASTUPDATE
  $DB_COL_BUF_SWPS_MACID
  $DB_COL_BUF_SWPS_MAC
  $DB_COL_BUF_SWPS_IP
  $DB_COL_BUF_SWPS_CLASSID
  $DB_COL_BUF_SWPS_TEMPID
  $DB_COL_BUF_SWPS_VGID
  $DB_COL_BUF_SWPS_VLANID
  $DB_COL_BUF_SWPS_VMACID
  $DB_COL_BUF_SWPS_VMAC
  $DB_COL_BUF_SWPS_VIP
  $DB_COL_BUF_SWPS_VCLASSID
  $DB_COL_BUF_SWPS_VTEMPID
  $DB_COL_BUF_SWPS_VVGID
  $DB_COL_BUF_SWPS_VVLANID
  $DB_COL_CLASS_ID
  $DB_COL_CLASS_NAME
  $DB_COL_CLASS_PRI
  $DB_COL_CLASS_REAUTH
  $DB_COL_CLASS_IDLE
  $DB_COL_CLASS_VGID
  $DB_COL_CLASS_ACT
  $DB_COL_CLASS_LOCKED
  $DB_COL_CLASS_COM
  $DB_SORT_CLASS_ID
  $DB_SORT_CLASS_NAME
  $DB_SORT_CLASS_PRI
  $DB_SORT_CLASS_ACT
  $DB_SORT_CLASS_LOCKED
  $DB_SORT_CLASS_VGID
  $DB_COL_CMP_AUTHTYPE
  $DB_COL_CMP_CLASSID
  $DB_COL_CMP_CLASSNAME
  $DB_COL_CMP_COM
  $DB_COL_CMP_COE
  $DB_COL_CMP_DEF_VGID
  $DB_COL_CMP_LOCKED
  $DB_COL_CMP_MACID
  $DB_COL_CMP_PRI
  $DB_COL_CMP_RECID
  $DB_COL_CMP_SUBPRI
  $DB_COL_CMP_RANDPRI
  $DB_COL_CMP_HASHPRI
  $DB_COL_CMP_SWPID
  $DB_COL_CMP_SWID
  $DB_COL_CMP_VGID
  $DB_COL_CMP_VLAN
  $DB_COL_CMP_VLANID
  $DB_COL_CMP_VLANNAME
  $DB_COL_CMP_VLANTYPE
  $DB_COL_CMP_VGNAME
  $DB_COL_CMP_TEMPID
  $DB_COL_CMP_TEMPNAME
  $DB_COL_CMP_VGID
  $DB_COL_CMP_LOCID
  $DB_COL_CMP_REAUTH
  $DB_COL_CMP_IDLE
  $DB_COL_DME_MACID
  $DB_COL_DME_TICKETREF
  $DB_COL_DME_CREATED
  $DB_COL_DME_COMMENT
  $DB_COL_DHCPS_MACID
  $DB_COL_DHCPS_LASTUPDATE
  $DB_COL_DHCPS_STATE
  $DB_COL_DHCPS_IP
  $DB_COL_EVENTLOG_ID
  $DB_COL_EVENTLOG_USERID
  $DB_COL_EVENTLOG_TIME
  $DB_COL_EVENTLOG_TIME_GT
  $DB_COL_EVENTLOG_TIME_LT
  $DB_COL_EVENTLOG_TYPE
  $DB_COL_EVENTLOG_HOST
  $DB_COL_EVENTLOG_CLASSID
  $DB_COL_EVENTLOG_LOCID
  $DB_COL_EVENTLOG_MACID
  $DB_COL_EVENTLOG_M2CID
  $DB_COL_EVENTLOG_P2CID
  $DB_COL_EVENTLOG_SWID
  $DB_COL_EVENTLOG_SWPID
  $DB_COL_EVENTLOG_SW2VID
  $DB_COL_EVENTLOG_TEMPID
  $DB_COL_EVENTLOG_TEMP2VGID
  $DB_COL_EVENTLOG_VGID
  $DB_COL_EVENTLOG_VG2VID
  $DB_COL_EVENTLOG_VLANID
  $DB_COL_EVENTLOG_IP
  $DB_COL_EVENTLOG_DESC
  $DB_COL_LOC_ID
  $DB_COL_LOC_SITE
  $DB_COL_LOC_BLDG
  $DB_COL_LOC_NAME
  $DB_COL_LOC_DESC
  $DB_COL_LOC_ACT
  $DB_COL_LOC_COM
  $DB_COL_LOC_SHORTNAME
  $DB_COL_LOOP_ID
  $DB_COL_LOOP_CIDR
  $DB_COL_LOOP_LOCID
  $DB_COL_MAC_ID
  $DB_COL_MAC_MAC
  $DB_COL_MAC_FS
  $DB_COL_MAC_LS
  $DB_COL_MAC_DESC
  $DB_COL_MAC_AT
  $DB_COL_MAC_ACT
  $DB_COL_MAC_COE
  $DB_COL_MAC_LOCKED
  $DB_COL_MAC_COM
  $DB_COL_MAC_LSC
  $DB_SORT_MAC_ID
  $DB_SORT_MAC_MAC
  $DB_COL_M2C_ID
  $DB_COL_M2C_PRI
  $DB_COL_M2C_MACID
  $DB_COL_M2C_CLASSID
  $DB_COL_M2C_VLANID
  $DB_COL_M2C_VGID
  $DB_COL_M2C_TEMPID
  $DB_COL_M2C_EXPIRE
  $DB_COL_M2C_COM
  $DB_COL_M2C_ACT
  $DB_COL_M2C_LOCKED
  $DB_M2C_IN_HASH_REF
  $DB_M2C_REMOVE_FLAG
  $DB_M2C_UPDATE_FLAG
  $DB_SORT_M2C_ID
  $DB_COL_MAGIC_ID
  $DB_COL_MAGIC_SWPID
  $DB_COL_MAGIC_CLASSID
  $DB_COL_MAGIC_VLANID
  $DB_COL_MAGIC_VGID
  $DB_COL_MAGIC_TEMPID
  $DB_COL_MAGIC_PRI
  $DB_COL_MAGIC_COM
  $DB_COL_MAGIC_TYPE
  $DB_COL_P2C_ID
  $DB_COL_P2C_SWPID
  $DB_COL_P2C_CLASSID
  $DB_COL_P2C_VLANID
  $DB_COL_P2C_VGID
  $DB_COL_P2C_COM
  $DB_COL_P2C_LOCKED
  $DB_COL_P2C_PRI
  $DB_COL_P2C_ACT
  $DB_COL_RA_ID
  $DB_COL_RA_MACID
  $DB_COL_RA_SWPID
  $DB_COL_RA_AUDIT_TIME
  $DB_COL_RA_AUDIT_TIME_GT
  $DB_COL_RA_AUDIT_TIME_LT
  $DB_COL_RA_AUDIT_SRV
  $DB_COL_RA_TYPE
  $DB_COL_RA_CAUSE
  $DB_COL_RA_OCTIN
  $DB_COL_RA_OCTOUT
  $DB_COL_RA_PACIN
  $DB_COL_RA_PACOUT
  $DB_COL_SW_ID
  $DB_COL_SW_NAME
  $DB_COL_SW_LOCID
  $DB_COL_SW_DESC
  $DB_COL_SW_IP
  $DB_COL_SW_COM
  $DB_COL_SW_LS
  $DB_COL_SWP_ID
  $DB_COL_SWP_SWID
  $DB_COL_SWP_NAME
  $DB_COL_SWP_IFINDEX
  $DB_COL_SWP_DESC
  $DB_COL_SWP_COM
  $DB_COL_SWP_LS
  $DB_COL_SWPS_SWPID
  $DB_COL_SWPS_LASTUPDATE
  $DB_COL_SWPS_STATEUPDATE
  $DB_COL_SWPS_MACID
  $DB_COL_SWPS_MACID_GT_ZERO
  $DB_COL_SWPS_IP
  $DB_COL_SWPS_CLASSID
  $DB_COL_SWPS_TEMPID
  $DB_COL_SWPS_VGID
  $DB_COL_SWPS_VLANID
  $DB_COL_SWPS_HOSTNAME
  $DB_COL_SWPS_VMACID
  $DB_COL_SWPS_VMACID_GT_ZERO
  $DB_COL_SWPS_VIP
  $DB_COL_SWPS_VCLASSID
  $DB_COL_SWPS_VTEMPID
  $DB_COL_SWPS_VVGID
  $DB_COL_SWPS_VVLANID
  $DB_COL_SWPS_VHOSTNAME
  $DB_COL_SW2V_ID
  $DB_COL_SW2V_SWID
  $DB_COL_SW2V_VLANID
  $DB_COL_TEMP_ID
  $DB_COL_TEMP_NAME
  $DB_COL_TEMP_DESC
  $DB_COL_TEMP_ACT
  $DB_COL_TEMP_COM
  $DB_COL_TEMP2VG_ID
  $DB_COL_TEMP2VG_TEMPID
  $DB_COL_TEMP2VG_VGID
  $DB_COL_TEMP2VG_PRI
  $DB_SORT_TEMP_ID
  $DB_SORT_TEMP_NAME
  $DB_SORT_TEMP_ACT
  $DB_COL_VG_ID
  $DB_COL_VG_NAME
  $DB_COL_VG_DESC
  $DB_COL_VG_ACT
  $DB_COL_VG_COM
  $DB_SORT_VG_ID
  $DB_SORT_VG_NAME
  $DB_SORT_VG_ACT
  $DB_COL_VG2V_ID
  $DB_COL_VG2V_VGID
  $DB_COL_VG2V_VLANID
  $DB_COL_VG2V_PRI
  $DB_COL_VLAN_ID
  $DB_COL_VLAN_LOCID
  $DB_COL_VLAN_VLAN
  $DB_COL_VLAN_TYPE
  $DB_COL_VLAN_CIDR
  $DB_COL_VLAN_NACIP
  $DB_COL_VLAN_NAME
  $DB_COL_VLAN_DESC
  $DB_COL_VLAN_ACT
  $DB_COL_VLAN_COE
  $DB_COL_VLAN_COM
  $DB_COL_VLAN2SWP_VLANID
  $DB_COL_VLAN2SWP_SWPID
  $DB_COL_VLAN2SWP_VLAN
  $DB_COL_VLAN2SWP_NAME
  $DB_COL_VG2SWP_VGID
  $DB_COL_VG2SWP_SWPID
  $DB_COL_VG2SWP_VLAN
  $DB_COL_VG2SWP_NAME
  $DB_COL_VG2SWP_VGNAME
  $DB_COL_STATUS_HOST_HOSTNAME
  $DB_COL_STATUS_HOST_LASTSEEN
  $DB_COL_STATUS_HOST_SLAVECHECKIN
  $DB_COL_STATUS_HOST_SLAVESTATUS
  $DB_COL_STATUS_LOCATION_LOCATIONID
  $DB_COL_STATUS_LOCATION_SITE
  $DB_COL_STATUS_LOCATION_BLDG
  $DB_COL_STATUS_LOCATION_LASTSEEN
  $DB_COL_STATUS_LOCATION_HOSTNAME
  $DB_COL_STATUS_MAC_MACID
  $DB_COL_STATUS_MAC_MAC
  $DB_COL_STATUS_MAC_LASTSEEN
  $DB_COL_STATUS_MAC_HOSTNAME
  $DB_COL_STATUS_SWITCH_SWITCHID
  $DB_COL_STATUS_SWITCH_SWITCHNAME
  $DB_COL_STATUS_SWITCH_LOCATIONID
  $DB_COL_STATUS_SWITCH_LASTSEEN
  $DB_COL_STATUS_SWITCH_HOSTNAME
  $DB_COL_STATUS_SWITCHPORT_SWITCHPORTID
  $DB_COL_STATUS_SWITCHPORT_LASTSEEN
  $DB_COL_STATUS_SWITCHPORT_HOSTNAME
  $DB_COL_STATUS_SWITCHPORT_LOCID
  $DB_COL_STATUS_SWITCHPORT_SITE
  $DB_COL_STATUS_SWITCHPORT_BLDG
  $DB_COL_STATUS_SWITCHPORT_SWITCHID
  $DB_COL_STATUS_SWITCHPORT_SWITCHNAME
  $DB_COL_STATUS_SWITCHPORT_PORTNAME
  $DB_COL_STATUS_SWITCHPORT_IFINDEX
  $DB_COL_STATUS_SWITCHPORT_DESCRIPTION
  $DB_COL_STATUS_SWITCHPORT_OPERSTATUS
  $DB_COL_STATUS_SWITCHPORT_ADMINSTATUS
  $DB_COL_STATUS_SWITCHPORT_MABENABLED
  $DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD
  $DB_COL_STATUS_SWITCHPORT_MABSTATE
  $DB_COL_STATUS_SWITCHPORT_MABAUTH
  $DB_KEY_CLASSID
  $DB_KEY_LOCATIONID
  $DB_KEY_LOCATIONSHORTNAME
  $DB_KEY_LOCATIONNAME
  $DB_KEY_LOOPCIDR2LOCID
  $DB_KEY_MACID
  $DB_KEY_MAC2CLASSID
  $DB_KEY_PORT2CLASSID
  $DB_KEY_PORTSWITCHID
  $DB_KEY_RADIUSAUDITID
  $DB_KEY_RADIUSAUDITMACID
  $DB_KEY_RADIUSAUDITSWITCHPORTID
  $DB_KEY_RADIUSAUDITTIME
  $DB_KEY_SWITCHID
  $DB_KEY_SWITCHNAME
  $DB_KEY_SWITCHPORTID
  $DB_KEY_SWITCH2VLANID
  $DB_KEY_SWITCHPORTSTATEID
  $DB_KEY_SWITCHPORTNAME
  $DB_KEY_TEMPLATEID
  $DB_KEY_TEMPLATE2VLANGROUPID
  $DB_KEY_VLANID
  $DB_KEY_VLANGROUPID
  $DB_KEY_VLANGROUP2VLANID
  $DB_TABLE_CLASS
  $DB_TABLE_CLASSMACPORT
  $DB_TABLE_COE_MAC_EXCEPTION
  $DB_TABLE_DHCPSTATE
  $DB_TABLE_EVENTLOG
  $DB_TABLE_LOCATION
  $DB_TABLE_LOOPCIDR2LOC
  $DB_TABLE_MAC
  $DB_TABLE_MAC2CLASS
  $DB_TABLE_MAGICPORT
  $DB_TABLE_PORT2CLASS
  $DB_TABLE_RADIUSAUDIT
  $DB_TABLE_SWITCH
  $DB_TABLE_SWITCH2VLAN
  $DB_TABLE_SWITCHPORT
  $DB_TABLE_SWITCHPORTSTATE
  $DB_TABLE_TEMPLATE
  $DB_TABLE_TEMPLATE2VLANGROUP
  $DB_TABLE_VLAN
  $DB_TABLE_VLANGROUP
  $DB_TABLE_VLANGROUP2VLAN
  $DB_BUF_TABLE_ADD_MAC
  $DB_BUF_TABLE_ADD_SWITCH
  $DB_BUF_TABLE_ADD_SWITCHPORT
  $DB_BUF_TABLE_ADD_RADIUSAUDIT
  $DB_BUF_TABLE_EVENTLOG
  $DB_BUF_TABLE_LASTSEEN_LOCATION
  $DB_BUF_TABLE_LASTSEEN_MAC
  $DB_BUF_TABLE_LASTSEEN_SWITCH
  $DB_BUF_TABLE_LASTSEEN_SWITCHPORT
  $DB_BUF_TABLE_SWITCHPORTSTATE
  $DB_STATUS_TABLE_HOST
  $DB_STATUS_TABLE_LOCATION
  $DB_STATUS_TABLE_MAC
  $DB_STATUS_TABLE_SWITCH
  $DB_STATUS_TABLE_SWITCHPORT
  $DB_TABLE_NAME
  $DB_KEY_NAME
  $DB_KEY_VALUE
  $SLAVE_STATE_UNKNOWN
  $SLAVE_STATE_OK
  $SLAVE_STATE_OFFLINE
  $SLAVE_STATE_DELAYED
);

