#!/usr/bin/perl
# SVN: $Id: NACDB.pm 1529 2012-10-13 17:22:52Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-13 13:22:52 -0400 (Sat, 13 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBEventlog.pm $:
#
#
#
# Author: Sean McAdam
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBEventlog;
use lib "$ENV{HOME}/lib/perl5";

use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck);
use DBD::mysql;
use POSIX;
use NAC::DBSql;
use NAC::DBConsts;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use NAC::Misc;
use strict;

our @ISA = qw(NAC::DBSql);

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;

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

    EventLog( EVENT_START, MYNAME . "() started" );

    my %parms  = ();
    my $config = NAC::ConfigDB->new();

    # For backward compatibility
    $parms{$SQL_DB}        = ( defined $parm_ref->{$SQL_DB} )        ? $parm_ref->{$SQL_DB}        : $config->nac_eventlog_write_db;
    $parms{$SQL_HOST}      = ( defined $parm_ref->{$SQL_HOST} )      ? $parm_ref->{$SQL_HOST}      : $config->nac_eventlog_write_hostname;
    $parms{$SQL_PORT}      = ( defined $parm_ref->{$SQL_PORT} )      ? $parm_ref->{$SQL_PORT}      : $config->nac_eventlog_write_port;
    $parms{$SQL_USER}      = ( defined $parm_ref->{$SQL_USER} )      ? $parm_ref->{$SQL_USER}      : $config->nac_eventlog_write_user;
    $parms{$SQL_PASS}      = ( defined $parm_ref->{$SQL_PASS} )      ? $parm_ref->{$SQL_PASS}      : $config->nac_eventlog_write_pass;
    $parms{$SQL_READ_ONLY} = ( defined $parm_ref->{$SQL_READ_ONLY} ) ? $parm_ref->{$SQL_READ_ONLY} : undef;
    $parms{$SQL_CLASS}     = ( defined $parm_ref->{$SQL_CLASS} )     ? $parm_ref->{$SQL_CLASS}     : $class;

    $self = $class->SUPER::new( \%parms );

    bless $self, $class;

    $self;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_eventlog($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    #
    # Note: Remove eventlog ID later
    #

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_EVENTLOG_TYPE} ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_CLASSID}   && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_CLASSID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_LOCID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_LOCID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_MACID}     && !( isdigit( abs( $parm_ref->{$DB_COL_EVENTLOG_MACID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_M2CID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_M2CID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_P2CID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_P2CID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SWID}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SWID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SWPID}     && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SWPID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_SW2VID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_SW2VID} ) ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TEMPID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TEMPID} ) ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID} && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_TEMP2VGID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VGID}      && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VGID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VG2VID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VG2VID} ) ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_EVENTLOG_VLANID}    && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_VLANID} ) ) )       { confess Dumper $parm_ref; }

    if ( defined $parm_ref->{$DB_COL_EVENTLOG_ID} && !( isdigit( $parm_ref->{$DB_COL_EVENTLOG_ID} ) ) ) { confess Dumper $parm_ref; }

    my $type      = $parm_ref->{$DB_COL_EVENTLOG_TYPE};
    my $eventtime = $parm_ref->{$DB_COL_EVENTLOG_TIME};
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

    my $eventlogid = ( ( defined $parm_ref->{$DB_COL_EVENTLOG_ID} ) ? $parm_ref->{$DB_COL_EVENTLOG_ID} : undef );

    $desc = '' if !defined $desc;
    $desc =~ s/\'/\\'/g;
    $desc =~ s/\"/\\"/g;

    my $sql = "INSERT INTO $DB_TABLE_EVENTLOG "
      . " ( eventtype "
      . ( ( defined $eventlogid ) ? ", eventlogid "           : '' )
      . ( ( defined $eventtime )  ? ", eventtime "            : '' )
      . ( ( defined $classid )    ? ", classid "              : '' )
      . ( ( defined $locid )      ? ", locationid "           : '' )
      . ( ( defined $macid )      ? ", macid "                : '' )
      . ( ( defined $m2cid )      ? ", mac2classid "          : '' )
      . ( ( defined $p2cid )      ? ", port2classid "         : '' )
      . ( ( defined $swid )       ? ", switchid "             : '' )
      . ( ( defined $swpid )      ? ", switchportid "         : '' )
      . ( ( defined $sw2vid )     ? ", switch2vlanid "        : '' )
      . ( ( defined $tempid )     ? ", templateid "           : '' )
      . ( ( defined $temp2vgid )  ? ", template2vlangroupid " : '' )
      . ( ( defined $vgid )       ? ", vlangroupid "          : '' )
      . ( ( defined $vg2vid )     ? ", vlangroup2vlanid "     : '' )
      . ( ( defined $vlanid )     ? ", vlanid "               : '' )
      . ( ( defined $ip )         ? ", ip "                   : '' )
      . ( ( defined $hostname )   ? ", hostname "             : '' )
      . ( ( defined $desc )       ? ", eventtext "            : '' )
      . " ) VALUES ( "
      . "'$type'"
      . ( ( defined $eventlogid ) ? ", $eventlogid "  : '' )
      . ( ( defined $eventtime )  ? ", '$eventtime' " : '' )
      . ( ( defined $classid )    ? ", $classid "     : '' )
      . ( ( defined $locid )      ? ", $locid "       : '' )
      . ( ( defined $macid )      ? ", $macid "       : '' )
      . ( ( defined $m2cid )      ? ", $m2cid "       : '' )
      . ( ( defined $p2cid )      ? ", $p2cid "       : '' )
      . ( ( defined $swid )       ? ", $swid "        : '' )
      . ( ( defined $swpid )      ? ", $swpid "       : '' )
      . ( ( defined $sw2vid )     ? ", $sw2vid "      : '' )
      . ( ( defined $tempid )     ? ", $tempid "      : '' )
      . ( ( defined $temp2vgid )  ? ", $temp2vgid "   : '' )
      . ( ( defined $vgid )       ? ", $vgid "        : '' )
      . ( ( defined $vg2vid )     ? ", $vg2vid "      : '' )
      . ( ( defined $vlanid )     ? ", $vlanid "      : '' )
      . ( ( defined $ip )         ? ", '$ip' "        : '' )
      . ( ( defined $hostname )   ? ", '$hostname' "  : '' )
      . ( ( defined $desc )       ? ", '$desc' "      : '' )
      . " )";

    if ( $self->sqldo($sql) ) {
        if ( !defined $eventlogid ) {
            if ( $self->dbh->{'mysql_insertid'} ) {
                $parm_ref->{$DB_COL_EVENTLOG_ID} = $self->dbh->{'mysql_insertid'};
                $ret++;
            }
            else {
                EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
                $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            }
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

    my $sql = "SELECT "
      . " eventlogid, "
      . " eventtime, "
      . " eventtype, "
      . " userid, "
      . " hostname, "
      . " classid, "
      . " locationid, "
      . " macid, "
      . " mac2classid, "
      . " port2classid, "
      . " switchid, "
      . " switchportid, "
      . " switch2vlanid, "
      . " templateid, "
      . " template2vlangroupid, "
      . " vlangroupid, "
      . " vlangroup2vlanid, "
      . " vlanid, "
      . " ip, "
      . " eventtext "
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
#-------------------------------------------------------
sub get_eventlog_max_id {
    my $self = shift;
    my $ret  = 0;

    my $sql = "SELECT MAX(eventlogid) FROM eventlog ";

    $self->sqlexecute($sql);
    if ( my @row = $self->sth->fetchrow_array() ) {
        $ret = ( $row[0] ) ? $row[0] : 0;
    }
    $ret;
}

1;
