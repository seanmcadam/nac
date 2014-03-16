#!/usr/bin/perl
# SVN: $Id: NACDB.pm 1529 2012-10-13 17:22:52Z sean $
#
# version	$Revision: 1751 $:
# lastmodified	$Date: 2012-10-13 13:22:52 -0400 (Sat, 13 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DB2.pm $:
#
#
#
# Author: Sean McAdam
# Purpose: Provide controlled access to the NAC database.
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DB2;
use FindBin;
use lib "$FindBin::Bin/..";
use version;
our $VERSION = "3.0";
my ($minor_version) = '$Revision: 1751 $:' =~ m{ \$Revision:\s+(\S+) }x;
$VERSION .= '.' . $minor_version;

use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck);
use POSIX;
use NAC::DBSql;
use NAC::DBConsts;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use NAC::DBBuffer;
use NAC::Misc;
use strict;

our @ISA = qw(NAC::DBSql);

if ( !defined %key2table ) { confess; }

sub _delete_record($$);
sub activate_record($$);
sub activate_location($$);
sub activate_macid($$);
sub add_class($$);
sub add_eventlog($$);
sub add_location($$);
sub add_mac($$);
sub add_mac2class($$);
sub add_mac2type($$);
sub add_port2class($$);
sub add_radiusaudit($$);
sub add_switch($$);
sub add_switch2vlan($$);
sub add_switchport($$);
sub add_vlan($$);
sub add_vlangroup2vlan($$);
sub add_vlangroup($$);
sub deactivate_record($$);
sub deactivate_location($$);
sub deactivate_mac($$);
sub deactivate_macid($$);
sub delete_loopcidr2locid($$);
sub get_active_class_macs($$);
sub get_all_locations($$);
sub get_all_switchports($$);
sub get_all_vlans($$);
sub get_class($$);
sub get_eventlog($$);
sub get_class_mac_port($$);
sub get_class_macs($$);

sub get_template_name($$);
sub get_vlangroup_name($$);
sub get_vlan_name($$);
sub get_switchport_name($$);
sub get_switch_name($$);
sub get_switchport_swid($$);
sub get_mac_name($$);
sub get_class_name($$);

sub get_inactive_class_macs($$);
sub get_location($$);
sub get_radiusaudit($$);
sub get_locid_from_switchid($$);
sub get_loopcidr2loc($$);
sub get_mac($$);
sub get_mac2class($$);
sub get_macid($$);
sub get_macid_all($$);
sub get_macs_in_class($$);
sub get_mactype_name($$);
sub get_port2class($$);
sub get_switch2vlan($$);
sub get_switches($$);
sub get_vg2swp($$);
sub get_vlan($$);
sub get_vlan2swp($$);
sub get_vlangroup($$);
sub get_vlangroupid($$);
sub get_vlan_record($$);
sub get_vlans_for_locid($$);
sub is_dbhset($);
sub is_record_active($$);
sub is_record_locked($$);
sub is_location_active($$);
sub lock_record($$);
sub remove_class($$);
sub remove_location($$);
sub remove_mac2class($$);
sub remove_radiusaudit($$);
sub remove_port2class($$);
sub remove_switch2vlan($$);
sub remove_switch($$);
sub remove_switchport($$);
sub remove_vlan($$);
sub remove_vlangroup($$);
sub remove_vlangroup2vlan($$);
sub set_active_on_location($$);
sub unlock_record($$);
sub update_mac_lastseen($$);
sub update_record($$);
sub update_record_db_col($$);
sub _verify_MAC;

my $AutoReconnect = 1;
my $DEBUG         = 1;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub new() {
    my $class    = shift;
    my $parm_ref = shift;
    my $self;

    if ( ( defined $parm_ref ) && ( ref($parm_ref) ne 'HASH' ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAME . "() started" );

    my %parms  = ();
    my $config = NAC::ConfigDB->new();

    # For backward compatibility
    $parms{$SQL_DB}        = ( defined $parm_ref->{$SQL_DB} )        ? $parm_ref->{$SQL_DB}        : $config->nac_master_write_db_audit;
    $parms{$SQL_HOST}      = ( defined $parm_ref->{$SQL_HOST} )      ? $parm_ref->{$SQL_HOST}      : $config->nac_master_write_hostname;
    $parms{$SQL_PORT}      = ( defined $parm_ref->{$SQL_PORT} )      ? $parm_ref->{$SQL_PORT}      : $config->nac_master_write_port;
    $parms{$SQL_USER}      = ( defined $parm_ref->{$SQL_USER} )      ? $parm_ref->{$SQL_USER}      : $config->nac_master_write_user;
    $parms{$SQL_PASS}      = ( defined $parm_ref->{$SQL_PASS} )      ? $parm_ref->{$SQL_PASS}      : $config->nac_master_write_pass;
    $parms{$SQL_READ_ONLY} = ( defined $parm_ref->{$SQL_READ_ONLY} ) ? $parm_ref->{$SQL_READ_ONLY} : undef;
    $parms{$SQL_CLASS}     = ( defined $parm_ref->{$SQL_CLASS} )     ? $parm_ref->{$SQL_CLASS}     : $class;

    $self = $class->SUPER::new( \%parms );

    bless $self, $class;

    $self;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub activate_location($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    if ( !( ( defined $parm_ref->{$DB_COL_LOC_ID} )
            || ( ( defined $parm_ref->{$DB_COL_LOC_SITE} ) && ( defined $parm_ref->{$DB_COL_LOC_SITE} ) ) ) ) {
        confess "Either LOCID or ( SITE & BLDG ) have to be defined\n" . Dumper $parm_ref;
    }

    if ( !defined $parm_ref->{$DB_COL_LOC_ID} ) {
        if ( !$self->get_location($parm_ref) ) { confess; }
    }
    my $locid = $parm_ref->{$DB_COL_LOC_ID};

    $parm_ref->{$DB_COL_LOC_ID} = $locid;

    $ret = $self->activate_record($parm_ref);

    $ret;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub activate_macid($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_MAC_ID} || ( !isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) { confess Dumper $parm_ref; }

    my $macid = $parm_ref->{$DB_COL_MAC_ID};

    $parm_ref->{$DB_COL_MAC_ID} = $macid;

    if ( $ret = $self->activate_record($parm_ref) ) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_TYPE  => EVENT_MAC_UPD,
                $EVENT_PARM_LOCID => $macid,
                $EVENT_PARM_DESC  => 'Activated',
        } );
    }
    $ret;
}

#--------------------------------------------------------------------------------
sub lock_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $tablename;
    my $keyname;
    my $keyval;
    my $key;

    if ( 1 != scalar( keys(%$parm_ref) ) ) { confess Dumper $parm_ref; }

    ($key) = keys(%$parm_ref);
    if ( !defined $key2table{$key} ) { confess Dumper $parm_ref; }

    $tablename = $key2table{$key};
    if ( !defined $tableswithlocks{$tablename} ) { confess Dumper $parm_ref; }

    $keyname = $key2keyid{$key};

    $keyval = $parm_ref->{$key};
    if ( !isdigit($keyval) ) { confess Dumper $parm_ref; }

    my $sql = "UPDATE $tablename SET locked = '1' WHERE $keyname = $keyval ";

    if ( !$self->sqldo($sql) ) {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    else {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_LOCID => $keyval,
                $EVENT_PARM_DESC  => 'Locked',
                $EVENT_PARM_TYPE  => $key2table_event_update{$key},
        } );
        $ret++;
    }

    $ret;

}

#--------------------------------------------------------------------------------
sub unlock_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $tablename;
    my $keyname;
    my $keyval;
    my $key;

    if ( 1 != scalar( keys(%$parm_ref) ) ) { confess Dumper $parm_ref; }

    ($key) = keys(%$parm_ref);
    if ( !defined $key2table{$key} ) { confess Dumper $parm_ref; }

    $tablename = $key2table{$key};
    if ( !defined $tableswithlocks{$tablename} ) { confess Dumper $parm_ref; }

    $keyname = $key2keyid{$key};

    $keyval = $parm_ref->{$key};
    if ( !isdigit($keyval) ) { confess Dumper $parm_ref; }

    my $sql = "UPDATE $tablename SET locked = '0' WHERE $keyname = $keyval ";

    if ( !$self->sqldo($sql) ) {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    else {

        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_LOCID => $keyval,
                $EVENT_PARM_DESC  => 'Unocked',
                $EVENT_PARM_TYPE  => $key2table_event_update{$key},
        } );
        $ret++;
    }

    $ret;

}

#--------------------------------------------------------------------------------
sub deactivate_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $tablename;
    my $keyname;
    my $keyval;
    my $key;

    $self->reseterr;

    if ( 1 != scalar( keys(%$parm_ref) ) ) { confess Dumper $parm_ref; }

    ($key) = keys(%$parm_ref);
    if ( !defined $key2table{$key} ) { confess Dumper $parm_ref; }

    $tablename = $key2table{$key};
    if ( !defined $tableswithactive{$tablename} ) { confess Dumper $parm_ref; }

    $keyname = $key2keyid{$key};

    $keyval = $parm_ref->{$key};
    if ( !isdigit($keyval) ) { confess Dumper $parm_ref; }

    my $sql = "UPDATE $tablename SET active = '0' WHERE $keyname = $keyval ";

    if ( !$self->sqldo($sql) ) {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    else {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_LOCID => $keyval,
                $EVENT_PARM_DESC  => 'Deactivate',
                $EVENT_PARM_TYPE  => $key2table_event_update{$key},
        } );
        $ret++;
    }

    $ret;

}

#--------------------------------------------------------------------------------
sub activate_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $tablename;
    my $keyname;
    my $keyval;
    my $key;

    $self->reseterr;

    if ( 1 != scalar( keys(%$parm_ref) ) ) { confess Dumper $parm_ref; }

    ($key) = keys(%$parm_ref);
    if ( !defined $key2table{$key} ) { confess Dumper $parm_ref; }

    $tablename = $key2table{$key};
    if ( !defined $tableswithactive{$tablename} ) { confess Dumper $parm_ref; }

    $keyname = $key2keyid{$key};

    $keyval = $parm_ref->{$key};
    if ( !isdigit($keyval) ) { confess Dumper $parm_ref; }

    my $sql = "UPDATE $tablename SET active = '1' WHERE $keyname = $keyval ";

    if ( !$self->sqldo($sql) ) {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    else {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_LOCID => $keyval,
                $EVENT_PARM_DESC  => 'Activate',
                $EVENT_PARM_TYPE  => $key2table_event_update{$key},
        } );
        $ret++;
    }

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_location($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_LOC_SITE} || $parm_ref->{$DB_COL_LOC_SITE} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_LOC_BLDG} || $parm_ref->{$DB_COL_LOC_BLDG} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_LOC_ACT} && !isdigit( $parm_ref->{$DB_COL_LOC_ACT} ) ) { confess Dumper $parm_ref; }
    my $site = $parm_ref->{$DB_COL_LOC_SITE};
    my $bldg = $parm_ref->{$DB_COL_LOC_BLDG};
    my $act  = $parm_ref->{$DB_COL_LOC_ACT};
    my $loc  = $site . "-" . $bldg;
    my $sql;

    $site =~ tr/a-z/A-Z/;
    $bldg =~ tr/a-z/A-Z/;

    $sql = "INSERT INTO $DB_TABLE_LOCATION "
      . " ( site, bldg "
      . ( ( defined $act ) ? ", active " : '' )
      . " ) VALUES ( "
      . "'$site'"
      . ",'$bldg'"
      . ( ( defined $act ) ? ",$act " : '' )
      . " )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_LOC_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_TYPE  => EVENT_LOC_ADD,
                $EVENT_PARM_LOCID => $parm_ref->{$DB_COL_LOC_ID},
                $EVENT_PARM_DESC  => " $site $bldg ",
        } );
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_eventlog($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_EVENTLOG_TYPE} ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_CLASSID}   && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_CLASSID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_LOCID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_LOCID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_MACID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_MACID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_M2CID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_M2CID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_P2CID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_P2CID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SWID}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SWID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SWPID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SWPID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SW2VID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SW2VID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TEMPID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TEMPID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID} && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VGID}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VGID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VG2VID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VG2VID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VLANID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VLANID} ) ) )    { confess Dumper $parm_ref; }

    my $type      = $parm_ref->{$DB_COL_EVENTLOG_TYPE};
    my $classid   = $parm_ref->{$DB_COL_EVENTLOG_CLASSID};
    my $locid     = $parm_ref->{$DB_COL_EVENTLOG_LOCID};
    my $macid     = $parm_ref->{$DB_COL_EVENTLOG_MACID};
    my $m2cid     = $parm_ref->{$DB_COL_EVENTLOG_M2CID};
    my $p2cid     = $parm_ref->{$DB_COL_EVENTLOG_P2CID};
    my $swid      = $parm_ref->{$DB_COL_EVENTLOG_SWID};
    my $swpid     = $parm_ref->{$DB_COL_EVENTLOG_SWPID};
    my $sw2vid    = $parm_ref->{$DB_COL_EVENTLOG_SW2VID};
    my $tempid    = $parm_ref->{$DB_COL_EVENTLOG_TEMPID};
    my $temp2vgid = $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID};
    my $vlanid    = $parm_ref->{$DB_COL_EVENTLOG_VLANID};
    my $vgid      = $parm_ref->{$DB_COL_EVENTLOG_VGID};
    my $vg2vid    = $parm_ref->{$DB_COL_EVENTLOG_VG2VID};
    my $ip        = $parm_ref->{$DB_COL_EVENTLOG_IP};
    my $hostname  = $parm_ref->{$DB_COL_EVENTLOG_HOST};
    my $desc      = $parm_ref->{$DB_COL_EVENTLOG_DESC};

    $desc = '' if !defined $desc;
    $desc =~ s/\'/\\'/g;
    $desc =~ s/\"/\\"/g;

    my $sql = "INSERT INTO $DB_TABLE_EVENTLOG "
      . " ( eventtype "
      . ( ( defined $classid )   ? ", classid "              : '' )
      . ( ( defined $locid )     ? ", locationid "           : '' )
      . ( ( defined $macid )     ? ", macid "                : '' )
      . ( ( defined $m2cid )     ? ", mac2classid "          : '' )
      . ( ( defined $p2cid )     ? ", port2classid "         : '' )
      . ( ( defined $swid )      ? ", switchid "             : '' )
      . ( ( defined $swpid )     ? ", switchportid "         : '' )
      . ( ( defined $sw2vid )    ? ", switch2vlanid "        : '' )
      . ( ( defined $tempid )    ? ", templateid "           : '' )
      . ( ( defined $temp2vgid ) ? ", template2vlangroupid " : '' )
      . ( ( defined $vgid )      ? ", vlangroupid "          : '' )
      . ( ( defined $vg2vid )    ? ", vlangroup2vlanid "     : '' )
      . ( ( defined $vlanid )    ? ", vlanid "               : '' )
      . ( ( defined $ip )        ? ", ip "                   : '' )
      . ( ( defined $hostname )  ? ", hostname "             : '' )
      . ( ( defined $desc )      ? ", eventtext "            : '' )
      . " ) VALUES ( "
      . "'$type'"
      . ( ( defined $classid )   ? ", $classid "    : '' )
      . ( ( defined $locid )     ? ", $locid "      : '' )
      . ( ( defined $macid )     ? ", $macid "      : '' )
      . ( ( defined $m2cid )     ? ", $m2cid "      : '' )
      . ( ( defined $p2cid )     ? ", $p2cid "      : '' )
      . ( ( defined $swid )      ? ", $swid "       : '' )
      . ( ( defined $swpid )     ? ", $swpid "      : '' )
      . ( ( defined $sw2vid )    ? ", $sw2vid "     : '' )
      . ( ( defined $tempid )    ? ", $tempid "     : '' )
      . ( ( defined $temp2vgid ) ? ", $temp2vgid "  : '' )
      . ( ( defined $vgid )      ? ", $vgid "       : '' )
      . ( ( defined $vg2vid )    ? ", $vg2vid "     : '' )
      . ( ( defined $vlanid )    ? ", $vlanid "     : '' )
      . ( ( defined $ip )        ? ", '$ip' "       : '' )
      . ( ( defined $hostname )  ? ", '$hostname' " : '' )
      . ( ( defined $desc )      ? ", '$desc' "     : '' )
      . " )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_EVENTLOG_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    # No event log for an event log...

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_loopcidr2locid($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_LOOP_CIDR} || $parm_ref->{$DB_COL_LOOP_CIDR} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_LOOP_LOCID} || ( !isdigit( $parm_ref->{$DB_COL_LOOP_LOCID} ) ) ) { confess Dumper $parm_ref; }
    my $cidr  = $parm_ref->{$DB_COL_LOOP_CIDR};
    my $locid = $parm_ref->{$DB_COL_LOOP_LOCID};
    my $sql;

    $sql = "INSERT INTO $DB_TABLE_LOOPCIDR2LOC ( cidr, locid ) VALUES ( '$cidr', $locid )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_LOOP_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        EventLog( EVENT_CIDR_ADD, "CIDR:'$cidr' LOCID:'$locid'" );
    }

    $ret;
}

#-------------------------------------------------------
# add new CLASS
#-------------------------------------------------------
sub add_class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_CLASS_NAME} || $parm_ref->{$DB_COL_CLASS_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_CLASS_PRI} || ( !isdigit( $parm_ref->{$DB_COL_CLASS_PRI} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_REAUTH} && ( !isdigit( $parm_ref->{$DB_COL_CLASS_REAUTH} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_IDLE}   && ( !isdigit( $parm_ref->{$DB_COL_CLASS_IDLE} ) ) )   { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_CLASS_VGID}  && ( !isdigit( $parm_ref->{$DB_COL_CLASS_VGID} ) ) )   { confess Dumper $parm_ref; }

    my $name        = $parm_ref->{$DB_COL_CLASS_NAME};
    my $pri         = $parm_ref->{$DB_COL_CLASS_PRI};
    my $reauth      = ( defined $parm_ref->{$DB_COL_CLASS_REAUTH} ) ? $parm_ref->{$DB_COL_CLASS_REAUTH} : 3600;    # Default is 3600;
    my $idle        = ( defined $parm_ref->{$DB_COL_CLASS_IDLE} ) ? $parm_ref->{$DB_COL_CLASS_IDLE} : 3600;        # Default is 3600;
    my $vlangroupid = ( $parm_ref->{$DB_COL_CLASS_VGID} ) ? $parm_ref->{$DB_COL_CLASS_VGID} : NULL;                # Default is NULL;
    my $active      = ( $parm_ref->{$DB_COL_CLASS_ACT} ) ? $parm_ref->{$DB_COL_CLASS_ACT} : 1;                     # Default is active
    my $comment     = ( $parm_ref->{$DB_COL_CLASS_COM} ) ? $parm_ref->{$DB_COL_CLASS_COM} : '';
    my $sql;

    $sql = "INSERT INTO $DB_TABLE_CLASS ( name,priority,reauthtime,idletimeout,vlangroupid,active,comment ) "
      . " VALUES  "
      . " ( '$name',$pri,$reauth,$idle,$vlangroupid,$active,'$comment' )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_CLASS_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO    => EVENT_INFO,
                $EVENT_PARM_TYPE    => EVENT_CLASS_ADD,
                $EVENT_PARM_CLASSID => $parm_ref->{$DB_COL_CLASS_ID},
                $EVENT_PARM_DESC    => "CLASS:'$name'" . "[" . $parm_ref->{$DB_COL_CLASS_ID} . "]",
        } );

    }

    $ret;
}

#-------------------------------------------------------
# add new DME
#-------------------------------------------------------
sub add_coe_mac_exception($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_DME_MACID} || !isdigit( $parm_ref->{$DB_COL_DME_MACID} ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_DME_TICKETREF} || $parm_ref->{$DB_COL_DME_TICKETREF} eq '' ) { confess Dumper $parm_ref; }

    my $macid     = $parm_ref->{$DB_COL_DME_MACID};
    my $ticketref = $parm_ref->{$DB_COL_DME_TICKETREF};
    my $comment   = $parm_ref->{$DB_COL_DME_COMMENT};

    $ticketref =~ s/\'//;
    $ticketref =~ s/\"//;
    $comment   =~ s/\'//;
    $comment   =~ s/\"//;

    my %p;
    $p{$DB_COL_DME_MACID} = $macid;
    if ( !$self->get_mac( \%p ) ) {
        EventLog( EVENT_ERR, MYNAMELINE() . " BAD MACID: $macid" );
        return $ret;
    }

    %p = ();
    $p{$DB_COL_DME_MACID} = $macid;
    if ( $self->get_coe_mac_exception( \%p ) ) {
        EventLog( EVENT_ERR, MYNAMELINE() . "Adding Duplicate MACID: $macid" );
        return $ret;
    }

    my $sql;

    $sql = "INSERT INTO $DB_TABLE_COE_MAC_EXCEPTION ( macid,ticketref,comment,created ) "
      . " VALUES  "
      . " ( $macid,'$ticketref','$comment',CURRENT_TIMESTAMP() )";

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    # if ($ret) {
    #     $self->EventDBLog( {
    #             $EVENT_PARM_PRIO  => EVENT_INFO,
    #             $EVENT_PARM_TYPE  => EVENT_MAC_ADD,
    #             $EVENT_PARM_DESC  => " $mac",
    #             $EVENT_PARM_MACID => $parm_ref->{$DB_COL_MAC_ID},
    #     } );
    # }

    $ret;
}

#-------------------------------------------------------
# add new MAC
#-------------------------------------------------------
sub add_mac($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_MAC_MAC} || $parm_ref->{$DB_COL_MAC_MAC} eq '' ) { confess; }
    my $mac = $parm_ref->{$DB_COL_MAC_MAC};
    my $sql;
    my $coe = 0;
    if ( defined $parm_ref->{$DB_COL_MAC_COE} && $parm_ref->{$DB_COL_MAC_COE} ) {
        $coe = 1;
    }

    # Groom MAC addresses to what we expect.
    $mac =~ s/-/:/;
    $mac =~ s/\./:/;
    $mac =~ tr/A-F/a-f/;

    if ( !_verify_MAC($mac) ) { confess; }

    $sql = "INSERT INTO $DB_TABLE_MAC ( mac,lastseen,laststatechange,coe ) "
      . " VALUES  "
      . " ( '$mac',CURRENT_TIMESTAMP(),CURRENT_TIMESTAMP(),$coe  )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_MAC_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_TYPE  => EVENT_MAC_ADD,
                $EVENT_PARM_DESC  => " $mac",
                $EVENT_PARM_MACID => $parm_ref->{$DB_COL_MAC_ID},
        } );
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_port2class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_P2C_SWPID} || ( !( isdigit $parm_ref->{$DB_COL_P2C_SWPID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_CLASSID} && ( !( isdigit $parm_ref->{$DB_COL_P2C_CLASSID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_VLANID}  && ( !( isdigit $parm_ref->{$DB_COL_P2C_VLANID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_VGID}    && ( !( isdigit $parm_ref->{$DB_COL_P2C_VGID} ) ) )    { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_CLASS_NAME} && ( $parm_ref->{$DB_COL_CLASS_NAME} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_NAME}  && ( $parm_ref->{$DB_COL_VLAN_NAME}  eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG_NAME}    && ( $parm_ref->{$DB_COL_VG_NAME}    eq '' ) ) { confess Dumper $parm_ref; }

    if ( !( defined $parm_ref->{$DB_COL_P2C_CLASSID} xor defined $parm_ref->{$DB_COL_CLASS_NAME} ) ) { confess Dumper $parm_ref; }

    #
    # These can be empty. The Class could be suppling the Deafult VG
    # if ( !( defined $parm_ref->{$DB_COL_P2C_VLANID} xor defined $parm_ref->{$DB_COL_VLAN_NAME} ) )   { confess Dumper $parm_ref; }
    # if ( !( defined $parm_ref->{$DB_COL_P2C_VGID} xor defined $parm_ref->{$DB_COL_VG_NAME} ) )       { confess Dumper $parm_ref; }
    #

    my $portid      = $parm_ref->{$DB_COL_P2C_SWPID};
    my $classid     = $parm_ref->{$DB_COL_P2C_CLASSID};
    my $vlanid      = ( $parm_ref->{$DB_COL_P2C_VLANID} ) ? $parm_ref->{$DB_COL_P2C_VLANID} : 0;
    my $vlangroupid = ( $parm_ref->{$DB_COL_P2C_VGID} ) ? $parm_ref->{$DB_COL_P2C_VGID} : 0;

    my $classname     = $parm_ref->{$DB_COL_CLASS_NAME};
    my $vlanname      = $parm_ref->{$DB_COL_VLAN_NAME};
    my $vlangroupname = $parm_ref->{$DB_COL_VG_NAME};

    if ( defined $classname ) {
        my %p;
        $p{$DB_COL_CLASS_NAME} = $classname;
        if ( !$self->get_class( \%p ) ) {
            $self->seterr( MYNAMELINE . " FAILED, no CLASS NAMED: $classname" );
            return 0;
        }
        $classid = $p{$DB_COL_CLASS_ID};
    }

    if ( defined $vlanname ) {
        my %p;
        $p{$DB_COL_VLAN_NAME} = $vlanname;
        if ( !$self->get_vlan( \%p ) ) {
            $self->seterr( MYNAMELINE . " FAILED, no VLAN NAMED: $vlanname" );
            return 0;
        }
        $vlanid = $p{$DB_COL_VLAN_ID};
    }

    if ( defined $vlangroupname ) {
        my %p;
        $p{$DB_COL_VG_NAME} = $vlangroupname;
        if ( !$self->get_vlangroup( \%p ) ) {
            $self->seterr( MYNAMELINE . " FAILED, no VLANGROUP NAMED: $vlangroupname" );
            return 0;
        }
        $vlanid = $p{$DB_COL_VG_ID};
    }

    my $sql = "INSERT INTO $DB_TABLE_PORT2CLASS ( switchportid, classid, vlanid, vlangroupid ) "
      . " VALUES ( $portid, $classid, $vlanid, $vlangroupid  ) ";

    if ( $self->sqldo($sql) ) {

        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_P2C_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        my $switchid   = 'x';
        my $switchname = 'x';
        my $portname   = 'x';
        my %p;
        if ( !defined $classname ) {
            %p = ();
            $p{$DB_COL_CLASS_ID} = $classid;
            if ( $self->get_class( \%p ) ) {
                $classname = $p{$DB_COL_CLASS_NAME};
            }
        }

        if ( !defined $vlanname ) {
            %p = ();
            $p{$DB_COL_VLAN_ID} = $vlanid;
            if ( $self->get_vlan( \%p ) ) {
                $vlanname = $p{$DB_COL_VLAN_NAME};
            }
        }

        if ( !defined $vlangroupname ) {
            %p = ();
            $p{$DB_COL_VG_ID} = $vlangroupid;
            if ( $self->get_vlangroup( \%p ) ) {
                $vlangroupname = $p{$DB_COL_VG_NAME};
            }
        }

        %p = ();
        $p{$DB_COL_SWP_ID} = $portid;
        if ( $self->get_switchport( \%p ) ) {
            $switchid = $p{$DB_COL_SWP_SWID};
            $portname = $p{$DB_COL_SWP_NAME};
        }

        %p = ();
        $p{$DB_COL_SW_ID} = $switchid;
        if ( $self->get_switch( \%p ) ) {
            $switchname = $p{$DB_COL_SW_NAME};
        }

        if ( !defined $vlanname && $vlanid ) {
            my %p;
            $p{$DB_COL_VLAN_ID} = $vlanid;
            if ( $self->get_vlan( \%p ) ) {
                $vlanname = $p{$DB_COL_VLAN_NAME};
            }
        }

        if ( !defined $vlangroupname && $vlangroupid ) {
            my %p;
            $p{$DB_COL_VG_ID} = $vlangroupid;
            if ( $self->get_vlangroup( \%p ) ) {
                $vlangroupname = $p{$DB_COL_VG_NAME};
            }
        }

        if ($ret) {
            $self->EventDBLog( {
                    $EVENT_PARM_PRIO    => EVENT_INFO,
                    $EVENT_PARM_TYPE    => EVENT_PORT2CLASS_ADD,
                    $EVENT_PARM_P2CID   => $parm_ref->{$DB_COL_P2C_ID},
                    $EVENT_PARM_SWID    => $switchid,
                    $EVENT_PARM_SWPID   => $portid,
                    $EVENT_PARM_CLASSID => $classid,
                    $EVENT_PARM_VLANID  => $vlanid,
                    $EVENT_PARM_VGID    => $vlangroupid,
                    $EVENT_PARM_DESC =>
                      "P2CID:"
                      . "[$parm_ref->{$DB_COL_P2C_ID}]"
                      . ", SWITCH:'$switchname'"
                      . "[$switchid], "
                      . "PORT:'$portname'"
                      . "[$portid], "
                      . "CLASS:'$classname'"
                      . "[$classid], "
                      . "VLAN:'$vlanname'"
                      . "[$vlanid], "
                      . "VG:'$vlangroupname'"
                      . "[$vlangroupid]",
            } );

        }

    }
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_mac2class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called: " . Dumper $parm_ref );

    eval {
        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_M2C_MACID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_MACID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_MAC_MAC} && ( $parm_ref->{$DB_COL_MAC_MAC} eq '' ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_CLASSID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_CLASSID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_CLASS_NAME} && ( $parm_ref->{$DB_COL_CLASS_NAME} eq '' ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_VLANID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_VLANID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VLAN_NAME} && ( $parm_ref->{$DB_COL_VLAN_NAME} eq '' ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_VGID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_VGID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_TEMP_NAME} && ( $parm_ref->{$DB_COL_TEMP_NAME} eq '' ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_TEMPID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_TEMPID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VG_NAME} && ( $parm_ref->{$DB_COL_VG_NAME} eq '' ) ) { confess Dumper $parm_ref; }

        # if ( defined $parm_ref->{$DB_COL_M2C_EXPIRE} && ( $parm_ref->{$DB_COL_M2C_EXPIRE} eq '' ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_PRI} && ( !( isdigit $parm_ref->{$DB_COL_M2C_PRI} ) ) ) { confess Dumper $parm_ref; }
        my $macid         = $parm_ref->{$DB_COL_M2C_MACID};
        my $classid       = $parm_ref->{$DB_COL_M2C_CLASSID};
        my $vlanid        = ( defined $parm_ref->{$DB_COL_M2C_VLANID} ) ? $parm_ref->{$DB_COL_M2C_VLANID} : 0;
        my $vlangroupid   = ( defined $parm_ref->{$DB_COL_M2C_VGID} ) ? $parm_ref->{$DB_COL_M2C_VGID} : 0;
        my $templateid    = ( defined $parm_ref->{$DB_COL_M2C_TEMPID} ) ? $parm_ref->{$DB_COL_M2C_TEMPID} : 0;
        my $expiretime    = ( defined $parm_ref->{$DB_COL_M2C_EXPIRE} ) ? $parm_ref->{$DB_COL_M2C_EXPIRE} : "0000-00-00 00:00:00";
        my $priority      = ( defined $parm_ref->{$DB_COL_M2C_PRI} ) ? $parm_ref->{$DB_COL_M2C_PRI} : 0;
        my $mac           = $parm_ref->{$DB_COL_MAC_MAC};
        my $classname     = $parm_ref->{$DB_COL_CLASS_NAME};
        my $vlanname      = $parm_ref->{$DB_COL_VLAN_NAME};
        my $vlangroupname = $parm_ref->{$DB_COL_VG_NAME};
        my $templatename  = $parm_ref->{$DB_COL_TEMP_NAME};
        my $comment       = $parm_ref->{$DB_COL_M2C_COM};

        if ( $expiretime eq '' ) {
            $expiretime = "0000-00-00 00:00:00";
        }

        if ( !( ( defined $classid ) xor( defined $classname ) ) ) { confess "Class ID or name required classid:'$classid', classname:'$classname'"; }

        # if ( !( (defined $vlanid ) xor ( defined $vlanname )) )   { confess "VLID:'$vlanid', VNAME:'$vlanname'\n" . Dumper $parm_ref; }
        # if ( !( (defined $vlangroupid )xor ( defined $vlangroupname )) )       { confess Dumper $parm_ref; }

        if ( defined $mac ) {
            my %p;
            p { $DB_COL_MAC_MAC };
            if ( !$self->get_mac( \%p ) ) {
                $self->seterr( MYNAMELINE . " FAILED, no MAC name : $mac" );
                return 0;
            }
            $macid = $p{$DB_COL_MAC_ID};
        }

        if ( defined $classname ) {
            my %p;
            p { $DB_COL_CLASS_NAME };
            if ( !$self->get_class( \%p ) ) {
                $self->seterr( MYNAMELINE . " FAILED, no CLASS NAMED: $classname" );
                return 0;
            }
            $classid = $p{$DB_COL_CLASS_ID};
        }

        if ( defined $vlanname ) {
            my %p;
            p { $DB_COL_VLAN_NAME };
            if ( !$self->get_vlan( \%p ) ) {
                $self->seterr( MYNAMELINE . " FAILED, no VLAN NAMED: $vlanname" );
                return 0;
            }
            $vlanid = $p{$DB_COL_VLAN_ID};
        }

        if ( defined $vlangroupname ) {
            my %p;
            p { $DB_COL_VG_NAME };
            if ( !$self->get_vlangroup( \%p ) ) {
                $self->seterr( MYNAMELINE . " FAILED, no VLANGROUP NAMED: $vlangroupname" );
                return 0;
            }
            $vlanid = $p{$DB_COL_VG_ID};
        }

        if ( defined $templatename ) {
            my %p;
            p { $DB_COL_TEMP_NAME };
            if ( !$self->get_template( \%p ) ) {
                $self->seterr( MYNAMELINE . " FAILED, no TEMPLATE NAMED: $templatename" );
                return 0;
            }
            $templateid = $p{$DB_COL_TEMP_ID};
        }

        if ( !defined $comment ) {
            $comment = '';
        }

        if ( $templateid eq '' ) {
            $templateid = 0;
        }

        if ( $vlangroupid eq '' ) {
            $vlangroupid = 0;
        }

        if ( $vlanid eq '' ) {
            $vlanid = 0;
        }

        if ( $priority eq '' ) {
            $priority = 0;
        }

        if ( $expiretime eq '' ) {
            $expiretime = 'NULL';
        }

        #
        # MACID & CLASSID required
        #
        if ( $macid < 1 ) {
            $self->seterr( MYNAMELINE . " FAILED, invalid macid: $macid" );
            return 0;
        }

        if ( $classid < 1 ) {
            $self->seterr( MYNAMELINE . " FAILED, invalid classid: $classid" );
            return 0;
        }

        # Make sure MAC is active
        if ( !$self->is_record_active( {
                    $DB_COL_MAC_ID => $macid,
                }, ) ) {
            $self->activate_record( {
                    $DB_COL_MAC_ID => $macid,
            }, );
        }

        my $sql = "INSERT INTO $DB_TABLE_MAC2CLASS ( macid, classid, vlanid, vlangroupid, templateid, expiretime, priority, comment ) "
          . " VALUES ( $macid, $classid, $vlanid, $vlangroupid, $templateid, '$expiretime', $priority, '$comment' ) ";

        if ( $self->sqldo($sql) ) {
            if ( $self->dbh->{'mysql_insertid'} ) {
                $parm_ref->{$DB_COL_M2C_ID} = $self->dbh->{'mysql_insertid'};
                $ret++;
            }
            else {
                EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            }
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        }

        if ($ret) {
            my %p         = ();
            my $mac       = 'x';
            my $class     = 'x';
            my $vlan      = 'x';
            my $vlangroup = 'x';

            %p = ();
            $p{$DB_COL_CLASS_ID} = $classid;
            if ( $self->get_class( \%p ) ) {
                $class = $p{$DB_COL_CLASS_NAME};
            }

            %p = ();
            $p{$DB_COL_VLAN_ID} = $vlanid;
            if ( $self->get_vlan( \%p ) ) {
                $vlan = $p{$DB_COL_VLAN_NAME};
            }

            %p = ();
            $p{$DB_COL_VG_ID} = $vlangroupid;
            if ( $self->get_vlangroup( \%p ) ) {
                $vlangroup = $p{$DB_COL_VG_NAME};
            }

            %p = ();
            $p{$DB_COL_MAC_ID} = $macid;
            if ( $self->get_mac( \%p ) ) {
                $mac = $p{$DB_COL_MAC_MAC};
            }

            if ($ret) {
                $self->EventDBLog( {
                        $EVENT_PARM_PRIO    => EVENT_INFO,
                        $EVENT_PARM_TYPE    => EVENT_MAC2CLASS_ADD,
                        $EVENT_PARM_M2CID   => $parm_ref->{$DB_COL_M2C_ID},
                        $EVENT_PARM_MACID   => $macid,
                        $EVENT_PARM_CLASSID => $classid,
                        $EVENT_PARM_VLANID  => $vlanid,
                        $EVENT_PARM_TEMPID  => $templateid,
                        $EVENT_PARM_VGID    => $vlangroupid,
                        $EVENT_PARM_DESC =>
                          "M2CID:"
                          . "[$parm_ref->{$DB_COL_M2C_ID}]"
                          . "MAC:'$mac'"
                          . "[$macid], "
                          . "CLASS:'$class'"
                          . "[$classid], "
                          . "VLAN:'$vlan'"
                          . "[$vlanid], "
                          . "VLANGROUP:'$vlangroup'"
                          . "[$vlangroupid] "
                          . "PRI: $priority",
                } );
            }

        }
    };
    LOGEVALFAIL() if ($@);

    $ret;
}

#-------------------------------------------------------
# Function Can FAIL, it is not critical to the operation of Authentication, Just notate the error in the logs
#-------------------------------------------------------
sub add_radiusaudit($$) {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_RA_MACID} || ( !( isdigit( $parm_ref->{$DB_COL_RA_MACID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_RA_SWPID} || ( !( isdigit( $parm_ref->{$DB_COL_RA_SWPID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_RA_TYPE} || ( $parm_ref->{$DB_COL_RA_TYPE} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTOUT} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_PACIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_PACOUT} ) ) ) { confess Dumper $parm_ref; }

    #    if ( defined $parm_ref->{$DB_COL_RA_DEFVGID} && ( !( isdigit( $parm_ref->{$DB_COL_RA_DEFVGID} ) ) ) ) { confess Dumper $parm_ref; }
    #    if ( defined $parm_ref->{$DB_COL_RA_VGID}    && ( !( isdigit( $parm_ref->{$DB_COL_RA_VGID} ) ) ) )    { confess Dumper $parm_ref; }
    #    if ( defined $parm_ref->{$DB_COL_RA_VLANID}  && ( !( isdigit( $parm_ref->{$DB_COL_RA_VLANID} ) ) ) )  { confess Dumper $parm_ref; }

    my $macid        = $parm_ref->{$DB_COL_RA_MACID};
    my $switchportid = $parm_ref->{$DB_COL_RA_SWPID};
    my $type         = $parm_ref->{$DB_COL_RA_TYPE};
    my $cause        = ( $parm_ref->{$DB_COL_RA_CAUSE} ) ? $parm_ref->{$DB_COL_RA_CAUSE} : '';
    my $octetsin     = ( $parm_ref->{$DB_COL_RA_OCTIN} ) ? $parm_ref->{$DB_COL_RA_OCTIN} : 0;
    my $octetsout    = ( $parm_ref->{$DB_COL_RA_OCTOUT} ) ? $parm_ref->{$DB_COL_RA_OCTOUT} : 0;
    my $packetsin    = ( $parm_ref->{$DB_COL_RA_PACIN} ) ? $parm_ref->{$DB_COL_RA_PACIN} : 0;
    my $packetsout   = ( $parm_ref->{$DB_COL_RA_PACOUT} ) ? $parm_ref->{$DB_COL_RA_PACOUT} : 0;
    my $hostname     = ( defined $parm_ref->{$DB_COL_RA_AUDIT_SRV} ) ? "'" . $parm_ref->{$DB_COL_RA_AUDIT_SRV} . "'" : "'NULL'";

    #    my $defaultvgid  = ( defined $parm_ref->{$DB_COL_RA_DEFVGID} ) ? $parm_ref->{$DB_COL_RA_DEFVGID} : "'NULL'";
    #    my $vgid         = ( defined $parm_ref->{$DB_COL_RA_VGID} ) ? $parm_ref->{$DB_COL_RA_VGID} : "'NULL'";
    #    my $vlanid       = ( defined $parm_ref->{$DB_COL_RA_VLANID} ) ? $parm_ref->{$DB_COL_RA_VLANID} : "'NULL'";
    my $sql;

    $sql = "INSERT INTO $DB_TABLE_RADIUSAUDIT "

      #      . " ( macid, switchportid, auditserver, type, cause, octetsin, octetsout, packetsin, packetsout, defvgid, vgid, vlanid ) "
      . " ( macid, switchportid, auditserver, type, cause, octetsin, octetsout, packetsin, packetsout ) "

      #      . " VALUES ( $macid, $switchportid, $hostname, '$type', '$cause', $octetsin, $octetsout, $packetsin, $packetsout, $defaultvgid, $vgid, $vlanid )";
      . " VALUES ( $macid, $switchportid, $hostname, '$type', '$cause', $octetsin, $octetsout, $packetsin, $packetsout )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $ret = $self->dbh->{'mysql_insertid'};
            $parm_ref->{$DB_COL_RA_ID} = $ret;
            $ret++;

            my %p = ();
            $p{$DB_TABLE_NAME}    = $DB_TABLE_MAC;
            $p{$DB_KEY_NAME}      = $DB_KEY_MACID;
            $p{$DB_KEY_VALUE}     = $macid;
            $p{'UPDATE_lastseen'} = NACMisc::get_current_timestamp();
            if ( !$self->update_record( \%p ) ) {
                EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot update MAC lastseen" );
            }
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    $ret;
}

#-------------------------------------------------------
#
# WORK HERE NEEDED
# Self populate LOCID with CIDR table if LOCID is not passed in.
#-------------------------------------------------------
sub add_switch($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_SW_NAME} || $parm_ref->{$DB_COL_SW_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_SW_LOCID} || ( !( isdigit( $parm_ref->{$DB_COL_SW_LOCID} ) ) ) ) { confess Dumper $parm_ref; }

    # if ( !defined $parm_ref->{$DB_COL_SW_DESC} || $parm_ref->{$DB_COL_SW_DESC} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_SW_IP} || $parm_ref->{$DB_COL_SW_IP} eq '' ) { confess Dumper $parm_ref; }
    my $name  = $parm_ref->{$DB_COL_SW_NAME};
    my $locid = $parm_ref->{$DB_COL_SW_LOCID};
    my $desc  = ( $parm_ref->{$DB_COL_SW_DESC} ) ? $parm_ref->{$DB_COL_SW_DESC} : '';
    my $ip    = $parm_ref->{$DB_COL_SW_IP};
    my $location;
    my $sql;

    $name =~ tr/A-Z/a-z/;

    $sql = "INSERT INTO $DB_TABLE_SWITCH ( switchname,locationid,switchdescription,ip ) "
      . " VALUES ( '$name', $locid, '" . $desc . "', '$ip' )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $ret = $self->dbh->{'mysql_insertid'};
            $parm_ref->{$DB_COL_SW_ID} = $ret;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    #
    # Event Logging
    #
    my %p = ();
    $p{$DB_COL_LOC_ID} = $locid;
    if ( $self->get_location( \%p ) ) {
        $location = $p{$DB_COL_LOC_SHORTNAME};
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_TYPE  => EVENT_SWITCH_ADD,
                $EVENT_PARM_SWID  => $ret,
                $EVENT_PARM_IP    => $ip,
                $EVENT_PARM_LOCID => $locid,
                $EVENT_PARM_DESC  => "$name" . "[$ret], IP:'$ip', LOC:'$location'[$locid]",
        } );

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_switch2vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_SW2V_SWID}   || ( !( isdigit( $parm_ref->{$DB_COL_SW2V_SWID} ) ) ) )   { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_SW2V_VLANID} || ( !( isdigit( $parm_ref->{$DB_COL_SW2V_VLANID} ) ) ) ) { confess Dumper $parm_ref; }
    my $switchid = $parm_ref->{$DB_COL_SW2V_SWID};
    my $vlanid   = $parm_ref->{$DB_COL_SW2V_VLANID};
    my $sql;

    $sql = "INSERT INTO $DB_TABLE_SWITCH2VLAN ( switchid, vlanid ) "
      . " VALUES ( $switchid, $vlanid )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_SW2V_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    #
    # Event Logging
    #
    if ($ret) {
        my $switchname = '';
        my $vlanname   = '';
        my %p          = ();
        $p{$DB_COL_VLAN_ID} = $vlanid;
        if ( $self->get_vlan( \%p ) ) {
            $vlanname = $p{$DB_COL_VLAN_NAME}
        }

        %p = ();
        $p{$DB_COL_SW_ID} = $switchid;
        if ( $self->get_switch( \%p ) ) {
            $switchname = $p{$DB_COL_SW_NAME}
        }

        $self->EventDBLog( {
                $EVENT_PARM_PRIO   => LOG_INFO,
                $EVENT_PARM_TYPE   => EVENT_SWITCH2VLAN_ADD,
                $EVENT_PARM_SWID   => $switchid,
                $EVENT_PARM_VLANID => $vlanid,
                $EVENT_PARM_DESC   => "SWITCH:'$switchname'[$switchid], VLAN:'$vlanname'[$vlanid]",
        }, );

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_switchport($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_SWP_NAME} || $parm_ref->{$DB_COL_SWP_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWP_DESC} && $parm_ref->{$DB_COL_SWP_DESC} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_SWP_SWID} || ( !( isdigit( $parm_ref->{$DB_COL_SWP_SWID} ) ) ) ) { confess Dumper $parm_ref; }
    my $portname = $parm_ref->{$DB_COL_SWP_NAME};
    my $portdesc = $parm_ref->{$DB_COL_SWP_DESC};
    my $switchid = $parm_ref->{$DB_COL_SWP_SWID};
    my $sql;

    $portname =~ tr/A-Z/a-z/;

    $sql = "INSERT INTO $DB_TABLE_SWITCHPORT ( switchid,portname,portdescription ) "
      . " VALUES ( $switchid, '$portname', '$portdesc' )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_SWP_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    #
    # Event Logging
    #
    if ($ret) {
        my $switchname = '';
        my %p          = ();
        $p{$DB_COL_SW_ID} = $switchid;
        if ( $self->get_switch( \%p ) ) {
            $switchname = $p{$DB_COL_SW_NAME}
        }

        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_TYPE  => EVENT_SWITCHPORT_ADD,
                $EVENT_PARM_SWPID => $parm_ref->{$DB_COL_SWP_ID},
                $EVENT_PARM_SWID  => $switchid,
                $EVENT_PARM_DESC  => "SWITCH:'$switchname'[$switchid], PORT:'$portname'[" . $parm_ref->{$DB_COL_SWP_ID} . "]",
        } );

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_SWPS_SWPID} || ( !( isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID} && ( !( abs( isdigit( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) ) ) { confess Dumper $parm_ref; }
###    #if ( defined $parm_ref->{$DB_COL_SWPS_VMACID} && ( !( abs( isdigit( $parm_ref->{$DB_COL_SWPS_VMACID} ) ) ) ) ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_SWPS_LASTUPDATE} ) {
        EventLog( EVENT_WARN, MYNAMELINE() . " ignoring LASTUPDATE " );
    }
    if ( defined $parm_ref->{$DB_COL_SWPS_STATEUPDATE} ) {
        EventLog( EVENT_WARN, MYNAMELINE() . " ignoring STATEUPDATE " );
    }

    my $swpid        = $parm_ref->{$DB_COL_SWPS_SWPID};
    my $macid        = $parm_ref->{$DB_COL_SWPS_MACID};
    my $ip           = $parm_ref->{$DB_COL_SWPS_IP};
    my $hostname     = $parm_ref->{$DB_COL_SWPS_HOSTNAME};
    my $classid      = $parm_ref->{$DB_COL_SWPS_CLASSID};
    my $vlangroupid  = $parm_ref->{$DB_COL_SWPS_VGID};
    my $vlanid       = $parm_ref->{$DB_COL_SWPS_VLANID};
    my $tempid       = $parm_ref->{$DB_COL_SWPS_TEMPID};
    my $vmacid       = $parm_ref->{$DB_COL_SWPS_VMACID};
    my $vip          = $parm_ref->{$DB_COL_SWPS_VIP};
    my $vhostname    = $parm_ref->{$DB_COL_SWPS_VHOSTNAME};
    my $vclassid     = $parm_ref->{$DB_COL_SWPS_VCLASSID};
    my $vvlangroupid = $parm_ref->{$DB_COL_SWPS_VVGID};
    my $vvlanid      = $parm_ref->{$DB_COL_SWPS_VVLANID};
    my $vtempid      = $parm_ref->{$DB_COL_SWPS_VTEMPID};
    my $sql;

    if ( !defined $macid ) {
        $macid = -1;
    }

    if ( !defined $vmacid ) {
        $vmacid = -1;
    }

    if ( !defined $classid ) {
        $classid = 0;
    }

    if ( !defined $vclassid ) {
        $vclassid = 0;
    }

    if ( !defined $vlanid ) {
        $vlanid = 0;
    }

    if ( !defined $vvlanid ) {
        $vvlanid = 0;
    }

    if ( !defined $vlangroupid ) {
        $vlangroupid = 0;
    }

    if ( !defined $vvlangroupid ) {
        $vvlangroupid = 0;
    }

    if ( !defined $tempid ) {
        $tempid = 0;
    }

    if ( !defined $vtempid ) {
        $vtempid = 0;
    }

    if ( ( !defined $hostname ) || ( $hostname eq '' ) ) {
        $hostname = NULL;
    }
    else {
        $hostname =~ tr/A-Z/a-z/;
    }

    if ( ( !defined $vhostname ) || ( $vhostname eq '' ) ) {
        $vhostname = NULL;
    }
    else {
        $vhostname =~ tr/A-Z/a-z/;
    }

    $sql = "INSERT INTO $DB_TABLE_SWITCHPORTSTATE ( "
      . ' switchportid, lastupdate, stateupdate, '
      . ' macid, classid, templateid, vlangroupid, vlanid'
      . ( ( defined $ip )       ? ', ip'       : '' )
      . ( ( defined $hostname ) ? ', hostname' : '' )
      . ', vmacid, vclassid, vtemplateid, vvlangroupid, vvlanid'
      . ( ( defined $vip )       ? ', vip'       : '' )
      . ( ( defined $vhostname ) ? ', vhostname' : '' )
      . " ) "
      . " VALUES ( $swpid, CURRENT_TIME(), CURRENT_TIME(), "
      . " $macid, $classid, $tempid, $vlangroupid, $vlanid "
      . ( ( defined $ip )       ? ", '$ip'"       : '' )
      . ( ( defined $hostname ) ? ", '$hostname'" : '' )
      . ", $vmacid, $vclassid, $vtempid, $vvlangroupid, $vvlanid "
      . ( ( defined $vip )       ? ", '$vip'"       : '' )
      . ( ( defined $vhostname ) ? ", '$vhostname'" : '' )
      . ' )';

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        $self->EventDBLog($parm_ref);
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_VLAN_LOCID} || ( !( isdigit $parm_ref->{$DB_COL_VLAN_LOCID} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_VLAN_VLAN}  || ( !( isdigit $parm_ref->{$DB_COL_VLAN_VLAN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_COE} && !isdigit( $parm_ref->{$DB_COL_VLAN_COE} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_TYPE} && $parm_ref->{$DB_COL_VLAN_VLAN} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_CIDR} && $parm_ref->{$DB_COL_VLAN_CIDR} eq '' ) { confess Dumper $parm_ref; }

    my $nacip = ( defined $parm_ref->{$DB_COL_VLAN_NACIP} ) ? $parm_ref->{$DB_COL_VLAN_NACIP} : '';
    my $coe   = ( defined $parm_ref->{$DB_COL_VLAN_COE} && $parm_ref->{$DB_COL_VLAN_COE} ) ? 1 : 0;
    my $locid = $parm_ref->{$DB_COL_VLAN_LOCID};
    my $vlan  = $parm_ref->{$DB_COL_VLAN_VLAN};
    my $type  = $parm_ref->{$DB_COL_VLAN_TYPE};
    my $cidr  = $parm_ref->{$DB_COL_VLAN_CIDR};
    my $location;
    my $vlanid;
    my $name;

    #
    # Create the Name Field if not specified
    #
    if ( defined $parm_ref->{$DB_COL_VLAN_NAME} ) {
        $name = $parm_ref->{$DB_COL_VLAN_NAME};
    }
    else {
        my %loc_parm = ();
        $loc_parm{$DB_COL_LOC_ID} = $locid;
        if ( !( $self->get_location( \%loc_parm ) ) ) {
            EventLog( EVENT_ERR, MYNAMELINE() . " Addming non existing LOCID: $locid to VLAN table" );
            $name = '';
        }
        else {
            my $site = $loc_parm{$DB_COL_LOC_SITE};
            my $bldg = $loc_parm{$DB_COL_LOC_BLDG};
            $name = $site . '-' . $bldg . '-' . sprintf( "%04d", $vlan ) . '-' . $type;
        }
    }

    my $sql;

    $name =~ s/\'//g;
    $name =~ s/^ //g;
    $name =~ s/^-//g;
    $name =~ s/^ //g;

    $sql = "INSERT INTO $DB_TABLE_VLAN ( locationid, vlan, type, cidr, coe"
      . ( ( $name  ne '' ) ? ", vlanname" : "" )
      . ( ( $nacip ne '' ) ? ", nacip"    : "" )
      . " ) VALUES ( $locid, $vlan, '$type', '$cidr', $coe"
      . ( ( $name  ne '' ) ? ", '$name'"  : "" )
      . ( ( $nacip ne '' ) ? ", '$nacip'" : "" )
      . " )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $vlanid = $parm_ref->{$DB_COL_VLAN_ID} = $self->dbh->{'mysql_insertid'};
            $name = $parm_ref->{$DB_COL_VLAN_NAME};
            $ret++;
        }
        else {
            my $msg = "Cannot assertain new INSERTed ID";
            $self->seterr($msg);
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " $msg" );
            $self->seterr( MYNAMELINE() . " $msg" );
        }
    }
    else {
        my $msg = "sqldo() FAILED:" . $sql;
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " $msg" );
        $self->seterr( MYNAMELINE() . " $msg" );
    }

    my %p = ();
    $p{$DB_COL_LOC_ID} = $locid;
    if ( $self->get_location( \%p ) ) {
        $location = $p{$DB_COL_LOC_SHORTNAME};
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO   => EVENT_INFO,
                $EVENT_PARM_TYPE   => EVENT_VLAN_ADD,
                $EVENT_PARM_VLANID => $vlanid,
                $EVENT_PARM_DESC =>
                  "'$name'"
                  . "[$vlanid], "
                  . "LOC:'$location'"
                  . "[$locid], "
                  . "VLAN:'$vlan', "
                  . "TYPE:'$type' "
                  . "CIDR:'$cidr' "
                  . "NACIP:'$nacip' ",
        } );

    }

    $ret;
}

#-------------------------------------------------------
sub update_vlan_coe_true($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my %parm     = ();

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_VLAN_ID} ) || ( !( isdigit $parm_ref->{$DB_COL_VLAN_ID} ) ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " VLANID:" . $parm_ref->{$DB_COL_VLAN_ID} );

    $parm{$DB_COL_VLAN_ID}  = $parm_ref->{$DB_COL_VLAN_ID};
    $parm{$DB_COL_VLAN_COE} = 1;
    $ret                    = $self->update_vlan_coe( \%parm );
    $ret;
}

#-------------------------------------------------------
sub update_vlan_coe_false($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my %parm     = ();

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_VLAN_ID} ) || ( !( isdigit $parm_ref->{$DB_COL_VLAN_ID} ) ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " VLANID:" . $parm_ref->{$DB_COL_VLAN_ID} );

    $parm{$DB_COL_VLAN_ID}  = $parm_ref->{$DB_COL_VLAN_ID};
    $parm{$DB_COL_VLAN_COE} = 0;
    $ret                    = $self->update_vlan_coe( \%parm );
    $ret;
}

#-------------------------------------------------------
sub update_vlan_coe($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $coe      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_VLAN_ID} )  || ( !( isdigit $parm_ref->{$DB_COL_VLAN_ID} ) ) )  { confess Dumper $parm_ref; }
    if ( ( !defined $parm_ref->{$DB_COL_VLAN_COE} ) || ( !( isdigit $parm_ref->{$DB_COL_VLAN_COE} ) ) ) { confess Dumper $parm_ref; }

    $coe = ( $parm_ref->{$DB_COL_VLAN_COE} ) ? 1 : 0;

    my %parm = ();
    $parm{$DB_TABLE_NAME} = $DB_TABLE_VLAN;
    $parm{$DB_KEY_NAME}   = $DB_KEY_VLANID;
    $parm{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_VLAN_ID};
    $parm{'UPDATE_coe'}   = $coe;
    $ret                  = $self->update_record( \%parm );

    $ret;
}

#-------------------------------------------------------
# add new TEMPLATE
#-------------------------------------------------------
sub add_template($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_TEMP_NAME} || $parm_ref->{$DB_COL_TEMP_NAME} eq '' ) { confess Dumper $parm_ref; }

    my $name    = $parm_ref->{$DB_COL_TEMP_NAME};
    my $desc    = ( $parm_ref->{$DB_COL_TEMP_DESC} ) ? $parm_ref->{$DB_COL_TEMP_DESC} : '';
    my $active  = ( $parm_ref->{$DB_COL_TEMP_ACT} ) ? $parm_ref->{$DB_COL_TEMP_ACT} : 1;      # Default is active
    my $comment = ( $parm_ref->{$DB_COL_TEMP_COM} ) ? $parm_ref->{$DB_COL_TEMP_COM} : '';
    my $sql;

    $sql = "INSERT INTO $DB_TABLE_TEMPLATE ( templatename,templatedescription,active,comment ) "
      . " VALUES  "
      . " ( '$name','$desc',$active,'$comment' )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_TEMP_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO   => EVENT_INFO,
                $EVENT_PARM_TYPE   => EVENT_TEMPLATE_ADD,
                $EVENT_PARM_TEMPID => $parm_ref->{$DB_COL_TEMP_ID},
                $EVENT_PARM_DESC   => "TEMPLATE: $name [" . $parm_ref->{$DB_COL_TEMP_ID} . "]",
        } );

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_template2vlangroup($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_TEMP2VG_TEMPID} || ( !( isdigit $parm_ref->{$DB_COL_TEMP2VG_TEMPID} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_TEMP2VG_VGID}   || ( !( isdigit $parm_ref->{$DB_COL_TEMP2VG_VGID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP2VG_PRI} && ( !( isdigit $parm_ref->{$DB_COL_TEMP2VG_PRI} ) ) ) { confess Dumper $parm_ref; }
    my $templateid  = $parm_ref->{$DB_COL_TEMP2VG_TEMPID};
    my $vlangroupid = $parm_ref->{$DB_COL_TEMP2VG_VGID};
    my $priority    = ( defined $parm_ref->{$DB_COL_TEMP2VG_PRI} ) ? $parm_ref->{$DB_COL_TEMP2VG_PRI} : 0;

    my $sql = "INSERT INTO $DB_TABLE_TEMPLATE2VLANGROUP ( templateid, vlangroupid, priority ) "
      . " VALUES ( $templateid, $vlangroupid, $priority ) ";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_TEMP2VG_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        my $templatename  = '';
        my $vlangroupname = '';
        my %p             = ();

        %p = ();
        $p{$DB_COL_TEMP_ID} = $templateid;
        if ( $self->get_template( \%p ) ) {
            $templatename = $p{$DB_COL_TEMP_NAME}
        }

        %p = ();
        $p{$DB_COL_VG_ID} = $vlangroupid;
        if ( $self->get_vlangroup( \%p ) ) {
            $vlangroupname = $p{$DB_COL_VG_NAME}
        }

        $self->EventDBLog( {
                $EVENT_PARM_PRIO      => EVENT_INFO,
                $EVENT_PARM_TYPE      => EVENT_TEMPLATE2VLANGROUP_ADD,
                $EVENT_PARM_TEMP2VGID => $parm_ref->{$DB_COL_TEMP2VG_ID},
                $EVENT_PARM_TEMPID    => $templateid,
                $EVENT_PARM_VGID      => $vlangroupid,
                $EVENT_PARM_DESC      => "Priority:$priority",
        } );

    }

    $ret;
}

#-------------------------------------------------------
# add new VLANGROUP
#-------------------------------------------------------
sub add_vlangroup($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_VG_NAME} || $parm_ref->{$DB_COL_VG_NAME} eq '' ) { confess Dumper $parm_ref; }

    my $name    = $parm_ref->{$DB_COL_VG_NAME};
    my $desc    = ( $parm_ref->{$DB_COL_VG_DESC} ) ? $parm_ref->{$DB_COL_VG_DESC} : '';
    my $active  = ( $parm_ref->{$DB_COL_VG_ACT} ) ? $parm_ref->{$DB_COL_VG_ACT} : 1;      # Default is active
    my $comment = ( $parm_ref->{$DB_COL_VG_COM} ) ? $parm_ref->{$DB_COL_VG_COM} : '';
    my $sql;

    $sql = "INSERT INTO $DB_TABLE_VLANGROUP ( vlangroupname,vlangroupdescription,active,comment ) "
      . " VALUES  "
      . " ( '$name','$desc',$active,'$comment' )";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_VG_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        $self->EventDBLog( {
                $EVENT_PARM_PRIO => EVENT_INFO,
                $EVENT_PARM_TYPE => EVENT_VLANGROUP_ADD,
                $EVENT_PARM_VGID => $parm_ref->{$DB_COL_VG_ID},
                $EVENT_PARM_DESC =>
                  "$name"
                  . "[" . $parm_ref->{$DB_COL_VG_ID} . "]",
        } );

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_vlangroup2vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_VG2V_VLANID} || ( !( isdigit $parm_ref->{$DB_COL_VG2V_VLANID} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_VG2V_VGID}   || ( !( isdigit $parm_ref->{$DB_COL_VG2V_VGID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG2V_PRI} && ( !( isdigit $parm_ref->{$DB_COL_VG2V_PRI} ) ) ) { confess Dumper $parm_ref; }
    my $vlanid      = $parm_ref->{$DB_COL_VG2V_VLANID};
    my $vlangroupid = $parm_ref->{$DB_COL_VG2V_VGID};
    my $priority    = ( defined $parm_ref->{$DB_COL_VG2V_PRI} ) ? $parm_ref->{$DB_COL_VG2V_PRI} : 0;

    my $sql = "INSERT INTO $DB_TABLE_VLANGROUP2VLAN ( vlanid, vlangroupid, priority ) "
      . " VALUES ( $vlanid, $vlangroupid, $priority ) ";

    if ( $self->sqldo($sql) ) {
        if ( $self->dbh->{'mysql_insertid'} ) {
            $parm_ref->{$DB_COL_VG2V_ID} = $self->dbh->{'mysql_insertid'};
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    if ($ret) {
        my $vlanname;
        my $vlangroupname;
        my %p = ();

        %p = ();
        $p{$DB_COL_VG_ID} = $vlangroupid;
        if ( $self->get_vlangroup( \%p ) ) {
            $vlangroupname = $p{$DB_COL_VG_NAME}
        }

        %p = ();
        $p{$DB_COL_VLAN_ID} = $vlanid;
        if ( $self->get_vlan( \%p ) ) {
            $vlanname = $p{$DB_COL_VLAN_NAME}
        }

        $self->EventDBLog( {
                $EVENT_PARM_PRIO   => EVENT_INFO,
                $EVENT_PARM_TYPE   => EVENT_VLANGROUP2VLAN_ADD,
                $EVENT_PARM_VG2VID => $parm_ref->{$DB_COL_VG2V_ID},
                $EVENT_PARM_VGID   => $vlangroupid,
                $EVENT_PARM_VLANID => $vlanid,
                $EVENT_PARM_DESC =>
                  "VLANGROUPID:"
                  . "[" . $parm_ref->{$DB_COL_VG2V_ID} . "] "
                  . "VLANGROUP: $vlangroupname"
                  . "[$vlangroupid] "
                  . "VLAN: $vlanname"
                  . "[$vlanid] "
                  . "PRIORITY: $priority",
        } );

    }

    $ret;
}

#-------------------------------------------------------
#
# Get MACID first
# Get Magicport entries
# Is it ADD or REPLACE
#	REPLACE: Remove M2C entries
#
# Add Magic entries to M2C table
#
#-------------------------------------------------------
sub check_magic_port($$) {
    my $self       = shift;
    my $swpid      = shift;
    my $macid      = shift;
    my $swid       = 0;
    my $ret        = 0;
    my $swpname    = 'unknown';
    my $swname     = 'unknown';
    my $type       = NULL;
    my %magic_parm = ();
    my %new_magic  = ();
    my %mac_parm   = ();
    my %m2c_parm   = ();
    my %m2c        = ();
    my %swp_parm   = ();
    my %swps_parm  = ();
    my %sw_parm    = ();
    my $m2c_count  = 0;
    my $comment    = 'Added by MAGICPORT ';

    $self->reseterr;

    if ( !defined $swpid || ( !isdigit($swpid) ) ) { confess Dumper $swpid; }
    if ( !defined $macid || ( !isdigit($macid) ) ) { confess Dumper $macid; }

    $mac_parm{$DB_COL_MAC_ID} = $macid;
    if ( !$self->get_mac( \%mac_parm ) ) {
        return $ret;
    }

    $magic_parm{$DB_COL_MAGIC_SWPID} = $swpid;
    $magic_parm{$HASH_REF}           = \%new_magic;
    if ( !$self->get_magicport( \%magic_parm ) ) {
        return $ret;
    }

    #
    # Check to see if MAC is already online and active
    # Only Magicport the MAC if it is just coming online
    #
    $swps_parm{$DB_COL_SWPS_MACID} = $macid;
    if ( $self->get_switchportstate( \%swps_parm ) ) {
        EventLog( EVENT_INFO, MYNAMELINE() . "SKIP MAGIC PORT MACID: $macid already online in SWPID:" . $swps_parm{$DB_COL_SWPS_SWPID} );
        return $ret;
    }

    $swp_parm{$DB_COL_SWP_ID} = $swpid;
    if ( $self->get_switchport( \%swp_parm ) ) {
        $swpname                = $swp_parm{$DB_COL_SWP_NAME};
        $swid                   = $swp_parm{$DB_COL_SWP_SWID};
        $sw_parm{$DB_COL_SW_ID} = $swid;
        if ( $self->get_switch( \%sw_parm ) ) {
            $swname = $sw_parm{$DB_COL_SW_NAME};
        }
        else {
            $self->EventDBLog( {
                    $EVENT_PARM_PRIO  => EVENT_ERR,
                    $EVENT_PARM_TYPE  => EVENT_MAGIC_PORT,
                    $EVENT_PARM_MACID => $macid,
                    $EVENT_PARM_SWPID => $swpid,
                    $EVENT_PARM_SWID  => $swid,
                    $EVENT_PARM_DESC  => "Failed to get switch",
            } );
            return $ret;
        }
    }

    $comment .= "SW:$swname PORT:$swpname";

    $self->EventDBLog( {
            $EVENT_PARM_PRIO  => EVENT_INFO,
            $EVENT_PARM_TYPE  => EVENT_MAGIC_PORT,
            $EVENT_PARM_MACID => $macid,
            $EVENT_PARM_SWPID => $swpid,
            $EVENT_PARM_SWID  => $swid,
            $EVENT_PARM_DESC  => $comment,
    } );

    my $magickey = ( keys(%new_magic) )[0];

    #
    # Work Needed Here
    # Check to see if the new settings are different then the old
    #

    # Add or replace? All of the records should be the same type
    if ( $new_magic{$magickey}->{$DB_COL_MAGIC_TYPE} eq $MAGICPORT_REPLACE ) {
        $type = $MAGICPORT_REPLACE;
        my %parm = ();

        $parm{$DB_COL_M2C_MACID} = $macid;
        if ( $self->get_mac2class( \%parm ) ) {

            # Replace, so remove existing M2C Records
            my %rm_parm = ();
            $rm_parm{$DB_COL_M2C_MACID} = $macid;
            if ( !$self->remove_mac2class( \%rm_parm ) ) {
                $self->EventDBLog( {
                        $EVENT_PARM_PRIO  => EVENT_ERR,
                        $EVENT_PARM_TYPE  => EVENT_MAGIC_PORT,
                        $EVENT_PARM_MACID => $macid,
                        $EVENT_PARM_SWPID => $swpid,
                        $EVENT_PARM_DESC  => "Failed to remove mac2class settings for MAGIC_PORT operation",
                } );
                confess "Failed to remove MAC2CLASS records";
            }
        }
    }
    else {
        $type = $MAGICPORT_ADD;
    }

  LOOP: foreach my $magicid ( keys(%new_magic) ) {
        my $classid = $new_magic{$magicid}->{$DB_COL_MAGIC_CLASSID};
        my $tempid  = $new_magic{$magicid}->{$DB_COL_MAGIC_TEMPID};
        my $vgid    = $new_magic{$magicid}->{$DB_COL_MAGIC_VGID};
        my $vlanid  = $new_magic{$magicid}->{$DB_COL_MAGIC_VLANID};
        my %parm    = ();
        my %m2c     = ();
        my %newm2c  = ();
        my $pri     = 0;

        if ( !defined $classid ) {
            confess 'magicID:' . $magicid . ' ' . ( Dumper \%new_magic );
        }
        if ( !defined $tempid ) {
            $tempid = 0;
        }
        if ( !defined $vgid ) {
            $vgid = 0;
        }
        if ( !defined $vlanid ) {
            $vlanid = 0;
        }

        # If add search for the record, and highest priority
        $pri                     = 0;
        $parm{$HASH_REF}         = \%m2c;
        $parm{$DB_COL_M2C_MACID} = $macid;
        if ( $self->get_mac2class( \%parm ) ) {

            # Append it to the priority list
            foreach my $id ( keys(%m2c) ) {
                my $p = $m2c{$id}->{$DB_COL_M2C_PRI};

                if ( $pri <= $p ) {
                    $pri = $p + 1;
                }

                if ( $classid == $m2c{$id}->{$DB_COL_M2C_CLASSID} ) {
                    if ($tempid) {
                        if ( $tempid == $m2c{$id}->{$DB_COL_M2C_TEMPID} ) {
                            print "SKIP - TEMP DUPLICATE " . Dumper $m2c{$id};
                            next LOOP;
                        }
                    }
                    if ($vgid) {
                        if ( $vgid == $m2c{$id}->{$DB_COL_M2C_VGID} ) {
                            print "SKIP - VGID DUPLICATE " . Dumper $m2c{$id};
                            next LOOP;
                        }
                    }
                    if ($vlanid) {
                        if ( $vlanid == $m2c{$id}->{$DB_COL_M2C_VLANID} ) {
                            print "SKIP - VLANID DUPLICATE " . Dumper $m2c{$id};
                            next LOOP;
                        }
                    }
                }
            }
        }

        $newm2c{$DB_COL_M2C_MACID}   = $macid;
        $newm2c{$DB_COL_M2C_CLASSID} = $classid;
        $newm2c{$DB_COL_M2C_TEMPID}  = $tempid;
        $newm2c{$DB_COL_M2C_VGID}    = $vgid;
        $newm2c{$DB_COL_M2C_VLANID}  = $vlanid;
        $newm2c{$DB_COL_M2C_PRI}     = $pri;
        $newm2c{$DB_COL_M2C_COM}     = $comment;

        # print "ADDING " . Dumper \%newm2c;

        if ( !$self->add_mac2class( \%newm2c ) ) {
            $self->EventDBLog( {
                    $EVENT_PARM_PRIO    => EVENT_ERR,
                    $EVENT_PARM_TYPE    => EVENT_MAGIC_PORT,
                    $EVENT_PARM_MACID   => $macid,
                    $EVENT_PARM_SWPID   => $swpid,
                    $EVENT_PARM_SWID    => $swid,
                    $EVENT_PARM_CLASSID => $classid,
                    $EVENT_PARM_TEMPID  => $tempid,
                    $EVENT_PARM_VGID    => $vgid,
                    $EVENT_PARM_VLANID  => $vlanid,
                    $EVENT_PARM_MAGICID => $magicid,
                    $EVENT_PARM_DESC    => 'Failed to add MAGIC Record',
            } );
        }
        else {
            $self->EventDBLog( {
                    $EVENT_PARM_PRIO    => EVENT_INFO,
                    $EVENT_PARM_TYPE    => EVENT_MAGIC_PORT,
                    $EVENT_PARM_MACID   => $macid,
                    $EVENT_PARM_SWPID   => $swpid,
                    $EVENT_PARM_SWID    => $swid,
                    $EVENT_PARM_CLASSID => $classid,
                    $EVENT_PARM_TEMPID  => $tempid,
                    $EVENT_PARM_VGID    => $vgid,
                    $EVENT_PARM_VLANID  => $vlanid,
                    $EVENT_PARM_MAGICID => $magicid,
                    $EVENT_PARM_DESC    => 'Added MAGIC Record',
            } );
            $ret++;

        }
    }

    eval {
        my $date    = NACMisc::get_current_timestamp();
        my $comment = "MAGICPORTed at $date";
        my %p       = ();
        $p{$DB_COL_MAC_ID}  = $macid;
        $p{$DB_COL_MAC_COM} = $comment;
        $self->update_mac_comment_insert( \%p );
    };

    return $ret;
}

#-------------------------------------------------------
#
# Clear MACID for DATA
#-------------------------------------------------------
sub clear_data_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $data_mac = 0;

    $self->reseterr;

    NACSyslog::ActivateDebug();

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID} && ( !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID} && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) ) { confess Dumper $parm_ref; }

    # Clear by SWPID or MACID
    my $swpid = ( ( defined $parm_ref->{$DB_COL_SWPS_SWPID} ) ? $parm_ref->{$DB_COL_SWPS_SWPID} : 0 );
    my $macid = ( ( defined $parm_ref->{$DB_COL_SWPS_MACID} ) ? $parm_ref->{$DB_COL_SWPS_MACID} : 0 );

    if ( !( $swpid || $macid ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " CLEAR DATA SWITCHPORTSTATE  PORT:[$swpid]" );

    my %clear_swp = ();
    my %parm      = ();
    $parm{EVENT_PARM_TYPE}      = 'EVENT_AUTH_CLEAR';
    $parm{EVENT_PARM_MACID}     = ( $macid > 0 ) ? $macid : 0;
    $parm{EVENT_PARM_IP}        = 0;
    $parm{EVENT_PARM_SWPID}     = $swpid;
    $parm{EVENT_PARM_CLASSID}   = 0;
    $parm{EVENT_PARM_TEMPID}    = 0;
    $parm{EVENT_PARM_VGID}      = 0;
    $parm{EVENT_PARM_VLANID}    = 0;
    $parm{EVENT_PARM_DESC}      = '';
    $parm{$DB_COL_SWPS_MACID}   = -1;
    $parm{$DB_COL_SWPS_IP}      = 0;
    $parm{$DB_COL_SWPS_CLASSID} = 0;
    $parm{$DB_COL_SWPS_VGID}    = 0;
    $parm{$DB_COL_SWPS_VLANID}  = 0;
    $parm{$DB_COL_SWPS_TEMPID}  = 0;

    if ($swpid) {
        %clear_swp = ();
        $clear_swp{$DB_COL_SWPS_SWPID} = $swpid;
        if ( !$self->get_switchportstate( \%clear_swp ) ) {

            # Add SWPS if it does not exist
            $parm{$DB_COL_SWPS_VMACID}   = -1;
            $parm{$DB_COL_SWPS_VIP}      = 0;
            $parm{$DB_COL_SWPS_VCLASSID} = 0;
            $parm{$DB_COL_SWPS_VVGID}    = 0;
            $parm{$DB_COL_SWPS_VVLANID}  = 0;
            $parm{$DB_COL_SWPS_VTEMPID}  = 0;
            $ret                         = $self->add_switchportstate( \%clear_swp );
            return $ret;
        }
        else {
            $data_mac                   = $clear_swp{$DB_COL_SWPS_MACID};
            $parm{$DB_COL_SWPS_MACID}   = -1;
            $parm{$DB_COL_SWPS_IP}      = 0;
            $parm{$DB_COL_SWPS_CLASSID} = 0;
            $parm{$DB_COL_SWPS_VGID}    = 0;
            $parm{$DB_COL_SWPS_VLANID}  = 0;
            $parm{$DB_COL_SWPS_TEMPID}  = 0;
            $parm{$DB_COL_SWPS_SWPID}   = $clear_swp{$DB_COL_SWPS_SWPID};
            $parm{$EVENT_PARM_MACID}    = $data_mac;
            $parm{$EVENT_PARM_SWPID}    = $clear_swp{$DB_COL_SWPS_SWPID};
            $ret                        = $self->update_switchportstate( \%parm );
        }
    }
    else {
        %clear_swp = ();
        $clear_swp{$DB_COL_SWPS_MACID} = $macid;
        if ( $self->get_switchportstate( \%clear_swp ) ) {
            $data_mac                   = $clear_swp{$DB_COL_SWPS_MACID};
            $parm{$DB_COL_SWPS_MACID}   = -1;
            $parm{$DB_COL_SWPS_IP}      = 0;
            $parm{$DB_COL_SWPS_CLASSID} = 0;
            $parm{$DB_COL_SWPS_VGID}    = 0;
            $parm{$DB_COL_SWPS_VLANID}  = 0;
            $parm{$DB_COL_SWPS_TEMPID}  = 0;
            $parm{$DB_COL_SWPS_SWPID}   = $clear_swp{$DB_COL_SWPS_SWPID};
            $parm{$EVENT_PARM_MACID}    = $data_mac;
            $parm{$EVENT_PARM_SWPID}    = $clear_swp{$DB_COL_SWPS_SWPID};
            $ret                        = $self->update_switchportstate( \%parm );
        }
    }

    $ret;

}

#-------------------------------------------------------
#
# Clear MACID for VOICE & DATA (if VOICE is cleared, assume data is gone too)
#-------------------------------------------------------
sub clear_voice_switchportstate($$) {
    my $self      = shift;
    my $parm_ref  = shift;
    my $ret       = 0;
    my $voice_mac = 0;
    my $data_mac  = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    # EventLog( EVENT_INFO,  MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID}  && ( !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID} && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_VMACID} ) ) ) ) { confess Dumper $parm_ref; }

    # Clear by SWPID or VMACID
    my $swpid  = ( ( defined $parm_ref->{$DB_COL_SWPS_SWPID} )  ? $parm_ref->{$DB_COL_SWPS_SWPID}  : 0 );
    my $vmacid = ( ( defined $parm_ref->{$DB_COL_SWPS_VMACID} ) ? $parm_ref->{$DB_COL_SWPS_VMACID} : 0 );

    if ( !( $swpid || $vmacid ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " CLEAR VOICE SWITCHPORTSTATE  PORT:[$swpid]" );

    # EventLog( EVENT_INFO,  MYNAMELINE . " CLEAR VOICE SWITCHPORTSTATE  PORT:[$swpid]" );

    my %clear_swp = ();
    my %parm      = ();
    $parm{EVENT_PARM_TYPE}       = 'EVENT_AUTH_CLEAR';
    $parm{EVENT_PARM_MACID}      = ( $vmacid > 0 ) ? $vmacid : 0;
    $parm{EVENT_PARM_IP}         = 0;
    $parm{EVENT_PARM_SWPID}      = $swpid;
    $parm{EVENT_PARM_CLASSID}    = 0;
    $parm{EVENT_PARM_TEMPID}     = 0;
    $parm{EVENT_PARM_VGID}       = 0;
    $parm{EVENT_PARM_VLANID}     = 0;
    $parm{EVENT_PARM_DESC}       = '';
    $parm{$DB_COL_SWPS_VMACID}   = -1;
    $parm{$DB_COL_SWPS_VIP}      = 0;
    $parm{$DB_COL_SWPS_VCLASSID} = 0;
    $parm{$DB_COL_SWPS_VVGID}    = 0;
    $parm{$DB_COL_SWPS_VVLANID}  = 0;
    $parm{$DB_COL_SWPS_VTEMPID}  = 0;

    if ($swpid) {
        %clear_swp = ();
        $clear_swp{$DB_COL_SWPS_SWPID} = $swpid;
        if ( !$self->get_switchportstate( \%clear_swp ) ) {

            # Add SWPS if it does not exist
            $parm{$DB_COL_SWPS_MACID}   = -1;
            $parm{$DB_COL_SWPS_IP}      = 0;
            $parm{$DB_COL_SWPS_CLASSID} = 0;
            $parm{$DB_COL_SWPS_VGID}    = 0;
            $parm{$DB_COL_SWPS_VLANID}  = 0;
            $parm{$DB_COL_SWPS_TEMPID}  = 0;
            $ret                        = $self->add_switchportstate( \%clear_swp );
            return $ret;
        }
        else {
            $self->clear_switchportstate( \%clear_swp );
        }
    }
    else {
        %clear_swp = ();
        $clear_swp{$DB_COL_SWPS_VMACID} = $vmacid;
        if ( $self->get_switchportstate( \%clear_swp ) ) {
            $self->clear_switchportstate( \%clear_swp );
        }
    }

    # EventLog( EVENT_INFO, MYNAMELINE . " FINISHED PORT:[$swpid]" );

    $ret;

}

#-------------------------------------------------------
#
# Clear MACID for VOICE & DATA (if VOICE is cleared, assume data is gone too)
#-------------------------------------------------------
sub clear_switchportstate($$) {
    my $self      = shift;
    my $parm_ref  = shift;
    my $ret       = 0;
    my $voice_mac = 0;
    my $data_mac  = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID}  && ( !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID}  && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID} && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_VMACID} ) ) ) ) { confess Dumper $parm_ref; }

    # Clear by SWPID or VMACID
    my $swpid  = ( ( defined $parm_ref->{$DB_COL_SWPS_SWPID} )  ? $parm_ref->{$DB_COL_SWPS_SWPID}  : 0 );
    my $macid  = ( ( defined $parm_ref->{$DB_COL_SWPS_MACID} )  ? $parm_ref->{$DB_COL_SWPS_MACID}  : 0 );
    my $vmacid = ( ( defined $parm_ref->{$DB_COL_SWPS_VMACID} ) ? $parm_ref->{$DB_COL_SWPS_VMACID} : 0 );

    if ( !( $swpid || $macid || $vmacid ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " CLEAR VOICE SWITCHPORTSTATE  PORT:[$swpid]" );

    my %clear_swp = ();
    my %parm      = ();
    $parm{EVENT_PARM_TYPE}       = 'EVENT_AUTH_CLEAR';
    $parm{EVENT_PARM_SWPID}      = $swpid;
    $parm{EVENT_PARM_MACID}      = ( ($macid) ? $macid : ( ( $vmacid > 0 ) ? $vmacid : 0 ) );
    $parm{EVENT_PARM_IP}         = 0;
    $parm{EVENT_PARM_CLASSID}    = 0;
    $parm{EVENT_PARM_TEMPID}     = 0;
    $parm{EVENT_PARM_VGID}       = 0;
    $parm{EVENT_PARM_VLANID}     = 0;
    $parm{EVENT_PARM_DESC}       = '';
    $parm{$DB_COL_SWPS_VMACID}   = -1;
    $parm{$DB_COL_SWPS_VIP}      = 0;
    $parm{$DB_COL_SWPS_VCLASSID} = 0;
    $parm{$DB_COL_SWPS_VVGID}    = 0;
    $parm{$DB_COL_SWPS_VVLANID}  = 0;
    $parm{$DB_COL_SWPS_VTEMPID}  = 0;

    %clear_swp = ();
    if ($swpid) {
        $clear_swp{$DB_COL_SWPS_SWPID} = $swpid;
        $parm{$DB_COL_SWPS_SWPID}      = $swpid;
    }
    elsif ($macid) {
        $clear_swp{$DB_COL_SWPS_MACID} = $macid;
    }
    elsif ($vmacid) {
        $clear_swp{$DB_COL_SWPS_SWPID} = $vmacid;
    }

    $parm{$DB_COL_SWPS_MACID}    = -1;
    $parm{$DB_COL_SWPS_IP}       = 0;
    $parm{$DB_COL_SWPS_CLASSID}  = 0;
    $parm{$DB_COL_SWPS_VGID}     = 0;
    $parm{$DB_COL_SWPS_VLANID}   = 0;
    $parm{$DB_COL_SWPS_TEMPID}   = 0;
    $parm{$DB_COL_SWPS_VMACID}   = -1;
    $parm{$DB_COL_SWPS_VIP}      = 0;
    $parm{$DB_COL_SWPS_VCLASSID} = 0;
    $parm{$DB_COL_SWPS_VVGID}    = 0;
    $parm{$DB_COL_SWPS_VVLANID}  = 0;
    $parm{$DB_COL_SWPS_VTEMPID}  = 0;

    if ( !$self->get_switchportstate( \%clear_swp ) ) {

        # Add SWPS if it does not exist
        if ($swpid) {
            $ret = $self->add_switchportstate( \%parm );
        }
    }
    else {
        $parm{$DB_COL_SWPS_SWPID} = $clear_swp{$DB_COL_SWPS_SWPID};
        $ret = $self->update_switchportstate( \%parm );
    }

    # EventLog( EVENT_INFO, MYNAMELINE . " FINISHED PORT:[$swpid]" );

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub deactivate_location($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $locid;
    my $site;
    my $bldg;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( ( defined $parm_ref->{$DB_COL_LOC_ID} ) && ( !( isdigit $parm_ref->{$DB_COL_LOC_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_LOC_SITE} ) && ( $parm_ref->{$DB_COL_LOC_SITE} eq '' ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_LOC_BLDG} ) && ( $parm_ref->{$DB_COL_LOC_BLDG} eq '' ) ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_LOC_ID} ) {
        $locid = $parm_ref->{$DB_COL_LOC_ID};
    }
    if ( defined $parm_ref->{$DB_COL_LOC_SITE} ) {
        $site = $parm_ref->{$DB_COL_LOC_SITE};
    }
    if ( defined $parm_ref->{$DB_COL_LOC_BLDG} ) {
        $bldg = $parm_ref->{$DB_COL_LOC_BLDG};
    }

    if ( !( ($locid) || ( $site && $bldg ) ) ) { confess "LOCID or SITE & BLDG required\n"; }

    if ( !defined $parm_ref->{$DB_COL_LOC_ID} ) {
        if ( !$self->get_location($parm_ref) ) { confess; }
        $locid = $parm_ref->{$DB_COL_LOC_ID};
    }

    $parm_ref->{$DB_COL_LOC_ID} = $locid;

    $ret = $self->deactivate_record($parm_ref);

    $ret;
}

#--------------------------------------------------------------------------------
#
# Deactivates MAC records
#
#--------------------------------------------------------------------------------
sub deactivate_mac($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_MAC_MAC} || $parm_ref->{$DB_COL_MAC_MAC} eq '' ) { confess Dumper $parm_ref; }

    my $mac = $parm_ref->{$DB_COL_MAC_MAC};
    if ( !_verify_MAC($mac) ) { confess Dumper $parm_ref; }

    if ( $self->get_macid($parm_ref) ) {
        $self->deactivate_macid($parm_ref);
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " get_macid() FAILED: mac:" . $mac );
    }

    $ret
}

#--------------------------------------------------------------------------------
#
# Deletes MAC records and MAC2TYPE record.
#
#--------------------------------------------------------------------------------
sub deactivate_macid($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_MAC_ID} || ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) ) { confess Dumper $parm_ref; }

    my $macid = $parm_ref->{$DB_COL_MAC_ID};

    $parm_ref->{$DB_COL_MAC_ID} = $macid;

    $ret = $self->deactivate_record($parm_ref);

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub delete_loopcidr2locid($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_LOOP_ID} ) {
        if ( !isdigit( $parm_ref->{$DB_COL_LOOP_ID} ) ) { confess Dumper $parm_ref; }
    }
    else {
        if ( !defined $parm_ref->{$DB_COL_LOOP_CIDR} || ( $parm_ref->{$DB_COL_LOOP_CIDR} eq '' ) ) { confess Dumper $parm_ref; }
        if ( !defined $parm_ref->{$DB_COL_LOOP_LOCID} || ( !isdigit( $parm_ref->{$DB_COL_LOOP_LOCID} ) ) ) { confess Dumper $parm_ref; }
        if ( !$self->get_loop2cidrlocid($parm_ref) ) {
            return $ret;
        }
    }
    my $loopcidr2locid = $parm_ref->{$DB_COL_LOOP_ID};

    my $table   = $parm_ref->{$DB_TABLE_NAME} = $DB_TABLE_LOOPCIDR2LOC;
    my $keyname = $parm_ref->{$DB_KEY_NAME}   = $DB_KEY_LOOPCIDR2LOCID;
    my $keyval  = $parm_ref->{$DB_KEY_VALUE}  = $loopcidr2locid;

    $ret = $self->_delete_record($parm_ref);

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub _delete_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_TABLE_NAME} || $parm_ref->{$DB_TABLE_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_NAME}   || $parm_ref->{$DB_KEY_NAME}   eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_VALUE}  || $parm_ref->{$DB_KEY_VALUE}  eq '' ) { confess Dumper $parm_ref; }
    my $table   = $parm_ref->{$DB_TABLE_NAME};
    my $keyname = $parm_ref->{$DB_KEY_NAME};
    my $keyval  = $parm_ref->{$DB_KEY_VALUE};

    if ( !defined $tablenames{$table} ) { confess "NO TABLE $table\n" . Dumper $parm_ref; }

    my $sql = "DELETE FROM $table "
      . " WHERE $keyname = "
      . ( ( $keyval =~ /[^\d+]/ ) ? " '$keyval' " : " $keyval " );

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_active_class_macs($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_CLASS_ID} || ( !( isdigit $parm_ref->{$DB_COL_CLASS_ID} ) ) ) { confess Dumper $parm_ref; }
    $parm_ref->{$DB_COL_CLASS_ACT} = 1;
    $ret = $self->get_class_macs($parm_ref);
    $ret;
}

#-------------------------------------------------------
# Get Class record(s)
#-------------------------------------------------------
sub get_class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_ID} && !isdigit( $parm_ref->{$DB_COL_CLASS_ID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_NAME} && $parm_ref->{$DB_COL_CLASS_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_PRI}    && !isdigit( $parm_ref->{$DB_COL_CLASS_PRI} ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_VGID}   && !isdigit( $parm_ref->{$DB_COL_CLASS_VGID} ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_ACT}    && !isdigit( $parm_ref->{$DB_COL_CLASS_ACT} ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CLASS_LOCKED} && !isdigit( $parm_ref->{$DB_COL_CLASS_LOCKED} ) ) { confess Dumper $parm_ref; }

    my $hash_ref    = $parm_ref->{$HASH_REF};
    my $id          = $parm_ref->{$DB_COL_CLASS_ID};
    my $name        = $parm_ref->{$DB_COL_CLASS_NAME};
    my $priority    = $parm_ref->{$DB_COL_CLASS_PRI};
    my $vlangroupid = $parm_ref->{$DB_COL_CLASS_VGID};
    my $active      = $parm_ref->{$DB_COL_CLASS_ACT};
    my $locked      = $parm_ref->{$DB_COL_CLASS_LOCKED};
    my $sort_id     = $parm_ref->{$DB_SORT_CLASS_ID};
    my $sort_name   = $parm_ref->{$DB_SORT_CLASS_NAME};
    my $sort_pri    = $parm_ref->{$DB_SORT_CLASS_PRI};
    my $sort_act    = $parm_ref->{$DB_SORT_CLASS_ACT};
    my $sort_lock   = $parm_ref->{$DB_SORT_CLASS_LOCKED};
    my $sort_vgid   = $parm_ref->{$DB_SORT_CLASS_VGID};
    my $where       = 0;
    my $sort        = 0;

    my $sql = "SELECT classid,name,priority,reauthtime,idletimeout,vlangroupid,active,locked,comment FROM class "
      . ( ( defined $id )          ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " classid = $id " )              : '' )
      . ( ( defined $name )        ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " name = '$name' " )             : '' )
      . ( ( defined $priority )    ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " priority = $priority " )       : '' )
      . ( ( defined $vlangroupid ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlangroupid = $vlangroupid " ) : '' )
      . ( ( defined $active )      ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " active = $active " )           : '' )
      . ( ( defined $locked )      ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locked = $locked " )           : '' )
      . ( ( defined $sort_id )   ? ( ( !$sort++ ) ? 'ORDER BY' : ', ' ) . " classid "     : '' )
      . ( ( defined $sort_name ) ? ( ( !$sort++ ) ? 'ORDER BY' : ', ' ) . " name "        : '' )
      . ( ( defined $sort_pri )  ? ( ( !$sort++ ) ? 'ORDER BY' : ', ' ) . " priority "    : '' )
      . ( ( defined $sort_act )  ? ( ( !$sort++ ) ? 'ORDER BY' : ', ' ) . " active "      : '' )
      . ( ( defined $sort_lock ) ? ( ( !$sort++ ) ? 'ORDER BY' : ', ' ) . " locked "      : '' )
      . ( ( defined $sort_vgid ) ? ( ( !$sort++ ) ? 'ORDER BY' : ', ' ) . " vlangroupid " : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_CLASS_ID}      = $answer[ $col++ ];
                $h{$DB_COL_CLASS_NAME}    = $answer[ $col++ ];
                $h{$DB_COL_CLASS_PRI}     = $answer[ $col++ ];
                $h{$DB_COL_CLASS_REAUTH}  = $answer[ $col++ ];
                $h{$DB_COL_CLASS_IDLE}    = $answer[ $col++ ];
                $h{$DB_COL_CLASS_VGID}    = $answer[ $col++ ];
                $h{$DB_COL_CLASS_ACT}     = $answer[ $col++ ];
                $h{$DB_COL_CLASS_LOCKED}  = $answer[ $col++ ];
                $h{$DB_COL_CLASS_COM}     = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_CLASS_ID}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_NAME}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_PRI}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_REAUTH} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_IDLE}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_VGID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_ACT}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_LOCKED} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_CLASS_COM}    = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    $ret;
}

#--------------------------------------------
sub get_class_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_CLASS_ID} = $id;
        if ( $self->get_class( \%parm ) ) {
            $name = $parm{$DB_COL_CLASS_NAME};
        }
    }
    $name;
}

#-------------------------------------------------------
#
# one off...
#-------------------------------------------------------
sub get_class_macs($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_M2C_CLASSID} || ( !( isdigit $parm_ref->{$DB_COL_M2C_CLASSID} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$HASH_REF} || $parm_ref->{$HASH_REF} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_MAC_ACT} ) { confess; }
    my $classid  = $parm_ref->{$DB_COL_M2C_CLASSID};
    my $active   = ( $parm_ref->{$DB_COL_MAC_ACT} ) ? 1 : 0;
    my $hash_ref = $parm_ref->{$HASH_REF};
    my $sql      = "SELECT mac.mac,mac.macid FROM mac2class,mac "
      . " WHERE mac2class.classid = $classid "
      . " AND mac2class.macid = mac.macid "
      . " AND mac.active = $active ";

    if ( $self->sqlexecute($sql) ) {
        while ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $hash_ref->{ $answer[1] } = \%h;
            $h{$DB_COL_MAC_MAC}       = $answer[ $col++ ];
            $h{$DB_COL_MAC_ID}        = $answer[ $col++ ];
            $ret++;
        }
    }

    $ret;
}

#-------------------------------------------------------
# The "Decision Core" code
#
# Need robust error checking here since Radius server calls this
# Adding LOCID, and SWITHCID to the mix to allow for narrowing down the search to just the VLANs we want
#
# Need to return a calulated Priority
#-------------------------------------------------------
sub get_class_mac_port($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_CMP_SWPID} ) || ( !( isdigit $parm_ref->{$DB_COL_CMP_SWPID} ) ) ) { confess Dumper $parm_ref; }
    if ( ( !defined $parm_ref->{$DB_COL_CMP_MACID} ) || ( !( isdigit $parm_ref->{$DB_COL_CMP_MACID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CMP_LOCID} && ( !( isdigit $parm_ref->{$DB_COL_CMP_LOCID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_CMP_SWID}  && ( !( isdigit $parm_ref->{$DB_COL_CMP_SWID} ) ) )  { confess Dumper $parm_ref; }
    if ( ( !defined $parm_ref->{$HASH_REF} ) || ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    my $switchportid = $parm_ref->{$DB_COL_CMP_SWPID};
    my $macid        = $parm_ref->{$DB_COL_CMP_MACID};
    my $locid        = $parm_ref->{$DB_COL_CMP_LOCID};
    my $swid         = $parm_ref->{$DB_COL_CMP_SWID};
    my $hash_ref     = $parm_ref->{$HASH_REF};
    my $sql;

    #
    # If we only have the SwitchportID then we have to determine
    # the Switch, and location ID
    #

    if ( ( !defined $locid ) || ( !defined $swid ) ) {

        #
        # Replace with get_switchport()
        #
        $sql =
          ' SELECT switch.switchid,switch.locationid FROM switchport, switch '
          . " WHERE switchport.switchportid = $switchportid "
          . ' AND switchport.switchid = switch.switchid ';

        my %loc_parm = ();
        if ( $self->sqlexecute($sql) ) {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $loc_parm{$DB_COL_CMP_SWID}  = $answer[ $col++ ];
                $loc_parm{$DB_COL_CMP_LOCID} = $answer[ $col++ ];
            }
        }

        $locid = $loc_parm{$DB_COL_CMP_LOCID};
        $swid  = $loc_parm{$DB_COL_CMP_SWID};
    }

    #
    # Priority Calculation
    # main
    #  class.priority
    # secondary
    #  mac2class.priority * 100
    #  vlangroup2vlan.priority * 1
    #  template2vlangroup.priority * 10
    #

    if ( defined $locid ) {
        $sql =

          #
          # PORT-VLAN Selection Sub-pri 800
          #
          '   SELECT '
          . ' class.priority          AS priority, '
          . ' 800                     AS subprio, '
          . ' vlan.vlan               AS vlan, '
          . ' vlan.vlanid             AS vlanid, '
          . ' vlan.vlanname           AS vlanname, '
          . ' vlan.coe                AS coe, '
          . " 'PORT-VLAN'             AS authtype, "
          . ' port2class.port2classid AS recordid, '
          . ' class.classid           AS classid, '
          . ' class.name              AS classname, '
          . ' 0                       AS locked, '
          . ' port2class.comment      AS comment, '
          . ' vlan.type               AS vlantype, '
          . ' class.reauthtime        AS reauthtime, '
          . ' class.idletimeout       AS idletimeout, '
          . ' 0                       AS vgid, '
          . " ''                      AS vgname, "
          . ' 0                       AS templateid, '
          . " ''                      AS templatename "
          . ' FROM switch2vlan, vlan, port2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE port2class.switchportid = $switchportid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlan.vlanid = port2class.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = port2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # PORT-VLANGROUP Selection Sub-pri 600
          #
          . ' SELECT '
          . ' class.priority                  AS priority, '
          . ' (600 + vlangroup2vlan.priority) AS subprio, '
          . ' vlan.vlan                       AS vlan, '
          . ' vlan.vlanid                     AS vlanid, '
          . ' vlan.vlanname                   AS vlanname, '
          . ' vlan.coe                        AS coe, '
          . " 'PORT-VLANGROUP'                AS authtype, "
          . ' port2class.port2classid         AS recordid, '
          . ' class.classid                   AS classid, '
          . ' class.name                      AS classname, '
          . ' 0                               AS locked, '
          . ' port2class.comment              AS comment, '
          . ' vlan.type                       AS vlantype, '
          . ' class.reauthtime                AS reauthtime, '
          . ' class.idletimeout               AS idletimeout, '
          . ' vlangroup.vlangroupid           AS vgid, '
          . ' vlangroup.vlangroupname         AS vgname, '
          . ' 0                               AS templateid, '
          . " ''                              AS templatename "
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, port2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE port2class.switchportid = $switchportid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlangroup.vlangroupid = port2class.vlangroupid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = port2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # PORT-DEFVLANGROUP Selection Sub-pri 400
          #
          . ' SELECT '
          . ' class.priority                  AS priority, '
          . ' (400 + vlangroup2vlan.priority) AS subprio, '
          . ' vlan.vlan                       AS vlan, '
          . ' vlan.vlanid                     AS vlanid, '
          . ' vlan.vlanname                   AS vlanname, '
          . ' vlan.coe                        AS coe, '
          . " 'PORT-DEFVLANGROUP'             AS authtype, "
          . ' port2class.port2classid         AS recordid, '
          . ' class.classid                   AS classid, '
          . ' class.name                      AS classname, '
          . ' 0                               AS locked, '
          . ' port2class.comment              AS comment, '
          . ' vlan.type                       AS vlantype, '
          . ' class.reauthtime                AS reauthtime, '
          . ' class.idletimeout               AS idletimeout, '
          . ' vlangroup.vlangroupid           AS vgid, '
          . ' vlangroup.vlangroupname         AS vgname, '
          . ' 0                               AS templateid, '
          . " ''                              AS templatename "
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, port2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE port2class.switchportid = $switchportid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlangroup.vlangroupid = class.vlangroupid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = port2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # MAC-VLAN Selection Sub-pri 700 + mac2class.priority
          #
          . ' SELECT '
          . ' class.priority             AS priority, '
          . ' (700 + mac2class.priority) AS subprio, '
          . ' vlan.vlan                  AS vlan, '
          . ' vlan.vlanid                AS vlanid, '
          . ' vlan.vlanname              AS vlanname, '
          . ' vlan.coe                   AS coe, '
          . " 'MAC-VLAN'                 AS authtype, "
          . ' mac2class.mac2classid      AS recordid, '
          . ' class.classid              AS classid, '
          . ' class.name                 AS classname, '
          . ' mac2class.locked           AS locked, '
          . ' mac2class.comment          AS comment, '
          . ' vlan.type                  AS vlantype, '
          . ' class.reauthtime           AS reauthtime, '
          . ' class.idletimeout          AS idletimeout, '
          . ' 0                          AS vgid, '
          . " ''                         AS vgname, "
          . ' 0                          AS templateid, '
          . " ''                         AS templatename "
          . ' FROM switch2vlan, vlan, mac2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE mac2class.macid = $macid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlan.vlanid = mac2class.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = mac2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # MAC-VLANGROUP Selection Sub-pri 500 + vlangroup2vlan.priority
          #
          . ' SELECT '
          . ' class.priority                  AS priority, '
          . ' (500 + vlangroup2vlan.priority) AS subprio, '
          . ' vlan.vlan                       AS vlan, '
          . ' vlan.vlanid                     AS vlanid, '
          . ' vlan.vlanname                   AS vlanname, '
          . ' vlan.coe                        AS coe, '
          . " 'MAC-VLANGROUP'                 AS authtype, "
          . ' mac2class.mac2classid           AS recordid, '
          . ' class.classid                   AS classid, '
          . ' class.name                      AS classname, '
          . ' 0                               AS locked, '
          . ' mac2class.comment               AS comment, '
          . ' vlan.type                       AS vlantype, '
          . ' class.reauthtime                AS reauthtime, '
          . ' class.idletimeout               AS idletimeout, '
          . ' vlangroup.vlangroupid           AS vgid, '
          . ' vlangroup.vlangroupname         AS vgname, '
          . ' 0                               AS templateid, '
          . " ''                              AS templatename "
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, mac2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE mac2class.macid = $macid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlangroup.vlangroupid = mac2class.vlangroupid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = mac2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # MAC-TEMPLATE Selection Sub-pri 300 + template2vlangroup.priority
          #
          . ' SELECT '
          . ' class.priority                  AS priority, '

          # . ' (300 + (template2vlangroup.priority * 10) + vlangroup2vlan.priority) AS subprio, '
          . ' (300 + (template2vlangroup.priority * 10)) AS subprio, '
          . ' vlan.vlan                       AS vlan, '
          . ' vlan.vlanid                     AS vlanid, '
          . ' vlan.vlanname                   AS vlanname, '
          . ' vlan.coe                        AS coe, '
          . " 'MAC-TEMPLATE'                  AS authtype, "
          . ' mac2class.mac2classid           AS recordid, '
          . ' class.classid                   AS classid, '
          . ' class.name                      AS classname, '
          . ' 0                               AS locked, '
          . ' mac2class.comment               AS comment, '
          . ' vlan.type                       AS vlantype, '
          . ' class.reauthtime                AS reauthtime, '
          . ' class.idletimeout               AS idletimeout, '
          . ' vlangroup.vlangroupid           AS vgid, '
          . ' vlangroup.vlangroupname         AS vgname, '
          . ' template.templateid             AS templateid, '
          . ' template.templatename           AS templatename '
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, template, template2vlangroup, mac2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE mac2class.macid = $macid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND template.templateid = mac2class.templateid '
          . ' AND template.templateid = template2vlangroup.templateid '
          . ' AND template2vlangroup.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = mac2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # MAC-DEFVLANGROUP Selection Sub-pri 100 + vlangroup2vlan.priority
          #
          . ' SELECT '
          . ' class.priority                  AS priority, '
          . ' (100 + vlangroup2vlan.priority) AS subprio, '
          . ' vlan.vlan                       AS vlan, '
          . ' vlan.vlanid                     AS vlanid, '
          . ' vlan.vlanname                   AS vlanname, '
          . ' vlan.coe                        AS coe, '
          . " 'MAC-DEFVLANGROUP'              AS authtype, "
          . ' mac2class.mac2classid           AS recordid, '
          . ' class.classid                   AS classid, '
          . ' class.name                      AS classname, '
          . ' 0                               AS locked, '
          . ' mac2class.comment               AS comment, '
          . ' vlan.type                       AS vlantype, '
          . ' class.reauthtime                AS reauthtime, '
          . ' class.idletimeout               AS idletimeout, '
          . ' vlangroup.vlangroupid           AS vgid, '
          . ' vlangroup.vlangroupname         AS vgname, '
          . ' 0                               AS templateid, '
          . " ''                              AS templatename "
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, mac2class '
          . ' JOIN class '
          . ' USING ( classid ) '
          . " WHERE mac2class.macid = $macid "
          . " AND vlan.locationid = $locid "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlangroup.vlangroupid = class.vlangroupid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND class.classid = mac2class.classid '
          . ' AND class.active = 1 '

          . "\n"
          . ' UNION '
          . "\n"

          #
          # Guest Challenge VLAN
          # GUESTCHALLENGE Selection Sub-pri 50 + vlangroup2vlan.priority
          #
          . ' SELECT '
          . ' class.priority           AS priority, '
          . ' vlangroup2vlan.priority  AS subprio, '
          . ' vlan.vlan                AS vlan, '
          . ' vlan.vlanid              AS vlanid, '
          . ' vlan.vlanname            AS vlanname, '
          . ' 0                        AS coe, '
          . " 'GUESTCHALLENGE'         AS authtype, "
          . ' 0                        AS recordid, '
          . ' class.classid            AS classid, '
          . ' class.name               AS classname, '
          . ' 0                        AS locked, '
          . " 'guest challenge vlan'   AS comment, "
          . ' vlan.type                AS vlantype, '
          . ' class.reauthtime         AS reauthtime, '
          . ' class.idletimeout        AS idletimeout, '
          . ' vlangroup.vlangroupid    AS vgid, '
          . ' vlangroup.vlangroupname  AS vgname, '
          . ' 0                        AS templateid, '
          . " ''                       AS templatename "
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, class '
          . " WHERE class.name = '$CLASS_NAME_GUESTCHALLENGE' "
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlangroup.vlangroupid = class.vlangroupid '
          . ' AND class.active = 1 '
          . " AND 0 = ( SELECT COUNT(macid) FROM mac2class WHERE mac2class.macid = $macid ) "

          . "\n"
          . ' UNION '
          . "\n"

          #
          # Default Challenge VLAN
          # CHALLENGE Selection Sub-pri 0 + vlangroup2vlan.priority
          #
          . ' SELECT '
          . ' class.priority           AS priority, '
          . ' vlangroup2vlan.priority  AS subprio, '
          . ' vlan.vlan                AS vlan, '
          . ' vlan.vlanid              AS vlanid, '
          . ' vlan.vlanname            AS vlanname, '
          . ' 0                        AS coe, '
          . " 'CHALLENGE'              AS authtype, "
          . ' 0                        AS recordid, '
          . ' class.classid            AS classid, '
          . ' class.name               AS classname, '
          . ' 0                        AS locked, '
          . " 'default challenge vlan' AS comment, "
          . ' vlan.type                AS vlantype, '
          . ' class.reauthtime         AS reauthtime, '
          . ' class.idletimeout        AS idletimeout, '
          . ' vlangroup.vlangroupid    AS vgid, '
          . ' vlangroup.vlangroupname  AS vgname, '
          . ' 0                        AS templateid, '
          . " ''                       AS templatename "
          . ' FROM switch2vlan, vlan, vlangroup, vlangroup2vlan, class '
          . " WHERE class.name = '$CLASS_NAME_CHALLENGE'"
          . " AND switch2vlan.switchid = $swid "
          . ' AND vlan.vlanid = switch2vlan.vlanid '
          . ' AND vlan.vlanid = vlangroup2vlan.vlanid '
          . ' AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid '
          . ' AND vlangroup.vlangroupid = class.vlangroupid '
          . ' AND class.active = 1 '

          ;

        #
        # - mac the back end deal with expiry times...
        #          . ' AND '
        #          . '     ( '
        #          . '     mac2class.expiretime IS NULL '
        #          . '     OR '
        #          . '     mac2class.expiretime > now( ) '
        #          . '     ) '
        #

        if ( $self->sqlexecute($sql) ) {
            while ( my @row = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $h{$DB_COL_CMP_PRI}       = $row[ $col++ ];
                $h{$DB_COL_CMP_SUBPRI}    = $row[ $col++ ];
                $h{$DB_COL_CMP_VLAN}      = $row[ $col++ ];
                $h{$DB_COL_CMP_VLANID}    = $row[ $col++ ];
                $h{$DB_COL_CMP_VLANNAME}  = $row[ $col++ ];
                $h{$DB_COL_CMP_COE}       = $row[ $col++ ];
                $h{$DB_COL_CMP_AUTHTYPE}  = $row[ $col++ ];
                $h{$DB_COL_CMP_RECID}     = $row[ $col++ ];
                $h{$DB_COL_CMP_CLASSID}   = $row[ $col++ ];
                $h{$DB_COL_CMP_CLASSNAME} = $row[ $col++ ];
                $h{$DB_COL_CMP_LOCKED}    = $row[ $col++ ];
                $h{$DB_COL_CMP_COM}       = $row[ $col++ ];
                $h{$DB_COL_CMP_VLANTYPE}  = $row[ $col++ ];
                $h{$DB_COL_CMP_REAUTH}    = $row[ $col++ ];
                $h{$DB_COL_CMP_IDLE}      = $row[ $col++ ];
                $h{$DB_COL_CMP_VGID}      = $row[ $col++ ];
                $h{$DB_COL_CMP_VGNAME}    = $row[ $col++ ];
                $h{$DB_COL_CMP_TEMPID}    = $row[ $col++ ];
                $h{$DB_COL_CMP_TEMPNAME}  = $row[ $col++ ];
                $h{$DB_COL_CMP_RANDPRI}   = rand(100);

                #
                # Deterministic randomizing priorities - Anything at Same PRI and SUB PRI will get a determinist random priority added on
                #

                #  *** Possible FUTURE option ***
                # Alternative to help randomize the results
                #
                # $h{$DB_COL_CMP_HASHPRI} = ( ( $macid * $switchportid ) % ( $h{$DB_COL_CMP_VLANID} + 1 ) ) % 100;
                #

                $h{$DB_COL_CMP_HASHPRI} = ( $macid * $switchportid * ( $h{$DB_COL_CMP_VLANID} + 1 ) ) % 100;

                my $priority = ( ( $row[0] + 1 ) * 10000 ) + ( ( $row[1] + 1 ) * 100 ) + $h{$DB_COL_CMP_HASHPRI};

                #
                #  *** Possible FUTURE option ***
                # Adding 1 to priority might be giving 293,2,1 a leg up on the lower numbers, depending on VLANID
                #
                while ( defined $hash_ref->{$priority} ) {
                    $priority++;

                    # EventLog( EVENT_WARN, MYNAMELINE() . "Duplicate PRI found" );
                }

                $hash_ref->{$priority} = \%h;
                $ret++;
            }
        }
    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "No Location Found, returning nothing" );
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_eventlog($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TYPE}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TYPE} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_CLASSID}   && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_CLASSID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_LOCID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_LOCID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_MACID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_MACID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_M2CID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_M2CID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_P2CID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_P2CID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SWID}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SWID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SWPID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SWPID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SW2VID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SW2VID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TEMPID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TEMPID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID} && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VGID}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VGID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VG2VID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VG2VID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VLANID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VLANID} ) ) )    { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};

    my $type      = $parm_ref->{$DB_COL_EVENTLOG_TYPE};
    my $classid   = $parm_ref->{$DB_COL_EVENTLOG_CLASSID};
    my $locid     = $parm_ref->{$DB_COL_EVENTLOG_LOCID};
    my $macid     = $parm_ref->{$DB_COL_EVENTLOG_MACID};
    my $m2cid     = $parm_ref->{$DB_COL_EVENTLOG_M2CID};
    my $p2cid     = $parm_ref->{$DB_COL_EVENTLOG_P2CID};
    my $swid      = $parm_ref->{$DB_COL_EVENTLOG_SWID};
    my $swpid     = $parm_ref->{$DB_COL_EVENTLOG_SWPID};
    my $sw2vid    = $parm_ref->{$DB_COL_EVENTLOG_SW2VID};
    my $tempid    = $parm_ref->{$DB_COL_EVENTLOG_TEMPID};
    my $temp2vgid = $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID};
    my $vlanid    = $parm_ref->{$DB_COL_EVENTLOG_VLANID};
    my $vgid      = $parm_ref->{$DB_COL_EVENTLOG_VGID};
    my $vg2vid    = $parm_ref->{$DB_COL_EVENTLOG_VG2VID};
    my $ip        = $parm_ref->{$DB_COL_EVENTLOG_IP};
    my $hostname  = $parm_ref->{$DB_COL_EVENTLOG_HOST};
    my $desc      = $parm_ref->{$DB_COL_EVENTLOG_DESC};
    my $time_gt   = $parm_ref->{$DB_COL_EVENTLOG_TIME_GT};
    my $time_lt   = $parm_ref->{$DB_COL_EVENTLOG_TIME_LT};
    my $time      = $parm_ref->{$DB_COL_EVENTLOG_TIME};
    my $where     = 0;

    if ( defined $time && ( defined $time_gt || defined $time_lt ) ) { confess Dumper $parm_ref; }
    if ( !( defined $type
            || defined $type
            || defined $classid
            || defined $locid
            || defined $macid
            || defined $m2cid
            || defined $p2cid
            || defined $swid
            || defined $swpid
            || defined $sw2vid
            || defined $tempid
            || defined $temp2vgid
            || defined $vlanid
            || defined $vgid
            || defined $vg2vid
            || defined $ip
            || defined $hostname
            || defined $desc
            || defined $time_gt
            || defined $time_lt
            || defined $time
        ) ) { confess Dumper $parm_ref; }

    my $sql = "SELECT eventlogid, eventtime, eventtype, userid, hostname, classid, locationid, macid, "
      . " mac2classid, port2classid, switchid, switchportid, switch2vlanid, templateid, template2vlangroupid, "
      . " vlangroupid, vlangroup2vlanid, vlanid, ip, eventtext "
      . " FROM eventlog "
      . ( ( defined $type )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " type = '$type' "         : '' )
      . ( ( defined $classid )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " classid = $classid "     : '' )
      . ( ( defined $locid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locid = $locid "         : '' )
      . ( ( defined $macid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $macid "         : '' )
      . ( ( defined $m2cid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " m2cid = $m2cid "         : '' )
      . ( ( defined $p2cid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " p2cid = $p2cid "         : '' )
      . ( ( defined $swid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " swid = $swid "           : '' )
      . ( ( defined $swpid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " swpid = $swpid "         : '' )
      . ( ( defined $tempid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " tempid = $tempid "       : '' )
      . ( ( defined $temp2vgid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " temp2vgid = $temp2vgid " : '' )
      . ( ( defined $vlanid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanid = $vlanid "       : '' )
      . ( ( defined $vgid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vgid = $vgid "           : '' )
      . ( ( defined $vg2vid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vg2vid = $vg2vid "       : '' )
      . ( ( defined $ip )        ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " ip = '$ip' "             : '' )
      . ( ( defined $hostname )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " hostname = '$hostname' " : '' )
      . ( ( defined $time_gt )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " eventtime > '$time_gt' " : '' )
      . ( ( defined $time_lt )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " eventtime < '$time_lt' " : '' )
      . ( ( defined $time )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " eventtime = '$time' "    : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        while ( my @row = $self->sth->fetchrow_array() ) {
            if ($hash_ref) {
                my %h;
                my $col = 0;
                $hash_ref->{ $row[0] }         = \%h;
                $h{$DB_COL_EVENTLOG_ID}        = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_TIME}      = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_TYPE}      = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_USERID}    = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_HOST}      = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_CLASSID}   = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_LOCID}     = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_MACID}     = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_M2CID}     = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_P2CID}     = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_SWID}      = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_SWPID}     = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_SW2VID}    = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_TEMPID}    = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_TEMP2VGID} = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_VGID}      = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_VG2VID}    = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_VLANID}    = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_IP}        = $row[ $col++ ];
                $h{$DB_COL_EVENTLOG_DESC}      = $row[ $col++ ];
            }
            $ret++;
        }
    }

    $ret;
}

#-------------------------------------------------------
#
# Used by syncing script
#-------------------------------------------------------
sub get_inactive_class_macs($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    eval {
        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( !defined $parm_ref->{$DB_COL_CLASS_ID} || ( !( isdigit $parm_ref->{$DB_COL_CLASS_ID} ) ) ) { confess Dumper $parm_ref; }
        $parm_ref->{$DB_COL_CLASS_ACT} = 0;
        $ret = $self->get_class_macs($parm_ref);
    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_location($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_LOC_ID} && ( !( isdigit $parm_ref->{$DB_COL_LOC_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_LOC_SITE} && ( $parm_ref->{$DB_COL_LOC_SITE} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_LOC_BLDG} && ( $parm_ref->{$DB_COL_LOC_BLDG} eq '' ) ) { confess Dumper $parm_ref; }

    my $locid    = $parm_ref->{$DB_COL_LOC_ID};
    my $site     = $parm_ref->{$DB_COL_LOC_SITE};
    my $bldg     = $parm_ref->{$DB_COL_LOC_BLDG};
    my $hash_ref = $parm_ref->{$HASH_REF};
    my $where    = 0;

    if ( defined $site && $site eq 'MASTER' ) {
        $parm_ref->{$DB_COL_LOC_ID} = 0;
        $ret = 1;
    }
    else {

        my $sql = "SELECT locationid,site,bldg,locationname,locationdescription,active FROM location "
          . ( ( defined $locid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locationid = $locid " : '' )
          . ( ( defined $site )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " site = '$site' "      : '' )
          . ( ( defined $bldg )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " bldg = '$bldg' "      : '' )
          ;

        if ( $self->sqlexecute($sql) ) {
            if ( defined $hash_ref ) {
                while ( my @answer = $self->sth->fetchrow_array() ) {
                    my %h;
                    my $col = 0;
                    $hash_ref->{ $answer[0] } = \%h;
                    $h{$DB_COL_LOC_ID}        = $answer[ $col++ ];
                    $h{$DB_COL_LOC_SITE}      = $answer[ $col++ ];
                    $h{$DB_COL_LOC_BLDG}      = $answer[ $col++ ];
                    $h{$DB_COL_LOC_NAME}      = $answer[ $col++ ];
                    $h{$DB_COL_LOC_DESC}      = $answer[ $col++ ];
                    $h{$DB_COL_LOC_ACT}       = $answer[ $col++ ];

                    # $h{$DB_COL_LOC_SHORTNAME} = $answer[1] . '-' . $answer[2];
                    $h{$DB_COL_LOC_SHORTNAME} = $answer[1] . '_' . $answer[2];
                    $ret++;
                }
            }
            else {
                if ( my @answer = $self->sth->fetchrow_array() ) {
                    my $col = 0;
                    $parm_ref->{$DB_COL_LOC_ID}   = $answer[ $col++ ];
                    $parm_ref->{$DB_COL_LOC_SITE} = $answer[ $col++ ];
                    $parm_ref->{$DB_COL_LOC_BLDG} = $answer[ $col++ ];
                    $parm_ref->{$DB_COL_LOC_NAME} = $answer[ $col++ ];
                    $parm_ref->{$DB_COL_LOC_DESC} = $answer[ $col++ ];
                    $parm_ref->{$DB_COL_LOC_ACT}  = $answer[ $col++ ];

                    # $parm_ref->{$DB_COL_LOC_SHORTNAME} = $answer[1] . '-' . $answer[2];
                    $parm_ref->{$DB_COL_LOC_SHORTNAME} = $answer[1] . '_' . $answer[2];
                    $ret++;
                }
            }
        }

    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_locid_from_switchid($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    eval {
        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( !defined $parm_ref->{'SWITCHID'} || ( !( isdigit( $parm_ref->{'SWITCHID'} ) ) ) ) { confess Dumper $parm_ref; }
        my $switchid = $parm_ref->{'SWITCHID'};

        my $sql = "SELECT locationid FROM switch WHERE switchid = $switchid";

        if ( $self->sqlexecute($sql) ) {
            if ( my @row = $self->sth->fetchrow_array() ) {
                $parm_ref->{$DB_COL_LOC_ID} = $row[0];
                $ret = 1;
            }
        }
    };
    LOGEVALFAIL() if ($@);

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_loopcidr2loc($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$DB_COL_LOOP_ID}    && ( !isdigit( $parm_ref->{$DB_COL_LOOP_CIDR} ) ) )  { confess; }
    if ( defined $parm_ref->{$DB_COL_LOOP_LOCID} && ( !isdigit( $parm_ref->{$DB_COL_LOOP_LOCID} ) ) ) { confess; }
    if ( defined $parm_ref->{$DB_COL_LOOP_CIDR} && ( $parm_ref->{$DB_COL_LOOP_CIDR} eq '' ) ) { confess; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $loopid   = $parm_ref->{$DB_COL_LOOP_ID};
    my $locid    = $parm_ref->{$DB_COL_LOOP_LOCID};
    my $cidr     = $parm_ref->{$DB_COL_LOOP_CIDR};
    my $where    = 0;

    my $sql = "SELECT loopcidr2locid,cidr,locid FROM loopcidr2loc "
      . ( ( defined $loopid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " loopcidr2locid = $loopid " : '' )
      . ( ( defined $locid )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locid = $locid "           : '' )
      . ( ( defined $cidr )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " cidr = '$cidr' "           : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        while ( my @answer = $self->sth->fetchrow_array() ) {
            if ( defined $hash_ref ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_LOOP_ID}       = $answer[ $col++ ];
                $h{$DB_COL_LOOP_CIDR}     = $answer[ $col++ ];
                $h{$DB_COL_LOOP_LOCID}    = $answer[ $col++ ];
                $ret++;
            }
            else {
                my $col = 0;
                $parm_ref->{$DB_COL_LOOP_ID}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_LOOP_CIDR}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_LOOP_LOCID} = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_coe_mac_exception($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$DB_COL_DME_MACID} && !isdigit( $parm_ref->{$DB_COL_DME_MACID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_DME_TICKETREF} && $parm_ref->{$DB_COL_DME_TICKETREF} eq '' ) { confess Dumper $parm_ref; }

    my $hash_ref  = $parm_ref->{$HASH_REF};
    my $id        = $parm_ref->{$DB_COL_DME_MACID};
    my $ticketref = $parm_ref->{$DB_COL_DME_TICKETREF};
    my $where     = 0;

    my $sql = "SELECT macid,ticketref,created,comment FROM $DB_TABLE_COE_MAC_EXCEPTION "
      . ( ( defined $id ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $id " : '' )
      . ( ( defined $ticketref ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " ticketref = '$ticketref' " : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ($hash_ref) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_DME_MACID}     = $answer[ $col++ ];    # 0
                $h{$DB_COL_DME_TICKETREF} = $answer[ $col++ ];    # 1
                $h{$DB_COL_DME_CREATED}   = $answer[ $col++ ];    # 2
                $h{$DB_COL_DME_COMMENT}   = $answer[ $col++ ];    # 3
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_DME_MACID}     = $answer[ $col++ ];    # 0
                $parm_ref->{$DB_COL_DME_TICKETREF} = $answer[ $col++ ];    # 1
                $parm_ref->{$DB_COL_DME_CREATED}   = $answer[ $col++ ];    # 2
                $parm_ref->{$DB_COL_DME_COMMENT}   = $answer[ $col++ ];    # 3
                $ret++;

            }
        }

    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_mac($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$DB_COL_MAC_ID} && !isdigit( $parm_ref->{$DB_COL_MAC_ID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_MAC} && $parm_ref->{$DB_COL_MAC_MAC} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_FS}  && $parm_ref->{$DB_COL_MAC_FS}  eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_LS}  && $parm_ref->{$DB_COL_MAC_LS}  eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_ACT} && !isdigit( $parm_ref->{$DB_COL_MAC_ACT} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_AT} && ( $parm_ref->{$DB_COL_MAC_AT} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_LOCKED} && !isdigit( $parm_ref->{$DB_COL_MAC_LOCKED} ) ) { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $id       = $parm_ref->{$DB_COL_MAC_ID};
    my $mac      = $parm_ref->{$DB_COL_MAC_MAC};
    my $fs       = $parm_ref->{$DB_COL_MAC_FS};
    my $ls       = $parm_ref->{$DB_COL_MAC_LS};
    my $at       = $parm_ref->{$DB_COL_MAC_AT};
    my $active   = $parm_ref->{$DB_COL_MAC_ACT};
    my $locked   = $parm_ref->{$DB_COL_MAC_LOCKED};
    my $sort_id  = $parm_ref->{$DB_SORT_MAC_ID};
    my $sort_mac = $parm_ref->{$DB_SORT_MAC_MAC};
    my $where    = 0;
    my $sort     = 0;

    if ( defined $mac && !_verify_MAC($mac) ) { confess ": BAD MAC: '$mac' "; }

    #    my $sql = "SELECT macid,mac,firstseen,lastseen,laststatechange,description,assettag,active,locked,comment FROM mac "
    my $sql = "SELECT macid,mac,firstseen,lastseen,laststatechange,description,assettag,active,locked,comment FROM mac "
      . ( ( defined $id )       ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " macid = $id "       : '' )
      . ( ( defined $mac )      ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " mac = '$mac' "      : '' )
      . ( ( defined $fs )       ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " firstseen = '$fs' " : '' )
      . ( ( defined $ls )       ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " lastseen = '$ls' "  : '' )
      . ( ( defined $at )       ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " assettag = '$at' "  : '' )
      . ( ( defined $active )   ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " active = $active "  : '' )
      . ( ( defined $locked )   ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " locked = $locked "  : '' )
      . ( ( defined $sort_id )  ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " macid "              : '' )
      . ( ( defined $sort_mac ) ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " mac "                : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ($hash_ref) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_MAC_ID}        = $answer[ $col++ ];    # 0
                $h{$DB_COL_MAC_MAC}       = $answer[ $col++ ];    # 1
                $h{$DB_COL_MAC_FS}        = $answer[ $col++ ];    # 2
                $h{$DB_COL_MAC_LS}        = $answer[ $col++ ];    # 3
                $h{$DB_COL_MAC_LSC}       = $answer[ $col++ ];    # 4
                $h{$DB_COL_MAC_DESC}      = $answer[ $col++ ];    # 5
                $h{$DB_COL_MAC_AT}        = $answer[ $col++ ];    # 6
                $h{$DB_COL_MAC_ACT}       = $answer[ $col++ ];    # 7
                $h{$DB_COL_MAC_LOCKED}    = $answer[ $col++ ];    # 8
                $h{$DB_COL_MAC_COM}       = $answer[ $col++ ];    # 9
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_MAC_ID}     = $answer[ $col++ ];    # 0
                $parm_ref->{$DB_COL_MAC_MAC}    = $answer[ $col++ ];    # 1
                $parm_ref->{$DB_COL_MAC_FS}     = $answer[ $col++ ];    # 2
                $parm_ref->{$DB_COL_MAC_LS}     = $answer[ $col++ ];    # 3
                $parm_ref->{$DB_COL_MAC_LSC}    = $answer[ $col++ ];    # 4
                $parm_ref->{$DB_COL_MAC_DESC}   = $answer[ $col++ ];    # 5
                $parm_ref->{$DB_COL_MAC_AT}     = $answer[ $col++ ];    # 6
                $parm_ref->{$DB_COL_MAC_ACT}    = $answer[ $col++ ];    # 7
                $parm_ref->{$DB_COL_MAC_LOCKED} = $answer[ $col++ ];    # 8
                $parm_ref->{$DB_COL_MAC_COM}    = $answer[ $col++ ];    # 9
                $ret++;
            }
        }

    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_mac_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_MAC_ID} = $id;
        if ( $self->get_mac( \%parm ) ) {
            $name = $parm{$DB_COL_MAC_MAC};
        }
    }
    $name;
}

#-------------------------------------------------------
# get_mac2class()
#
# CLASSID  optional
# MACID    Optional
# HASH_REF Optional
#-------------------------------------------------------
sub get_mac2class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_ID}      && ( !( isdigit $parm_ref->{$DB_COL_M2C_ID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_CLASSID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_CLASSID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_MACID}   && ( !( isdigit $parm_ref->{$DB_COL_M2C_MACID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_VLANID}  && ( !( isdigit $parm_ref->{$DB_COL_M2C_VLANID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_VGID}    && ( !( isdigit $parm_ref->{$DB_COL_M2C_VGID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_TEMPID}  && ( !( isdigit $parm_ref->{$DB_COL_M2C_TEMPID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_M2C_LOCKED}  && ( !( isdigit $parm_ref->{$DB_COL_M2C_LOCKED} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_LOCKED}  && ( !( isdigit $parm_ref->{$DB_COL_MAC_LOCKED} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAC_ACT}     && ( !( isdigit $parm_ref->{$DB_COL_MAC_ACT} ) ) )     { confess Dumper $parm_ref; }
    my $m2cid       = $parm_ref->{$DB_COL_M2C_ID};
    my $macid       = $parm_ref->{$DB_COL_M2C_MACID};
    my $classid     = $parm_ref->{$DB_COL_M2C_CLASSID};
    my $vlanid      = $parm_ref->{$DB_COL_M2C_VLANID};
    my $vlangroupid = $parm_ref->{$DB_COL_M2C_VGID};
    my $templateid  = $parm_ref->{$DB_COL_M2C_TEMPID};
    my $locked      = $parm_ref->{$DB_COL_M2C_LOCKED};
    my $mac_locked  = $parm_ref->{$DB_COL_MAC_LOCKED};
    my $mac_active  = $parm_ref->{$DB_COL_MAC_ACT};
    my $hash_ref    = $parm_ref->{$HASH_REF};
    my $include_mac = ( defined $parm_ref->{$DB_COL_MAC_LOCKED} || defined $parm_ref->{$DB_COL_MAC_ACT} ) ? 1 : 0;
    my $where       = 0;

    my $sql = "SELECT mac2class.mac2classid,mac2class.macid,mac2class.classid,mac2class.vlanid,mac2class.vlangroupid,mac2class.templateid,"
      . "mac2class.priority,mac2class.expiretime,mac2class.locked,mac2class.comment "
      . " FROM mac2class "
      . ( ($include_mac) ? ",mac" : '' )
      . " "
      . ( ( defined $m2cid )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.mac2classid = $m2cid "       : '' )
      . ( ( defined $classid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.classid = $classid "         : '' )
      . ( ( defined $macid )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.macid = $macid "             : '' )
      . ( ( defined $vlanid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.vlanid = $vlanid "           : '' )
      . ( ( defined $vlangroupid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.vlangroupid = $vlangroupid " : '' )
      . ( ( defined $templateid )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.templateid = $templateid "   : '' )
      . ( ( defined $locked )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac2class.locked = $locked "           : '' )
      . ( ($include_mac)           ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac.macid = mac2class.macid "          : '' )
      . ( ( defined $mac_locked )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac.locked = $mac_locked "             : '' )
      . ( ( defined $mac_active )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " mac.active = $mac_active "             : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_M2C_ID}        = $answer[ $col++ ];
                $h{$DB_COL_M2C_MACID}     = $answer[ $col++ ];
                $h{$DB_COL_M2C_CLASSID}   = $answer[ $col++ ];
                $h{$DB_COL_M2C_VLANID}    = $answer[ $col++ ];
                $h{$DB_COL_M2C_VGID}      = $answer[ $col++ ];
                $h{$DB_COL_M2C_TEMPID}    = $answer[ $col++ ];
                $h{$DB_COL_M2C_PRI}       = $answer[ $col++ ];
                $h{$DB_COL_M2C_EXPIRE}    = $answer[ $col++ ];
                $h{$DB_COL_M2C_LOCKED}    = $answer[ $col++ ];
                $h{$DB_COL_M2C_COM}       = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_M2C_ID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_MACID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_CLASSID} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_VLANID}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_VGID}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_TEMPID}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_PRI}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_EXPIRE}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_LOCKED}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_M2C_COM}     = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
# get_magicport()
#-------------------------------------------------------
sub get_magicport($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_ID}      && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_ID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_SWPID}   && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_SWPID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_CLASSID} && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_CLASSID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_VLANID}  && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_VLANID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_VGID}    && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_VGID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_TEMPID}  && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_TEMPID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_PRI}     && ( !( isdigit $parm_ref->{$DB_COL_MAGIC_PRI} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_MAGIC_TYPE}
        && ( !(
                ( $MAGICPORT_ADD eq $parm_ref->{$DB_COL_MAGIC_TYPE} )
                || ( $MAGICPORT_REPLACE eq $parm_ref->{$DB_COL_MAGIC_TYPE} ) ) ) ) {
        confess Dumper $parm_ref;
    }

    my $magicportid  = $parm_ref->{$DB_COL_MAGIC_ID};
    my $switchportid = $parm_ref->{$DB_COL_MAGIC_SWPID};
    my $classid      = $parm_ref->{$DB_COL_MAGIC_CLASSID};
    my $vlanid       = $parm_ref->{$DB_COL_MAGIC_VLANID};
    my $vlangroupid  = $parm_ref->{$DB_COL_MAGIC_VGID};
    my $templateid   = $parm_ref->{$DB_COL_MAGIC_TEMPID};
    my $priority     = $parm_ref->{$DB_COL_MAGIC_PRI};
    my $type         = $parm_ref->{$DB_COL_MAGIC_TYPE};
    my $hash_ref     = $parm_ref->{$HASH_REF};
    my $where        = 0;

    my $sql = "SELECT magicport.magicportid,magicport.switchportid,magicport.classid,magicport.vlanid,magicport.vlangroupid,magicport.templateid,"
      . "magicport.priority,magicport.magicporttype,magicport.comment "
      . " FROM magicport "
      . ( ( defined $magicportid )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.magicportid = $magicportid "   : '' )
      . ( ( defined $switchportid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.switchportid = $switchportid " : '' )
      . ( ( defined $classid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.classid = $classid "           : '' )
      . ( ( defined $vlanid )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.vlanid = $vlanid "             : '' )
      . ( ( defined $vlangroupid )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.vlangroupid = $vlangroupid "   : '' )
      . ( ( defined $templateid )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.templateid = $templateid "     : '' )
      . ( ( defined $priority )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.priority = $priority "         : '' )
      . ( ( defined $type )         ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " magicport.magicporttype = '$type' "      : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_MAGIC_ID}      = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_SWPID}   = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_CLASSID} = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_VLANID}  = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_VGID}    = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_TEMPID}  = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_PRI}     = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_TYPE}    = $answer[ $col++ ];
                $h{$DB_COL_MAGIC_COM}     = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_MAGIC_ID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_SWPID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_CLASSID} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_VLANID}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_VGID}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_TEMPID}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_PRI}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_TYPE}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_MAGIC_COM}     = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
# get_port2class()
#
#-------------------------------------------------------
sub get_port2class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    # EventLog( EVENT_DEBUG, MYNAMELINE() . Dumper $parm_ref );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_CLASSID} && ( !( isdigit $parm_ref->{$DB_COL_P2C_CLASSID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_SWPID}   && ( !( isdigit $parm_ref->{$DB_COL_P2C_SWPID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_VLANID}  && ( !( isdigit $parm_ref->{$DB_COL_P2C_VLANID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_VGID}    && ( !( isdigit $parm_ref->{$DB_COL_P2C_VGID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_P2C_LOCKED}  && ( !( isdigit $parm_ref->{$DB_COL_P2C_LOCKED} ) ) )  { confess Dumper $parm_ref; }

    my $switchportid = $parm_ref->{$DB_COL_P2C_SWPID};
    my $classid      = $parm_ref->{$DB_COL_P2C_CLASSID};
    my $vlanid       = $parm_ref->{$DB_COL_P2C_VLANID};
    my $vlangroupid  = $parm_ref->{$DB_COL_P2C_VGID};
    my $locked       = $parm_ref->{$DB_COL_P2C_LOCKED};
    my $hash_ref     = $parm_ref->{$HASH_REF};
    my $where        = 0;

    my $sql = "SELECT port2classid,switchportid,classid,vlanid,vlangroupid,locked,comment "
      . " FROM port2class "
      . " "
      . ( ( defined $classid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " classid = $classid "           : '' )
      . ( ( defined $switchportid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchportid = $switchportid " : '' )
      . ( ( defined $vlanid )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanid = $vlanid "             : '' )
      . ( ( defined $vlangroupid )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlangroupid = $vlangroupid "   : '' )
      . ( ( defined $locked )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locked = $locked "             : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_P2C_ID}        = $answer[ $col++ ];
                $h{$DB_COL_P2C_SWPID}     = $answer[ $col++ ];
                $h{$DB_COL_P2C_CLASSID}   = $answer[ $col++ ];
                $h{$DB_COL_P2C_VLANID}    = $answer[ $col++ ];
                $h{$DB_COL_P2C_VGID}      = $answer[ $col++ ];
                $h{$DB_COL_P2C_LOCKED}    = $answer[ $col++ ];
                $h{$DB_COL_P2C_COM}       = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_P2C_ID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_P2C_SWPID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_P2C_CLASSID} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_P2C_VLANID}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_P2C_VGID}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_P2C_LOCKED}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_P2C_COM}     = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
# Get radiusaudit record(s)
#-------------------------------------------------------
sub get_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_ID}    && !isdigit( $parm_ref->{$DB_COL_RA_ID} ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_MACID} && !isdigit( $parm_ref->{$DB_COL_RA_MACID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_SWPID} && !isdigit( $parm_ref->{$DB_COL_RA_SWPID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_AUDIT_TIME}    && ( $parm_ref->{$DB_COL_RA_AUDIT_TIME}    eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_AUDIT_TIME_LT} && ( $parm_ref->{$DB_COL_RA_AUDIT_TIME_LT} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_AUDIT_TIME_GT} && ( $parm_ref->{$DB_COL_RA_AUDIT_TIME_GT} eq '' ) ) { confess Dumper $parm_ref; }

    # if ( defined $parm_ref->{$DB_ENDTIME}   && ( $parm_ref->{$DB_ENDTIME}   eq '' ) ) { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $id       = $parm_ref->{$DB_COL_RA_ID};
    my $macid    = $parm_ref->{$DB_COL_RA_MACID};
    my $swpid    = $parm_ref->{$DB_COL_RA_SWPID};
    my $time     = $parm_ref->{$DB_COL_RA_AUDIT_TIME};
    my $time_gt  = $parm_ref->{$DB_COL_RA_AUDIT_TIME_GT};
    my $time_lt  = $parm_ref->{$DB_COL_RA_AUDIT_TIME_LT};

    #my $starttime = $parm_ref->{$DB_STARTTIME};
    #my $endtime   = $parm_ref->{$DB_ENDTIME};
    my $where = 0;
    my $sort  = 0;

    if ( defined $time && ( defined $time_gt || defined $time_lt ) ) { confess Dumper $parm_ref; }

    my $sql = "SELECT radiusauditid,macid,switchportid,audittime,auditserver,type,cause,octetsin,octetsout,packetsin,packetsout "
      . " FROM radiusaudit "
      . ( ( defined $id )    ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " id = $id " )       : '' )
      . ( ( defined $macid ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $macid " ) : '' )
      . ( ( defined $swpid ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " swpid = $swpid " ) : '' )
      . ( ( defined $time_gt ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime > '$time_gt' " : '' )
      . ( ( defined $time_lt ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime < '$time_lt' " : '' )
      . ( ( defined $time )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime = '$time' "    : '' )

      #      . ( ( defined $starttime ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime > '$starttime' " ) : '' )
      #      . ( ( defined $endtime )   ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime < '$endtime' " )   : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_RA_ID}         = $answer[ $col++ ];
                $h{$DB_COL_RA_MACID}      = $answer[ $col++ ];
                $h{$DB_COL_RA_SWPID}      = $answer[ $col++ ];
                $h{$DB_COL_RA_AUDIT_TIME} = $answer[ $col++ ];
                $h{$DB_COL_RA_AUDIT_SRV}  = $answer[ $col++ ];
                $h{$DB_COL_RA_TYPE}       = $answer[ $col++ ];
                $h{$DB_COL_RA_CAUSE}      = $answer[ $col++ ];
                $h{$DB_COL_RA_OCTIN}      = $answer[ $col++ ];
                $h{$DB_COL_RA_OCTOUT}     = $answer[ $col++ ];
                $h{$DB_COL_RA_PACIN}      = $answer[ $col++ ];
                $h{$DB_COL_RA_PACOUT}     = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_RA_ID}         = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_MACID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_SWPID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_AUDIT_TIME} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_AUDIT_SRV}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_TYPE}       = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_CAUSE}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_OCTIN}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_OCTOUT}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_PACIN}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_PACOUT}     = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switch2vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess "No Parameter Passed in"; }
    if ( ref($parm_ref) ne 'HASH' ) { confess "Bad Parameter passed in 'HASH' != " . ref($parm_ref); }
    if ( defined $parm_ref->{$HASH_REF} && $parm_ref->{$HASH_REF} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW2V_ID}     && ( !( isdigit $parm_ref->{$DB_COL_SW2V_ID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW2V_SWID}   && ( !( isdigit $parm_ref->{$DB_COL_SW2V_SWID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW2V_VLANID} && ( !( isdigit $parm_ref->{$DB_COL_SW2V_VLANID} ) ) ) { confess Dumper $parm_ref; }

    if ( !( ( defined $parm_ref->{$HASH_REF} )
            || ( defined $parm_ref->{$DB_COL_SW2V_ID} )
            || ( defined $parm_ref->{$DB_COL_SW2V_SWID} )
            || ( defined $parm_ref->{$DB_COL_SW2V_VLANID} ) ) )
    {
        confess Dumper $parm_ref;
    }

    my $id       = $parm_ref->{$DB_COL_SW2V_ID};
    my $switchid = $parm_ref->{$DB_COL_SW2V_SWID};
    my $vlanid   = $parm_ref->{$DB_COL_SW2V_VLANID};
    my $hash_ref = $parm_ref->{$HASH_REF};
    my $where    = 0;

    my $sql = "SELECT switch2vlanid,switchid,vlanid FROM switch2vlan "
      . ( ( defined $id )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switch2vlanid = $id "  : '' )
      . ( ( defined $vlanid )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanid = $vlanid "     : '' )
      . ( ( defined $switchid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchid = $switchid " : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %s;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%s;
                $s{$DB_COL_SW2V_ID}       = $answer[ $col++ ];
                $s{$DB_COL_SW2V_SWID}     = $answer[ $col++ ];
                $s{$DB_COL_SW2V_VLANID}   = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_SW2V_ID}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_SW2V_SWID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_SW2V_VLANID} = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switch($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW_ID} && !isdigit( $parm_ref->{$DB_COL_SW_ID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW_NAME} && $parm_ref->{$DB_COL_SW_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW_LOCID} && !isdigit( $parm_ref->{$DB_COL_SW_LOCID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SW_IP} && $parm_ref->{$DB_COL_SW_IP} eq '' ) { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $id       = $parm_ref->{$DB_COL_SW_ID};
    my $name     = $parm_ref->{$DB_COL_SW_NAME};
    my $locid    = $parm_ref->{$DB_COL_SW_LOCID};
    my $ip       = $parm_ref->{$DB_COL_SW_IP};
    my $where    = 0;

    $self->reseterr;

    my $sql = "SELECT switchid,switchname,locationid,switchdescription,ip,lastseen,comment FROM switch "
      . ( ( defined $id )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchid = $id "       : '' )
      . ( ( defined $name )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchname = '$name' " : '' )
      . ( ( defined $locid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locationid = $locid "  : '' )
      . ( ( defined $ip )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " ip = '$ip' "           : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @row = $self->sth->fetchrow_array() ) {
                my %s;
                my $col = 0;
                $hash_ref->{ $row[0] } = \%s;
                $s{$DB_COL_SW_ID}      = $row[ $col++ ];
                $s{$DB_COL_SW_NAME}    = $row[ $col++ ];
                $s{$DB_COL_SW_LOCID}   = $row[ $col++ ];
                $s{$DB_COL_SW_DESC}    = $row[ $col++ ];
                $s{$DB_COL_SW_IP}      = $row[ $col++ ];
                $s{$DB_COL_SW_LS}      = $row[ $col++ ];
                $s{$DB_COL_SW_COM}     = $row[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @row = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_SW_ID}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_SW_NAME}  = $row[ $col++ ];
                $parm_ref->{$DB_COL_SW_LOCID} = $row[ $col++ ];
                $parm_ref->{$DB_COL_SW_DESC}  = $row[ $col++ ];
                $parm_ref->{$DB_COL_SW_IP}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_SW_LS}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_SW_COM}   = $row[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switch_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_SW_ID} = $id;
        if ( $self->get_switch( \%parm ) ) {
            $name = $parm{$DB_COL_SW_NAME};
        }
    }
    $name;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $id;
    my $macid;
    my $macid_gtz;
    my $classid;
    my $vgid;
    my $vlanid;
    my $tempid;
    my $ip;
    my $vmacid;
    my $vmacid_gtz;
    my $vclassid;
    my $vvgid;
    my $vvlanid;
    my $vtempid;
    my $vip;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID}    && !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID}    && !isdigit( abs( $parm_ref->{$DB_COL_SWPS_MACID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_CLASSID}  && !isdigit( $parm_ref->{$DB_COL_SWPS_CLASSID} ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VGID}     && !isdigit( $parm_ref->{$DB_COL_SWPS_VGID} ) )          { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VLANID}   && !isdigit( $parm_ref->{$DB_COL_SWPS_VLANID} ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_TEMPID}   && !isdigit( $parm_ref->{$DB_COL_SWPS_TEMPID} ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID}    && defined $parm_ref->{$DB_COL_SWPS_MACID_GT_ZERO} )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID}   && !isdigit( abs( $parm_ref->{$DB_COL_SWPS_VMACID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VCLASSID} && !isdigit( $parm_ref->{$DB_COL_SWPS_VCLASSID} ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VVGID}    && !isdigit( $parm_ref->{$DB_COL_SWPS_VVGID} ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VVLANID}  && !isdigit( $parm_ref->{$DB_COL_SWPS_VVLANID} ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VTEMPID}  && !isdigit( $parm_ref->{$DB_COL_SWPS_VTEMPID} ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID}   && defined $parm_ref->{$DB_COL_SWPS_VMACID_GT_ZERO} )    { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID} )         { $id        = $parm_ref->{$DB_COL_SWPS_SWPID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_IP} )            { $ip        = $parm_ref->{$DB_COL_SWPS_IP} }
    if ( defined $parm_ref->{$DB_COL_SWPS_CLASSID} )       { $classid   = $parm_ref->{$DB_COL_SWPS_CLASSID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VGID} )          { $vgid      = $parm_ref->{$DB_COL_SWPS_VGID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VLANID} )        { $vlanid    = $parm_ref->{$DB_COL_SWPS_VLANID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_TEMPID} )        { $tempid    = $parm_ref->{$DB_COL_SWPS_TEMPID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID_GT_ZERO} ) { $macid_gtz = 1; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID} && $parm_ref->{$DB_COL_SWPS_MACID} > -1 ) { $macid = $parm_ref->{$DB_COL_SWPS_MACID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VIP} )            { $vip        = $parm_ref->{$DB_COL_SWPS_VIP} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VCLASSID} )       { $vclassid   = $parm_ref->{$DB_COL_SWPS_VCLASSID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VVGID} )          { $vvgid      = $parm_ref->{$DB_COL_SWPS_VVGID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VVLANID} )        { $vvlanid    = $parm_ref->{$DB_COL_SWPS_VVLANID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VTEMPID} )        { $vtempid    = $parm_ref->{$DB_COL_SWPS_VTEMPID} }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID_GT_ZERO} ) { $vmacid_gtz = 1; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID} && $parm_ref->{$DB_COL_SWPS_VMACID} > -1 ) { $vmacid = $parm_ref->{$DB_COL_SWPS_VMACID} }
    my $where = 0;

    $self->reseterr;

    my $sql = "SELECT switchportid,lastupdate,stateupdate,"
      . "macid,ip,hostname,classid,templateid,vlangroupid,vlanid, "
      . "vmacid,vip,vhostname,vclassid,vtemplateid,vvlangroupid,vvlanid "
      . " FROM switchportstate "
      . ( ( defined $id )         ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchportid = $id "     : '' )
      . ( ( defined $macid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $macid "         : '' )
      . ( ( defined $classid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " classid = $classid "     : '' )
      . ( ( defined $vgid )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlangroupid = $vgid "    : '' )
      . ( ( defined $vlanid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanid = $vlanid "       : '' )
      . ( ( defined $tempid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " templateid = $tempid "   : '' )
      . ( ( defined $ip )         ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " ip = '$ip' "             : '' )
      . ( ( defined $macid_gtz )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid > 0 "              : '' )
      . ( ( defined $vmacid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vmacid = $vmacid "       : '' )
      . ( ( defined $vclassid )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vclassid = $vclassid "   : '' )
      . ( ( defined $vvgid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vvlangroupid = $vvgid "  : '' )
      . ( ( defined $vvlanid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vvlanid = $vvlanid "     : '' )
      . ( ( defined $vtempid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vtemplateid = $vtempid " : '' )
      . ( ( defined $vip )        ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vip = '$vip' "           : '' )
      . ( ( defined $vmacid_gtz ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vmacid > 0 "             : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @row = $self->sth->fetchrow_array() ) {
                my %s;
                my $col = 0;
                $hash_ref->{ $row[0] }       = \%s;
                $s{$DB_COL_SWPS_SWPID}       = $row[ $col++ ];
                $s{$DB_COL_SWPS_LASTUPDATE}  = $row[ $col++ ];
                $s{$DB_COL_SWPS_STATEUPDATE} = $row[ $col++ ];
                $s{$DB_COL_SWPS_MACID}       = $row[ $col++ ];
                $s{$DB_COL_SWPS_IP}          = $row[ $col++ ];
                $s{$DB_COL_SWPS_HOSTNAME}    = $row[ $col++ ];
                $s{$DB_COL_SWPS_CLASSID}     = $row[ $col++ ];
                $s{$DB_COL_SWPS_TEMPID}      = $row[ $col++ ];
                $s{$DB_COL_SWPS_VGID}        = $row[ $col++ ];
                $s{$DB_COL_SWPS_VLANID}      = $row[ $col++ ];
                $s{$DB_COL_SWPS_VMACID}      = $row[ $col++ ];
                $s{$DB_COL_SWPS_VIP}         = $row[ $col++ ];
                $s{$DB_COL_SWPS_VHOSTNAME}   = $row[ $col++ ];
                $s{$DB_COL_SWPS_VCLASSID}    = $row[ $col++ ];
                $s{$DB_COL_SWPS_VTEMPID}     = $row[ $col++ ];
                $s{$DB_COL_SWPS_VVGID}       = $row[ $col++ ];
                $s{$DB_COL_SWPS_VVLANID}     = $row[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @row = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_SWPS_SWPID}       = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_LASTUPDATE}  = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_STATEUPDATE} = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_MACID}       = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_IP}          = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_HOSTNAME}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_CLASSID}     = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_TEMPID}      = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VGID}        = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VLANID}      = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VMACID}      = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VIP}         = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VHOSTNAME}   = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VCLASSID}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VTEMPID}     = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VVGID}       = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWPS_VVLANID}     = $row[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
# NAME:  get_switchport()
# TABLE: switchport
#
# RETURNS: $ret - count of rows found, 0 on error
# PARAMS:
#     parm_ref - {$HASH_REF} (optional) - for returning multiple rows
#                {'SWITCHID'} (optional) - switchid
#                {'PORTNAME'} (optional) - Port Name (works with switchid)
#
#     Returns a single parm_ref
#     A Single switch worth of ports
#     All switch ports divided by switch, then ports
#-------------------------------------------------------
sub get_switchport($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    # EventLog( EVENT_DEBUG, MYNAMELINE() . Dumper $parm_ref);

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWP_ID}   && ( !( isdigit( $parm_ref->{$DB_COL_SWP_ID} ) ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWP_SWID} && ( !( isdigit( $parm_ref->{$DB_COL_SWP_SWID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWP_NAME} && ( $parm_ref->{$DB_COL_SWP_NAME} eq '' ) ) { confess Dumper $parm_ref; }

    if ( ( defined $parm_ref->{$DB_COL_SWP_ID} )
        && ( defined $parm_ref->{$DB_COL_SWP_SWID} || defined $parm_ref->{$DB_COL_SWP_NAME} ) ) { confess Dumper $parm_ref; }

    my $id       = $parm_ref->{$DB_COL_SWP_ID};
    my $swid     = $parm_ref->{$DB_COL_SWP_SWID};
    my $portname = $parm_ref->{$DB_COL_SWP_NAME};
    my $hash_ref = $parm_ref->{$HASH_REF};
    my $where    = 0;

    my $sql = "SELECT switchportid,portname,portdescription,switchid FROM switchport "
      . ( ( defined $id )       ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchportid = $id "     : '' )
      . ( ( defined $swid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchid = $swid "       : '' )
      . ( ( defined $portname ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " portname = '$portname' " : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @row = $self->sth->fetchrow_array() ) {
                my %s;
                my $col = 0;
                $hash_ref->{ $row[0] } = \%s;
                $s{$DB_COL_SWP_ID}     = $row[ $col++ ];
                $s{$DB_COL_SWP_NAME}   = $row[ $col++ ];
                $s{$DB_COL_SWP_DESC}   = $row[ $col++ ];
                $s{$DB_COL_SWP_SWID}   = $row[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @row = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_SWP_ID}   = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWP_NAME} = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWP_DESC} = $row[ $col++ ];
                $parm_ref->{$DB_COL_SWP_SWID} = $row[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switchport_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_SWP_ID} = $id;
        if ( $self->get_switchport( \%parm ) ) {
            $name = $parm{$DB_COL_SWP_NAME};
        }
    }
    $name;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switchport_swid($$) {
    my $self = shift;
    my $id   = shift;
    my $swid = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_SWP_ID} = $id;
        if ( $self->get_switchport( \%parm ) ) {
            $swid = $parm{$DB_COL_SWP_SWID};
        }
    }
    $swid;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_template($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP_ID} && ( !isdigit( $parm_ref->{$DB_COL_TEMP_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP_NAME} && ( $parm_ref->{$DB_COL_TEMP_NAME} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP_ACT} && ( !isdigit( $parm_ref->{$DB_COL_TEMP_ACT} ) ) ) { confess Dumper $parm_ref; }

    my $hash_ref  = $parm_ref->{$HASH_REF};
    my $id        = $parm_ref->{$DB_COL_TEMP_ID};
    my $name      = $parm_ref->{$DB_COL_TEMP_NAME};
    my $active    = $parm_ref->{$DB_COL_TEMP_ACT};
    my $sort_id   = $parm_ref->{$DB_SORT_TEMP_ID};
    my $sort_name = $parm_ref->{$DB_SORT_TEMP_NAME};
    my $sort_act  = $parm_ref->{$DB_SORT_TEMP_ACT};
    my $where     = 0;
    my $sort      = 0;

    my $sql = "SELECT templateid,templatename,templatedescription,active,comment FROM template "
      . ( ( defined $id )        ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " templateid = $id "       : '' )
      . ( ( defined $name )      ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " templatename = '$name' " : '' )
      . ( ( defined $active )    ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " active = $active "       : '' )
      . ( ( defined $sort_id )   ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " templateid "              : '' )
      . ( ( defined $sort_name ) ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " templatename "            : '' )
      . ( ( defined $sort_act )  ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " active "                  : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_TEMP_ID}       = $answer[ $col++ ];
                $h{$DB_COL_TEMP_NAME}     = $answer[ $col++ ];
                $h{$DB_COL_TEMP_DESC}     = $answer[ $col++ ];
                $h{$DB_COL_TEMP_ACT}      = $answer[ $col++ ];
                $h{$DB_COL_TEMP_COM}      = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_TEMP_ID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP_NAME} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP_DESC} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP_ACT}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP_COM}  = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_template_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_TEMP_ID} = $id;
        if ( $self->get_template( \%parm ) ) {
            $name = $parm{$DB_COL_TEMP_NAME};
        }
    }
    $name;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_template2vlangroup($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP2VG_ID}     && ( !isdigit( $parm_ref->{$DB_COL_TEMP2VG_ID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP2VG_TEMPID} && ( !isdigit( $parm_ref->{$DB_COL_TEMP2VG_TEMPID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP2VG_VGID}   && ( !isdigit( $parm_ref->{$DB_COL_TEMP2VG_VGID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_TEMP2VG_PRI}    && ( !isdigit( $parm_ref->{$DB_COL_TEMP2VG_PRI} ) ) )    { confess Dumper $parm_ref; }

    my $hash_ref  = $parm_ref->{$HASH_REF};
    my $temp2vgid = $parm_ref->{$DB_COL_TEMP2VG_ID};
    my $tempid    = $parm_ref->{$DB_COL_TEMP2VG_TEMPID};
    my $vgid      = $parm_ref->{$DB_COL_TEMP2VG_VGID};
    my $priority  = $parm_ref->{$DB_COL_TEMP2VG_PRI};
    my $where     = 0;

    my $sql = "SELECT template2vlangroupid,templateid,vlangroupid,priority FROM template2vlangroup "
      . ( ( defined $temp2vgid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " template2vlangroupid = $temp2vgid " : '' )
      . ( ( defined $tempid )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " templateid = $tempid "              : '' )
      . ( ( defined $vgid )      ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlangroupid = $vgid "               : '' )
      . ( ( defined $priority )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " priority = $priority "              : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        while ( my @answer = $self->sth->fetchrow_array() ) {
            if ( defined $hash_ref ) {
                my %v;
                my $col = 0;
                $hash_ref->{ $answer[0] }  = \%v;
                $v{$DB_COL_TEMP2VG_ID}     = $answer[ $col++ ];
                $v{$DB_COL_TEMP2VG_TEMPID} = $answer[ $col++ ];
                $v{$DB_COL_TEMP2VG_VGID}   = $answer[ $col++ ];
                $v{$DB_COL_TEMP2VG_PRI}    = $answer[ $col++ ];
                $ret++;
            }
            else {
                my $col = 0;
                $parm_ref->{$DB_COL_TEMP2VG_ID}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP2VG_TEMPID} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP2VG_VGID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_TEMP2VG_PRI}    = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_vlangroup($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG_ID} && ( !isdigit( $parm_ref->{$DB_COL_VG_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG_NAME} && ( $parm_ref->{$DB_COL_VG_NAME} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG_ACT} && ( !isdigit( $parm_ref->{$DB_COL_VG_ACT} ) ) ) { confess Dumper $parm_ref; }

    my $hash_ref  = $parm_ref->{$HASH_REF};
    my $id        = $parm_ref->{$DB_COL_VG_ID};
    my $name      = $parm_ref->{$DB_COL_VG_NAME};
    my $active    = $parm_ref->{$DB_COL_VG_ACT};
    my $sort_id   = $parm_ref->{$DB_SORT_VG_ID};
    my $sort_name = $parm_ref->{$DB_SORT_VG_NAME};
    my $sort_act  = $parm_ref->{$DB_SORT_VG_ACT};
    my $where     = 0;
    my $sort      = 0;

    my $sql = "SELECT vlangroupid,vlangroupname,vlangroupdescription,active,comment FROM vlangroup "
      . ( ( defined $id )        ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " vlangroupid = $id "       : '' )
      . ( ( defined $name )      ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " vlangroupname = '$name' " : '' )
      . ( ( defined $active )    ? ( ( !$where++ ) ? 'WHERE'    : 'AND' ) . " active = $active "        : '' )
      . ( ( defined $sort_id )   ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " vlangroupid "              : '' )
      . ( ( defined $sort_name ) ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " vlangroupname "            : '' )
      . ( ( defined $sort_act )  ? ( ( !$sort++ )  ? 'ORDER BY' : ', ' ) . " active "                   : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_VG_ID}         = $answer[ $col++ ];
                $h{$DB_COL_VG_NAME}       = $answer[ $col++ ];
                $h{$DB_COL_VG_DESC}       = $answer[ $col++ ];
                $h{$DB_COL_VG_ACT}        = $answer[ $col++ ];
                $h{$DB_COL_VG_COM}        = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_VG_ID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG_NAME} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG_DESC} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG_ACT}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG_COM}  = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#--------------------------------------------
#
#--------------------------------------------
sub get_vlangroup_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_VG_ID} = $id;
        if ( $self->get_vlangroup( \%parm ) ) {
            $name = $parm{$DB_COL_VG_NAME};
        }
    }
    $name;
}

#-------------------------------------------------------
# Get vlan numbers associated with a location id
#-------------------------------------------------------
#sub get_vlan_for_locid_vlangroupid($$) {
#    my $self     = shift;
#    my $parm_ref = shift;
#    my $ret      = 0;
#
#    $self->reseterr;
#
#    if ( !defined $parm_ref ) { confess; }
#    if ( ref($parm_ref) ne 'HASH' ) { confess; }
#    if ( !defined $parm_ref->{$DB_COL_VLAN_LOCID} || ( !( isdigit $parm_ref->{$DB_COL_VLAN_LOCID} ) ) ) { confess Dumper $parm_ref; }
#    if ( !defined $parm_ref->{$DB_COL_VG2V_VGID}  || ( !( isdigit $parm_ref->{$DB_COL_VG2V_VGID} ) ) )  { confess Dumper $parm_ref; }
#    if ( !defined $parm_ref->{$HASH_REF} ) { confess; }
#    my $locid       = $parm_ref->{$DB_COL_VLAN_LOCID};
#    my $vlangroupid = $parm_ref->{$DB_COL_VG2V_VGID};
#    my $hash_ref    = $parm_ref->{$HASH_REF};
#
#    my $sql = 'SELECT vlan.vlanid,vlan.vlan,vlan.cidr,vlan.vlanname,vlan.vlandescription,vlan.active,vlan.coe '
#      . ' FROM vlan,vlangroup2vlan '
#      . " WHERE vlan.locationid = $locid "
#      . " AND vlangroup2vlan.vlangroupid = $vlangroupid "
#      . ' AND vlan.vlanid = vlangroup2vlan.vlanid';
#
#    if ( $self->sqlexecute($sql) ) {
#        while ( my @answer = $self->sth->fetchrow_array() ) {
#            my %h;
#            my $col = 0;
#            $hash_ref->{ $answer[0] } = \%h;
#            $h{$DB_COL_VLAN_ID}       = $answer[$col++];
#            $h{$DB_COL_VLAN_VLAN}     = $answer[$col++];
#            $h{$DB_COL_VLAN_CIDR}     = $answer[$col++];
#            $h{$DB_COL_VLAN_NAME}     = $answer[$col++];
#            $h{$DB_COL_VLAN_DESC}     = $answer[$col++];
#            $h{$DB_COL_VLAN_ACT}      = $answer[$col++];
#            $h{$DB_COL_VLAN_COE}      = $answer[$col++];
#            $ret++;
#        }
#    }
#
#    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
#    $ret;
#}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_vlangroup2vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG2V_ID}     && ( !isdigit( $parm_ref->{$DB_COL_VG2V_ID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG2V_VLANID} && ( !isdigit( $parm_ref->{$DB_COL_VG2V_VLANID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG2V_VGID}   && ( !isdigit( $parm_ref->{$DB_COL_VG2V_VGID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VG2V_PRI}    && ( !isdigit( $parm_ref->{$DB_COL_VG2V_PRI} ) ) )    { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $vg2vid   = $parm_ref->{$DB_COL_VG2V_ID};
    my $vlanid   = $parm_ref->{$DB_COL_VG2V_VLANID};
    my $vgid     = $parm_ref->{$DB_COL_VG2V_VGID};
    my $priority = $parm_ref->{$DB_COL_VG2V_PRI};
    my $where    = 0;

    my $sql = "SELECT vlangroup2vlanid,vlanid,vlangroupid,priority FROM vlangroup2vlan "
      . ( ( defined $vg2vid )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlangroup2vlanid = $vg2vid " : '' )
      . ( ( defined $vlanid )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanid = $vlanid "           : '' )
      . ( ( defined $vgid )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlangroupid = $vgid "        : '' )
      . ( ( defined $priority ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " priority = $priority "       : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        while ( my @answer = $self->sth->fetchrow_array() ) {
            if ( defined $hash_ref ) {
                my %v;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%v;
                $v{$DB_COL_VG2V_ID}       = $answer[ $col++ ];
                $v{$DB_COL_VG2V_VLANID}   = $answer[ $col++ ];
                $v{$DB_COL_VG2V_VGID}     = $answer[ $col++ ];
                $v{$DB_COL_VG2V_PRI}      = $answer[ $col++ ];
                $ret++;
            }
            else {
                my $col = 0;
                $parm_ref->{$DB_COL_VG2V_ID}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG2V_VLANID} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG2V_VGID}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VG2V_PRI}    = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined( $parm_ref->{$HASH_REF} ) && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_ID}    && ( !( isdigit $parm_ref->{$DB_COL_VLAN_ID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_LOCID} && ( !( isdigit $parm_ref->{$DB_COL_VLAN_LOCID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_VLAN}  && ( !( isdigit $parm_ref->{$DB_COL_VLAN_VLAN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_TYPE}  && $parm_ref->{$DB_COL_VLAN_TYPE}  eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_CIDR}  && $parm_ref->{$DB_COL_VLAN_CIDR}  eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_NACIP} && $parm_ref->{$DB_COL_VLAN_NACIP} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_ACT}   && $parm_ref->{$DB_COL_VLAN_ACT}   eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_VLAN_NAME}  && $parm_ref->{$DB_COL_VLAN_NAME}  eq '' ) { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $id       = $parm_ref->{$DB_COL_VLAN_ID};
    my $locid    = $parm_ref->{$DB_COL_VLAN_LOCID};
    my $vlan     = $parm_ref->{$DB_COL_VLAN_VLAN};
    my $type     = $parm_ref->{$DB_COL_VLAN_TYPE};
    my $cidr     = $parm_ref->{$DB_COL_VLAN_CIDR};
    my $nacip    = $parm_ref->{$DB_COL_VLAN_NACIP};
    my $active   = $parm_ref->{$DB_COL_VLAN_ACT};
    my $name     = $parm_ref->{$DB_COL_VLAN_NAME};
    my $where    = 0;

    my $sql = "SELECT vlanid,vlanname,vlan,type,locationid,cidr,nacip,vlandescription,active,comment FROM vlan "
      . ( ( defined $id )     ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanid = $id "        : '' )
      . ( ( defined $locid )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " locationid = $locid " : '' )
      . ( ( defined $vlan )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlan = $vlan "        : '' )
      . ( ( defined $type )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " type = '$type' "      : '' )
      . ( ( defined $cidr )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " cidr = '$cidr' "      : '' )
      . ( ( defined $nacip )  ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " nacip = '$nacip' "    : '' )
      . ( ( defined $active ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " active = $active "    : '' )
      . ( ( defined $name )   ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " vlanname = '$name' "  : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( !defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_VLAN_ID}    = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_NAME}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_VLAN}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_TYPE}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_LOCID} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_CIDR}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_NACIP} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_DESC}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_ACT}   = $answer[ $col++ ];
                $parm_ref->{$DB_COL_VLAN_COM}   = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %v;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%v;
                $v{$DB_COL_VLAN_ID}       = $answer[ $col++ ];
                $v{$DB_COL_VLAN_NAME}     = $answer[ $col++ ];
                $v{$DB_COL_VLAN_VLAN}     = $answer[ $col++ ];
                $v{$DB_COL_VLAN_TYPE}     = $answer[ $col++ ];
                $v{$DB_COL_VLAN_LOCID}    = $answer[ $col++ ];
                $v{$DB_COL_VLAN_CIDR}     = $answer[ $col++ ];
                $v{$DB_COL_VLAN_NACIP}    = $answer[ $col++ ];
                $v{$DB_COL_VLAN_DESC}     = $answer[ $col++ ];
                $v{$DB_COL_VLAN_ACT}      = $answer[ $col++ ];
                $v{$DB_COL_VLAN_COM}      = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    $ret;
}

#--------------------------------------------
sub get_vlan_name($$) {
    my $self = shift;
    my $id   = shift;
    my $name = 0;

    if ($id) {
        my %parm = ();
        $parm{$DB_COL_VLAN_ID} = $id;
        if ( $self->get_vlan( \%parm ) ) {
            $name = $parm{$DB_COL_VLAN_NAME};
        }
    }
    $name;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
#sub get_vlan2swp($$) {
#    my $self     = shift;
#    my $parm_ref = shift;
#    my $ret      = 0;
#
#    $self->reseterr;
#
#    if ( !defined $parm_ref ) { confess; }
#    if ( ref($parm_ref) ne 'HASH' ) { confess; }
#    if ( !defined( $parm_ref->{$HASH_REF} ) || ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
#    if ( !defined $parm_ref->{$DB_COL_VLAN2SWP_VLANID} || ( !( isdigit $parm_ref->{$DB_COL_VLAN2SWP_VLANID} ) ) ) { confess Dumper $parm_ref; }
#    if ( !defined $parm_ref->{$DB_COL_VLAN2SWP_SWPID}  || ( !( isdigit $parm_ref->{$DB_COL_VLAN2SWP_SWPID} ) ) )  { confess Dumper $parm_ref; }
#
#    my $hash_ref = $parm_ref->{$HASH_REF};
#    my $vlanid   = $parm_ref->{$DB_COL_VLAN2SWP_VLANID};
#    my $swpid    = $parm_ref->{$DB_COL_VLAN2SWP_SWPID};
#
#    my $sql = " SELECT vlan.vlanid, vlan.vlan, vlan.vlanname "
#      . " FROM vlan, switch2vlan, switchport "
#      . " WHERE switchport.switchid = switch2vlan.switchid "
#      . " AND switch2vlan.vlanid = vlan.vlanid "
#      . " AND switchport.switchportid = $swpid "
#      . " AND vlan.vlanid = $vlanid "
#      ;
#
#    if ( $self->sqlexecute($sql) ) {
#        while ( my @answer = $self->sth->fetchrow_array() ) {
#            my %v;
#                my $col = 0;
#            $hash_ref->{ $answer[0] } = \%v;
#            $v{$DB_COL_VLAN2SWP_VLANID} = $answer[$col++];
#            $v{$DB_COL_VLAN2SWP_VLAN} = $answer[$col++];
#            $v{$DB_COL_VLAN2SWP_NAME} = $answer[$col++];
#            $ret++;
#        }
#    }
#
#    $ret;
#}

#-------------------------------------------------------
#
#-------------------------------------------------------
#sub get_vg2swp($$) {
#    my $self     = shift;
#    my $parm_ref = shift;
#    my $ret      = 0;
#
#    $self->reseterr;
#
#    if ( !defined $parm_ref ) { confess; }
#    if ( ref($parm_ref) ne 'HASH' ) { confess; }
#    if ( !defined( $parm_ref->{$HASH_REF} ) || ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
#    if ( !defined $parm_ref->{$DB_COL_VG2SWP_VGID}  || ( !( isdigit $parm_ref->{$DB_COL_VG2SWP_VGID} ) ) )  { confess Dumper $parm_ref; }
#    if ( !defined $parm_ref->{$DB_COL_VG2SWP_SWPID} || ( !( isdigit $parm_ref->{$DB_COL_VG2SWP_SWPID} ) ) ) { confess Dumper $parm_ref; }
#
#    my $hash_ref = $parm_ref->{$HASH_REF};
#    my $vgid     = $parm_ref->{$DB_COL_VG2SWP_VGID};
#    my $swpid    = $parm_ref->{$DB_COL_VG2SWP_SWPID};
#
#    my $sql = " SELECT vlan.vlanid, vlan.vlan, vlan.vlanname, vlangroup.vlangroupname "
#      . " FROM vlan, switch2vlan, switchport, vlangroup2vlan, vlangroup "
#      . " WHERE switchport.switchid = switch2vlan.switchid "
#      . " AND switch2vlan.vlanid = vlan.vlanid "
#      . " AND vlangroup2vlan.vlanid = vlan.vlanid "
#      . " AND vlangroup2vlan.vlangroupid = vlangroup.vlangroupid "
#      . " AND switchport.switchportid = $swpid "
#      . " AND vlangroup.vlangroupid = $vgid "
#      ;
#
#    if ( $self->sqlexecute($sql) ) {
#        while ( my @answer = $self->sth->fetchrow_array() ) {
#            my %v;
#                my $col = 0;
#            $hash_ref->{ $answer[0] } = \%v;
#            $v{$DB_COL_VG2SWP_VGID}   = $answer[$col++];
#            $v{$DB_COL_VG2SWP_VLAN}   = $answer[$col++];
#            $v{$DB_COL_VG2SWP_NAME}   = $answer[$col++];
#            $v{$DB_COL_VG2SWP_VGNAME} = $answer[$col++];
#            $ret++;
#        }
#    }
#
#    $ret;
#}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub is_location_active($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $locid;
    my $site;
    my $bldg;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( ( defined $parm_ref->{$DB_COL_LOC_ID} ) && ( !( isdigit $parm_ref->{$DB_COL_LOC_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_LOC_SITE} ) && ( $parm_ref->{$DB_COL_LOC_SITE} eq '' ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_LOC_BLDG} ) && ( $parm_ref->{$DB_COL_LOC_BLDG} eq '' ) ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_LOC_ID} ) {
        $locid = $parm_ref->{$DB_COL_LOC_ID};
    }
    if ( defined $parm_ref->{$DB_COL_LOC_SITE} ) {
        $site = $parm_ref->{$DB_COL_LOC_SITE};
    }
    if ( defined $parm_ref->{$DB_COL_LOC_BLDG} ) {
        $bldg = $parm_ref->{$DB_COL_LOC_BLDG};
    }

    if ( !( ($locid) || ( $site && $bldg ) ) ) { confess "LOCID or SITE & BLDG required\n"; }

    if ( !defined $parm_ref->{$DB_COL_LOC_ID} ) {
        if ( !$self->get_location($parm_ref) ) { confess; }
        $locid = $parm_ref->{$DB_COL_LOC_ID};
    }

    $parm_ref->{$DB_COL_LOC_ID} = $locid;

    $ret = $self->is_record_active($parm_ref);

    $ret;
}

#--------------------------------------------------------------------------------
sub is_record_locked($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $tablename;
    my $keyname;
    my $keyval;
    my $key;

    $self->reseterr;

    if ( 1 != scalar( keys(%$parm_ref) ) ) { confess Dumper $parm_ref; }

    ($key) = keys(%$parm_ref);
    if ( !defined $key2table{$key} ) { confess Dumper $parm_ref; }

    $tablename = $key2table{$key};
    if ( !defined $tableswithlocks{$tablename} ) { confess Dumper $parm_ref; }

    $keyname = $key2keyid{$key};

    $keyval = $parm_ref->{$key};
    if ( !isdigit($keyval) ) { confess Dumper $parm_ref; }

    my $sql = "SELECT locked FROM $tablename WHERE $keyname = $keyval ";

    if ( !$self->sqlexecute($sql) ) {
        my $msg = MYNAMELINE() . " sqlexecute() FAILED:" . $sql;
        EventLog( EVENT_DB_ERR, $msg );
        $self->seterr($msg);
    }
    else {
        my @answer = $self->sth->fetchrow_array();
        $ret = $answer[0];
    }

    $ret;

}

#--------------------------------------------------------------------------------
sub is_record_active($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $tablename;
    my $keyname;
    my $keyval;
    my $key;

    $self->reseterr;

    ($key) = keys(%$parm_ref);
    if ( !defined $key2table{$key} ) { confess "No such key defined:" . ( Dumper $parm_ref ) . ( Dumper %key2table ); }

    $tablename = $key2table{$key};
    if ( !defined $tableswithactive{$tablename} ) { confess Dumper $parm_ref; }

    $keyname = $key2keyid{$key};

    $keyval = $parm_ref->{$key};
    if ( !isdigit($keyval) ) { confess Dumper $parm_ref; }

    my $sql = "SELECT active FROM $tablename WHERE $keyname = $keyval ";

    if ( !$self->sqlexecute($sql) ) {
        my $msg = MYNAMELINE() . " sqlexecute() FAILED:" . $sql;
        EventLog( EVENT_DB_ERR, $msg );
        $self->seterr($msg);
    }
    else {
        my @answer = $self->sth->fetchrow_array();
        $ret = $answer[0];
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub update_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID} && ( !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_SWPS_MACID}    && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_CLASSID}  && ( !isdigit( $parm_ref->{$DB_COL_SWPS_CLASSID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VGID}     && ( !isdigit( $parm_ref->{$DB_COL_SWPS_VGID} ) ) )           { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VLANID}   && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_VLANID} ) ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_TEMPID}   && ( !isdigit( $parm_ref->{$DB_COL_SWPS_TEMPID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VMACID}   && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_VMACID} ) ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VCLASSID} && ( !isdigit( $parm_ref->{$DB_COL_SWPS_VCLASSID} ) ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VVGID}    && ( !isdigit( $parm_ref->{$DB_COL_SWPS_VVGID} ) ) )          { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VVLANID}  && ( !isdigit( abs( $parm_ref->{$DB_COL_SWPS_VVLANID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_VTEMPID}  && ( !isdigit( $parm_ref->{$DB_COL_SWPS_VTEMPID} ) ) )        { confess Dumper $parm_ref; }

    my $swpid      = $parm_ref->{$DB_COL_SWPS_SWPID};
    my $macid      = $parm_ref->{$DB_COL_SWPS_MACID};
    my $ip         = $parm_ref->{$DB_COL_SWPS_IP};
    my $classid    = $parm_ref->{$DB_COL_SWPS_CLASSID};
    my $vgid       = $parm_ref->{$DB_COL_SWPS_VGID};
    my $vlanid     = $parm_ref->{$DB_COL_SWPS_VLANID};
    my $tempid     = $parm_ref->{$DB_COL_SWPS_TEMPID};
    my $vmacid     = $parm_ref->{$DB_COL_SWPS_VMACID};
    my $vip        = $parm_ref->{$DB_COL_SWPS_VIP};
    my $vclassid   = $parm_ref->{$DB_COL_SWPS_VCLASSID};
    my $vvgid      = $parm_ref->{$DB_COL_SWPS_VVGID};
    my $vvlanid    = $parm_ref->{$DB_COL_SWPS_VVLANID};
    my $vtempid    = $parm_ref->{$DB_COL_SWPS_VTEMPID};
    my $lastupdate = $parm_ref->{$DB_COL_SWPS_LASTUPDATE};
    my $hostname;
    my $vhostname;

    if ( !( defined $swpid || defined $macid || defined $vmacid ) ) { confess; }

    my %get = ();
    if ( defined $swpid ) {
        $get{$DB_COL_SWPS_SWPID} = $swpid;
    }
    elsif ( defined $macid ) {
        $get{$DB_COL_SWPS_MACID} = $macid;
    }
    else {
        $get{$DB_COL_SWPS_VMACID} = $vmacid;
    }

    if ( !$self->get_switchportstate( \%get ) ) {
        if ( defined $swpid ) {
            $ret = $self->add_switchportstate($parm_ref);
            EventLog( EVENT_INFO, MYNAMELINE() . " ADD SWPS SWPID:$swpid MACID:$macid" );
        }
        else {
            EventLog( EVENT_WARN, MYNAMELINE() . " Cannot ADD SWPS SWPID:$swpid MACID:$macid" );
        }
    }
    else {

        my $run_update = 0;
        my %parm       = ();
        $parm{$DB_TABLE_NAME} = $DB_TABLE_SWITCHPORTSTATE;
        $parm{$DB_KEY_NAME}   = $DB_KEY_SWITCHPORTSTATEID;
        $parm{$DB_KEY_VALUE}  = $get{$DB_COL_SWPS_SWPID};
        if ( defined $macid && ( $macid != $get{$DB_COL_SWPS_MACID} ) ) { $parm{$DB_COL_SWPS_MACID} = $macid; $run_update++; }
        if ( defined $ip && ( $ip ne $get{$DB_COL_SWPS_IP} ) ) { $parm{$DB_COL_SWPS_IP} = $ip; $run_update++; }
        if ( defined $classid && ( $classid != $get{$DB_COL_SWPS_CLASSID} ) ) { $parm{$DB_COL_SWPS_CLASSID} = $classid; $run_update++; }
        if ( defined $vgid    && ( $vgid != $get{$DB_COL_SWPS_VGID} ) )       { $parm{$DB_COL_SWPS_VGID}    = $vgid;    $run_update++; }
        if ( defined $vlanid  && ( $vlanid != $get{$DB_COL_SWPS_VLANID} ) )   { $parm{$DB_COL_SWPS_VLANID}  = $vlanid;  $run_update++; }
        if ( defined $tempid  && ( $tempid != $get{$DB_COL_SWPS_TEMPID} ) )   { $parm{$DB_COL_SWPS_TEMPID}  = $tempid;  $run_update++; }
        if ( defined $hostname && ( $hostname ne $get{$DB_COL_SWPS_HOSTNAME} ) ) { $parm{$DB_COL_SWPS_HOSTNAME} = $hostname; $run_update++; }
        if ( defined $vmacid && ( $vmacid != $get{$DB_COL_SWPS_VMACID} ) ) { $parm{$DB_COL_SWPS_VMACID} = $vmacid; $run_update++; }
        if ( defined $vip && ( $vip ne $get{$DB_COL_SWPS_VIP} ) ) { $parm{$DB_COL_SWPS_VIP} = $vip; $run_update++; }
        if ( defined $vclassid && ( $vclassid != $get{$DB_COL_SWPS_VCLASSID} ) ) { $parm{$DB_COL_SWPS_VCLASSID} = $vclassid; $run_update++; }
        if ( defined $vvgid    && ( $vvgid != $get{$DB_COL_SWPS_VVGID} ) )       { $parm{$DB_COL_SWPS_VVGID}    = $vvgid;    $run_update++; }
        if ( defined $vvlanid  && ( $vvlanid != $get{$DB_COL_SWPS_VVLANID} ) )   { $parm{$DB_COL_SWPS_VVLANID}  = $vvlanid;  $run_update++; }
        if ( defined $vtempid  && ( $vtempid != $get{$DB_COL_SWPS_VTEMPID} ) )   { $parm{$DB_COL_SWPS_VTEMPID}  = $vtempid;  $run_update++; }
        if ( defined $vhostname && ( $vhostname ne $get{$DB_COL_SWPS_VHOSTNAME} ) ) { $parm{$DB_COL_SWPS_VHOSTNAME} = $vhostname; $run_update++; }

        if ($run_update) {
            $parm{$DB_COL_SWPS_LASTUPDATE} = NACMisc::get_current_timestamp();
            if ( $ret = $self->update_record_db_col( \%parm ) ) {
                %parm = ();
                if ( defined $swpid ) {
                    $parm{$DB_COL_SWPS_SWPID} = $swpid;
                }
                if ( defined $macid ) {
                    $parm{$DB_COL_SWPS_MACID} = $macid;
                }
                if ( defined $vmacid ) {
                    $parm{$DB_COL_SWPS_VMACID} = $vmacid;
                }
                $ret++;
                EventLog( EVENT_DEBUG, MYNAMELINE() . " UPDATE SWPS SWPID:$swpid MACID:$macid " );
            }
            $self->update_switchportstate_statechange( \%parm );
        }
    }

    #--- NOTE
    # This is the logging that hits the main event log
    # Only Log when the state on the port Changes
    #---
    if ($ret) {
        $self->EventDBLog($parm_ref);
    }
    else {
        EventLog( EVENT_DEBUG, " NO SWPS UPDATE NEEDED - SWPID:$swpid MACID:$macid " );
    }

    $self->update_switchportstate_lastseen($parm_ref);

    $ret;

}

#-------------------------------------------------------
#
# Find Switch port and DMAC records
# Same ID, update - Else shutdown MAC port, log, and move to new port
#
#-------------------------------------------------------
sub set_data_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm     = ();
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_SWPS_SWPID} || ( !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_SWPS_MACID} || ( !isdigit( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) { confess Dumper $parm_ref; }

    my $swpid   = $parm_ref->{$DB_COL_SWPS_SWPID};
    my $macid   = $parm_ref->{$DB_COL_SWPS_MACID};
    my $ip      = $parm_ref->{$DB_COL_SWPS_IP};
    my $classid = $parm_ref->{$DB_COL_SWPS_CLASSID};
    my $vlanid  = $parm_ref->{$DB_COL_SWPS_VLANID};
    my $vgid    = $parm_ref->{$DB_COL_SWPS_VGID};
    my $tempid  = $parm_ref->{$DB_COL_SWPS_TEMPID};

    if ( !$swpid ) {
        EventLog( EVENT_ERR, MYNAMELINE . " NO SWPID defined " );
        return 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called SWPID:$swpid, MACID:$macid " );

    my %swp_only   = ();
    my %vmac_only  = ();
    my %dmac_only  = ();
    my $swp_result = 0;
    my $mac_result = 0;

    $swp_only{$DB_COL_SWPS_SWPID}   = $swpid;
    $vmac_only{$DB_COL_SWPS_VMACID} = $macid;
    $dmac_only{$DB_COL_SWPS_MACID}  = $macid;

    if ( !( defined $swpid && defined $macid ) ) {
        EventLog( EVENT_WARN, MYNAMELINE() . " NO swpid and vmacid specified " );
    }
    else {

        if ( defined $swpid && $swpid ) {
            $swp_result = $self->get_switchportstate( \%swp_only );
        }

        #-----
        # Create the switch port state since it does not exist
        #-----
        if ( !$swp_result ) {

            EventLog( EVENT_DEBUG, MYNAMELINE() . " CREATE SWPS RECORD " );
            $self->clear_data_switchportstate( \%dmac_only );
            $self->clear_voice_switchportstate( \%vmac_only );
            $ret = $self->add_switchportstate($parm_ref);
        }

        #-----
        # switch port state record exists
        #-----
        else {

            if ( $macid != $swp_only{$DB_COL_SWPS_MACID} ) {
                $self->clear_data_switchportstate( \%dmac_only );
                $self->clear_voice_switchportstate( \%vmac_only );
            }

            $ret = $self->update_switchportstate($parm_ref);

        }
    }

    $ret;

}

#-------------------------------------------------------
#
# Find Switch port and VMAC records
# Same ID, update - Else shutdown MAC port, log, and move to new port
#
#-------------------------------------------------------
sub set_voice_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm     = ();
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_SWPS_SWPID}  || ( !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) )  { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_SWPS_VMACID} || ( !isdigit( $parm_ref->{$DB_COL_SWPS_VMACID} ) ) ) { confess Dumper $parm_ref; }

    my $swpid    = $parm_ref->{$DB_COL_SWPS_SWPID};
    my $vmacid   = $parm_ref->{$DB_COL_SWPS_VMACID};
    my $vip      = $parm_ref->{$DB_COL_SWPS_VIP};
    my $vclassid = $parm_ref->{$DB_COL_SWPS_VCLASSID};
    my $vvlanid  = $parm_ref->{$DB_COL_SWPS_VVLANID};
    my $vvgid    = $parm_ref->{$DB_COL_SWPS_VVGID};
    my $vtempid  = $parm_ref->{$DB_COL_SWPS_VTEMPID};

    if ( !$swpid ) {
        EventLog( EVENT_ERR, MYNAMELINE . " NO SWPID defined " );
        return 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called SWPID:$swpid, MACID:$vmacid " );

    my %swp_only    = ();
    my %vmac_only   = ();
    my %dmac_only   = ();
    my $swp_result  = 0;
    my $vmac_result = 0;

    $swp_only{$DB_COL_SWPS_SWPID}   = $swpid;
    $vmac_only{$DB_COL_SWPS_VMACID} = $vmacid;
    $dmac_only{$DB_COL_SWPS_MACID}  = $vmacid;

    if ( !( defined $swpid && defined $vmacid ) ) {
        EventLog( EVENT_WARN, MYNAMELINE() . " NO swpid and vmacid specified " );
    }
    else {

        if ( defined $swpid && $swpid ) {
            $swp_result = $self->get_switchportstate( \%swp_only );
        }

        #-----
        # Create the switch port state since it does not exist
        #-----
        if ( !$swp_result ) {

            EventLog( EVENT_DEBUG, MYNAMELINE() . " CREATE SWPS RECORD " );
            $self->clear_data_switchportstate( \%dmac_only );
            $self->clear_voice_switchportstate( \%vmac_only );
            $ret = $self->add_switchportstate($parm_ref);
        }

        #-----
        # switch port state record exists
        #-----
        else {

            if ( $vmacid != $swp_only{$DB_COL_SWPS_VMACID} ) {
                $self->clear_data_switchportstate( \%dmac_only );
                $self->clear_voice_switchportstate( \%vmac_only );
            }

            $ret = $self->update_switchportstate($parm_ref);

        }
    }

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub update_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm     = ();
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_RA_ID} || ( !isdigit( $parm_ref->{$DB_COL_RA_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTOUT} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_PACIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_PACOUT} ) ) ) { confess Dumper $parm_ref; }

    #    if ( defined $parm_ref->{$DB_COL_RA_DEFVGID} && ( !( isdigit( $parm_ref->{$DB_COL_RA_DEFVGID} ) ) ) ) { confess Dumper $parm_ref; }
    #    if ( defined $parm_ref->{$DB_COL_RA_VGID}    && ( !( isdigit( $parm_ref->{$DB_COL_RA_VGID} ) ) ) )    { confess Dumper $parm_ref; }
    #    if ( defined $parm_ref->{$DB_COL_RA_VLANID}  && ( !( isdigit( $parm_ref->{$DB_COL_RA_VLANID} ) ) ) )  { confess Dumper $parm_ref; }

    $parm{$DB_TABLE_NAME} = $DB_TABLE_RADIUSAUDIT;
    $parm{$DB_KEY_NAME}   = $DB_KEY_RADIUSAUDITID;
    $parm{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_RA_ID};
    if ( defined $parm_ref->{$DB_COL_RA_OCTIN} )  { $parm{$DB_COL_RA_OCTIN}  = $parm_ref->{$DB_COL_RA_OCTIN}; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTOUT} ) { $parm{$DB_COL_RA_OCTOUT} = $parm_ref->{$DB_COL_RA_OCTOUT}; }
    if ( defined $parm_ref->{$DB_COL_RA_PACIN} )  { $parm{$DB_COL_RA_PACIN}  = $parm_ref->{$DB_COL_RA_PACIN}; }
    if ( defined $parm_ref->{$DB_COL_RA_PACOUT} ) { $parm{$DB_COL_RA_PACOUT} = $parm_ref->{$DB_COL_RA_PACOUT}; }
    $ret = $self->update_record_db_col( \%parm );

    $ret;

}

#-------------------------------------------------------
#
#            {$DB_COL_NAME} => value
# Translate DB_COL to use update_record()
#-------------------------------------------------------
sub update_record_db_col($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . Dumper $parm_ref );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    foreach my $k ( keys(%$parm_ref) ) {
        my $n;
        if ( $k eq $DB_TABLE_NAME ) { next; }
        if ( $k eq $DB_KEY_NAME )   { next; }
        if ( $k eq $DB_KEY_VALUE )  { next; }
        $n = $column_names{$k};
        if ( !defined $n ) {
            EventLog( EVENT_DEBUG, MYNAMELINE() . "Undefined column name $k, skipping" );
            next;
        }
        my $value = $parm_ref->{$k};
        $parm_ref->{ 'UPDATE_' . $n } = $value;
    }

    return $self->update_record($parm_ref);

}

#-------------------------------------------------------
#	Hard coded column names being passed in.
#            {UPDATE_columnname} => value
#-------------------------------------------------------
sub update_record($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_TABLE_NAME} || $parm_ref->{$DB_TABLE_NAME} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_NAME}   || $parm_ref->{$DB_KEY_NAME}   eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_KEY_VALUE}  || $parm_ref->{$DB_KEY_VALUE}  eq '' ) { confess Dumper $parm_ref; }
    my $table   = $parm_ref->{$DB_TABLE_NAME};
    my $keyname = $parm_ref->{$DB_KEY_NAME};
    my $keyval  = $parm_ref->{$DB_KEY_VALUE};

    if ( 3 >= keys(%$parm_ref) ) { confess Dumper $parm_ref; }

    # if ( !defined $tablenames{$table} ) { confess "No Table $table\n" . Dumper $parm_ref; }
    # if ( !defined $keynames{$keyname} ) { confess "No Key $keyname\n" . Dumper $parm_ref; }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . Dumper $parm_ref );

    foreach my $s ( keys(%$parm_ref) ) {
        if ( $s =~ /^UPDATE_/ ) {
            my $value = $parm_ref->{$s};
            $s =~ s/^UPDATE_//;
            my $name = $s;

            if ( !defined $value ) {
                cluck MYNAMELINE() . " undefined variables passed in" . Dumper $parm_ref;
            }

            my $sql = "UPDATE $table SET $name = "
              . ( ( $value ne '' ) && ( isdigit($value) || $value eq 'NULL' || $value eq 'true' || $value eq 'false' )
                ? " $value " : " '$value' " )
              . " WHERE $keyname = "
              . ( ( isdigit($keyval) ) ? " $keyval " : " '$keyval' " );

            EventLog( EVENT_DEBUG, MYNAMELINE() . "sql:" . $sql );

            if ( $self->sqldo($sql) ) {
                $ret++;
            }
            else {
                EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
            }
        }
    }
    $ret;
}

#-------------------------------------------------------
#
# FIXME, combine with update_macid_lastseen
#-------------------------------------------------------
sub update_mac_lastseen($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $lastseen = '';

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( defined $parm_ref->{$DB_COL_MAC_ID} ) && ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_MAC_LS} ) && ( $parm_ref->{$DB_COL_MAC_LS} eq '' ) ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_MAC_LS} ) {
        $lastseen = $parm_ref->{$DB_COL_MAC_LS};
    }
    else {
        $lastseen = NACMisc::get_current_timestamp();
    }

    my %parm = ();
    $parm{$DB_TABLE_NAME}    = $DB_TABLE_MAC;
    $parm{$DB_KEY_NAME}      = $DB_KEY_MACID;
    $parm{$DB_KEY_VALUE}     = $parm_ref->{$DB_COL_MAC_ID};
    $parm{'UPDATE_lastseen'} = $lastseen;
    $ret                     = $self->update_record( \%parm );

    $ret;
}

#-------------------------------------------------------
sub update_mac_coe_true($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my %parm     = ();

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_MAC_ID} ) || ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " MACID:" . $parm_ref->{$DB_COL_MAC_ID} );

    $parm{$DB_COL_MAC_ID}  = $parm_ref->{$DB_COL_MAC_ID};
    $parm{$DB_COL_MAC_COE} = 1;
    $ret                   = $self->update_mac_coe( \%parm );
    $ret;
}

#-------------------------------------------------------
sub update_mac_coe_false($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my %parm     = ();

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_MAC_ID} ) || ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " MACID:" . $parm_ref->{$DB_COL_MAC_ID} );

    $parm{$DB_COL_MAC_ID}  = $parm_ref->{$DB_COL_MAC_ID};
    $parm{$DB_COL_MAC_COE} = 0;
    $ret                   = $self->update_mac_coe( \%parm );
    $ret;
}

#-------------------------------------------------------
sub update_mac_coe($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $coe      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( !defined $parm_ref->{$DB_COL_MAC_ID} )  || ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) )  { confess Dumper $parm_ref; }
    if ( ( !defined $parm_ref->{$DB_COL_MAC_COE} ) || ( !( isdigit $parm_ref->{$DB_COL_MAC_COE} ) ) ) { confess Dumper $parm_ref; }

    $coe = ( $parm_ref->{$DB_COL_MAC_COE} ) ? 1 : 0;

    my %parm = ();
    $parm{$DB_TABLE_NAME} = $DB_TABLE_MAC;
    $parm{$DB_KEY_NAME}   = $DB_KEY_MACID;
    $parm{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_MAC_ID};
    $parm{'UPDATE_coe'}   = $coe;
    $ret                  = $self->update_record( \%parm );

    $ret;
}

#-------------------------------------------------------
#
#
#-------------------------------------------------------
sub update_switch_lastseen($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $lastseen = '';

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( defined $parm_ref->{$DB_COL_SW_ID} ) && ( !( isdigit $parm_ref->{$DB_COL_SW_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_SW_LS} ) && ( $parm_ref->{$DB_COL_SW_LS} eq '' ) ) { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_SW_LS} ) {
        $lastseen = $parm_ref->{$DB_COL_SW_LS};
    }
    else {
        $lastseen = NACMisc::get_current_timestamp();
    }

    my %parm = ();
    $parm{$DB_TABLE_NAME}    = $DB_TABLE_SWITCH;
    $parm{$DB_KEY_NAME}      = $DB_KEY_SWITCHID;
    $parm{$DB_KEY_VALUE}     = $parm_ref->{$DB_COL_SW_ID};
    $parm{'UPDATE_lastseen'} = $lastseen;
    $ret                     = $self->update_record( \%parm );

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub update_mac_comment_insert($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $lastseen = '';
    my %parm     = ();

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ( defined $parm_ref->{$DB_COL_MAC_ID} ) && ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( ( defined $parm_ref->{$DB_COL_MAC_COM} ) && ( $parm_ref->{$DB_COL_MAC_COM} eq '' ) ) { confess Dumper $parm_ref; }

    my $macid          = $parm_ref->{$DB_COL_MAC_ID};
    my $insert_comment = $parm_ref->{$DB_COL_MAC_COM};
    my $comment        = '';

    %parm = ();
    $parm{$DB_COL_MAC_ID} = $macid;
    if ( $self->get_mac( \%parm ) ) {
        $comment = $parm{$DB_COL_MAC_COM};
    }

    %parm                   = ();
    $parm{$DB_TABLE_NAME}   = $DB_TABLE_MAC;
    $parm{$DB_KEY_NAME}     = $DB_KEY_MACID;
    $parm{$DB_KEY_VALUE}    = $parm_ref->{$DB_COL_MAC_ID};
    $parm{'UPDATE_comment'} = $insert_comment . "\n" . $comment;
    $ret                    = $self->update_record( \%parm );

    $ret;
}

#-------------------------------------------------------
#
# FIXME, combine with update_macid_lastseen
#-------------------------------------------------------
sub update_switchportstate_lastseen($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID} && ( !( isdigit $parm_ref->{$DB_COL_SWPS_SWPID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID} && ( !( isdigit abs( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) ) { confess Dumper $parm_ref; }

    my $swpid = $parm_ref->{$DB_COL_SWPS_SWPID};
    my $macid = $parm_ref->{$DB_COL_SWPS_MACID};
    my $where = 0;

    if ( !( defined $swpid || defined $macid ) ) { confess Dumper $parm_ref; }

    my $sql = "UPDATE switchportstate SET lastupdate = CURRENT_TIMESTAMP() "
      . ( ( defined $swpid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchportid = $swpid " : '' )
      . ( ( defined $macid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $macid "        : '' )
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    $ret;
}

#-------------------------------------------------------
#
# FIXME, combine with update_macid_lastseen
#-------------------------------------------------------
sub update_switchportstate_statechange($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$DB_COL_SWPS_SWPID} && ( !( isdigit $parm_ref->{$DB_COL_SWPS_SWPID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_SWPS_MACID} && ( !( isdigit abs( $parm_ref->{$DB_COL_SWPS_MACID} ) ) ) ) { confess Dumper $parm_ref; }

    my $swpid = $parm_ref->{$DB_COL_SWPS_SWPID};
    my $macid = $parm_ref->{$DB_COL_SWPS_MACID};
    my $where = 0;

    if ( !( defined $swpid || defined $macid ) ) { confess Dumper $parm_ref; }

    my $sql = "UPDATE switchportstate SET stateupdate = CURRENT_TIMESTAMP() "
      . ( ( defined $swpid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " switchportid = $swpid " : '' )
      . ( ( defined $macid ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $macid "        : '' )
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    $ret;
}

#-------------------------------------------------------
#
# FIXME, combine with update_macid_lastseen
#-------------------------------------------------------
sub update_macid_lastseen($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_MAC_ID} || ( !( isdigit $parm_ref->{$DB_COL_MAC_ID} ) ) ) { confess Dumper $parm_ref; }
    my $macid = $parm_ref->{$DB_COL_MAC_ID};

    my $sql = "UPDATE mac SET lastseen = CURRENT_TIMESTAMP() WHERE macid = $macid ";

    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    $ret;
}

#-------------------------------------------------------
#
# Used to update a particular vlan group
# Expects a HASH of MACs as Input
# Each MAC is expected to have a single MAC2CLASS entry
# for the CLASSID and VLANGROUPID provided
# Entries are Added, Removed, Updated, or left in place
#
# Focus on the M2C table, look for a MACID and CLASSID match (these two are unique)
# Check the VLANGROUPID entry
#
#-------------------------------------------------------
sub update_mac2class_vlangroup() {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE . "Called" );
    EventLog( EVENT_DEBUG, MYNAMELINE . Dumper $parm_ref );

    eval {

        # Trust, but Verify
        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_M2C_CLASSID} && ( !( isdigit $parm_ref->{$DB_COL_M2C_CLASSID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_VGID}    && ( !( isdigit $parm_ref->{$DB_COL_M2C_VGID} ) ) )    { confess Dumper $parm_ref; }
        if ( !defined $parm_ref->{$DB_M2C_IN_HASH_REF} ) { confess Dumper $parm_ref; }

        if ( defined $parm_ref->{$DB_COL_CLASS_NAME} && ( $parm_ref->{$DB_COL_CLASS_NAME} eq '' ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VG_NAME}    && ( $parm_ref->{$DB_COL_VG_NAME}    eq '' ) ) { confess Dumper $parm_ref; }

        my $in_mac_ref = $parm_ref->{$DB_M2C_IN_HASH_REF};
        if ( ref($in_mac_ref) ne 'HASH' ) { confess; }

        my $classname     = $parm_ref->{$DB_COL_CLASS_NAME};
        my $vlangroupname = $parm_ref->{$DB_COL_VG_NAME};
        my $classid       = $parm_ref->{$DB_COL_M2C_CLASSID};
        my $vlangroupid   = $parm_ref->{$DB_COL_M2C_VGID};
        my $remove_flag   = ( defined $parm_ref->{$DB_M2C_REMOVE_FLAG} ) ? $parm_ref->{$DB_M2C_REMOVE_FLAG} : 0;
        my $update_flag   = ( defined $parm_ref->{$DB_M2C_UPDATE_FLAG} ) ? $parm_ref->{$DB_M2C_UPDATE_FLAG} : 0;
        my %parm          = ();
        my %m2c           = ();
        my $db_m2c_ref    = \%m2c;
        my $mac;

        #
        # Get the CLASSID or Name if neded
        #
        if ( !defined $classid ) {
            if ( !defined $classname ) { confess Dumper $parm_ref; }
            %parm = ();
            $parm{$DB_COL_CLASS_NAME} = $classname;
            if ( !$self->get_class( \%parm ) ) {
                EventLog( EVENT_WARN, MYNAMELINE . "Bad CLASSNAME:'$classname' passed in" );
                return 0;
            }
            $classid = $parm{$DB_COL_CLASS_ID};
        }
        else {
            %parm = ();
            $parm{$DB_COL_CLASS_ID} = $classid;
            if ( !$self->get_class( \%parm ) ) {
                EventLog( EVENT_WARN, MYNAMELINE . "Bad CLASSID:'$classid' passed in" );
                return 0;
            }
            $classname = $parm{$DB_COL_CLASS_NAME};
        }

        #
        # Get the VLANGROUPID or Name if neded
        #
        if ( !defined $vlangroupid ) {
            if ( !defined $vlangroupname ) { confess Dumper $parm_ref; }
            %parm = ();
            $parm{$DB_COL_VG_NAME} = $vlangroupname;
            if ( !$self->get_vlangroup( \%parm ) ) {
                EventLog( EVENT_WARN, MYNAMELINE . "Bad VLANGROUPNAME:'$vlangroupname' passed in" );
                return 0;
            }
            $vlangroupid = $parm{$DB_COL_VG_ID};
        }
        else {
            %parm = ();
            $parm{$DB_COL_VG_ID} = $vlangroupid;
            if ( !$self->get_vlangroup( \%parm ) ) {
                EventLog( EVENT_WARN, MYNAMELINE . "Bad VLANGROUPID:'$vlangroupid' passed in" );
                return 0;
            }
            $vlangroupname = $parm{$DB_COL_VG_NAME};
        }

        #
        # Pull all M2C records from the DB
        #
        %parm = (
            $DB_COL_M2C_VGID    => $vlangroupid,
            $DB_COL_M2C_CLASSID => $classid,
            'HASH_REF'          => $db_m2c_ref,
        );
        $self->get_mac2class( \%parm );

        # EventLog( EVENT_DEBUG, MYNAMELINE . "Pulled " . scalar(keys(%$in_mac_ref)) . " from the input" );
        # EventLog( EVENT_DEBUG, MYNAMELINE . "Pulled " . scalar(keys(%$db_m2c_ref)) . " from the database" );

        #
        # Check Each incoming MAC against the ACTIVE MAC list
        #
        foreach $mac ( sort( keys(%$in_mac_ref) ) ) {

            my $m2c_ref = $in_mac_ref->{$mac};

            my $macid   = $m2c_ref->{'MACID'};
            my $vgname  = $m2c_ref->{'VLANGROUPNAME'};
            my $lock    = ( defined $m2c_ref->{'LOCK'} ) ? $m2c_ref->{'LOCK'} : 0;
            my $pri     = ( defined $m2c_ref->{'PRI'} ) ? $m2c_ref->{'PRI'} : 0;
            my $expire  = ( defined $m2c_ref->{'EXPIRE'} ) ? $m2c_ref->{'EXPIRE'} : 0;
            my $comment = ( defined $m2c_ref->{'COMMENT'} ) ? $m2c_ref->{'COMMENT'} : 0;

            EventLog( EVENT_INFO, "Check IN MAC:$mac" . "[$macid] VLANGROUP:$vgname" );

            # EventLog( EVENT_DEBUG, MYNAMELINE . "Check IN MAC:$mac" );

            if ( $mac eq '00:00:00:00:00:00' ) { next; }

            if ( !_verify_MAC($mac) ) {
                confess;
            }

            if ( !defined $macid ) {
                %parm = ();
                $parm{$DB_COL_MAC_MAC} = $mac;
                if ( !$self->get_mac( \%parm ) ) {
                    $self->add_mac( \%parm );
                }
                $macid = $parm{$DB_COL_MAC_ID};
            }

            %parm = ();
            %parm = (
                $DB_COL_M2C_MACID   => $macid,
                $DB_COL_M2C_CLASSID => $classid,
            );

            #
            # No MACID/CLASSID Entry, so add it
            #
            if ( !( $self->get_mac2class( \%parm ) ) ) {
                if ( !$self->add_mac2class( {
                            $DB_COL_M2C_MACID   => $macid,
                            $DB_COL_M2C_CLASSID => $classid,
                            $DB_COL_M2C_VGID    => $vlangroupid,
                            $DB_COL_M2C_COM     => $comment,
                            $DB_COL_M2C_LOCKED  => $lock,
                            $DB_COL_M2C_PRI     => $pri,
                            $DB_COL_M2C_EXPIRE  => $expire,
                        }, ) ) {
                    confess " adding mac2class failed\n";
                }
            }

            #
            # There is a MACID/CLASSID Entry with no VLANGROUPID
            #
            elsif ( !defined $parm{$DB_COL_M2C_VGID} ) {

                #
                if ($update_flag) {
                    my %p     = ();
                    my $m2cid = $parm{$DB_COL_M2C_ID};
                    $p{$DB_TABLE_NAME}       = $DB_TABLE_MAC2CLASS;
                    $p{$DB_KEY_NAME}         = $DB_KEY_MAC2CLASSID;
                    $p{$DB_KEY_VALUE}        = $m2cid;
                    $p{'UPDATE_vlangroupid'} = $vlangroupid;
                    $p{'UPDATE_comment'}     = $comment;
                    $p{'UPDATE_expire'}      = $expire;
                    $p{'UPDATE_priority'}    = $pri;
                    $p{'UPDATE_lock'}        = $lock;
                    if ( !$self->update_record( \%p ) ) {
                        EventLog( EVENT_DB_ERR, MYNAMELINE() . " Failed to update MAC2CLASS VLANGROUPID for M2CID:$m2cid" );
                    }
                    else {
                        EventLog( EVENT_MAC2CLASS_UPD, "M2CID"
                              . "[$m2cid] MAC:$mac"
                              . "[$macid], CLASS:$classname"
                              . "[$classid], with OLD VG:x"
                              . "[0], -> NEW VG:$vlangroupname"
                              . "[$vlangroupid]"
                        );
                    }
                }
                else {
                    EventLog( EVENT_WARN, MYNAMELINE
                          . "Got M2C with no VGID - MAC:$mac"
                          . "[$macid], CLASS:$classname"
                          . "[$classid], set UPDATE_FLAG to -> VG:$vlangroupname"
                          . "[$vlangroupid]"
                    );
                }
            }

            #
            # There is a MACID/CLASSID Entry with different VLANGROUPID
            #
            elsif ( $parm{$DB_COL_M2C_VGID} != $vlangroupid ) {
                my %p      = ();
                my $oldvgn = '';
                my $oldvid = $parm{$DB_COL_M2C_VGID};
                $p{$DB_COL_VG_ID} = $oldvid;
                $self->get_vlangroup( \%p );
                $oldvgn = ( defined $p{$DB_COL_VG_NAME} ) ? $p{$DB_COL_VG_NAME} : '';

                #
                if ($update_flag) {
                    my %p     = ();
                    my $m2cid = $parm{$DB_COL_M2C_ID};
                    $p{$DB_TABLE_NAME}       = $DB_TABLE_MAC2CLASS;
                    $p{$DB_KEY_NAME}         = $DB_KEY_MAC2CLASSID;
                    $p{$DB_KEY_VALUE}        = $m2cid;
                    $p{'UPDATE_vlangroupid'} = $vlangroupid;
                    $p{'UPDATE_comment'}     = $comment;
                    $p{'UPDATE_expire'}      = $expire;
                    $p{'UPDATE_priority'}    = $pri;
                    $p{'UPDATE_lock'}        = $lock;
                    if ( !$self->update_record( \%p ) ) {
                        EventLog( EVENT_DB_ERR, MYNAMELINE() . " Failed to update MAC2CLASS VLANGROUPID for M2CID:$m2cid" );
                    }
                    else {
                        EventLog( EVENT_MAC2CLASS_UPD, "M2CID"
                              . "[$m2cid] MAC:$mac"
                              . "[$macid], CLASS:$classname"
                              . "[$classid], with OLD VG:$oldvgn"
                              . "[$oldvid], -> NEW VG:$vlangroupname"
                              . "[$vlangroupid]"
                        );
                    }
                }
                else {
                    EventLog( EVENT_WARN, MYNAMELINE
                          . "Got M2C - MAC:$mac"
                          . "[$macid], CLASS:$classname"
                          . "[$classid], with VG:$oldvgn"
                          . "[$oldvid], set UPDATE_FLAG to -> VG:$vlangroupname"
                          . "[$vlangroupid]"
                    );
                }

            }

            #
            # There is a MACID/CLASSID That matches
            #
            else {
                EventLog( EVENT_DEBUG, MYNAMELINE
                      . "Got M2C - MAC:$mac"
                      . "[$macid]"
                      . " record is good to go"
                );
            }
        }

        #
        # Check Each DB MAC against the incoming MAC list
        #
        foreach my $m2cid ( sort( keys(%$db_m2c_ref) ) ) {
            my $macid  = $db_m2c_ref->{$m2cid}->{$DB_COL_M2C_MACID};
            my $oldvid = $db_m2c_ref->{$m2cid}->{$DB_COL_M2C_VGID};

            my $mac    = '';
            my %p      = ();
            my $oldvgn = '';
            if ( isdigit($oldvid) && $oldvid ) {
                $p{$DB_COL_VG_ID} = $oldvid;
                $self->get_vlangroup( \%p );
                $oldvgn = ( defined $p{$DB_COL_VG_NAME} ) ? $p{$DB_COL_VG_NAME} : '';
            }

            %p = ();
            $p{$DB_COL_MAC_ID} = $macid;
            if ( !$self->get_mac( \%p ) ) {

                #
                # Found M2C record, but MACID D.N.E.
                #
                if ($remove_flag) {
                    if ( !$self->remove_mac2class( {
                                $DB_COL_M2C_ID => $m2cid,
                            } ) ) {
                        EventLog( EVENT_ERR, MYNAMELINE
                              . "remove_mac2class FAILED - M2CID:"
                              . "[$m2cid] MACID:"
                              . "[$macid], CLASS:$classname"
                              . "[$classid], with VG:$oldvgn"
                              . "[$oldvid], set REMOVE_FLAG to remove"
                        );
                        confess;
                    }
                    else {
                        EventLog( EVENT_MAC2CLASS_DEL, "M2CID"
                              . "[$m2cid] MAC:$mac"
                              . "[$macid], CLASS:$classname"
                              . "[$classid], VG:$oldvgn"
                              . "[$oldvid]"
                        );
                    }
                }
                else {
                    EventLog( EVENT_ERR, MYNAMELINE
                          . "Got M2C record with no MAC record - MACID:"
                          . "[$macid], CLASS:$classname"
                          . "[$classid], with VG:$oldvgn"
                          . "[$oldvid], set REMOVE_FLAG to remove"
                    );
                }
                next;
            }
            $mac = ( defined $p{$DB_COL_MAC_MAC} ) ? $p{$DB_COL_MAC_MAC} : 'no mac';

            EventLog( EVENT_DEBUG, MYNAMELINE . "Check DB MAC:$mac" );

            #
            # Is there a coresponding input MAC for this database MAC?
            #
            if ( !defined $in_mac_ref->{$mac} ) {

                # Remove MAC to Class record
                if ($remove_flag) {
                    %parm = ();
                    if ( !$self->remove_mac2class( {
                                $DB_COL_M2C_ID => $m2cid,
                            } ) ) {
                        confess "remove mac2class failed\n";
                    }
                    else {
                        EventLog( EVENT_MAC2CLASS_DEL, "M2CID:"
                              . "[$m2cid] MAC:$mac"
                              . "[$macid], CLASS:$classname"
                              . "[$classid], VG:$oldvgn"
                              . "[$oldvid]"
                        );
                    }
                }
                else {
                    EventLog( EVENT_WARN, MYNAMELINE
                          . "Got M2C record with no INPUT - MAC:$mac"
                          . "[$macid], CLASS:$classname"
                          . "[$classid], with VG:$oldvgn"
                          . "[$oldvid], set REMOVE_FLAG to remove"
                    );
                }
            }
        }

    };
    LOGEVALFAIL() if ($@);

    $ret;
}

#-------------------------------------------------------
#
#
# Verify MAC2CLASS and PORT2CLASS are not locked
#
#-------------------------------------------------------
sub remove_class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_CLASS_ID} && !isdigit( $parm_ref->{$DB_COL_CLASS_ID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_CLASS_NAME} && $parm_ref->{$DB_COL_CLASS_NAME} eq '' ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_CLASS_VGID} && !isdigit( $parm_ref->{$DB_COL_CLASS_VGID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }
        my $classid   = $parm_ref->{$DB_COL_CLASS_ID};
        my $classname = $parm_ref->{$DB_COL_CLASS_NAME};
        my $vgid      = $parm_ref->{$DB_COL_CLASS_VGID};

        if ( !( defined $classid || defined $classname || defined $vgid ) ) { confess Dumper $parm_ref; }

        my %class = ();
        $parm_ref->{HASH_REF} = \%class;

        if ( !$self->get_class($parm_ref) ) {
            return 0;
        }

        foreach $classid ( keys(%class) ) {
            my $classname = $class{$classid}->{$DB_COL_CLASS_NAME};

            if ( $class{$classid}->{$DB_COL_CLASS_LOCKED} ) {
                EventLog( EVENT_WARN, "Remove Class called on LOCKED class $classname" . "[$classid], aborting" );
                $self->seterr('REMOVING LOCKED CLASS RECORDS');
                return 0;
            }

            #
            # Get MAC2CLASS (check for locks)
            #

            my %m2p = ();
            $m2p{$DB_COL_M2C_CLASSID} = $classid;
            $m2p{$DB_COL_M2C_LOCKED}  = 1;
            if ( $self->get_mac2class( \%m2p ) ) {
                EventLog( EVENT_WARN, "Remove Class called on class $classname" . "[$classid] with LOCKED M2C records, aborting" );
                $self->seterr('REMOVING CLASS WITH LOCKED MAC2CLASS RECORDS');
                return 0;
            }

            #
            # Get PORT2CLASS (check for locks)
            #

            my %p2p = ();
            $m2p{$DB_COL_P2C_CLASSID} = $classid;
            $m2p{$DB_COL_P2C_LOCKED}  = 1;
            if ( $self->get_port2class( \%m2p ) ) {
                EventLog( EVENT_WARN, "Remove Class called on class $classname" . "[$classid] with LOCKED P2C records, aborting" );
                $self->seterr('REMOVING CLASS WITH LOCKED PORT2CLASS RECORDS');
                return 0;
            }

            #
            # Remove MAC2CLASS
            #

            %m2p = ();
            $m2p{$DB_COL_M2C_CLASSID} = $classid;
            $self->remove_mac2class( \%m2p );
            if ( $self->err() ) {
                EventLog( EVENT_DB_ERR, "Remove for CLASS:$classname" . "[$classid] FAILED to delete M2C records, " . $self->errstr . ", aborting" );
                return 0;
            }

            #
            # Remove PORT2CLASS
            #

            %p2p = ();
            $p2p{$DB_COL_P2C_CLASSID} = $classid;
            $self->remove_port2class( \%p2p );
            if ( $self->err() ) {
                EventLog( EVENT_DB_ERR, "Remove for CLASS:$classname" . "[$classid] FAILED to delete P2C records, aborting" );
                return 0;
            }

            my %record  = ();
            my $table   = $record{$DB_TABLE_NAME} = $DB_TABLE_CLASS;
            my $keyname = $record{$DB_KEY_NAME} = $DB_KEY_CLASSID;
            my $keyval  = $record{$DB_KEY_VALUE} = $classid;

            if ( !( $ret = $self->_delete_record( \%record ) ) ) {
                EventLog( EVENT_DB_ERR, "Remove for CLASS:$classname" . "[$classid] FAILED to delete CLASS record, aborting" );
                return 0;
            }

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO    => EVENT_INFO,
                    $EVENT_PARM_TYPE    => EVENT_CLASS_DEL,
                    $EVENT_PARM_CLASSID => $classid,
            } );

            #EventLog( EVENT_CLASS_DEL,
            #    "'$classname'"
            #      . "[$classid] "
            #);
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_location($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_LOC_ID} && !isdigit( $parm_ref->{$DB_COL_LOC_ID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_LOC_SITE} && $parm_ref->{$DB_COL_LOC_SITE} eq '' ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_LOC_BLDG} && $parm_ref->{$DB_COL_LOC_BLDG} eq '' ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }
        my $locid = $parm_ref->{$DB_COL_LOC_ID};
        my $site  = $parm_ref->{$DB_COL_LOC_SITE};
        my $bldg  = $parm_ref->{$DB_COL_LOC_BLDG};

        if ( !$self->get_location($parm_ref) ) {
            return 0;
        }

        $locid = $parm_ref->{$DB_COL_LOC_ID};
        $site  = $parm_ref->{$DB_COL_LOC_SITE};
        $bldg  = $parm_ref->{$DB_COL_LOC_BLDG};
        my $location = $parm_ref->{$DB_COL_LOC_SHORTNAME};

        if ( !defined $locid ) { confess; }

        my %switch = ();
        $switch{$DB_COL_SW_LOCID} = $locid;
        $self->remove_switch( \%switch );
        if ( $self->err() ) {
            EventLog( EVENT_DB_ERR, "Remove for LOC:$location" . "[$locid] SITE:$site BLDG:$bldg FAILED to delete SWITCH records, " . $self->errstr . ", aborting" );
            $self->seterr( "Remove for LOC:$location" . "[$locid] SITE:$site BLDG:$bldg FAILED to delete SWITCH records, " . $self->errstr . ", aborting" );
            return 0;
        }

        my %vlan = ();
        $vlan{$DB_COL_VLAN_LOCID} = $locid;
        $self->remove_vlan( \%vlan );
        if ( $self->err() ) {
            EventLog( EVENT_DB_ERR, "Remove for LOC:$location" . "[$locid] SITE:$site BLDG:$bldg FAILED to delete VLAN records, " . $self->errstr . ", aborting" );
            $self->seterr( "Remove for LOC:$location" . "[$locid] SITE:$site BLDG:$bldg FAILED to delete VLAN records, " . $self->errstr . ", aborting" );
            return 0;
        }

        my $table   = $parm_ref->{$DB_TABLE_NAME} = $DB_TABLE_LOCATION;
        my $keyname = $parm_ref->{$DB_KEY_NAME}   = $DB_KEY_LOCATIONID;
        my $keyval  = $parm_ref->{$DB_KEY_VALUE}  = $locid;

        if ( !( $ret = $self->_delete_record($parm_ref) ) ) {
            EventLog( EVENT_DB_ERR, "Remove for LOCATION:$location" . "[$locid] FAILED to delete LOCATION record, aborting" );
            $self->seterr( "Remove for LOCATION:$location" . "[$locid] FAILED to delete LOCATION record, aborting" );
            return 0;
        }
        $self->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_INFO,
                $EVENT_PARM_TYPE  => EVENT_LOC_DEL,
                $EVENT_PARM_LOCID => $locid,
        } );

        #EventLog( EVENT_LOC_DEL,
        #    "'$location'"
        #      . "[$locid] "
        #);

    };
    LOGEVALFAIL() if ($@);
    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_loopcidr2locid($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_LOOP_ID} && !isdigit( $parm_ref->{$DB_COL_LOOP_ID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my %p;
        $p{$DB_TABLE_NAME} = $DB_TABLE_LOOPCIDR2LOC;
        $p{$DB_KEY_NAME}   = $DB_KEY_LOOPCIDR2LOCID;
        $p{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_LOOP_ID};

        if ( !( $ret = $self->_delete_record( \%p ) ) ) {
            $self->seterr( MYNAMELINE . " ID:$parm_ref->{$DB_COL_LOOP_ID}" );
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;

}

#-------------------------------------------------------
#
# Collect MACID and MACTYPEID for mac, and name
# If they both exist then add a MAC2TYPE record
#
#-------------------------------------------------------
sub remove_mac2class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_M2C_ID}      && !isdigit( $parm_ref->{$DB_COL_M2C_ID} ) )      { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_MACID}   && !isdigit( $parm_ref->{$DB_COL_M2C_MACID} ) )   { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_CLASSID} && !isdigit( $parm_ref->{$DB_COL_M2C_CLASSID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_VGID}    && !isdigit( $parm_ref->{$DB_COL_M2C_VGID} ) )    { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_VLANID}  && !isdigit( $parm_ref->{$DB_COL_M2C_VLANID} ) )  { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_M2C_TEMPID}  && !isdigit( $parm_ref->{$DB_COL_M2C_TEMPID} ) )  { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $macid       = $parm_ref->{$DB_COL_M2C_MACID};
        my $classid     = $parm_ref->{$DB_COL_M2C_CLASSID};
        my $id          = $parm_ref->{$DB_COL_M2C_ID};
        my $templateid  = $parm_ref->{$DB_COL_M2C_TEMPID};
        my $vlangroupid = $parm_ref->{$DB_COL_M2C_VGID};
        my $vlanid      = $parm_ref->{$DB_COL_M2C_VLANID};

        if ( !( defined $id || defined $classid || defined $macid ) ) {
            confess MYNAMELINE . " ID, CLASSID, or MACID required";
        }

        my $mac   = '';
        my $class = '';
        my %p;
        my %m2c;

        if ( defined $macid ) {
            $p{$DB_COL_M2C_MACID} = $macid;
            my %q;
            $q{$DB_COL_MAC_ID} = $macid;
            $self->get_mac( \%q );
            $mac = "MAC:" . $q{$DB_COL_MAC_MAC} . "[$macid]";
        }
        if ( defined $classid ) {
            $p{$DB_COL_M2C_CLASSID} = $classid;
            my %q;
            $q{$DB_COL_CLASS_ID} = $classid;
            $self->get_class( \%q );
            $class = "CLASS:" . $q{$DB_COL_CLASS_NAME} . "[$classid]";
        }
        if ( defined $id ) {
            $p{$DB_COL_M2C_ID} = $id;
        }
        if ( defined $vlanid ) {
            $p{$DB_COL_M2C_VLANID} = $vlanid;
        }
        if ( defined $vlangroupid ) {
            $p{$DB_COL_M2C_VGID} = $vlangroupid;
        }
        if ( defined $templateid ) {
            $p{$DB_COL_M2C_TEMPID} = $templateid;
        }

        $p{$DB_COL_M2C_LOCKED} = 1;

        # There is a locked record...
        if ( $self->get_mac2class( \%p ) ) {
            EventLog( EVENT_WARN, " locked M2C records $id $class $mac" );
            $self->seterr('MAC2CLASS Record is Locked, ID:$id MACID:$macid CLASSID:$classid');
            return 0;
        }

        $p{$HASH_REF}          = \%m2c;
        $p{$DB_COL_M2C_LOCKED} = 0;
        if ( !$self->get_mac2class( \%p ) ) {
            EventLog( EVENT_WARN, " Cant Find M2C record: $id $class $mac" );
            return 0;
        }

        foreach my $m2cid ( sort { $a <=> $b } ( keys(%m2c) ) ) {
            my $classname     = '';
            my $mac           = '';
            my $vlanname      = '';
            my $vlangroupname = '';
            my $templatename  = '';
            my %p             = ();

            $p{$DB_COL_M2C_ID} = $m2cid;
            if ( !$self->get_mac2class( \%p ) ) {
                EventLog( EVENT_DB_ERR, MYNAMELINE . "M2CID:$m2cid not found, skipping" );
                next;
            }
            my $m_classid     = $p{$DB_COL_M2C_CLASSID};
            my $m_macid       = $p{$DB_COL_M2C_MACID};
            my $m_vlangroupid = $p{$DB_COL_M2C_VGID};
            my $m_templateid  = $p{$DB_COL_M2C_TEMPID};
            my $m_vlanid      = $p{$DB_COL_M2C_VLANID};

            %p                 = ();
            $p{$DB_TABLE_NAME} = $DB_TABLE_MAC2CLASS;
            $p{$DB_KEY_NAME}   = $DB_KEY_MAC2CLASSID;
            $p{$DB_KEY_VALUE}  = $m2cid;
            if ( !$self->_delete_record( \%p ) ) {
                EventLog( EVENT_DB_ERR, "Remove failed, M2CID:$m2cid $class $mac " );
                $self->seterr("Remove failed, M2CID:$m2cid $class $mac ");
                return 0;
            }
            $ret++;

            %p = ();
            $p{$DB_COL_CLASS_ID} = $m_classid;
            $self->get_class( \%p );
            $classname = ( defined $p{$DB_COL_CLASS_NAME} ) ? $p{$DB_COL_CLASS_NAME} : '';

            %p = ();
            $p{$DB_COL_MAC_ID} = $m_macid;
            $self->get_mac( \%p );
            $mac = ( defined $p{$DB_COL_MAC_MAC} ) ? $p{$DB_COL_MAC_MAC} : '';

            %p = ();
            $p{$DB_COL_VLAN_ID} = $m_vlanid;
            $self->get_vlan( \%p );
            $vlanname = ( defined $p{$DB_COL_VLAN_NAME} ) ? $p{$DB_COL_VLAN_NAME} : 'x';

            %p = ();
            $p{$DB_COL_VG_ID} = $m_vlangroupid;
            $self->get_vlangroup( \%p );
            $vlangroupname = ( defined $p{$DB_COL_VG_NAME} ) ? $p{$DB_COL_VG_NAME} : 'x';

            %p = ();
            $p{$DB_COL_TEMP_ID} = $m_templateid;
            $self->get_template( \%p );
            $templatename = ( defined $p{$DB_COL_TEMP_NAME} ) ? $p{$DB_COL_TEMP_NAME} : 'x';

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO    => EVENT_INFO,
                    $EVENT_PARM_TYPE    => EVENT_MAC2CLASS_DEL,
                    $EVENT_PARM_MACID   => $m_macid,
                    $EVENT_PARM_CLASSID => $m_classid,
                    $EVENT_PARM_VLANID  => $m_vlanid,
                    $EVENT_PARM_VGID    => $m_vlangroupid,
                    $EVENT_PARM_TEMPID  => $m_templateid,
            } );

            #EventLog( EVENT_MAC2CLASS_DEL,
            #    "M2CID:"
            #      . "[$m2cid], "
            #      . "MAC:'$mac'"
            #      . "[$macid], "
            #      . "CLASS:'$classname'"
            #      . "[$classid], "
            #      . "VLAN:'$vlanname'"
            #      . "[$vlanid], "
            #      . "VLANGROUP:'$vlangroupname'"
            #      . "[$vlangroupid], "
            #      . "TEMPLATE:'$templatename'"
            #      . "[$templateid], "
            #);
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
sub remove_port2class($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_P2C_ID}      && !isdigit( $parm_ref->{$DB_COL_P2C_ID} ) )      { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_P2C_SWPID}   && !isdigit( $parm_ref->{$DB_COL_P2C_SWPID} ) )   { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_P2C_CLASSID} && !isdigit( $parm_ref->{$DB_COL_P2C_CLASSID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $id      = $parm_ref->{$DB_COL_P2C_ID};
        my $swpid   = $parm_ref->{$DB_COL_P2C_SWPID};
        my $classid = $parm_ref->{$DB_COL_P2C_CLASSID};
        my $swid;

        if ( !( defined $id || defined $swpid || defined $classid ) ) {
            confess "Need one of: P2CID, SWPID, CLASSID to delete a P2C record";
        }

        my $port   = '';
        my $switch = '';
        my $class  = '';

        my %p = ();
        my %p2c;

        if ( defined $swpid ) {
            $p{$DB_COL_P2C_SWPID} = $swpid;
            my %q;
            $q{$DB_COL_SWP_ID} = $swpid;
            $self->get_switchport( \%q );
            $port = "PORT:" . $q{$DB_COL_SWP_NAME} . "[$swpid]";
            if ( $swid = $q{$DB_COL_SWP_SWID} ) {
                %q = ();
                $q{$DB_COL_SW_ID} = $swid;
                $self->get_switchport( \%q );
                $switch = "SWITCH:" . $q{$DB_COL_SW_NAME} . "[$swid]";
            }
        }
        if ( defined $classid ) {
            $p{$DB_COL_P2C_CLASSID} = $classid;
            my %q;
            $q{$DB_COL_CLASS_ID} = $classid;
            $self->get_class( \%q );
            $class = "CLASS:" . $q{$DB_COL_CLASS_NAME} . "[$classid]";
        }
        if ( defined $id ) {
            $p{$DB_COL_P2C_ID} = $id;
        }

        $p{$DB_COL_P2C_LOCKED} = 1;

        # There is a locked record...
        if ( $self->get_port2class( \%p ) ) {
            EventLog( EVENT_WARN, " locked P2C records $id $class $switch $port" );
            $self->seterr('PORT2CLASS Record is Locked, ID:$id SWITCH:$switch PORT:$port CLASSID:$classid');
            return 0;
        }

        $p{$HASH_REF}          = \%p2c;
        $p{$DB_COL_P2C_LOCKED} = 0;
        if ( !$self->get_port2class( \%p ) ) {
            return 0;
        }

        foreach my $p2cid ( sort { $a <=> $b } ( keys(%p2c) ) ) {
            my $classid;
            my $classname;
            my $portid;
            my $portname;
            my $switchid;
            my $switchname;
            my $vlanname;
            my $vlangroupname;
            my $vlanid;
            my $vlangroupid;
            %p = ();

            $p{$DB_COL_P2C_ID} = $p2cid;
            if ( !$self->get_port2class( \%p ) ) {
                EventLog( EVENT_DB_ERR, MYNAMELINE . "P2CID:$p2cid not found, skipping" );
                next;
            }

            $classid     = $p{$DB_COL_P2C_CLASSID};
            $portid      = $p{$DB_COL_P2C_SWPID};
            $vlanid      = $p{$DB_COL_P2C_VLANID};
            $vlangroupid = $p{$DB_COL_P2C_VGID};

            %p                 = ();
            $p{$DB_TABLE_NAME} = $DB_TABLE_PORT2CLASS;
            $p{$DB_KEY_NAME}   = $DB_KEY_PORT2CLASSID;
            $p{$DB_KEY_VALUE}  = $p2cid;
            if ( !$self->_delete_record( \%p ) ) {
                EventLog( EVENT_DB_ERR, "Remove failed, P2CID:$p2cid $class $switch $port " );
                $self->seterr("Remove failed, P2CID:$p2cid $class $switch $port ");
                return 0;
            }
            $ret++;

            %p = ();
            $p{$DB_COL_CLASS_ID} = $classid;
            $self->get_class( \%p );
            $classname = $p{$DB_COL_CLASS_NAME};

            %p = ();
            $p{$DB_COL_SWP_ID} = $portid;
            $self->get_switchport( \%p );
            $portname = $p{$DB_COL_SWP_NAME};
            $switchid = $p{$DB_COL_SWP_SWID};

            %p = ();
            $p{$DB_COL_SW_ID} = $switchid;
            $self->get_switch( \%p );
            $switchname = $p{$DB_COL_SW_NAME};

            %p = ();
            $p{$DB_COL_VLAN_ID} = $vlanid;
            $self->get_vlan( \%p );
            $vlanname = $p{$DB_COL_VLAN_NAME};

            %p = ();
            $p{$DB_COL_VG_ID} = $vlangroupid;
            $self->get_vlangroup( \%p );
            $vlangroupname = $p{$DB_COL_VG_NAME};

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO    => EVENT_INFO,
                    $EVENT_PARM_TYPE    => EVENT_PORT2CLASS_DEL,
                    $EVENT_PARM_SWPID   => $swpid,
                    $EVENT_PARM_SWID    => $swid,
                    $EVENT_PARM_CLASSID => $classid,
                    $EVENT_PARM_VLANID  => $vlanid,
            } );

            #EventLog( EVENT_PORT2CLASS_DEL,
            #    "P2CID:"
            #      . "[$p2cid] "
            #      . "CLASS:$classname"
            #      . "[$classid] "
            #      . "SWITCH:$switchname"
            #      . "[$switchid] "
            #      . "PORT:$portname"
            #      . "[$portid] "
            #      . "VLAN:$vlanname"
            #      . "[$vlanid] "
            #      . "VLANGROUP:$vlangroupname"
            #      . "[$vlangroupid] "
            #);
        }
    };
    LOGEVALFAIL() if ($@);

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    if ( defined $parm_ref->{$DB_COL_RA_ID} && !isdigit( $parm_ref->{$DB_COL_RA_ID} ) ) { confess Dumper $parm_ref; }

    my %parm = ();
    $parm{$DB_TABLE_NAME} = $DB_TABLE_RADIUSAUDIT;
    $parm{$DB_KEY_NAME}   = $DB_KEY_RADIUSAUDITID;
    $parm{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_RA_ID};

    $ret = $self->_delete_record( \%parm );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_switch($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_SW_ID}    && !isdigit( $parm_ref->{$DB_COL_SW_ID} ) )    { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_SW_LOCID} && !isdigit( $parm_ref->{$DB_COL_SW_LOCID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_SW_IP} && $parm_ref->{$DB_COL_SW_IP} ne '' ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $switchid = $parm_ref->{$DB_COL_SW_ID};
        my $locid    = $parm_ref->{$DB_COL_SW_LOCID};
        my $ip       = $parm_ref->{$DB_COL_SW_IP};
        my $switchname;

        if ( !( defined $switchid || defined $locid || defined $ip ) ) {
            EventLog( EVENT_ERR, MYNAMELINE . " IP, LOCID, or IP required to remove switch, aborting function" );
            $self->seterr( MYNAMELINE . " IP, LOCID, or IP required to remove switch, aborting function" );
            return 0;
        }

        if ( !$self->get_switch($parm_ref) ) {
            EventLog( EVENT_WARN, "removing switch Failed, no ID: $switchid LOCID:$locid or IP:$ip" );
            return 0;
        }

        $switchname = $parm_ref->{$DB_COL_SW_NAME};
        $switchid   = $parm_ref->{$DB_COL_SW_ID};
        $locid      = $parm_ref->{$DB_COL_SW_LOCID};
        $ip         = $parm_ref->{$DB_COL_SW_IP};

        # Recursivly remove SWITCHPORTS
        my %p = ();
        $p{$DB_COL_SWP_SWID} = $switchid;
        $self->remove_switchport( \%p );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "removing switchports for SWITCH:$switchname" . "[$switchid], aborting" );
            return 0;
        }

        %p = ();
        $p{$DB_COL_SW2V_SWID} = $switchid;
        $self->remove_switch2vlan( \%p );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "removing switch2vlan records for SWITCH:$switchname" . "[$switchid], aborting" );
            return 0;
        }

        my $sql = "DELETE FROM switch WHERE switchid = $switchid ";
        if ( $self->sqldo($sql) ) {
            $ret++;
        }
        else {
            EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        }

        if ($ret) {
            $self->EventDBLog( {
                    $EVENT_PARM_PRIO => LOG_INFO,
                    $EVENT_PARM_TYPE => EVENT_SWITCH_DEL,
                    $EVENT_PARM_SWID => $switchid,
            } );

            # EventLog( EVENT_SWITCH_DEL, "SWITCH:$switchname" . "[$switchid]" );
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_switch2vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;
    my $count    = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_SW2V_ID}     && !isdigit( $parm_ref->{$DB_COL_SW2V_ID} ) )     { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_SW2V_SWID}   && !isdigit( $parm_ref->{$DB_COL_SW2V_SWID} ) )   { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_SW2V_VLANID} && !isdigit( $parm_ref->{$DB_COL_SW2V_VLANID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $id       = $parm_ref->{$DB_COL_SW2V_ID};
        my $switchid = $parm_ref->{$DB_COL_SW2V_SWID};
        my $vlanid   = $parm_ref->{$DB_COL_SW2V_VLANID};

        EventLog( EVENT_DEBUG, MYNAMELINE . "ID:$id SWID:$switchid VLANID:$vlanid" );

        # One of these is required
        if ( !( ( defined $id ) || ( defined $switchid ) || ( defined $vlanid ) ) ) { confess Dumper $parm_ref; }

        my $switch = '';
        my $vlan   = '';
        my %p      = ();
        my %sw2v   = ();

        if ( defined $switchid ) {
            my %q;
            $q{$DB_COL_SW_ID} = $switchid;
            $self->get_switch( \%q );
            $switch = "SWITCH:" . $q{$DB_COL_SW_NAME} . "[$switchid]";
            $p{$DB_COL_SW2V_SWID} = $switchid;
        }
        if ( defined $vlanid ) {
            my %q;
            $q{$DB_COL_VLAN_ID} = $vlanid;
            $self->get_vlan( \%q );
            $vlan = "VLAN:" . $q{$DB_COL_VLAN_NAME} . "[$vlanid]";
            $p{$DB_COL_SW2V_VLANID} = $vlanid;
        }
        if ( defined $id ) {
            $p{$DB_COL_SW2V_ID} = $id;
        }

        $p{$HASH_REF} = \%sw2v;
        if ( !( $count = $self->get_switch2vlan( \%p ) ) ) {
            return 0;
        }

        EventLog( EVENT_DEBUG, MYNAMELINE . "ID:$id SWID:$switchid VLANID:$vlanid" );

        foreach my $sw2vid ( sort { $a <=> $b } ( keys(%sw2v) ) ) {
            my $switch;
            my $switchid;
            my $vlan;
            my $vlanid;
            %p = ();

            $switchid = $sw2v{$sw2vid}->{$DB_COL_SW2V_SWID};
            $vlanid   = $sw2v{$sw2vid}->{$DB_COL_SW2V_VLANID};

            $p{$DB_TABLE_NAME} = $DB_TABLE_SWITCH2VLAN;
            $p{$DB_KEY_NAME}   = $DB_KEY_SWITCH2VLANID;
            $p{$DB_KEY_VALUE}  = $sw2vid;
            if ( !$self->_delete_record( \%p ) ) {
                EventLog( EVENT_DB_ERR, "Remove failed, SW2VID:$sw2vid $switch $vlan " );
                $self->seterr("Remove failed, SW2VID:$sw2vid $switch $vlan ");
                return 0;
            }
            $ret++;

            %p = ();
            $p{$DB_COL_SW_ID} = $switchid;
            $self->get_switch( \%p );
            $switch = ( defined $p{$DB_COL_SW_NAME} ) ? $p{$DB_COL_SW_NAME} : 'unknown';

            %p = ();
            $p{$DB_COL_VLAN_ID} = $vlanid;
            $self->get_vlan( \%p );
            $vlan = ( defined $p{$DB_COL_VLAN_NAME} ) ? $p{$DB_COL_VLAN_NAME} : 'unknwon';

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO   => LOG_INFO,
                    $EVENT_PARM_TYPE   => EVENT_SWITCH2VLAN_DEL,
                    $EVENT_PARM_SWID   => $switchid,
                    $EVENT_PARM_VLANID => $vlanid,
            } );
            EventLog( EVENT_SWITCH2VLAN_DEL,
                "SW2VID:"
                  . "[$sw2vid] "
                  . "SWITCH:$switch"
                  . "[$switchid] "
                  . "VLAN:$vlan "
                  . "[$vlanid] "
            );
        }

    };
    LOGEVALFAIL() if ($@);

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_switchport($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );

    eval {
        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_SWP_ID}   && ( !isdigit( $parm_ref->{$DB_COL_SWP_ID} ) ) )   { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_SWP_SWID} && ( !isdigit( $parm_ref->{$DB_COL_SWP_SWID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $switchportid = $parm_ref->{$DB_COL_SWP_ID};
        my $switchid     = $parm_ref->{$DB_COL_SWP_SWID};
        my $switchname;
        my $switchportname;

        if ( !( defined $switchid || defined $switchportid ) ) { confess Dumper $parm_ref; }

        my %switchport = ();
        $parm_ref->{HASH_REF} = \%switchport;
        $self->get_switchport($parm_ref);
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "get_switchport returned error SWPID:$switchportid SWID:$switchid, aborting" );
            return 0;
        }

        foreach $switchportid ( keys(%switchport) ) {

            $switchportname = $switchport{$switchportid}->{$DB_COL_SWP_NAME};

            if ( !defined $switchname ) {
                my %switch = ();

                $switch{$DB_COL_SW_ID} = $switchport{$switchportid}->{$DB_COL_SWP_SWID};

                if ( !$self->get_switch( \%switch ) ) {
                    EventLog( EVENT_DB_ERR, "SWID:$switchid does not exist, aborting" );
                    $self->seterr("SWID:$switchid does not exist, aborting");
                    return 0;
                }
                $switchname = $switch{$DB_COL_SW_NAME};
            }

            # Check each port2class record for locks
            # If there are locks, kick it back
            #
            my %p2cquery;
            my %p2c = ();
            $p2cquery{$HASH_REF}          = \%p2c;
            $p2cquery{$DB_COL_P2C_SWPID}  = $switchportid;
            $p2cquery{$DB_COL_P2C_LOCKED} = 1;
            if ( $self->get_port2class( \%p2cquery ) ) {
                EventLog( EVENT_WARN, "LOCKED PORT2CLASS record tied to switch port ID:$switchportid, aborting" );
                $self->seterr("LOCKED PORT2CLASS record tied to switch port ID:$switchportid, aborting");
                return 0;
            }
            if ( $self->err ) {
                EventLog( EVENT_DB_ERR, "error calling get_port2class SWP:$switchportname, SW:$switchname, aborting" );
                return 0;
            }

            %p2cquery = ();
            $p2cquery{$DB_COL_P2C_SWPID} = $switchportid;
            $self->remove_port2class( \%p2cquery );
            if ( $self->err ) {
                EventLog( EVENT_DB_ERR, "Could not remove_port2class, on SWP:$switchportname, SW:$switchname, aborting" );
                return 0;
            }

            #
            # Remove coresponding switch port state entry
            #
            # my %swps = ();
            # $swps{$DB_COL_SWPS_SWPID} = $switchportid;
            # if ( $self->get_switchportstate( \%swps ) ) {
            #     if ( !$self->remove_switchportstate( \%swps ) ) {
            #         # EventLog( EVENT_DB_ERR, "Remove SwitchPortState failed, SWPID:$switchportid PORT:$switchportname SW:$switchname " );
            #         # $self->seterr("Remove SwitchPortState failed, SW2VID:$switchportid PORT:$switchportname SW:$switchname ");
            #         # return 0;

            #       }
            # }

            my %parm = ();
            $parm{$DB_TABLE_NAME} = $DB_TABLE_SWITCHPORT;
            $parm{$DB_KEY_NAME}   = $DB_KEY_SWITCHPORTID;
            $parm{$DB_KEY_VALUE}  = $switchportid;
            if ( !$self->_delete_record( \%parm ) ) {
                EventLog( EVENT_DB_ERR, "Remove failed, SWPID:$switchportid PORT:$switchportname SW:$switchname " );
                $self->seterr("Remove failed, SWPID:$switchportid PORT:$switchportname SW:$switchname ");
                return 0;
            }
            $ret++;
            $self->EventDBLog( {
                    $EVENT_PARM_PRIO  => LOG_INFO,
                    $EVENT_PARM_TYPE  => EVENT_SWITCHPORT_DEL,
                    $EVENT_PARM_SWPID => $switchportid,
                    $EVENT_PARM_SWID  => $switchid,
            } );

            #EventLog( EVENT_SWITCHPORT_DEL,
            #    "SWPID:$switchportid "
            #      . "SWITCH:$switchname"
            #      . "[$switchid] "
            #      . "PORT:$switchportname "
            #);

        }
    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_switchportstate($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_SWPS_SWPID} && !isdigit( $parm_ref->{$DB_COL_SWPS_SWPID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_SWPS_MACID} && !isdigit( $parm_ref->{$DB_COL_SWPS_MACID} ) ) { confess Dumper $parm_ref; }

        if ( !( defined $parm_ref->{$DB_COL_SWPS_SWPID} || defined $parm_ref->{$DB_COL_SWPS_MACID} ) ) { confess Dumper $parm_ref; }

        if ( !$self->get_switchportstate($parm_ref) ) {
            return 0;
        }

        my $swpsid = $parm_ref->{$DB_COL_SWPS_SWPID};
        my $macid  = $parm_ref->{$DB_COL_SWPS_MACID};

        %parm                 = ();
        $parm{$DB_TABLE_NAME} = $DB_TABLE_SWITCHPORTSTATE;
        $parm{$DB_KEY_NAME}   = $DB_KEY_SWITCHPORTSTATEID;
        $parm{$DB_KEY_VALUE}  = $swpsid;
        if ( !$self->_delete_record( \%parm ) ) {
            EventLog( EVENT_DB_ERR, "Remove record: SWITCHPORTSTATEID:[$swpsid]" . ", aborting function..." );
            $self->seterr( "Remove record: SWITCHPORTSTATEID:[$swpsid]" . ", aborting function..." );
        }
        else {
            my $swpname = 'UNKNOWN';
            my $swname  = 'UNKNOWN';
            my $swid    = 0;

            # %parm = ();
            # $parm{$DB_COL_SWP_ID} = $swpsid;
            # if( $self->get_switchport(\%parm) ) {
            # $swpname = $parm{$DB_COL_SWP_NAME};
            # $swid = $parm{$DB_COL_SWP_SWID};

            # %parm = ();
            # $parm{$DB_COL_SW_ID} = $swid;
            # if( $self->get_switch(\%parm) ) {
            # 	$swname = $parm{$DB_COL_SW_NAME};
            # }
            # }

            # $self->EventDBLog( {
            #         $EVENT_PARM_PRIO  => LOG_INFO,
            #         $EVENT_PARM_TYPE  => EVENT_SWITCHPORTSTATE_DEL,
            #         $EVENT_PARM_SWPID => $swpsid,
            #         $EVENT_PARM_SWID  => $swid,
            # } );

            $ret++;
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_template($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_TEMP_ID} && !isdigit( $parm_ref->{$DB_COL_TEMP_ID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_TEMP_NAME} && $parm_ref->{$DB_COL_TEMP_NAME} eq '' ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        if ( !( defined $parm_ref->{$DB_COL_TEMP_ID} || defined $parm_ref->{$DB_COL_TEMP_NAME} ) ) { confess Dumper $parm_ref; }
        my $vgid   = $parm_ref->{$DB_COL_TEMP_ID};
        my $vgname = $parm_ref->{$DB_COL_TEMP_NAME};

        if ( !$self->get_template($parm_ref) ) {
            return 0;
        }

        my $tempid   = $parm_ref->{$DB_COL_TEMP_ID};
        my $tempname = $parm_ref->{$DB_COL_TEMP_NAME};

        %parm = ();
        $parm{$DB_COL_TEMP2VG_TEMPID} = $tempid;
        $self->remove_template2vlangroup( \%parm );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove TEMPLATE2VLANGROUP Failed on remove_template2vlangroup, aborting function..." );
            return 0;
        }

        %parm                 = ();
        $parm{$DB_TABLE_NAME} = $DB_TABLE_TEMPLATE;
        $parm{$DB_KEY_NAME}   = $DB_KEY_TEMPLATEID;
        $parm{$DB_KEY_VALUE}  = $tempid;
        if ( !$self->_delete_record( \%parm ) ) {
            EventLog( EVENT_DB_ERR, "Remove record: TEMPLATE:$tempname" . "[$tempid]" . ", aborting function..." );
            $self->seterr( "Remove record: TEMPLATE:$tempname" . "[$tempid]" . ", aborting function..." );
        }
        else {
            my $vlanname;

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO   => LOG_INFO,
                    $EVENT_PARM_TYPE   => EVENT_TEMPLATE_DEL,
                    $EVENT_PARM_TEMPID => $tempid,
            } );

            #EventLog( EVENT_TEMPLATE_DEL,
            #    "'$tempname'"
            #      . "[$tempid] "
            #);

            $ret++;
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_template2vlangroup($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );

    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_TEMP2VG_ID}     && !isdigit( $parm_ref->{$DB_COL_TEMP2VG_ID} ) )     { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_TEMP2VG_TEMPID} && !isdigit( $parm_ref->{$DB_COL_TEMP2VG_TEMPID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_TEMP2VG_VGID}   && !isdigit( $parm_ref->{$DB_COL_TEMP2VG_VGID} ) )   { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $temp2vgid = $parm_ref->{$DB_COL_TEMP2VG_ID};
        my $tempid    = $parm_ref->{$DB_COL_TEMP2VG_TEMPID};
        my $vgid      = $parm_ref->{$DB_COL_TEMP2VG_VGID};

        if ( !( defined $temp2vgid || defined $tempid || defined $vgid ) ) { confess Dumper $parm_ref; }

        my %temp2vg = ();

        $parm_ref->{HASH_REF} = \%temp2vg;
        $self->get_template2vlangroup($parm_ref);
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove record: TEMPLATE2VLANGROUP:" . "[$temp2vgid]" . ", aborting function..." );
            return 0;
        }

        foreach $temp2vgid ( keys(%temp2vg) ) {
            my %p = ();
            my $templateid;
            my $templatename;
            my $vlangroupid;
            my $vlangroupname;
            my $priority;

            $templateid  = $temp2vg{$temp2vgid}->{$DB_COL_TEMP2VG_TEMPID};
            $vlangroupid = $temp2vg{$temp2vgid}->{$DB_COL_TEMP2VG_VGID};
            $priority    = $temp2vg{$temp2vgid}->{$DB_COL_TEMP2VG_PRI};

            %p                 = ();
            $p{$DB_TABLE_NAME} = $DB_TABLE_TEMPLATE2VLANGROUP;
            $p{$DB_KEY_NAME}   = $DB_KEY_TEMPLATE2VLANGROUPID;
            $p{$DB_KEY_VALUE}  = $temp2vgid;

            if ( !$self->_delete_record( \%p ) ) {
                EventLog( EVENT_DB_ERR, "Remove record: TEMPLATE2VLANGROUPID:" . "[$temp2vgid]" . ", aborting function..." );
                $self->seterr( "Remove record: TEMPLATE2VLANGROUPID:" . "[$temp2vgid]" . ", aborting function..." );
                return 0;
            }

            %p = ();
            $p{$DB_COL_TEMP2VG_VGID} = $vlangroupid;
            $self->get_vlangroup( \%p );
            $vlangroupname = $p{$DB_COL_VG_NAME};

            %p = ();
            $p{$DB_COL_TEMP_ID} = $templateid;
            $self->get_template( \%p );
            $templatename = $p{$DB_COL_TEMP_NAME};

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO      => LOG_INFO,
                    $EVENT_PARM_TYPE      => EVENT_TEMPLATE2VLANGROUP_DEL,
                    $EVENT_PARM_TEMP2VGID => $temp2vgid,
                    $EVENT_PARM_TEMPID    => $templateid,
                    $EVENT_PARM_VGID      => $vlangroupid,
            } );
            EventLog( EVENT_TEMPLATE2VLANGROUP_DEL,
                "TEMP2VGID:"
                  . "[$temp2vgid] "
                  . "TEMPLATE:$templatename"
                  . "[$templateid] "
                  . "VLANGROUP:$vlangroupname"
                  . "[$vlangroupid] "
                  . "PRIORITY: $priority"
            );

            $ret++;
        }
    };
    LOGEVALFAIL() if ($@);

    $ret;

}

#-------------------------------------------------------
#
# Check vlangroup2vlan
# Check switch2vlan
# check mac2class (inluding locks)
# check port2class (inluding locks)
#-------------------------------------------------------
sub remove_vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_VLAN_ID}    && !isdigit( $parm_ref->{$DB_COL_VLAN_ID} ) )    { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VLAN_LOCID} && !isdigit( $parm_ref->{$DB_COL_VLAN_LOCID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        if ( !( defined $parm_ref->{$DB_COL_VLAN_ID} || defined $parm_ref->{$DB_COL_VLAN_LOCID} ) ) {
            EventLog( EVENT_ERR, MYNAMELINE . "called with out ID or LOCID" );
            $self->seterr( MYNAMELINE . "called with out ID or LOCID" );
        }

        my %vlan;
        $parm_ref->{$HASH_REF} = \%vlan;
        if ( !$self->get_vlan($parm_ref) ) {
            return 0;
        }

        #
        # Loop though each VLAN found
        #
        foreach my $vlanid ( keys(%vlan) ) {
            my $vlanname = $vlan{$vlanid}->{$DB_COL_VLAN_NAME};

            # Check mac2class for locked records
            my %m2c;
            %parm                     = ();
            $parm{$HASH_REF}          = \%m2c;
            $parm{$DB_COL_M2C_VLANID} = $vlanid;
            $parm{$DB_COL_M2C_LOCKED} = 1;
            if ( $self->get_mac2class( \%parm ) ) {
                EventLog( EVENT_WARN, "Remove VLAN:$vlanname found Locked MAC2CLASS record: $m2c{$DB_COL_M2C_ID}, skipping" );
                $self->seterr("Remove VLAN:$vlanname found Locked MAC2CLASS record: $m2c{$DB_COL_M2C_ID}, skipping");
                return 0;
            }

            # Check port2class for locked records
            my %p2c;
            %parm                     = ();
            $parm{$HASH_REF}          = \%p2c;
            $parm{$DB_COL_P2C_VLANID} = $vlanid;
            $parm{$DB_COL_P2C_LOCKED} = 1;
            if ( $self->get_port2class( \%parm ) ) {
                EventLog( EVENT_WARN, "Remove VLAN:$vlanname found Locked PORT2CLASS record: $p2c{$DB_COL_P2C_ID}, skipping" );
                $self->seterr("Remove VLAN:$vlanname found Locked PORT2CLASS record: $p2c{$DB_COL_P2C_ID}, skipping");
                return 0;
            }

            # remove mac2class for unlocked records if there is no associated VLANGOUPID
            %m2c                      = ();
            %parm                     = ();
            $parm{$HASH_REF}          = \%m2c;
            $parm{$DB_COL_M2C_VLANID} = $vlanid;
            $parm{$DB_COL_M2C_LOCKED} = 0;
            if ( $self->get_mac2class( \%parm ) ) {
                foreach my $m2cid ( keys(%m2c) ) {
                    my %p;
                    $p{$DB_COL_M2C_ID} = $m2cid;
                    $self->get_mac2class( \%p );
                    if ( !defined $p{$DB_COL_M2C_VGID} || !$p{$DB_COL_M2C_VGID} ) {
                        if ( !$self->remove_mac2class( \%p ) ) {
                            EventLog( EVENT_DB_ERR, "Remove M2C record: $m2cid for VLAN:$vlanname, aborting function..." );
                            $self->seterr("Remove M2C record: $m2cid for VLAN:$vlanname, aborting function...");
                            return 0;
                        }
                    }

                }
            }

            # Check port2class for locked records
            %p2c                      = ();
            %parm                     = ();
            $parm{$HASH_REF}          = \%p2c;
            $parm{$DB_COL_P2C_VLANID} = $vlanid;
            $parm{$DB_COL_P2C_LOCKED} = 0;
            if ( $self->get_port2class( \%parm ) ) {

                foreach my $p2cid ( keys(%p2c) ) {
                    my %p;
                    $p{$DB_COL_P2C_ID} = $p2cid;
                    if ( !defined $p{$DB_COL_P2C_VGID} || !$p{$DB_COL_P2C_VGID} ) {
                        $self->get_port2class( \%p );
                        if ( !$self->remove_port2class( \%p ) ) {
                            EventLog( EVENT_DB_ERR, "Remove P2C record: $p2cid for VLAN:$vlanname, aborting function..." );
                            $self->seterr("Remove P2C record: $p2cid for VLAN:$vlanname, aborting function...");
                            return 0;
                        }
                    }
                }
            }

            # Recursivly remove switch2vlan
            my %sw2v;
            %parm                      = ();
            $parm{$HASH_REF}           = \%sw2v;
            $parm{$DB_COL_SW2V_VLANID} = $vlanid;
            if ( $self->get_switch2vlan( \%parm ) ) {
                foreach my $sw2vid ( keys(%sw2v) ) {
                    my %p;
                    $p{$DB_COL_SW2V_ID} = $sw2vid;
                    if ( !$self->remove_switch2vlan( \%p ) ) {
                        EventLog( EVENT_DB_ERR, "Remove SW2V record: $sw2vid for VLAN:$vlanname, aborting function..." );
                        $self->seterr("Remove SW2V record: $sw2vid for VLAN:$vlanname, aborting function...");
                        return 0;
                    }
                }
            }

            # Recursivly remove VLANGROUP2VLAN
            my %vg2v;
            %parm                      = ();
            $parm{$HASH_REF}           = \%vg2v;
            $parm{$DB_COL_VG2V_VLANID} = $vlanid;
            if ( $self->get_vlangroup2vlan( \%parm ) ) {
                foreach my $vg2vid ( keys(%vg2v) ) {
                    my %p;
                    $p{$DB_COL_VG2V_ID} = $vg2vid;
                    if ( !$self->remove_vlangroup2vlan( \%p ) ) {
                        EventLog( EVENT_DB_ERR, "Remove VG2V record: $vg2vid for VLAN:$vlanname, aborting function..." );
                        $self->seterr("Remove VG2V record: $vg2vid for VLAN:$vlanname, aborting function...");
                        return 0;
                    }
                }
            }

            %parm                 = ();
            $parm{$DB_TABLE_NAME} = $DB_TABLE_VLAN;
            $parm{$DB_KEY_NAME}   = $DB_KEY_VLANID;
            $parm{$DB_KEY_VALUE}  = $vlanid;
            if ( !$self->_delete_record( \%parm ) ) {
                EventLog( EVENT_DB_ERR, "Remove record: VLAN:$vlanname" . "[$vlanid]" . ", aborting function..." );
                $self->seterr( "Remove record: VLAN:$vlanname" . "[$vlanid]" . ", aborting function..." );
            }
            else {
                $self->EventDBLog( {
                        $EVENT_PARM_PRIO   => LOG_INFO,
                        $EVENT_PARM_TYPE   => EVENT_VLAN_DEL,
                        $EVENT_PARM_VLANID => $vlanid,
                } );

                #    my $msg = "VLAN:$vlanname" . "[$vlanid]";
                #    EventLog( EVENT_VLAN_DEL, $msg );
                $ret++;
            }
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_vlangroup($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );
    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_VG_ID} && !isdigit( $parm_ref->{$DB_COL_VG_ID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VG_NAME} && $parm_ref->{$DB_COL_VLAN_LOCID} ne '' ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        if ( !( defined $parm_ref->{$DB_COL_VG_ID} || defined $parm_ref->{$DB_COL_VG_NAME} ) ) { confess Dumper $parm_ref; }
        my $vgid   = $parm_ref->{$DB_COL_VG_ID};
        my $vgname = $parm_ref->{$DB_COL_VG_NAME};

        if ( !$self->get_vlangroup($parm_ref) ) {
            return 0;
        }

        $vgid   = $parm_ref->{$DB_COL_VG_ID};
        $vgname = $parm_ref->{$DB_COL_VG_NAME};

        # Check mac2class for locked records
        my %class;
        %parm                       = ();
        $parm{$HASH_REF}            = \%class;
        $parm{$DB_COL_CLASS_VGID}   = $vgid;
        $parm{$DB_COL_CLASS_LOCKED} = 1;
        if ( $self->get_class( \%parm ) ) {
            EventLog( EVENT_WARN, "Remove VLANGROUP:$vgname found Locked CLASS record, skipping" );
            $self->seterr("Remove VLANGROUP:$vgname found Locked CLASS record, skipping");
            return 0;
        }

        # Check mac2class for locked records
        my %m2c;
        %parm                     = ();
        $parm{$HASH_REF}          = \%m2c;
        $parm{$DB_COL_M2C_VGID}   = $vgid;
        $parm{$DB_COL_M2C_LOCKED} = 1;
        if ( $self->get_mac2class( \%parm ) ) {
            EventLog( EVENT_WARN, "Remove VLANGROUP:$vgname found Locked MAC2CLASS record: $m2c{$DB_COL_M2C_ID}, skipping" );
            $self->seterr("Remove VLANGROUP:$vgname found Locked MAC2CLASS record: $m2c{$DB_COL_M2C_ID}, skipping");
            return 0;
        }

        my $mac2vlangroup_classid = 0;
        %parm = ();
        $parm{$DB_COL_CLASS_NAME} = $CLASS_NAME_MAC2VLANGROUP;
        if ( $self->get_class( \%parm ) ) {
            $mac2vlangroup_classid = $parm{$DB_COL_CLASS_ID};
        }
        else {
            confess "CLASS $CLASS_NAME_STATICMACVLAN does not exist\n";
        }

        #---
        # Do we really really want to do this?
        #---
        %parm = ();
        $parm{$DB_COL_CLASS_VGID} = $vgid;
        $self->remove_class( \%parm );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove VLANGROUP Failed on remove_class, aborting function..." );
            return 0;
        }

        %parm = ();
        $parm{$DB_COL_TEMP2VG_VGID} = $vgid;
        $self->remove_template2vlangroup( \%parm );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove VLANGROUP Failed on remove_template2vlangroup, aborting function..." );
            return 0;
        }

        %parm = ();
        $parm{$DB_COL_VG2V_VGID} = $vgid;
        $self->remove_vlangroup2vlan( \%parm );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove VLANGROUP Failed on remove_vlangroup2vlan, aborting function..." );
            return 0;
        }

        %parm                      = ();
        $parm{$DB_COL_M2C_VGID}    = $vgid;
        $parm{$DB_COL_M2C_CLASSID} = $mac2vlangroup_classid;
        $self->remove_mac2class( \%parm );
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove VLANGROUP Failed on remove_mac2class, aborting function..." );
            return 0;
        }

        %parm                 = ();
        $parm{$DB_TABLE_NAME} = $DB_TABLE_VLANGROUP;
        $parm{$DB_KEY_NAME}   = $DB_KEY_VLANGROUPID;
        $parm{$DB_KEY_VALUE}  = $vgid;
        if ( !$self->_delete_record( \%parm ) ) {
            EventLog( EVENT_DB_ERR, "Remove record: VLANGROUP:$vgname" . "[$vgid]" . ", aborting function..." );
            $self->seterr( "Remove record: VLANGROUP:$vgname" . "[$vgid]" . ", aborting function..." );
        }
        else {
            my $vlanname;

            my %p = ();
            if ( !defined $vgname ) {
                $p{$DB_COL_VG_ID} = $vgid;
                if ( $self->get_vlangroup( \%p ) ) {
                    $vgname = $p{$DB_COL_VG_NAME}
                }
            }

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO => LOG_INFO,
                    $EVENT_PARM_TYPE => EVENT_VLANGROUP_DEL,
                    $EVENT_PARM_VGID => $vgid,
            } );

            #EventLog( EVENT_VLANGROUP_DEL,
            #    "'$vgname'"
            #      . "[$vgid] "
            #);

            $ret++;
        }

    };
    LOGEVALFAIL() if ($@);
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_vlangroup2vlan($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "\n" . Dumper $parm_ref );

    eval {

        $self->reseterr;

        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }
        if ( defined $parm_ref->{$DB_COL_VG2V_ID}     && !isdigit( $parm_ref->{$DB_COL_VG2V_ID} ) )     { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VG2V_VGID}   && !isdigit( $parm_ref->{$DB_COL_VG2V_VGID} ) )   { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$DB_COL_VG2V_VLANID} && !isdigit( $parm_ref->{$DB_COL_VG2V_VLANID} ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{HASH_REF} ) { confess Dumper $parm_ref; }

        my $vg2vid = $parm_ref->{$DB_COL_VG2V_ID};
        my $vgid   = $parm_ref->{$DB_COL_VG2V_VGID};
        my $vlanid = $parm_ref->{$DB_COL_VG2V_VLANID};

        if ( !( defined $vg2vid || defined $vgid || defined $vlanid ) ) { confess Dumper $parm_ref; }

        my %vg2v = ();
        $parm_ref->{HASH_REF} = \%vg2v;
        $self->get_vlangroup2vlan($parm_ref);
        if ( $self->err ) {
            EventLog( EVENT_DB_ERR, "Remove record: VLANGROUP2VLANID:" . "[$vg2vid]" . ", aborting function..." );
            return 0;
        }

        foreach $vg2vid ( keys(%vg2v) ) {
            my %p = ();
            my $vlangroupname;
            my $vlangroupid;
            my $vlanname;
            my $vlanid;
            my $priority;

            $vlanid      = $vg2v{$vg2vid}->{$DB_COL_VG2V_VLANID};
            $vlangroupid = $vg2v{$vg2vid}->{$DB_COL_VG2V_VGID};
            $priority    = $vg2v{$vg2vid}->{$DB_COL_VG2V_PRI};

            %p                 = ();
            $p{$DB_TABLE_NAME} = $DB_TABLE_VLANGROUP2VLAN;
            $p{$DB_KEY_NAME}   = $DB_KEY_VLANGROUP2VLANID;
            $p{$DB_KEY_VALUE}  = $vg2vid;

            if ( !$self->_delete_record( \%p ) ) {
                EventLog( EVENT_DB_ERR, "Remove record: VLANGROUP2VLANID:" . "[$vg2vid]" . ", aborting function..." );
                $self->seterr( "Remove record: VLANGROUP2VLAN:" . "[$vg2vid]" . ", aborting function..." );
                return 0;
            }

            %p = ();
            $p{$DB_COL_VG_ID} = $vlangroupid;
            $self->get_vlangroup( \%p );
            $vlangroupname = $p{$DB_COL_VG_NAME};

            %p = ();
            $p{$DB_COL_VLAN_ID} = $vlanid;
            $self->get_vlan( \%p );
            $vlanname = $p{$DB_COL_VLAN_NAME};

            $self->EventDBLog( {
                    $EVENT_PARM_PRIO   => LOG_INFO,
                    $EVENT_PARM_TYPE   => EVENT_VLANGROUP2VLAN_DEL,
                    $EVENT_PARM_VG2VID => $vg2vid,
                    $EVENT_PARM_VLANID => $vlanid,
                    $EVENT_PARM_VGID   => $vgid,
            } );
            EventLog( EVENT_VLANGROUP2VLAN_DEL,
                "VG2VID:"
                  . "[$vg2vid] "
                  . "VLANGROUP:$vlangroupname"
                  . "[$vlangroupid] "
                  . "VLAN:$vlanname"
                  . "[$vlanid] "
                  . "PRIORITY: $priority"
            );

            $ret++;
        }
    };
    LOGEVALFAIL() if ($@);

    $ret;

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub set_active_on_location($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !( ( defined $parm_ref->{$DB_COL_LOC_ID} )
            || ( ( defined $parm_ref->{$DB_COL_LOC_SITE} ) && ( defined $parm_ref->{$DB_COL_LOC_SITE} ) ) ) ) {
        confess "Either LOCID or ( SITE & BLDG ) have to be defined";
    }
    if ( defined $parm_ref->{$DB_COL_LOC_ID} && ( !( isdigit $parm_ref->{$DB_COL_LOC_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_LOC_SITE} && $parm_ref->{$DB_COL_LOC_SITE} eq '' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_LOC_BLDG} && $parm_ref->{$DB_COL_LOC_BLDG} eq '' ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_LOC_ACT} ) { confess; }

    my $active = ( $parm_ref->{$DB_COL_LOC_ACT} ) ? 1 : 0;
    my $where_str;
    if ( defined $parm_ref->{$DB_COL_LOC_ID} ) {
        $where_str = " locationid = " . $parm_ref->{$DB_COL_LOC_ID};
    }
    else {
        $where_str = " site = " . $parm_ref->{$DB_COL_LOC_SITE}
          . " AND "
          . " bldg = " . $parm_ref->{$DB_COL_LOC_BLDG}
    }

    my $sql;
    $sql = "UPDATE location SET ( active = $active ) WHERE " . $where_str;
    if ( $self->sqldo($sql) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    $ret;
}

#---------------------------------------------------------------------------
sub _verify_MAC {
    my ($mac) = @_;
    my $ret = 0;

    $mac =~ tr/A-F/a-f/;
    if ( $mac =~ /[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}/ ) {
        $ret = 1;
    }
    $ret;
}

#-----------------------------------------------------------
sub EventDBLog ($$) {
    my ( $self, $parm_ref ) = @_;
    my %eventlog = ();
    my $text_message;

    EventLog( EVENT_INFO, MYNAMELINE() . " called" );

    if ( !defined $self->{NACDBBUFFER} ) {
        $self->{NACDBBUFFER} = NACDBBuffer->new();
    }

    eval {
        $self->{NACDBBUFFER}->EventDBLog($parm_ref);
    };
    LOGEVALFAIL() if ($@);

    return;

    # -x-x-x -x-x-x -x-x-x -x-x-x -x-x-x -x-x-x -x-x-x

    eval {
        if ( !defined $parm_ref ) { confess; }
        if ( ref($parm_ref) ne 'HASH' ) { confess; }

        if ( !defined $parm_ref->{$EVENT_PARM_PRIO} ) {
            $parm_ref->{$EVENT_PARM_PRIO} = LOG_INFO;
        }

        my $prio = $parm_ref->{$EVENT_PARM_PRIO};
        if ( $prio eq LOG_DEBUG ) { return; }

        if ( !defined $parm_ref->{$EVENT_PARM_TYPE} ) {
            $parm_ref->{$EVENT_PARM_TYPE} = EVENT_INFO;
        }
        my $eventtype = $parm_ref->{$EVENT_PARM_TYPE};

        if ( defined $parm_ref->{$EVENT_PARM_CLASSID}   && !isdigit( $parm_ref->{$EVENT_PARM_CLASSID} ) )      { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_LOCID}     && !isdigit( $parm_ref->{$EVENT_PARM_LOCID} ) )        { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_MACID}     && !isdigit( abs( $parm_ref->{$EVENT_PARM_MACID} ) ) ) { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_M2CID}     && !isdigit( $parm_ref->{$EVENT_PARM_M2CID} ) )        { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_P2CID}     && !isdigit( $parm_ref->{$EVENT_PARM_P2CID} ) )        { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_SWID}      && !isdigit( $parm_ref->{$EVENT_PARM_SWID} ) )         { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_SWPID}     && !isdigit( $parm_ref->{$EVENT_PARM_SWPID} ) )        { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_SW2VID}    && !isdigit( $parm_ref->{$EVENT_PARM_SW2VID} ) )       { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_TEMPID}    && !isdigit( $parm_ref->{$EVENT_PARM_TEMPID} ) )       { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_TEMP2VGID} && !isdigit( $parm_ref->{$EVENT_PARM_TEMP2VGID} ) )    { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_VGID}      && !isdigit( $parm_ref->{$EVENT_PARM_VGID} ) )         { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_VG2VID}    && !isdigit( $parm_ref->{$EVENT_PARM_VG2VID} ) )       { confess Dumper $parm_ref; }
        if ( defined $parm_ref->{$EVENT_PARM_VLANID}    && !isdigit( $parm_ref->{$EVENT_PARM_VLANID} ) )       { confess Dumper $parm_ref; }

        my $logline = $parm_ref->{$EVENT_PARM_LOGLINE};

        my $userid    = $parm_ref->{$EVENT_PARM_USERID};
        my $host      = $parm_ref->{$EVENT_PARM_HOST};
        my $classid   = $parm_ref->{$EVENT_PARM_CLASSID};
        my $locid     = $parm_ref->{$EVENT_PARM_LOCID};
        my $macid     = ( $parm_ref->{$EVENT_PARM_MACID} < 0 ) ? 0 : $parm_ref->{$EVENT_PARM_MACID};
        my $m2cid     = $parm_ref->{$EVENT_PARM_M2CID};
        my $p2cid     = $parm_ref->{$EVENT_PARM_P2CID};
        my $swid      = $parm_ref->{$EVENT_PARM_SWID};
        my $swpid     = $parm_ref->{$EVENT_PARM_SWPID};
        my $sw2vid    = $parm_ref->{$EVENT_PARM_SW2VID};
        my $tempid    = $parm_ref->{$EVENT_PARM_TEMPID};
        my $temp2vgid = $parm_ref->{$EVENT_PARM_TEMP2VGID};
        my $vgid      = $parm_ref->{$EVENT_PARM_VGID};
        my $vg2vid    = $parm_ref->{$EVENT_PARM_VG2VID};
        my $vlanid    = $parm_ref->{$EVENT_PARM_VLANID};
        my $ip        = $parm_ref->{$EVENT_PARM_IP};
        my $desc      = $parm_ref->{$EVENT_PARM_DESC};

        $eventlog{$DB_COL_EVENTLOG_TYPE} = $eventtype;

        my $syslog_text = '';
        my $db_text;

        if ( defined $logline ) {
            $syslog_text = ( ( caller(1) )[3] ) . ":" . ( ( caller(1) )[2] ) . ':';
            $desc = "File: " . ( ( caller(1) )[3] ) . "\nLine:" . ( ( caller(1) )[2] ) . ':' . $desc;
        }

        if ( defined $host ) {
            $eventlog{$DB_COL_EVENTLOG_HOST} = $host;
            $syslog_text .= "HOST:$host ";
        }
        if ( defined $classid ) {
            $eventlog{$DB_COL_EVENTLOG_CLASSID} = $classid;
            $syslog_text .= "CLASSID:$classid ";
        }
        if ( defined $locid ) {
            $eventlog{$DB_COL_EVENTLOG_LOCID} = $locid;
            $syslog_text .= "LOCID:$locid ";
        }
        if ( defined $macid ) {
            $eventlog{$DB_COL_EVENTLOG_MACID} = $macid;
            $syslog_text .= "MACID:$macid ";
        }
        if ( defined $m2cid ) {
            $eventlog{$DB_COL_EVENTLOG_M2CID} = $m2cid;
            $syslog_text .= "M2CID:$m2cid ";
        }
        if ( defined $p2cid ) {
            $eventlog{$DB_COL_EVENTLOG_P2CID} = $p2cid;
            $syslog_text .= "P2CID:$p2cid ";
        }
        if ( defined $swid ) {
            $eventlog{$DB_COL_EVENTLOG_SWID} = $swid;
            $syslog_text .= "SWID:$swid ";
        }
        if ( defined $swpid ) {
            $eventlog{$DB_COL_EVENTLOG_SWPID} = $swpid;
            $syslog_text .= "SWPID:$swpid ";
        }
        if ( defined $sw2vid ) {
            $eventlog{$DB_COL_EVENTLOG_SW2VID} = $sw2vid;
            $syslog_text .= "SW2VID:$sw2vid ";
        }
        if ( defined $tempid ) {
            $eventlog{$DB_COL_EVENTLOG_TEMPID} = $tempid;
            $syslog_text .= "TEMPID:$tempid ";
        }
        if ( defined $temp2vgid ) {
            $eventlog{$DB_COL_EVENTLOG_TEMP2VGID} = $temp2vgid;
            $syslog_text .= "T2VGID:$temp2vgid ";
        }
        if ( defined $vgid ) {
            $eventlog{$DB_COL_EVENTLOG_VGID} = $vgid;
            $syslog_text .= "VGID:$vgid ";
        }
        if ( defined $vg2vid ) {
            $eventlog{$DB_COL_EVENTLOG_VG2VID} = $vg2vid;
            $syslog_text .= "VG2VID:$vg2vid ";
        }
        if ( defined $vlanid ) {
            $eventlog{$DB_COL_EVENTLOG_VLANID} = $vlanid;
            $syslog_text .= "VLANID:$vlanid ";
        }
        if ( defined $ip ) {
            $eventlog{$DB_COL_EVENTLOG_IP} = $ip;
            $syslog_text .= "IP:$ip ";
        }
        if ( defined $desc ) {
            $eventlog{$DB_COL_EVENTLOG_DESC} = $desc;
            $syslog_text .= $desc;
        }

        $self->add_eventlog( \%eventlog );

        # Proll need to setup this up for Just Warnings and Errors
        EventLog( $eventtype, $syslog_text );

    };
    if ($@) { LOGEVALFAIL(); }
}

1;
