#!/usr/bin/perl
# SVN: $Id: $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-10 15:53:51 -0400 (Wed, 10 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBBufSync.pm $:
#
#
#
# Author: Sean McAdam
# Purpose: Provide Write access to a local NAC buffer database.
#
#------------------------------------------------------
# Notes:
#
# Opens up the Buffer database and the Master database
# Runs a series of sync jobs that puts the local buffer
# data into the master DB in an orderly fashion.
#
# Add MAC, Switch, Switchport, RadiusAudit
# Updtate Lastseen MAC, Switch, Switchport
# Push EventLog data
#------------------------------------------------------

package NAC::DBBufSync;

use Readonly;
Readonly our $USE_SNMP => 0;

BEGIN {
    use FindBin;
    use lib "$FindBin::Bin/..";
    if ($USE_SNMP) {
        use NAC::SNMP;
    }
}

use base qw( Exporter );
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp;
use DBD::mysql;
use NAC::Syslog;
use NAC::DBConsts;
use NAC::Constants;
use NAC::DBSql;
use NAC::DBStatus;
use NAC::DBBuffer;
use NAC::DBReadOnly;
use NAC::DBAudit;
use NAC::DBEventlog;
use NAC::DBRadiusAudit;
use NAC::Misc;
use strict;

Readonly our $NACDB                   => 'NAC-DATABASE-MAIN';
Readonly our $NACRO                   => 'NAC-DATABASE-LOCAL';
Readonly our $NACSTATUS               => 'NAC-DATABASE-STATUS';
Readonly our $NACBUFFER               => 'NAC-DATABASE-BUFFER';
Readonly our $NACEVENTLOG             => 'NAC-DATABASE-EVENTLOG';
Readonly our $NACRADIUSAUDIT          => 'NAC-DATABASE-RADIUSAUDIT';
Readonly our $SNMPCONN                => 'SNMP-CONN';
Readonly our $SNMPOK                  => 'SNMP-OK';
Readonly our $MIN_SEND_TIME           => 90;
Readonly our $MIN_LOOP_LS_TIME        => 300;
Readonly our $MIN_LOOP_SYNC_TIME      => 3660;
Readonly our $MAX_LOOP_COUNT          => 100;
Readonly our $RUN_NEXT_LS_LOOP        => 'RUN-NEXT-LS-LOOP-TIME';
Readonly our $RUN_NEXT_SYNC_LOOP      => 'RUN-NEXT-SYNC-LOOP-TIME';
Readonly our $HOST_LS_SEND_TIME       => 'HOST-LS-SEND-TIME';
Readonly our $HOST_LS_SLAVE_CHECKIN   => 'HOST-LS-SLAVE-CHECKIN-TIME';
Readonly our $MAC_LS_SEND_TIME        => 'MAC-LS-SEND-TIME';
Readonly our $LOCATION_LS_SEND_TIME   => 'LOCATION-LS-SEND-TIME';
Readonly our $SWITCH_LS_SEND_TIME     => 'SWITCH-LS-SEND-TIME';
Readonly our $SWITCHPORT_LS_SEND_TIME => 'SWITCHPORT-LS-SEND-TIME';

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;
my $hostname = NAC::Syslog::hostname;

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub new() {
    my ( $class, $parm_ref, ) = @_;
    my $self;

    if ( ( defined $parm_ref ) && ( ref($parm_ref) ne 'HASH' ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAME . "() starting" );

    my %macls;
    my %switchls;
    my %switchportls;
    my %locationls;
    $self = {
        $SNMPCONN                => undef,
        $SNMPOK                  => 0,
        $NACDB                   => undef,
        $NACRO                   => undef,
        $NACBUFFER               => undef,
        $NACSTATUS               => undef,
        $NACEVENTLOG             => undef,
        $NACRADIUSAUDIT          => undef,
        $HOST_LS_SEND_TIME       => undef,
        $HOST_LS_SLAVE_CHECKIN   => undef,
        $MAC_LS_SEND_TIME        => \%macls,
        $SWITCH_LS_SEND_TIME     => \%switchls,
        $SWITCHPORT_LS_SEND_TIME => \%switchportls,
        $LOCATION_LS_SEND_TIME   => \%locationls,
        $RUN_NEXT_LS_LOOP        => 0,
        $RUN_NEXT_SYNC_LOOP      => 0,
    };

    bless $self, $class;

    if ( !( $self->init_db($NACDB)
            && $self->init_db($NACRO)
            && $self->init_db($NACBUFFER)
            && $self->init_db($NACSTATUS)
            && $self->init_db($NACEVENTLOG)
            && $self->init_db($NACRADIUSAUDIT)
        ) ) {
        warn "Count not initialize on of the database connections\n";
        return undef;
    }

    $self;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub init_db {
    my ( $self, $dbname ) = @_;
    EventLog( EVENT_DEBUG, MYNAMELINE . " Called" );
    if ( defined( $self->{$dbname} ) ) {
        EventLog( EVENT_WARN, "DB alread setup: $dbname" );
    }
    elsif ( !( $self->connect_db($dbname) ) ) {
        EventLog( EVENT_WARN, "Failed to connect to DB: $dbname" );
        return 0;
    }

    return $self->{$dbname};

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub connect_db {
    my ( $self, $db ) = @_;

    my %db_package = (
        $NACDB          => 'NAC::DBAudit',
        $NACRO          => 'NAC::DBReadOnly',
        $NACBUFFER      => 'NAC::DBBuffer',
        $NACSTATUS      => 'NAC::DBStatus',
        $NACEVENTLOG    => 'NAC::DBEventlog',
        $NACRADIUSAUDIT => 'NAC::DBRadiusAudit',
    );

    EventLog( EVENT_DEBUG, MYNAME . "DB: $db" );

    if ( !defined $db_package{$db} ) { confess Dumper @_; }

    eval {
        if ( !defined $self->{$db} ) {
            if ( !( $self->{$db} = "$db_package{$db}"->new() ) ) {
                return 0;
            }
        }

        if ( !$self->{$db}->sql_connected() ) {
            if ( !$self->{$db}->connect ) {
                return 0;
            }
        }
    };
    if ($@) {
        LOGEVALFAIL();
        carp( MYNAMELINE . "$@" );
        return 0;
    }

    return $self->{$db};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub MAINDB {
    my ($self) = @_;
    return $self->{$NACDB};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub LOCALRO {
    my ($self) = @_;
    return $self->{$NACRO};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub BUF {
    my ($self) = @_;
    return $self->{$NACBUFFER};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub STATUS {
    my ($self) = @_;
    return $self->{$NACSTATUS};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub EL {
    my ($self) = @_;
    return $self->{$NACEVENTLOG};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub RA {
    my ($self) = @_;
    return $self->{$NACRADIUSAUDIT};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub SNMP {
    if ( !$USE_SNMP ) { return undef; }
    my ( $self, $hostname ) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE . " Called" );

    if ( !defined $hostname ) { confess; }
    if ( !$self->{$SNMPOK} )  { confess; }

    if ( !defined( $self->{$SNMPCONN} ) ) {
        if ( !( $self->{$SNMPCONN} = NAC::SNMP->new() ) ) {
            return undef;
        }
    }

    if ( defined $hostname ) {
        if ( !$self->{$SNMPCONN}->open_host_session($hostname) ) {
            EventLog( EVENT_ERR, MYNAMELINE . "Failed to open SNMP Session with $hostname" );
        }
    }

    if ( !$self->{$SNMPCONN} ) {
        $self->{$SNMPCONN} = undef;
    }

    return $self->{$SNMPCONN};
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub server_setup {
    my ($self) = @_;
    $self->BUF->setup_udp_server;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub server_buf_loop {
    my ($self) = @_;
    my $connected = 0;

    #
    # This holds messages while we are disconnected for short periods of time
    #
    my %msg_hold = ();

    while ( my $msg = $self->BUF->udp_server_recv ) {

        if ( defined $msg && $msg ne '' ) {
            $msg_hold{$msg}++;
        }

        if ( !( $self->MAINDB->sql_connected && $self->MAINDB->reconnect ) ) {
            EventLog( EVENT_WARN, "LOST DB CONNECTION... WAIT TO RECONNECT" );
            $connected = 0;
            next;
        }

        if ( !$connected ) {
            EventLog( EVENT_DEBUG, "DB ALREADY CONNECTED" );
            $connected = 1;
        }

        foreach my $m ( keys %msg_hold ) {
            EventLog( EVENT_DEBUG, MYNAMELINE . "Process MSG: $msg" );

            if ( $m =~ /$MSG_EVENTLOG/ ) {
                $self->sync_eventlog();
            }
            elsif ( $m =~ /$MSG_RADIUS/ ) {
                $self->sync_add_radiusaudit();
            }
            elsif ( $m =~ /$MSG_ADD_MAC/ ) {
                $self->sync_add_mac();
            }
            elsif ( $m =~ /$MSG_ADD_SWITCH/ ) {
                $self->sync_add_switch();
            }
            elsif ( $m =~ /$MSG_ADD_SWITCHPORT/ ) {
                $self->sync_add_switchport();
            }
            elsif ( $m =~ /$MSG_LASTSEEN_LOCATION(:\d+)*/ ) {
                if ( defined $1 ) {
                    my $id = $1;
                    $id =~ s/://;
                    $self->sync_lastseen_location_id($id);
                }
                else {

                    #  $self->sync_lastseen_location_all;
                }
            }
            elsif ( $m =~ /$MSG_LASTSEEN_MAC(:\d+)*/ ) {
                if ( defined $1 ) {
                    my $id = $1;
                    $id =~ s/://;
                    $self->sync_lastseen_mac_id($id);
                }
                else {

                    #  $self->sync_lastseen_mac_all;
                }
            }
            elsif ( $m =~ /$MSG_LASTSEEN_SWITCH(:\d+)*/ ) {
                if ( defined $1 ) {
                    my $id = $1;
                    $id =~ s/://;
                    $self->sync_lastseen_switch_id($id);
                }
                else {

                    #  $self->sync_lastseen_switch_all;
                }
            }
            elsif ( ( $m =~ /$MSG_LASTSEEN_SWITCHPORT(:\d+)*/ )
                || ( $m =~ /$MSG_SWITCHPORTSTATE(:\d+)*/ ) ) {
                if ( defined $1 ) {
                    my $id = $1;
                    $id =~ s/://;
                    EventLog( EVENT_DEBUG, MYNAMELINE . " SWITCHPORT ID: $id " );
                    $self->sync_lastseen_switchport_id($id);
                    $self->sync_switchportstate_id($id);
                }
                else {
                    EventLog( EVENT_DEBUG, MYNAMELINE . " SWITCHPORT ALL " );

                    #  $self->sync_lastseen_switchport_all;
                    #  $self->sync_switchportstate_all;
                }
            }
            elsif ( $m =~ /$MSG_SLAVE_OK/ ) {
                $self->sync_slave($SLAVE_STATE_OK);
            }
            elsif ( $m =~ /$MSG_SLAVE_OFFLINE/ ) {
                $self->sync_slave($SLAVE_STATE_OFFLINE);
            }
            elsif ( $m =~ /$MSG_SLAVE_DELAY/ ) {
                $self->sync_slave($SLAVE_STATE_DELAYED);
            }
            elsif ( $m =~ /$MSG_SLAVE_UNKNOWN/ ) {
                $self->sync_slave($SLAVE_STATE_UNKNOWN);
            }
            else {
                EventLog( EVENT_ERR, "UNKNOWN MSG: '$m', DISCARDING..." );
            }
        }

        #
        # Clear msg_hold out and start fresh
        #
        # %msg_hold = ();

        #
        # Run everything once for good measure every MIN_LOOP_TIME
        #
        if ( $self->{$RUN_NEXT_LS_LOOP} < time ) {
            my $loop_more = 0;

            EventLog( EVENT_INFO, "MIN LOOP RUN " );

            $loop_more += $self->sync_eventlog();
            $loop_more += $self->sync_add_radiusaudit();
            $loop_more += $self->sync_add_mac();
            $loop_more += $self->sync_add_switch();
            $loop_more += $self->sync_add_switchport();

            $self->{$RUN_NEXT_LS_LOOP} = ($loop_more) ? ( time + 1 ) : ( time + $MIN_LOOP_LS_TIME );

            EventLog( EVENT_INFO, "MIN LOOP RUN - DONE" );
        }

        if ( $self->{$RUN_NEXT_SYNC_LOOP} < time ) {

            # EventLog( EVENT_INFO, "MAX LOOP RUN " );
            # $self->sync_lastseen_location_all();
            # $self->sync_lastseen_switch_all();
            # $self->sync_lastseen_switchport_all();
            # $self->sync_lastseen_mac_all();
            # $self->sync_switchportstate_all();
            # EventLog( EVENT_INFO, "MAX LOOP RUN - DONE" );

            $self->{$RUN_NEXT_SYNC_LOOP} = ( time + $MIN_LOOP_SYNC_TIME );

        }

        $self->sync_lastseen_host;
    }
}

#-------------------------------------------------------
# Sync tables
#
# Step 1
# Get next record
# Check RO table:
#    Exists
#	Delete from BUF
#
# Step 2
# Get next record
# Check RO table:
#     Does Not Exist
#	Check Main Table
#	   Exists -> skip
#	   Does Not Exist -> Add Main
#
#-------------------------------------------------------
# Sync add_mac table
#-------------------------------------------------------
sub sync_add_mac {
    my ($self)     = @_;
    my $count      = 0;
    my @delete_ids = ();
    my $ret        = 0;
    my $ref;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called " );

    # Clear out MACs that are in the RO table that are up to date
    while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_add_mac( $count++ ) ) ) {
        my %parm_ref = ();
        $parm_ref{$DB_COL_MAC_MAC} = $ref->{$DB_COL_BUF_ADD_MAC_MAC};
        if ( $self->LOCALRO->get_mac( \%parm_ref, ) ) {
            push( @delete_ids, $ref->{$DB_COL_BUF_ADD_MAC_ID} );
            EventLog( EVENT_INFO, MYNAMELINE . " MAC Added to Main DB: " . $ref->{$DB_COL_BUF_ADD_MAC_MAC} );
        }
    }

    foreach my $id (@delete_ids) {
        $self->BUF->delete_mac_id($id);
        EventLog( EVENT_INFO, MYNAMELINE . " Remove local MAC: " . $id );
    }
    @delete_ids = ();

    # Add MACs that are not in the DB table
    $count = 0;

    if ( $self->MAINDB->sql_connected ) {
        while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_add_mac( $count++ ) ) ) {
            my $id  = $ref->{$DB_COL_BUF_ADD_MAC_ID};
            my $mac = $ref->{$DB_COL_BUF_ADD_MAC_MAC};
            if ( !$self->MAINDB->get_mac( {
                        $DB_COL_MAC_MAC => $mac,
                    }, ) ) {
                if ( $self->MAINDB->add_mac( {
                            $DB_COL_MAC_MAC => $mac,
                        }, ) ) {
                    $ret++;
                    push( @delete_ids, $id );
                    EventLog( EVENT_INFO, MYNAMELINE . " PUSH to DB: " . $mac );
                }
            }
            else {
                EventLog( EVENT_INFO, MYNAMELINE . " MAC PUSHED already to DB: " . $mac );
            }
        }
        foreach my $id (@delete_ids) {
            $self->BUF->delete_mac_id($id);
            EventLog( EVENT_INFO, MYNAMELINE . " Remove local MAC: " . $id );
        }
    }
    $ret;
}

#-------------------------------------------------------
# Sync add_switch table
#-------------------------------------------------------
sub sync_add_switch {
    my ($self)     = @_;
    my $count      = 0;
    my @delete_ids = ();
    my $ret        = 0;
    my $ref;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called " );

    # Clear out SWITCHes that are in the RO table
    while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_add_switch( $count++ ) ) ) {
        my %parm_ref = ();
        $parm_ref{$DB_COL_SW_IP} = $ref->{$DB_COL_BUF_ADD_SWITCH_IP};
        if ( $self->LOCALRO->get_switch( \%parm_ref, ) ) {
            push( @delete_ids, $ref->{$DB_COL_BUF_ADD_SWITCH_ID} );
            EventLog( EVENT_DEBUG, MYNAMELINE . " SWITCH Added to Main DB: " . $ref->{$DB_COL_BUF_ADD_SWITCH_IP} );
        }
    }

    foreach my $id (@delete_ids) {
        $self->BUF->delete_switch_id($id);
        EventLog( EVENT_INFO, MYNAMELINE . " Remove local SWITCH: " . $id );
    }
    @delete_ids = ();

    # Add SWITCHes that are not in the DB table
    $count = 0;

    if ( $self->MAINDB->sql_connected ) {
        while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_add_switch( $count++ ) ) ) {
            my $id = $ref->{$DB_COL_BUF_ADD_SWITCH_ID};
            my $ip = $ref->{$DB_COL_BUF_ADD_SWITCH_IP};
            if ( !$self->MAINDB->get_switch( {
                        $DB_COL_SW_IP => $ip,
                    }, ) ) {
                if ( $self->MAINDB->add_switch( {
                            $DB_COL_SW_IP    => $ip,
                            $DB_COL_SW_NAME  => ( 'UNKNOWN [' . $NACSyslog::hostname ),
                            $DB_COL_SW_LOCID => 0,
                            $DB_COL_SW_DESC  => ( 'ADDED BY [' . $NACSyslog::hostname . ' at ' . localtime(time) ),
                        }, ) ) {
                    $ret++;
                    push( @delete_ids, $id );
                    EventLog( EVENT_DEBUG, MYNAMELINE . " PUSH to DB: " . $ip );
                }
            }
        }
        foreach my $id (@delete_ids) {
            $self->BUF->delete_switch_id($id);
            EventLog( EVENT_INFO, MYNAMELINE . " Remove local SWITCH: " . $id );
        }
    }

    $ret;
}

#-------------------------------------------------------
# Sync add_switchport table
#-------------------------------------------------------
sub sync_add_switchport {
    my ($self)     = @_;
    my $count      = 0;
    my @delete_ids = ();
    my $ret        = 0;
    my $ref;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called " );

    # Clear out SWITCHPORTS that are in the RO table
    while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_add_switchport( $count++ ) ) ) {
        my %parm_ref = ();
        $parm_ref{$DB_COL_SWP_SWID} = $ref->{$DB_COL_BUF_ADD_SWITCHPORT_SWITCHID};
        $parm_ref{$DB_COL_SWP_NAME} = $ref->{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME};
        if ( $self->LOCALRO->get_switchport( \%parm_ref, ) ) {
            push( @delete_ids, $ref->{$DB_COL_BUF_ADD_SWITCHPORT_ID} );
            EventLog( EVENT_DEBUG, MYNAMELINE . " Add: " . $ref->{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME} );
        }
    }

    foreach my $id (@delete_ids) {
        $self->BUF->delete_switchport_id($id);
        EventLog( EVENT_INFO, MYNAMELINE . " Remove local SWITCHPORT: " . $id );
    }
    @delete_ids = ();

    # Add SWITCHPORTs that are not in the DB table
    $count = 0;

    if ( $self->MAINDB->sql_connected ) {
        while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_add_switchport( $count++ ) ) ) {
            my $id       = $ref->{$DB_COL_BUF_ADD_SWITCHPORT_ID};
            my $switchid = $ref->{$DB_COL_BUF_ADD_SWITCHPORT_SWITCHID};
            my $name     = $ref->{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME};
            if ( !$self->MAINDB->get_switchport( {
                        $DB_COL_SWP_SWID => $switchid,
                        $DB_COL_SWP_NAME => $name,
                    }, ) ) {
                if ( $self->MAINDB->add_switchport( {
                            $DB_COL_SWP_SWID => $switchid,
                            $DB_COL_SWP_NAME => $name,
                            $DB_COL_SWP_DESC => ( "Auto Added by " . $NACSyslog::hostname . " at " . localtime(time) ),
                        }, ) ) {
                    $ret++;
                    push( @delete_ids, $id );
                    EventLog( EVENT_DEBUG, MYNAMELINE . " PUSH to DB: " . $ref->{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME} );
                }
            }
        }
        foreach my $id (@delete_ids) {
            $self->BUF->delete_switchport_id($id);
            EventLog( EVENT_INFO, MYNAMELINE . " Remove local SWITCHPORT: " . $id );
        }
    }
    $ret;
}

#-------------------------------------------------------
# Sync add_radiusaudit table
#-------------------------------------------------------
sub sync_add_radiusaudit {
    my ($self)     = @_;
    my $count      = 0;
    my @delete_ids = ();
    my $ret        = 0;
    my $ref;

    EventLog( EVENT_INFO, MYNAMELINE . " called " );

    $count = 0;

    # if ( $self->MAINDB->sql_connected ) {
    if ( $self->RA->sql_connected ) {
        while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_radiusaudit( $count++ ) ) ) {
            my $id        = $ref->{$DB_COL_BUF_ADD_RA_ID};
            my $macid     = $ref->{$DB_COL_BUF_ADD_RA_MACID};
            my $swpid     = $ref->{$DB_COL_BUF_ADD_RA_SWPID};
            my $type      = $ref->{$DB_COL_BUF_ADD_RA_TYPE};
            my $cause     = $ref->{$DB_COL_BUF_ADD_RA_CAUSE};
            my $octin     = $ref->{$DB_COL_BUF_ADD_RA_OCTIN};
            my $octout    = $ref->{$DB_COL_BUF_ADD_RA_OCTOUT};
            my $pacin     = $ref->{$DB_COL_BUF_ADD_RA_PACIN};
            my $pacout    = $ref->{$DB_COL_BUF_ADD_RA_PACOUT};
            my $audittime = $ref->{$DB_COL_BUF_ADD_RA_AUDITTIME};

            # if ( $self->MAINDB->add_radiusaudit( {
            if ( $self->RA->add_radiusaudit( {
                        $DB_COL_RA_MACID      => $macid,
                        $DB_COL_RA_SWPID      => $swpid,
                        $DB_COL_RA_TYPE       => $type,
                        $DB_COL_RA_CAUSE      => $cause,
                        $DB_COL_RA_OCTIN      => $octin,
                        $DB_COL_RA_OCTOUT     => $octout,
                        $DB_COL_RA_PACIN      => $pacin,
                        $DB_COL_RA_PACOUT     => $pacout,
                        $DB_COL_RA_MACID      => $macid,
                        $DB_COL_RA_AUDIT_SRV  => $hostname,
                        $DB_COL_RA_AUDIT_TIME => $audittime,
                    }, ) ) {
                $ret++;
                push( @delete_ids, $id );
                EventLog( EVENT_INFO, MYNAMELINE . " PUSH to DB for MACID: " . $ref->{$DB_COL_BUF_ADD_RA_MACID} );
            }
            else {
                EventLog( EVENT_ERR, MYNAMELINE . " PUSH to DB FAILED... exiting loop " );
                last;
            }
        }
    }

    foreach my $id (@delete_ids) {
        $self->BUF->delete_radiusaudit_id($id);
        EventLog( EVENT_INFO, MYNAMELINE . " Remove local RADIUSAUDIT: " . $id );
    }

    $ret;
}

#-------------------------------------------------------
# Sync eventlog table
#-------------------------------------------------------
sub sync_eventlog {
    my ($self)     = @_;
    my $count      = 0;
    my @delete_ids = ();
    my $ret        = 0;
    my $ref;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called " );

    # if ( $self->MAINDB->sql_connected ) {
    if ( $self->EL->sql_connected ) {
        while ( ( $count < $MAX_LOOP_COUNT ) && ( $ref = $self->BUF->get_next_eventlog( $count++ ) ) ) {
            my $id        = $ref->{$DB_COL_BUF_EVENTLOG_ID};
            my $time      = $ref->{$DB_COL_BUF_EVENTLOG_TIME};
            my $type      = $ref->{$DB_COL_BUF_EVENTLOG_TYPE};
            my $classid   = $ref->{$DB_COL_BUF_EVENTLOG_CLASSID};
            my $locid     = $ref->{$DB_COL_BUF_EVENTLOG_LOCID};
            my $macid     = $ref->{$DB_COL_BUF_EVENTLOG_MACID};
            my $m2cid     = $ref->{$DB_COL_BUF_EVENTLOG_M2CID};
            my $p2cid     = $ref->{$DB_COL_BUF_EVENTLOG_P2CID};
            my $swid      = $ref->{$DB_COL_BUF_EVENTLOG_SWID};
            my $swpid     = $ref->{$DB_COL_BUF_EVENTLOG_SWPID};
            my $sw2vid    = $ref->{$DB_COL_BUF_EVENTLOG_SW2VID};
            my $tempid    = $ref->{$DB_COL_BUF_EVENTLOG_TEMPID};
            my $temp2vgid = $ref->{$DB_COL_BUF_EVENTLOG_TEMP2VGID};
            my $vgid      = $ref->{$DB_COL_BUF_EVENTLOG_VGID};
            my $vg2vid    = $ref->{$DB_COL_BUF_EVENTLOG_VG2VID};
            my $vlanid    = $ref->{$DB_COL_BUF_EVENTLOG_VLANID};
            my $ip        = $ref->{$DB_COL_BUF_EVENTLOG_IP};
            my $desc      = $ref->{$DB_COL_BUF_EVENTLOG_DESC};

            if ( $self->EL->add_eventlog( {

                        # if ( $self->MAINDB->add_eventlog( {
                        $DB_COL_EVENTLOG_TIME      => $time,
                        $DB_COL_EVENTLOG_TYPE      => $type,
                        $DB_COL_EVENTLOG_CLASSID   => $classid,
                        $DB_COL_EVENTLOG_LOCID     => $locid,
                        $DB_COL_EVENTLOG_MACID     => $macid,
                        $DB_COL_EVENTLOG_M2CID     => $m2cid,
                        $DB_COL_EVENTLOG_P2CID     => $p2cid,
                        $DB_COL_EVENTLOG_SWID      => $swid,
                        $DB_COL_EVENTLOG_SWPID     => $swpid,
                        $DB_COL_EVENTLOG_SW2VID    => $sw2vid,
                        $DB_COL_EVENTLOG_TEMPID    => $tempid,
                        $DB_COL_EVENTLOG_TEMP2VGID => $temp2vgid,
                        $DB_COL_EVENTLOG_VLANID    => $vlanid,
                        $DB_COL_EVENTLOG_VGID      => $vgid,
                        $DB_COL_EVENTLOG_VG2VID    => $vg2vid,
                        $DB_COL_EVENTLOG_IP        => $ip,
                        $DB_COL_EVENTLOG_HOST      => $hostname,
                        $DB_COL_EVENTLOG_DESC      => $desc,
                    }, ) ) {
                $ret++;
                push( @delete_ids, $id );
                EventLog( EVENT_INFO, MYNAMELINE . " PUSH to DB LOCAL EVENT ID:" . $id );
            }
            else {
                EventLog( EVENT_WARN, MYNAMELINE . " FAILED to PUSH to DB LOCAL EVENT ID:" . $id );
            }
        }

        foreach my $id (@delete_ids) {
            $self->BUF->delete_eventlog_id($id);
            EventLog( EVENT_DEBUG, MYNAMELINE . " REMOVE LOCAL EVENT ID:" . $id );
        }

    }
    $ret;
}

#-------------------------------------------------------
# Sync Switchporstate table
#-------------------------------------------------------
sub sync_switchportstate_all {
    my ($self) = @_;
    my $count = 0;
    my $ref;

    EventLog( EVENT_INFO, MYNAMELINE . " called " );

    if ( $self->MAINDB->sql_connected ) {
        while ( $ref = $self->BUF->get_next_switchportstate( $count++ ) ) {
            my $id = $ref->{$DB_COL_BUF_SWPS_SWPID};
            if ( !$self->sync_switchportstate_id($id) ) {
                EventLog( EVENT_WARN, MYNAMELINE . " Failed to UPDATE ID: $id " );
                last;
            }
        }
    }
}

#-------------------------------------------------------
# Sync Switchporstate table
#-------------------------------------------------------
sub sync_switchportstate_id {
    my ( $self, $id ) = @_;
    my $count = 0;
    my $ref;
    my $ret = 0;

    if ( !$self->MAINDB->sql_connected ) {
        EventLog( EVENT_WARN, MYNAMELINE . " NOT CONNECTED to DB" );
        return 0;
    }

    my %buf_parm = ();
    $buf_parm{$DB_COL_BUF_SWPS_SWPID} = $id;
    if ( $self->BUF->get_switchportstate( \%buf_parm ) ) {
        my %db_parm = ();
        my $id = $db_parm{$DB_COL_SWPS_SWPID} = $buf_parm{$DB_COL_BUF_SWPS_SWPID};

        if ( $self->LOCALRO->get_switchportstate( \%db_parm ) || $self->MAINDB->get_switchportstate( \%db_parm ) ) {
            if ( $db_parm{$DB_COL_SWPS_LASTUPDATE} lt $buf_parm{$DB_COL_BUF_SWPS_LASTUPDATE} ) {
                EventLog( EVENT_DEBUG, MYNAMELINE . " UPDATE to DB LOCAL SWPS ID:" . $id . "BUF:" . $buf_parm{$DB_COL_BUF_SWPS_LASTUPDATE} . " DB:" . $db_parm{$DB_COL_BUF_SWPS_LASTUPDATE} );

                my $macid  = ( $db_parm{$DB_COL_BUF_SWPS_MACID} > 0 )  ? $db_parm{$DB_COL_BUF_SWPS_MACID}  : 0;
                my $vmacid = ( $db_parm{$DB_COL_BUF_SWPS_VMACID} > 0 ) ? $db_parm{$DB_COL_BUF_SWPS_VMACID} : 0;

                if ($macid) {
                    $self->MAINDB->clear_macid_not_swpsid_switchportstate( $macid, $id );
                    $self->MAINDB->clear_vmacid_not_swpsid_switchportstate( $macid, $id );
                }

                if ($vmacid) {
                    $self->MAINDB->clear_macid_not_swpsid_switchportstate( $vmacid, $id );
                    $self->MAINDB->clear_vmacid_not_swpsid_switchportstate( $vmacid, $id );
                }

                $db_parm{$DB_COL_SWPS_HOSTNAME}   = $hostname;
                $db_parm{$DB_COL_SWPS_VHOSTNAME}  = $hostname;
                $db_parm{$DB_COL_SWPS_LASTUPDATE} = $buf_parm{$DB_COL_BUF_SWPS_LASTUPDATE};
                $db_parm{$DB_COL_SWPS_MACID}      = $buf_parm{$DB_COL_BUF_SWPS_MACID};
                $db_parm{$DB_COL_SWPS_CLASSID}    = $buf_parm{$DB_COL_BUF_SWPS_CLASSID};
                $db_parm{$DB_COL_SWPS_TEMPID}     = $buf_parm{$DB_COL_BUF_SWPS_TEMPID};
                $db_parm{$DB_COL_SWPS_VGID}       = $buf_parm{$DB_COL_BUF_SWPS_VGID};
                $db_parm{$DB_COL_SWPS_VLANID}     = $buf_parm{$DB_COL_BUF_SWPS_VLANID};
                $db_parm{$DB_COL_SWPS_VMACID}     = $buf_parm{$DB_COL_BUF_SWPS_VMACID};
                $db_parm{$DB_COL_SWPS_VCLASSID}   = $buf_parm{$DB_COL_BUF_SWPS_VCLASSID};
                $db_parm{$DB_COL_SWPS_VTEMPID}    = $buf_parm{$DB_COL_BUF_SWPS_VTEMPID};
                $db_parm{$DB_COL_SWPS_VVGID}      = $buf_parm{$DB_COL_BUF_SWPS_VVGID};
                $db_parm{$DB_COL_SWPS_VVLANID}    = $buf_parm{$DB_COL_BUF_SWPS_VVLANID};

                if ( !$self->MAINDB->update_switchportstate( \%db_parm ) ) {
                    EventLog( EVENT_INFO, MYNAMELINE . " NO UPDATE NEEDED  SWPS ID:" . $id );
                }
                else {
                    EventLog( EVENT_INFO, MYNAMELINE . " SWITCHPORTSTATE UPDATED " );
                    $ret++;
                }
            }
            else {
                EventLog( EVENT_DEBUG, MYNAMELINE . " SWITCHPORTSTATE LASTUPDATE TIME is newer: "
                      . $db_parm{$DB_COL_SWPS_LASTUPDATE}
                      . " > "
                      . $buf_parm{$DB_COL_BUF_SWPS_LASTUPDATE} );
                $ret++;
            }
        }
        else {
            EventLog( EVENT_WARN, MYNAMELINE . " SWITCHPORTSTATE ID:$id not found, Add it " );

            my $macid  = ( $buf_parm{$DB_COL_BUF_SWPS_MACID} > 0 )  ? $buf_parm{$DB_COL_BUF_SWPS_MACID}  : 0;
            my $vmacid = ( $buf_parm{$DB_COL_BUF_SWPS_VMACID} > 0 ) ? $buf_parm{$DB_COL_BUF_SWPS_VMACID} : 0;

            if ($macid) {
                $self->MAINDB->clear_macid_not_swpsid_switchportstate($macid);
                $self->MAINDB->clear_vmacid_not_swpsid_switchportstate($macid);
            }

            if ($vmacid) {
                $self->MAINDB->clear_macid_not_swpsid_switchportstate($vmacid);
                $self->MAINDB->clear_vmacid_not_swpsid_switchportstate($vmacid);
            }

            $db_parm{$DB_COL_SWPS_SWPID}    = $buf_parm{$DB_COL_BUF_SWPS_SWPID};
            $db_parm{$DB_COL_SWPS_MACID}    = $buf_parm{$DB_COL_BUF_SWPS_MACID};
            $db_parm{$DB_COL_SWPS_CLASSID}  = $buf_parm{$DB_COL_BUF_SWPS_CLASSID};
            $db_parm{$DB_COL_SWPS_VGID}     = $buf_parm{$DB_COL_BUF_SWPS_VGID};
            $db_parm{$DB_COL_SWPS_VLANID}   = $buf_parm{$DB_COL_BUF_SWPS_VLANID};
            $db_parm{$DB_COL_SWPS_TEMPID}   = $buf_parm{$DB_COL_BUF_SWPS_TEMPID};
            $db_parm{$DB_COL_SWPS_VMACID}   = $buf_parm{$DB_COL_BUF_SWPS_VMACID};
            $db_parm{$DB_COL_SWPS_VCLASSID} = $buf_parm{$DB_COL_BUF_SWPS_VCLASSID};
            $db_parm{$DB_COL_SWPS_VVGID}    = $buf_parm{$DB_COL_BUF_SWPS_VVGID};
            $db_parm{$DB_COL_SWPS_VVLANID}  = $buf_parm{$DB_COL_BUF_SWPS_VVLANID};
            $db_parm{$DB_COL_SWPS_VTEMPID}  = $buf_parm{$DB_COL_BUF_SWPS_VTEMPID};

            if ( $db_parm{$DB_COL_SWPS_MACID} > 0 ) {
                $db_parm{$DB_COL_SWPS_HOSTNAME} = $hostname;
            }
            if ( $db_parm{$DB_COL_SWPS_VMACID} > 0 ) {
                $db_parm{$DB_COL_SWPS_VHOSTNAME} = $hostname
            }

            if ( !$self->MAINDB->add_switchportstate( \%db_parm ) ) {
                EventLog( EVENT_ERR, MYNAMELINE . " FAILED to UPDATE to DB LOCAL SWPS ID:" . $id );
            }
        }

        $ret++;
    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE . " Bad ID: $id" );
    }

    $ret;
}

#-------------------------------------------------------
# update HOST lastseen
#
#-------------------------------------------------------
sub sync_lastseen_host {
    my ($self) = @_;
    my $count = 0;

    if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
        if ( ( !defined $self->{$HOST_LS_SEND_TIME} ) || ( $self->{$HOST_LS_SEND_TIME} < ( time - $MIN_SEND_TIME ) ) ) {
            if ( !$self->STATUS->update_host_lastseen() ) {
                EventLog( EVENT_WARN, MYNAMELINE . " Failed to UPDATE HOST " );
            }
            else {
                $self->{$HOST_LS_SEND_TIME} = time;
            }
        }
    }
    else {
        EventLog( EVENT_WARN, MYNAMELINE . " NOT CONNECTED to STATUS" );
    }

}

#-------------------------------------------------------
# update HOST (slave) lastseen
#
#-------------------------------------------------------
sub sync_slave {
    my ( $self, $state ) = @_;
    my $count = 0;

    if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
        if ( !$self->STATUS->update_slave_status($state) ) {
            EventLog( EVENT_WARN, MYNAMELINE . " Failed SLAVE Checkin " );
        }
        else {
            EventLog( EVENT_DEBUG, MYNAMELINE . " Run " );
            $self->{$HOST_LS_SLAVE_CHECKIN} = time;
        }
    }
    else {
        EventLog( EVENT_WARN, MYNAMELINE . " NOT CONNECTED to STATUS" );
    }
}

#-------------------------------------------------------
# update MAC lastseen
#
# Rolls though the lastseen table starting with the most current
# updating the master database until it finds one that current
#-------------------------------------------------------
sub sync_lastseen_location_all {
    my ($self) = @_;
    my $count = 0;

    if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
        while ( my $ref = $self->BUF->get_next_lastseen_location( $count++, 1 ) ) {
            my $id       = $ref->{$DB_COL_BUF_LASTSEEN_LOCATION_ID};
            my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN};
            my $lastsend = $self->{$LOCATION_LS_SEND_TIME}->{$id};

            if ( ( !defined $lastsend ) || ( $lastsend < ( time - $MIN_SEND_TIME ) ) ) {
                if ( !$self->sync_lastseen_location_id($id) ) {
                    EventLog( EVENT_WARN, MYNAMELINE . " Failed to UPDATE ID: $id " );
                    last;
                }
            }
        }
    }
    else {
        EventLog( EVENT_WARN, MYNAMELINE . " NOT CONNECTED to STATUS" );
    }
}

#-------------------------------------------------------
# update lastseen
#
# Rolls though the lastseen table starting with the most current
# updating the master database until it finds one that current
#-------------------------------------------------------
sub sync_lastseen_location_id {
    my ( $self, $id ) = @_;
    my $count = 0;
    my $ret   = 0;

    my $lastsend = $self->{$LOCATION_LS_SEND_TIME}->{$id};

    if ( ( ( !defined $lastsend ) || ( $lastsend < ( time - $MIN_SEND_TIME ) ) ) ) {
        if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
            if ( my $ref = $self->BUF->get_lastseen_location($id) ) {
                my $locid    = $ref->{$DB_COL_BUF_LASTSEEN_LOCATION_ID};
                my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN};

                if ( my $ref = $self->STATUS->get_location($locid) ) {
                    my $db_lastseen = $ref->{$DB_COL_STATUS_LOCATION_LASTSEEN};
                    if ( $db_lastseen lt $lastseen ) {
                        if ( !$self->STATUS->update_location_lastseen( $locid, $lastseen ) ) {
                            EventLog( EVENT_ERR, MYNAMELINE . " UPDATE LOCATION LASTSEEN FAILED for LOCID:$locid and TIME:$lastseen " );
                        }
                        else {
                            EventLog( EVENT_DEBUG, MYNAMELINE . " Run: $locid " );
                            $ret++;
                        }
                    }
                    else {
                        $ret++;
                        EventLog( EVENT_DEBUG, MYNAMELINE . " SKIP UPDATE " );
                    }
                }
                else {
                    my %parm_ref = ();
                    $parm_ref{$DB_COL_LOC_ID} = $id;
                    if ( $self->LOCALRO->get_location( \%parm_ref, ) ) {
                        if ( !( $self->STATUS->add_location( {
                                        $DB_COL_STATUS_LOCATION_LOCATIONID => $locid,
                                        $DB_COL_STATUS_LOCATION_SITE       => $parm_ref{$DB_COL_LOC_SITE},
                                        $DB_COL_STATUS_LOCATION_BLDG       => $parm_ref{$DB_COL_LOC_BLDG},
                                    }, ) ) ) {
                            EventLog( EVENT_ERR, MYNAMELINE . " FAILED to add LOCID $locid in Status DB" );
                        }
                        else {
                            $ret++;
                        }
                    }
                    else {
                        EventLog( EVENT_ERR, MYNAMELINE . " BAD LOCID $id used, cant get record from RO DB" );
                    }
                }

                if ($ret) {
                    $self->{$LOCATION_LS_SEND_TIME}->{$id} = time;
                    $self->sync_lastseen_location_id($locid);
                }
            }
            else {
                $self->BUF->update_lastseen_locationid($id);
            }
        }
        else {
            EventLog( EVENT_WARN, MYNAMELINE . " STATUS not connected" );
        }
    }
    else {
        EventLog( EVENT_DEBUG, MYNAMELINE . " SKIP, Recently synced LS:$lastsend  Time:" . time );
    }

    $ret;
}

#-------------------------------------------------------
# update MAC lastseen
#
# Rolls though the lastseen table starting with the most current
# updating the master database until it finds one that current
#-------------------------------------------------------
sub sync_lastseen_mac_all {
    my ($self) = @_;
    my $count = 0;

    EventLog( EVENT_INFO, MYNAMELINE . " Called " );

    if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
        while ( my $ref = $self->BUF->get_next_lastseen_mac( $count++, 1 ) ) {
            my $id = $ref->{$DB_COL_BUF_LASTSEEN_MAC_ID};

            if ( ( !defined $self->{$MAC_LS_SEND_TIME}->{$id} ) || ( $self->{$MAC_LS_SEND_TIME}->{$id} < ( time - $MIN_SEND_TIME ) ) ) {
                if ( !$self->sync_lastseen_mac_id($id) ) {
                    EventLog( EVENT_WARN, MYNAMELINE . " Failed to UPDATE ID: $id " );
                    last;
                }
            }
        }
    }
    else {
        EventLog( EVENT_WARN, MYNAMELINE . " NOT CONNECTED to STATUS" );
    }
}

#-------------------------------------------------------
# update lastseen
#
# Rolls though the lastseen table starting with the most current
# updating the master database until it finds one that current
#-------------------------------------------------------
sub sync_lastseen_mac_id {
    my ( $self, $id ) = @_;
    my $count = 0;
    my $ret   = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . " Called: $id " );

    if ( ( !defined $self->{$MAC_LS_SEND_TIME}->{$id} ) || ( $self->{$MAC_LS_SEND_TIME}->{$id} < ( time - $MIN_SEND_TIME ) ) ) {

        #
        # MAINDB
        #
        if ( $self->MAINDB && ( $self->MAINDB->sql_connected || $self->MAINDB->reconnect ) ) {
            if ( my $ref = $self->BUF->get_lastseen_mac($id) ) {
                my $macid    = $ref->{$DB_COL_BUF_LASTSEEN_MAC_ID};
                my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_MAC_LASTSEEN};

                my %parm = ();
                $parm{$DB_COL_MAC_ID} = $id;

                if ( $self->MAINDB ) {
                    if ( $self->MAINDB->get_mac( \%parm ) ) {
                        my $db_lastseen = $ref->{$DB_COL_STATUS_MAC_LASTSEEN};
                        if ( $db_lastseen lt $lastseen ) {
                            my %parm = ();
                            $parm{$DB_COL_MAC_ID} = $id;
                            $parm{$DB_COL_MAC_LS} = $db_lastseen;

                            if ( !$self->MAINDB->update_mac_lastseen( \%parm ) ) {
                                EventLog( EVENT_ERR, MYNAMELINE . " UPDATE MAC LASTSEEN FAILED for MACID:$macid and TIME:$lastseen " );
                            }
                            else {
                                $ret++;
                            }
                        }
                        else {
                            $ret++;
                            EventLog( EVENT_DEBUG, MYNAMELINE . " SKIP MAINDB UPDATE " );
                        }
                    }
                    else {
                        EventLog( EVENT_ERR, MYNAMELINE . " SHOULD NEVER BE HERE - BAD MACID $id cant get record from DB" );
                    }
                }

            }
            else {
                $self->BUF->update_lastseen_macid($id);
            }
        }
        else {
            EventLog( EVENT_INFO, MYNAMELINE . " MAINDB not connected" );
            return 0;
        }

        #
        # STATUS
        #
        if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
            if ( my $ref = $self->BUF->get_lastseen_mac($id) ) {
                my $macid    = $ref->{$DB_COL_BUF_LASTSEEN_MAC_ID};
                my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_MAC_LASTSEEN};

                if ( $self->STATUS ) {
                    if ( my $ref = $self->STATUS->get_mac($macid) ) {
                        my $db_lastseen = $ref->{$DB_COL_STATUS_MAC_LASTSEEN};
                        if ( $db_lastseen lt $lastseen ) {
                            if ( !$self->STATUS->update_mac_lastseen( $macid, $lastseen ) ) {
                                EventLog( EVENT_ERR, MYNAMELINE . " UPDATE MAC LASTSEEN FAILED for MACID:$macid and TIME:$lastseen " );
                            }
                            else {
                                $ret++;
                            }
                        }
                        else {
                            $ret++;
                            EventLog( EVENT_DEBUG, MYNAMELINE . " SKIP UPDATE " );
                        }
                    }
                    else {
                        my %parm_ref = ();
                        $parm_ref{$DB_COL_MAC_ID} = $macid;
                        if ( $self->LOCALRO->get_mac( \%parm_ref, ) ) {
                            if ( !( $self->STATUS->add_mac( {
                                            $DB_COL_STATUS_MAC_MACID => $macid,
                                            $DB_COL_STATUS_MAC_MAC   => $parm_ref{$DB_COL_MAC_MAC},
                                        }, ) ) ) {
                                EventLog( EVENT_ERR, MYNAMELINE . " FAILED to add MACID $macid in Status DB" );
                            }
                            else {
                                $ret++;
                            }
                        }
                        else {
                            EventLog( EVENT_ERR, MYNAMELINE . " BAD MACID $id used, cant get record from RO DB" );
                        }
                    }
                }

                if ($ret) {
                    $self->{$MAC_LS_SEND_TIME}->{$id} = time;
                }
            }
            else {
                EventLog( EVENT_ERR, MYNAMELINE . " BAD MACID $id used" );
            }
        }
        else {
            EventLog( EVENT_INFO, MYNAMELINE . " STATUS not connected" );
        }
    }
    else {
        EventLog( EVENT_DEBUG, MYNAMELINE . " SKIP, Recently synced" );
    }

    $ret;
}

#-------------------------------------------------------
# update lastseen
#
# Rolls though the lastseen table starting with the most current
# updating the master database until it finds one that current
#-------------------------------------------------------
sub sync_lastseen_switch_all {
    my ($self) = @_;
    my $count = 0;

    EventLog( EVENT_INFO, MYNAMELINE . " Called " );

    if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
        while ( my $ref = $self->BUF->get_next_lastseen_switch( $count++, 1 ) ) {
            my $id = $ref->{$DB_COL_BUF_LASTSEEN_SWITCH_ID};
            if ( ( !defined $self->{$SWITCH_LS_SEND_TIME}->{$id} ) || ( $self->{$SWITCH_LS_SEND_TIME}->{$id} < ( time - $MIN_SEND_TIME ) ) ) {
                if ( !$self->sync_lastseen_switch_id($id) ) {
                    EventLog( EVENT_WARN, MYNAMELINE . " Failed to UPDATE ID: $id " );
                    last;
                }
            }
        }
    }
    else {
        EventLog( EVENT_INFO, MYNAMELINE . " STATUS not connected" );
    }
}

#-------------------------------------------------------
# update SWITCH lastseen
#-------------------------------------------------------
sub sync_lastseen_switch_id {
    my ( $self, $id ) = @_;
    my $count = 0;
    my $ret   = 0;

    #
    # Verify connection to Master Status database table
    #
    if ( !( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) ) {
        EventLog( EVENT_WARN, MYNAMELINE . " STATUS not connected" );
        return 0;
    }

    #
    # Get last send time
    #
    my $last_send_time = ( defined $self->{$SWITCH_LS_SEND_TIME} ) ? $self->{$SWITCH_LS_SEND_TIME}->{$id} : undef;

    EventLog( EVENT_DEBUG, MYNAMELINE . " Called: $id  SEND_TIME:" . $self->{$SWITCH_LS_SEND_TIME}->{$id} . " time:" . ( time - $MIN_SEND_TIME ) ) if defined $last_send_time;

    #
    # If last send time DNE, or is > current time - MIN_SEND_TIME 
    # 	then update
    #
    if ( ( !defined $last_send_time ) || ( $last_send_time < ( time - $MIN_SEND_TIME ) ) ) {

	#
	# Verify that the switchid is in the local BUFFER table
	#
        if ( my $ref = $self->BUF->get_lastseen_switch($id) ) {
            my $swid     = $ref->{$DB_COL_BUF_LASTSEEN_SWITCH_ID};
            my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN};

		#
		# Get STATUS switch data
		#
            if ( my $ref = $self->STATUS->get_switch($swid) ) {
                my $db_lastseen = $ref->{$DB_COL_STATUS_SWITCH_LASTSEEN};

                # EventLog( EVENT_INFO, MYNAMELINE . " Compare LOCAL:$lastseen to DB:$db_lastseen " );

	    	#
	    	# Compare lastsend time, if buffer is newer update the STATUS table
	    	#
                if ( $db_lastseen < ( $lastseen - $MIN_SEND_TIME )) {

                    EventLog( EVENT_INFO, MYNAMELINE . " UPDATE DB from $db_lastseen TO LOCAL:$lastseen " );

                    if ( !$self->STATUS->update_switch_lastseen( $swid, $lastseen ) ) {
                        EventLog( EVENT_ERR, MYNAMELINE . " UPDATE SWITCH LASTSEEN FAILED for MACID:$swid and TIME:$lastseen " );
                    }
                    else {
                        $ret++;
                    }

                }
                else {
                    EventLog( EVENT_DEBUG, MYNAMELINE . " SKIP UPDATE " );
                    $ret++;
                }
            }
	    #
	    # Switch does not exist yet so create it
	    #
            else {
                my %parm_get = ();
                $parm_get{$DB_COL_SW_ID} = $id;
                if ( $self->LOCALRO->get_switch( \%parm_get, ) ) {
                    my %parm = ();
                    $parm{$DB_COL_STATUS_SWITCH_SWITCHID}   = $id;
                    $parm{$DB_COL_STATUS_SWITCH_SWITCHNAME} = $parm_get{$DB_COL_SW_NAME};
                    $parm{$DB_COL_STATUS_SWITCH_LOCATIONID} = $parm_get{$DB_COL_SW_LOCID};
                    if ( !( $self->STATUS->add_switch( \%parm ) ) ) {
                        EventLog( EVENT_ERR, MYNAMELINE . " FAILED to add SWID $id in STATUS DB" );
                    }
                    else {
                        $ret++;
                    }
                }
                else {
                    EventLog( EVENT_ERR, MYNAMELINE . " BAD SWID $id used, cant get record from RO DB" );
                }
            }

            if ($ret) {
                $self->{$SWITCH_LS_SEND_TIME}->{$id} = time;
            }
        }
	#
	# SWITCHID is not in buffer table, this will create it and restart the update process
	#
        else {
            $self->BUF->update_lastseen_switchid($id);
        }
    }
    else {
        EventLog( EVENT_INFO, MYNAMELINE . " STATUS too soon to update ID: $id, LST: " . localtime($last_send_time) ." > MIN:" . localtime( time - $MIN_SEND_TIME ) );
    }
    $ret;
}

#-------------------------------------------------------
# update lastseen
#
# Rolls though the lastseen table starting with the most current
# updating the master database until it finds one that current
#-------------------------------------------------------
sub sync_lastseen_switchport_all {
    my ($self) = @_;

    EventLog( EVENT_INFO, MYNAMELINE . " Called " );

    if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
        EventLog( EVENT_INFO, MYNAMELINE . " STATUS not connected" );
        return;
    }

    my $count = 0;
    while ( my $ref = $self->BUF->get_next_lastseen_switchport( $count++, 1 ) ) {
        my $id       = $ref->{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID};
        my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN};

        if ( ( !defined $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} ) || ( $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} < ( time - $MIN_SEND_TIME ) ) ) {
            if ( my $ref = $self->STATUS->get_switchport($id) ) {
                my $db_lastseen = $ref->{$DB_COL_STATUS_SWITCHPORT_LASTSEEN};

                EventLog( EVENT_INFO, MYNAMELINE . " Compare LOCAL:$lastseen to DB:$db_lastseen " );

                if ( $db_lastseen lt $lastseen ) {

                    EventLog( EVENT_INFO, MYNAMELINE . " UPDATE DB WITH LOCAL:$lastseen " );

                    if ( !$self->STATUS->update_switchport_lastseen( $id, $lastseen ) ) {
                        EventLog( EVENT_ERR, MYNAMELINE . " UPDATE SWITCHPORT LASTSEEN FAILED for SWPID:$id and TIME:$lastseen " );
                    }
                }
                else {
                    EventLog( EVENT_INFO, MYNAMELINE . " SKIP UPDATE $db_lastseen > $lastseen " );
                }
            }
            else {
                $self->add_lastseen_switchport_id($id);
            }
        }
    }
}

#-------------------------------------------------------
# switchport update lastseen ID
#
#-------------------------------------------------------
sub sync_lastseen_switchport_id {
    my ( $self, $id ) = @_;
    my $count = 0;
    my $ret   = 0;

    my $last_send_time = ( defined $self->{$SWITCHPORT_LS_SEND_TIME} ) ? $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} : undef;

    EventLog( EVENT_INFO, MYNAMELINE . " Called: $id LAST SEND:" . $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} . " time:" . ( time - $MIN_SEND_TIME ) );

    if ( ( !defined $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} ) || ( $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} < ( time - $MIN_SEND_TIME ) ) ) {
        if ( $self->STATUS && ( $self->STATUS->sql_connected || $self->STATUS->reconnect ) ) {
            if ( my $ref = $self->BUF->get_lastseen_switchport($id) ) {

                my $swpid    = $ref->{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID};
                my $lastseen = $ref->{$DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN};

                if ( my $ref = $self->STATUS->get_switchport($swpid) ) {
                    my $db_lastseen = $ref->{$DB_COL_STATUS_SWITCHPORT_LASTSEEN};

                    EventLog( EVENT_INFO, MYNAMELINE . " Compare LOCAL:$lastseen to DB:$db_lastseen " );

                    if ( $db_lastseen lt $lastseen ) {

                        EventLog( EVENT_INFO, MYNAMELINE . " UPDATE DB WITH LOCAL:$lastseen " );

                        if ( !$self->STATUS->update_switchport_lastseen( $swpid, $lastseen ) ) {
                            EventLog( EVENT_ERR, MYNAMELINE . " UPDATE SWITCHPORT LASTSEEN FAILED for MACID:$swpid and TIME:$lastseen " );
                        }
                        else {
                            $ret++;
                        }

                    }
                    else {
                        EventLog( EVENT_INFO, MYNAMELINE . " SKIP UPDATE " );
                        $ret++;
                    }
                    if ($ret) {
                        $self->{$SWITCHPORT_LS_SEND_TIME}->{$id} = time;
                    }
                }
                else {
                    $ret = $self->add_lastseen_switchport_id($id);
                }
            }
            else {
                $self->BUF->update_lastseen_switchportid($id);
            }
        }
        else {
            EventLog( EVENT_INFO, MYNAMELINE . " STATUS not connected" );
        }
    }
    else {
        EventLog( EVENT_INFO, MYNAMELINE . " STATUS too soon to update ID: $id, LST: $last_send_time < " . ( time - $MIN_SEND_TIME ) );
    }
    $ret;
}

#-------------------------------------------------------
# switchport update lastseen
#
#-------------------------------------------------------
sub add_lastseen_switchport_id {
    my ( $self, $id ) = @_;
    my $count = 0;
    my $ret   = 0;

    EventLog( EVENT_INFO, MYNAMELINE . " Called: $id " );

    my %parm_ref = ();
    $parm_ref{$DB_COL_SWP_ID} = $id;
    if ( $self->LOCALRO->get_switchport( \%parm_ref, ) ) {
        my $portname   = $parm_ref{$DB_COL_SWP_NAME};
        my $switchid   = $parm_ref{$DB_COL_SWP_SWID};
        my $switchname = '';
        my $switchip   = 0;
        my $locid      = 0;
        my $site       = '';
        my $bldg       = '';

        %parm_ref = ();
        $parm_ref{$DB_COL_SW_ID} = $switchid;
        if ( $self->LOCALRO->get_switch( \%parm_ref, ) ) {
            $switchname = $parm_ref{$DB_COL_SW_NAME};
            $locid      = $parm_ref{$DB_COL_SW_LOCID};
            $switchip   = $parm_ref{$DB_COL_SW_IP};
        }
        else {
            EventLog( EVENT_ERR, MYNAMELINE . " Switch: $switchid NOT Found " );
        }

        if ($locid) {
            %parm_ref = ();
            $parm_ref{$DB_COL_LOC_ID} = $locid;
            if ( $self->LOCALRO->get_location( \%parm_ref, ) ) {
                $site = $parm_ref{$DB_COL_LOC_SITE};
                $bldg = $parm_ref{$DB_COL_LOC_BLDG};
            }
            else {
                EventLog( EVENT_ERR, MYNAMELINE . " Location: $locid NOT Found " );
            }
        }

        if ( !( $self->STATUS->add_switchport( {
                        $DB_COL_STATUS_SWITCHPORT_SWITCHPORTID => $id,
                        $DB_COL_STATUS_SWITCHPORT_PORTNAME     => $portname,
                        $DB_COL_STATUS_SWITCHPORT_SWITCHID     => $switchid,
                        $DB_COL_STATUS_SWITCHPORT_SWITCHNAME   => $switchname,
                        $DB_COL_STATUS_SWITCHPORT_LOCID        => $locid,
                        $DB_COL_STATUS_SWITCHPORT_SITE         => $site,
                        $DB_COL_STATUS_SWITCHPORT_BLDG         => $bldg,
                    }, ) ) ) {
            EventLog( EVENT_ERR, MYNAMELINE . " FAILED to add SWPID $id in Status DB" );
        }
        else {
            $ret++;

            if ( $self->{SNMPOK} ) {
                my $name_idx_ref = $self->SNMP($switchip)->get_name_to_index_ref();
                my $idx          = $name_idx_ref->{$portname};
                if ( !defined $idx ) {
                    EventLog( EVENT_WARN, MYNAMELINE . " BAD NAME '$portname', for $switchip, '$switchname'" );
                    EventLog( EVENT_WARN, MYNAMELINE . Dumper $name_idx_ref );
                }
                else {
                    if ( !( $self->STATUS->update_switchport_ifindex( $id, $idx ) ) ) {
                        EventLog( EVENT_WARN, MYNAMELINE . " CAN'T Update IfIndex $portname, for $switchip, $switchname" );
                    }

                    my $enabled = $self->SNMP->get_mac_auth_enabled_index($idx);

                    if ( !( $self->STATUS->update_switchport_ifindex( $id, $idx ) ) ) {
                        EventLog( EVENT_WARN, MYNAMELINE . " CAN'T Update IfIndex $portname, for $switchip, $switchname" );
                    }

                    if ( defined $enabled ) {
                        if ( !( $self->STATUS->update_switchport_enabled( $id, $enabled ) ) ) {
                            EventLog( EVENT_WARN, MYNAMELINE . " CAN'T Update ENABLED $portname, for $switchip, $switchname" );
                        }

                        if ($enabled) {
                            my $method    = $self->SNMP->get_mac_auth_method_index($idx);
                            my $state_ref = $self->SNMP->get_mac_auth_state_index_ref($idx);
                            my $auth_ref  = $self->SNMP->get_mac_auth_auth_index_ref($idx);
                            my $state     = undef;
                            my $auth      = undef;

                            if ( defined $state_ref ) {
                                $state = $state_ref->{ ( keys(%$state_ref) )[0] };
                            }

                            if ( defined $auth_ref ) {
                                $auth = $auth_ref->{ ( keys(%$auth_ref) )[0] };
                            }

                            if ( defined $method ) {
                                if ( !( $self->STATUS->update_switchport_enabled( $id, $method ) ) ) {
                                    EventLog( EVENT_WARN, MYNAMELINE . " CAN'T Update METHHOD $portname, for $switchip, $switchname" );
                                }
                            }

                            if ( defined $state ) {
                                if ( !( $self->STATUS->update_switchport_state( $id, $state ) ) ) {
                                    EventLog( EVENT_WARN, MYNAMELINE . " CAN'T Update STATE $portname, for $switchip, $switchname" );
                                }
                            }

                            if ( defined $auth ) {
                                if ( !( $self->STATUS->update_switchport_auth( $id, $auth ) ) ) {
                                    EventLog( EVENT_WARN, MYNAMELINE . " CAN'T Update AUTH $portname, for $switchip, $switchname" );
                                }
                            }
                        }
                    }

                }
            }
        }
    }
    else {
        EventLog( EVENT_ERR, MYNAMELINE . " BAD SWPID $id used, cant get record from RO DB" );
    }
    $ret;
}

1;
