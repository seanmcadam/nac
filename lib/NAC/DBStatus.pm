#!/usr/bin/perl
# SVN: $Id: NACDBStatus.pm 1538 2012-10-16 14:11:02Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-16 10:11:02 -0400 (Tue, 16 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBStatus.pm $:
#
#
#
# Author: Sean McAdam
#
#
# Purpose: Provide Write access to a master NAC status database.
#
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBStatus;
use FindBin;
use lib "$FindBin::Bin/..";
use Readonly;
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck);
use DBD::mysql;
use Net::Netmask;
use POSIX;
use Readonly;
use NAC::DBSql;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::DBConsts;
use NAC::Constants;
use NAC::Misc;
use strict;

our @ISA = qw ( NAC::DBSql );

sub update_lastseen_host;
sub update_lastseen_location;
sub update_lastseen_mac;
sub update_lastseen_switch;
sub update_lastseen_switchport;

my $DEBUG = 1;

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;
my $myhostname = NAC::Syslog::hostname;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub new {
    my ($class) = @_;
    my $self;

    EventLog( EVENT_DEBUG, MYNAME . "() started" );

    my %parms = ();

    my $config = NAC::ConfigDB->new() || return 0;

    $parms{$SQL_DB}    = $config->nac_master_status_db;
    $parms{$SQL_HOST}  = $config->nac_master_status_hostname;
    $parms{$SQL_PORT}  = $config->nac_master_status_port;
    $parms{$SQL_USER}  = $config->nac_master_status_user;
    $parms{$SQL_PASS}  = $config->nac_master_status_pass;
    $parms{$SQL_CLASS} = $class;

    $self = $class->SUPER::new( \%parms );

    bless $self, $class;

    $self;
}

#-------------------------------------------------------
# Get Host
#-------------------------------------------------------
sub get_host {
    my ($self) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called $myhostname" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_HOST_HOSTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_HOST_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_HOST_SLAVECHECKIN}
      . ', '
      . $column_names{$DB_COL_STATUS_HOST_SLAVESTATUS}
      . ' FROM '
      . $DB_STATUS_TABLE_HOST
      . ' WHERE '
      . $column_names{$DB_COL_STATUS_HOST_HOSTNAME}
      . " = '$myhostname' "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_HOST_HOSTNAME} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_HOST_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Location
#-------------------------------------------------------
sub get_location {
    my ( $self, $locid ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called  $locid" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_LOCATION_LOCATIONID}
      . ', '
      . $column_names{$DB_COL_STATUS_LOCATION_SITE}
      . ', '
      . $column_names{$DB_COL_STATUS_LOCATION_BLDG}
      . ', '
      . $column_names{$DB_COL_STATUS_LOCATION_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_LOCATION_HOSTNAME}
      . ' FROM '
      . $DB_STATUS_TABLE_LOCATION
      . ' WHERE '
      . $column_names{$DB_COL_STATUS_LOCATION_LOCATIONID}
      . " = $locid "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_LOCATION_LOCATIONID} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_LOCATION_SITE}       = $answer[ $col++ ];
            $h{$DB_COL_STATUS_LOCATION_BLDG}       = $answer[ $col++ ];
            $h{$DB_COL_STATUS_LOCATION_LASTSEEN}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_LOCATION_HOSTNAME}   = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Mac
#-------------------------------------------------------
sub get_mac {
    my ( $self, $macid ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called  $macid" );

    if ( !defined $macid ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_MAC_MACID}
      . ', '
      . $column_names{$DB_COL_STATUS_MAC_MAC}
      . ', '
      . $column_names{$DB_COL_STATUS_MAC_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_MAC_HOSTNAME}
      . ' FROM '
      . $DB_STATUS_TABLE_MAC
      . ' WHERE '
      . $column_names{$DB_COL_STATUS_MAC_MACID}
      . " = $macid "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_MAC_MACID}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_MAC_MAC}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_MAC_LASTSEEN} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_MAC_HOSTNAME} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switch
#-------------------------------------------------------
sub get_switch {
    my ( $self, $swid ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called  $swid" );

    if ( !defined $swid ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_SWITCH_SWITCHID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCH_SWITCHNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCH_LOCATIONID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCH_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCH_HOSTNAME}
      . ' FROM '
      . $DB_STATUS_TABLE_SWITCH
      . ' WHERE '
      . $column_names{$DB_COL_STATUS_SWITCH_SWITCHID}
      . " = $swid "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_SWITCH_SWITCHID}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCH_SWITCHNAME} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCH_LOCATIONID} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCH_LASTSEEN}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCH_HOSTNAME}   = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switchport
#-------------------------------------------------------
sub get_switchport {
    my ( $self, $swpid ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called  $swpid" );

    if ( !defined $swpid ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LOCID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SITE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_BLDG}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_PORTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_IFINDEX}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABENABLED}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABSTATE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTH}
      . ' FROM '
      . $DB_STATUS_TABLE_SWITCHPORT
      . ' WHERE '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . " = $swpid "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}  = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_LASTSEEN}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_LOCID}         = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SITE}          = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_BLDG}          = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHID}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_PORTNAME}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_IFINDEX}       = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABENABLED}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABSTATE}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABAUTH}       = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get switchport
#-------------------------------------------------------
sub get_next_switchport {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called  $offset" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LOCID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SITE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_BLDG}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_PORTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_IFINDEX}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABENABLED}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABSTATE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTH}
      . ' FROM '
      . $DB_STATUS_TABLE_SWITCHPORT
      . ' ORDER BY '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}  = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_LASTSEEN}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_LOCID}         = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SITE}          = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_BLDG}          = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHID}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_PORTNAME}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_IFINDEX}       = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS}   = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABENABLED}    = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD} = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABSTATE}      = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABAUTH}       = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get All Switchport
#-------------------------------------------------------
sub get_all_switchport {
    my ($self) = @_;
    my $ret    = 0;
    my %ref    = ();

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    my $sql = "SELECT "
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LOCID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SITE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_BLDG}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_PORTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_IFINDEX}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABENABLED}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABSTATE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTH}
      . ' FROM '
      . $DB_STATUS_TABLE_SWITCHPORT
      . ' ORDER BY '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      ;

    if ( $self->sqlexecute($sql) ) {
        while ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}         = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_LASTSEEN}             = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}             = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_LOCID}                = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SITE}                 = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_BLDG}                 = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHID}             = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}           = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_PORTNAME}             = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_IFINDEX}              = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION}          = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS}           = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS}          = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABENABLED}           = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD}        = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABSTATE}             = $answer[ $col++ ];
            $h{$DB_COL_STATUS_SWITCHPORT_MABAUTH}              = $answer[ $col++ ];
            $ref{ $h{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} } = \%h;
        }
    }

    \%ref;
}

#-------------------------------------------------------
# Add Host
#-------------------------------------------------------
sub add_host {
    my ( $self, $status ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( !defined $status ) {
        $status = $SLAVE_STATE_UNKNOWN;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    my $sql = "INSERT INTO "
      . $DB_STATUS_TABLE_HOST
      . ' ( '
      . $column_names{$DB_COL_STATUS_HOST_HOSTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_HOST_LASTSEEN}
      . ', '
      . $column_names{$DB_COL_STATUS_HOST_SLAVECHECKIN}
      . ', '
      . $column_names{$DB_COL_STATUS_HOST_SLAVESTATUS}
      . ' ) VALUES ( '
      . "'$myhostname'"
      . ', '
      . ' NOW() '
      . ', '
      . ' NOW() '
      . ', '
      . " '$status' "
      . ' ) '
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
# Add Mac
#-------------------------------------------------------
sub add_mac {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref->{$DB_COL_STATUS_MAC_MACID} ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_STATUS_MAC_MAC} )   { confess; }

    my $sql = "INSERT INTO "
      . $DB_STATUS_TABLE_MAC
      . ' ( '
      . $column_names{$DB_COL_STATUS_MAC_MACID}
      . ', '
      . $column_names{$DB_COL_STATUS_MAC_MAC}
      . ', '
      . ( ( defined $parm_ref->{$DB_COL_STATUS_MAC_LASTSEEN} ) ?  ( $column_names{$DB_COL_STATUS_MAC_LASTSEEN} . ', ' ) : '')
      . $column_names{$DB_COL_STATUS_MAC_HOSTNAME}
      . ' ) VALUES ( '
      . $parm_ref->{$DB_COL_STATUS_MAC_MACID}
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_MAC_MAC} . "'"
      . ', '
      . ( ( defined $parm_ref->{$DB_COL_STATUS_MAC_LASTSEEN} ) ?  ( "'" . $parm_ref->{$DB_COL_STATUS_MAC_LASTSEEN} . "'" . ', ' ) : '')
      . "'" . $myhostname . "'"
      . ' ) '
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
# Add Location
#-------------------------------------------------------
sub add_location {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref->{$DB_COL_STATUS_LOCATION_LOCATIONID} ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_STATUS_LOCATION_SITE} )       { confess; }
    if ( !defined $parm_ref->{$DB_COL_STATUS_LOCATION_BLDG} )       { confess; }

    my $lastseen = $parm_ref->{$DB_COL_STATUS_SWITCH_LASTSEEN};

    my $sql = "INSERT INTO "
      . $DB_STATUS_TABLE_LOCATION
      . ' ( '
      . $column_names{$DB_COL_STATUS_LOCATION_LOCATIONID}
      . ', '
      . $column_names{$DB_COL_STATUS_LOCATION_SITE}
      . ', '
      . $column_names{$DB_COL_STATUS_LOCATION_BLDG}
      . ', '
      . ( ( ( defined $lastseen ) && ( $lastseen ne '' ) ) ?
          ( $column_names{$DB_COL_STATUS_LOCATION_LASTSEEN} . ', ' )
        : ''
      )
      . $column_names{$DB_COL_STATUS_LOCATION_HOSTNAME}
      . ' ) VALUES ( '
      . $parm_ref->{$DB_COL_STATUS_LOCATION_LOCATIONID}
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_LOCATION_SITE} . "'"
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_LOCATION_BLDG} . "'"
      . ', '
      . ( ( ( defined $lastseen ) && ( $lastseen ne '' ) ) ?
          ( "'" . $parm_ref->{$DB_COL_STATUS_LOCATION_LASTSEEN} . "'" . ', ' )
        : ''
      )
      . "'" . $myhostname . "'"
      . ' ) '
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
# Add Switch
#-------------------------------------------------------
sub add_switch {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref->{$DB_COL_STATUS_SWITCH_SWITCHID} )   { confess; }
    if ( !defined $parm_ref->{$DB_COL_STATUS_SWITCH_SWITCHNAME} ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_STATUS_SWITCH_LOCATIONID} ) { confess; }

    my $lastseen = $parm_ref->{$DB_COL_STATUS_SWITCH_LASTSEEN};

    my $sql = "INSERT INTO "
      . $DB_STATUS_TABLE_SWITCH
      . ' ( '
      . $column_names{$DB_COL_STATUS_SWITCH_SWITCHID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCH_SWITCHNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCH_LOCATIONID}
      . ', '
      . ( ( ( defined $lastseen ) && ( $lastseen ne '' ) ) ?
          ( $column_names{$DB_COL_STATUS_SWITCH_LASTSEEN} . ', ' )
        : ''
      )
      . $column_names{$DB_COL_STATUS_SWITCH_HOSTNAME}
      . ' ) VALUES ( '
      . $parm_ref->{$DB_COL_STATUS_SWITCH_SWITCHID}
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_SWITCH_SWITCHNAME} . "'"
      . ', '
      . $parm_ref->{$DB_COL_STATUS_SWITCH_LOCATIONID}
      . ', '
      . ( ( ( defined $lastseen ) && ( $lastseen ne '' ) ) ?
          ( "'" . $parm_ref->{$DB_COL_STATUS_SWITCH_LASTSEEN} . "'" . ', ' )
        : ''
      )
      . "'" . $myhostname . "'"
      . ' ) '
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
# Add Switchport
#-------------------------------------------------------
sub add_switchport {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;
    my $switch_ref;
    my $portname   = '';
    my $switchid   = 0;
    my $switchname = '';
    my $locid      = 0;
    my $site       = '';
    my $bldg       = '';

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} ) { confess; }

    my $lastseen = $parm_ref->{$DB_COL_STATUS_SWITCH_LASTSEEN};

    if ( defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_PORTNAME} ) {
        $portname = $parm_ref->{$DB_COL_STATUS_SWITCHPORT_PORTNAME};
    }
    if ( defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHID} ) {
        $switchid = $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHID};
    }
    if ( defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME} ) {
        $switchname = $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME};
    }
    if ( defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_LOCID} ) {
        $locid = $parm_ref->{$DB_COL_STATUS_SWITCHPORT_LOCID};
    }
    if ( defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SITE} ) {
        $site = $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SITE};
    }
    if ( defined $parm_ref->{$DB_COL_STATUS_SWITCHPORT_BLDG} ) {
        $bldg = $parm_ref->{$DB_COL_STATUS_SWITCHPORT_BLDG};
    }

    my $sql = "INSERT INTO "
      . $DB_STATUS_TABLE_SWITCHPORT
      . ' ( '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_PORTNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_LOCID}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_SITE}
      . ', '
      . $column_names{$DB_COL_STATUS_SWITCHPORT_BLDG}
      . ', '
      . ( ( ( defined $lastseen ) && ( $lastseen ne '' ) ) ?  ( $column_names{$DB_COL_STATUS_SWITCHPORT_LASTSEEN} . ', ' ) : '')
      . $column_names{$DB_COL_STATUS_SWITCHPORT_HOSTNAME}
      . ' ) VALUES ( '
      . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID}
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_PORTNAME} . "'"
      . ', '
      . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHID}
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SWITCHNAME} . "'"
      . ', '
      . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_LOCID}
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_SITE} . "'"
      . ', '
      . "'" . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_BLDG} . "'"
      . ', '
      . ( ( ( defined $lastseen ) && ( $lastseen ne '' ) ) ?  ( "'" . $parm_ref->{$DB_COL_STATUS_SWITCHPORT_LASTSEEN} . "'" . ', ' ) : '')
      . "'" . $myhostname . "'"
      . ' ) '
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
# Update Host
#-------------------------------------------------------
sub update_host_lastseen {
    my ( $self, $lastseen ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $lastseen ) {
        $lastseen = ' NOW() ';
    }
    else {
        $lastseen = "'" . $lastseen . "'";
    }

    if ( $self->get_host() ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_HOST
          . ' SET '
          . $column_names{$DB_COL_STATUS_HOST_LASTSEEN} . ' = ' . $lastseen
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_HOST_HOSTNAME} . " = '$myhostname' "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        $self->add_host();
    }

    $ret;
}

#-------------------------------------------------------
# Update Host (Slave)
#-------------------------------------------------------
sub update_slave_status {
    my ( $self, $status ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called, Status: $status" );

    if ( my $ref = $self->get_host() ) {
        my $cur_status = $ref->{$DB_COL_STATUS_HOST_SLAVESTATUS};

        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_HOST
          . ' SET '
          . $column_names{$DB_COL_STATUS_HOST_SLAVECHECKIN} . ' = NOW() '
          . ( ( $cur_status ne $status ) ? ( ', ' . $column_names{$DB_COL_STATUS_HOST_SLAVESTATUS} . " = '$status' " ) : '' )
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_HOST_HOSTNAME} . " = '$myhostname' "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    elsif ( $self->add_host($status) ) {
        $ret++;
    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . " cannot update slave status for $myhostname" );
    }

    $ret;
}

#-------------------------------------------------------
# Update Mac
#-------------------------------------------------------
sub update_location_lastseen {
    my ( $self, $id, $lastseen ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $lastseen ) {
        $lastseen = ' NOW() ';
    }
    else {
        $lastseen = "'" . $lastseen . "'";
    }

    if ( $self->get_location($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_LOCATION
          . ' SET '
          . $column_names{$DB_COL_STATUS_LOCATION_LASTSEEN} . ' = ' . $lastseen
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_LOCATION_LOCATIONID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . " no location ID: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Mac
#-------------------------------------------------------
sub update_mac_lastseen {
    my ( $self, $id, $lastseen ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( !defined $lastseen ) {
        $lastseen = ' NOW() ';
    }
    else {
        $lastseen = "'" . $lastseen . "'";
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called $id, '$lastseen' " );

    if ( $self->get_mac($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_MAC
          . ' SET '
          . $column_names{$DB_COL_STATUS_MAC_LASTSEEN}
          . ' = '
          . $lastseen
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_MAC_MACID}
          . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . " no location MAC: $id to update " );

    }
    $ret;
}

#-------------------------------------------------------
# Update Switch
#-------------------------------------------------------
sub update_switch_lastseen {
    my ( $self, $id, $lastseen ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $lastseen ) {
        $lastseen = ' NOW() ';
    }
    else {
        $lastseen = "'" . $lastseen . "'";
    }

    if ( $self->get_switch($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCH
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCH_LASTSEEN} . ' = ' . $lastseen
          . ' WHERE ' 
	  . $column_names{$DB_COL_STATUS_SWITCH_SWITCHID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . " no location SWITCH: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport
#-------------------------------------------------------
sub update_switchport_lastseen {
    my ( $self, $id, $lastseen ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $lastseen ) {
        $lastseen = ' NOW() ';
    }
    else {
        $lastseen = "'" . $lastseen . "'";
    }

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_LASTSEEN} . ' = ' . $lastseen
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . " no location SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport ifindex
#-------------------------------------------------------
sub update_switchport_ifindex {
    my ( $self, $id, $ifindex ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_IFINDEX} . ' = ' . $ifindex
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport description
#-------------------------------------------------------
sub update_switchport_description {
    my ( $self, $id, $description ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_DESCRIPTION} . ' = ' . "'" . $description . "'"
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport operstatus
#-------------------------------------------------------
sub update_switchport_operstatus {
    my ( $self, $id, $operstatus ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_OPERSTATUS} . ' = ' . $operstatus
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport adminstatus
#-------------------------------------------------------
sub update_switchport_adminstatus {
    my ( $self, $id, $adminstatus ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_ADMINSTATUS} . ' = ' . $adminstatus
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport mabenabled
#-------------------------------------------------------
sub update_switchport_mabenabled {
    my ( $self, $id, $mabenabled ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_MABENABLED} . ' = ' . $mabenabled
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport mabauthmethod
#-------------------------------------------------------
sub update_switchport_mabauthmethod {
    my ( $self, $id, $mabauthmethod ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTHMETHOD} . ' = ' . $mabauthmethod
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport mabstate
#-------------------------------------------------------
sub update_switchport_mabstate {
    my ( $self, $id, $mabstate ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_MABSTATE} . ' = ' . $mabstate
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

#-------------------------------------------------------
# Update Switchport mabauth
#-------------------------------------------------------
sub update_switchport_mabauth {
    my ( $self, $id, $mabauth ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( $self->get_switchport($id) ) {
        my $sql = "UPDATE "
          . $DB_STATUS_TABLE_SWITCHPORT
          . ' SET '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_MABAUTH} . ' = ' . $mabauth
          . ' WHERE '
          . $column_names{$DB_COL_STATUS_SWITCHPORT_SWITCHPORTID} . " = $id "
          ;

        if ( $self->sqldo($sql) ) {
            $ret++;
        }

    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE() . "  SWITCHPORT: $id to update " );
    }

    $ret;
}

1;
