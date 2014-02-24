#!/usr/bin/perl
# SVN: $Id: NACDBBuffer.pm 1538 2012-10-16 14:11:02Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-16 10:11:02 -0400 (Tue, 16 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBBuffer.pm $:
#
#
#
# Author: Sean McAdam
# Purpose: Provide Write access to a local NAC buffer database.
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBBuffer;
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck);
use DBD::mysql;
use POSIX;
use Readonly;
use IO::Socket::INET;
use NAC::DBSql;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::DBReadOnly;
use NAC::DBConsts;
use NAC::Constants;
use NAC::Misc;
use strict;

our @ISA = qw ( NAC::DBSql );

#
# Add a MAC to "add_mac" table with the mac as an argument
# Add a SWITCH to "add_switch" table with the IP as an argument
# Add a SWITCHPORT to "add_switchport" table with the SWITCHID, and PORTNAME as arguments
#
sub add_mac;
sub add_switch;
sub add_switchport;
sub add_radiusaudit;
sub add_eventlog;

#
# Update lastupdate time for MAC to "lastupdate_mac" table with current time
# Update lastupdate time for SWITCH to "lastupdate_switch" table with current time
# Update lastupdate time for SWITCHPORT to "lastupdate_switchport" table with current time
#
sub update_lastseen_mac;
sub update_lastseen_macid;
sub update_lastseen_switch;
sub update_lastseen_switchport;
sub update_lastseen_location;

sub EventDBLogBuf ($$);

Readonly our $SERVER_PORT             => 64092;
Readonly our $SERVER_HOST             => '127.0.0.1';
Readonly our $SERVER_MAXLEN           => 32;
Readonly our $SERVER_TIMEOUT          => 5;
Readonly our $BUF_CLIENT              => 'BUF_CLIENT';
Readonly our $BUF_SERVER              => 'BUF_SERVER';
Readonly our $MSG_EVENTLOG            => 'EVENTLOG';
Readonly our $MSG_RADIUS              => 'RADIUS';
Readonly our $MSG_ADD_MAC             => 'ADD_MAC';
Readonly our $MSG_ADD_SWITCH          => 'ADD_SWITCH';
Readonly our $MSG_ADD_SWITCHPORT      => 'ADD_SWITCHPORT';
Readonly our $MSG_LASTSEEN_LOCATION   => 'LASTSEEN_LOCATION';
Readonly our $MSG_LASTSEEN_MAC        => 'LASTSEEN_MAC';
Readonly our $MSG_LASTSEEN_SWITCH     => 'LASTSEEN_SWITCH';
Readonly our $MSG_LASTSEEN_SWITCHPORT => 'LASTSEEN_SWITCHPORT';
Readonly our $MSG_SWITCHPORTSTATE     => 'SWITCHPORTSTATE';
Readonly our $MSG_SLAVE_UNKNOWN       => 'SLAVE_UNKNOWN';
Readonly our $MSG_SLAVE_OK            => 'SLAVE_OK';
Readonly our $MSG_SLAVE_OFFLINE       => 'SLAVE_OFFLINE';
Readonly our $MSG_SLAVE_DELAY         => 'SLAVE_DELAY';

Readonly our $DBRO => 'DBRO';
Readonly our $MSG  => 'MSG';

our @EXPORT = qw (
  $MSG_EVENTLOG
  $MSG_RADIUS
  $MSG_ADD_MAC
  $MSG_ADD_SWITCH
  $MSG_ADD_SWITCHPORT
  $MSG_LASTSEEN_LOCATION
  $MSG_LASTSEEN_MAC
  $MSG_LASTSEEN_SWITCH
  $MSG_LASTSEEN_SWITCHPORT
  $MSG_SWITCHPORTSTATE
  $MSG_SLAVE_UNKNOWN
  $MSG_SLAVE_OK
  $MSG_SLAVE_OFFLINE
  $MSG_SLAVE_DELAY
);

my $AutoReconnect = 1;
my $DEBUG         = 1;

my $DB_MAX_RECONNECT_TRY = 10;

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;

#---------------------------------------------------------------------------
# Database Connections
# Standard connection, read/write to the master database, full access.
# Read Only access, could be to the master or a local mirror
# Buffer, for audit data, local buffer database access
# Audit, direct Audit database on master access
#
# Checnge should only be getting made at the master.
# Slave servers should be only updating the timestamps on records, or inserting audit data.
#
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub new {
    my ( $class, $parm_ref ) = @_;
    my $self;

    if ( ( defined $parm_ref ) && ( ref($parm_ref) ne 'HASH' ) ) { confess; }

    EventLog( EVENT_START, MYNAME . "() started" );

    eval {

        my %parms = ();

        my $config = NAC::ConfigDB->new();

        $parms{$SQL_DB}    = $config->nac_local_buffer_db;
        $parms{$SQL_HOST}  = $config->nac_local_buffer_hostname;
        $parms{$SQL_PORT}  = $config->nac_local_buffer_port;
        $parms{$SQL_USER}  = $config->nac_local_buffer_user;
        $parms{$SQL_PASS}  = $config->nac_local_buffer_pass;
        $parms{$SQL_CLASS} = $class;

        $self = $class->SUPER::new( \%parms );

    };
    if ($@) {
        LOGEVALFAIL();
        confess( MYNAMELINE . "$@" );
    }

    my @local_msg_buffer = ();

    $self->{$BUF_CLIENT} = undef;
    $self->{$BUF_SERVER} = undef;
    $self->{$DBRO}       = undef;
    $self->{$MSG}        = \@local_msg_buffer;

    bless $self, $class;

    $self;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub DBRO {
    my ($self) = @_;

    if ( !defined $self->{$DBRO} ) {
        if ( !( $self->{$DBRO} = NACDBReadOnly->new() ) ) {
            EventLog( EVENT_ERR, "Cannot ALLOCATE a NACDBReadOnly object" );
            return 0;
        }

    }

    if ( !$self->{$DBRO}->sql_connected() ) {
        if ( !( $self->{$DBRO}->connect ) ) {
            EventLog( EVENT_ERR, "Cannot CONNECT a NACDBReadOnly object" );
            return 0;
        }
    }

    return $self->{$DBRO};

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub setup_udp_server {
    my ($self) = @_;

    if ( defined $self->{$BUF_CLIENT} ) {
        EventLog( EVENT_ERR, "Already a Client, and I refuse to talk to myself. Exiting" );
        confess;
    }

    if ( !defined $self->{$BUF_SERVER} ) {
        if ( !( $self->{$BUF_SERVER} = IO::Socket::INET->new( LocalAddr => $SERVER_HOST, LocalPort => $SERVER_PORT, Proto => "udp", ) ) ) {
            EventLog( EVENT_ERR, "Cannot setup UDP Server on port $SERVER_PORT" );
            confess "Couldn't be a udp server on port $SERVER_PORT : $@";
        }
    }
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub setup_udp_client {
    my ($self) = @_;

    if ( !defined $self->{$BUF_CLIENT} ) {
        if ( !( $self->{$BUF_CLIENT} = IO::Socket::INET->new( PeerAddr => $SERVER_HOST, PeerPort => $SERVER_PORT, Proto => "udp" ) ) ) {
            EventLog( EVENT_ERR, "Cannot setup UDP Client for port $SERVER_PORT" );
            confess "Couldn't be a udp client for port $SERVER_PORT : $@";
        }
    }
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub udp_server_recv {
    my ($self) = @_;
    my $msg = '';

    EventLog( EVENT_DEBUG, "(RECV START)" );

    my $m = $self->{$MSG};
    if (@$m) {
        $msg = pop(@$m);
        EventLog( EVENT_INFO, "MESSAGE FROM QUEUE: $msg" );
    }
    else {
        $self->setup_udp_server;
        $self->{$BUF_SERVER}->recv( $msg, $SERVER_MAXLEN );
        EventLog( EVENT_DEBUG, "MESSAGE FROM UDP: $msg" );
    }

    EventLog( EVENT_DEBUG, "(RECV FINISH): $msg" );
    $msg;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub udp_client_send {
    my ( $self, $msg ) = @_;

    if ( defined $self->{$BUF_SERVER} ) {
        my $m = $self->{$MSG};
        push( @$m, $msg );
        EventLog( EVENT_DEBUG, MYNAMELINE . " MESSAGE SEND (LOCAL): $msg" );
    }
    else {

        $self->setup_udp_client;

        $self->{$BUF_CLIENT}->send($msg);

        EventLog( EVENT_DEBUG, MYNAMELINE . " MESSAGE SEND: $msg" );
    }
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_switchportstate_update {
    my ( $self, $id ) = @_;

    if ( ( defined $id ) && ( !isdigit($id) ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " ID: $id" );

    $self->udp_client_send( $MSG_SWITCHPORTSTATE
          . ( ( defined $id ) ? ":$id" : '' )
    );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_lastseen_location_update {
    my ( $self, $id ) = @_;

    if ( ( defined $id ) && ( !isdigit($id) ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " ID: $id" );

    $self->udp_client_send( $MSG_LASTSEEN_LOCATION
          . ( ( defined $id ) ? ":$id" : '' )
    );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_lastseen_mac_update {
    my ( $self, $id ) = @_;

    if ( ( defined $id ) && ( !isdigit($id) ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " ID: $id" );

    $self->udp_client_send( $MSG_LASTSEEN_MAC
          . ( ( defined $id ) ? ":$id" : '' )
    );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_lastseen_switch_update {
    my ( $self, $id ) = @_;

    if ( ( defined $id ) && ( !isdigit($id) ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " ID: $id" );

    $self->udp_client_send( $MSG_LASTSEEN_SWITCH
          . ( ( defined $id ) ? ":$id" : '' )
    );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_lastseen_switchport_update {
    my ( $self, $id ) = @_;

    if ( ( defined $id ) && ( !isdigit($id) ) ) { confess; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " ID: $id" );

    $self->udp_client_send( $MSG_LASTSEEN_SWITCHPORT
          . ( ( defined $id ) ? ":$id" : '' )
    );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_eventlog_update {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_EVENTLOG);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_radius_update {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_RADIUS);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_add_mac_update {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_ADD_MAC);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_add_switch_update {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_ADD_SWITCH);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_add_switchport_update {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_ADD_SWITCHPORT);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_slave_unknown {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_SLAVE_UNKNOWN);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_slave_ok {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_SLAVE_OK);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_slave_offline {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_SLAVE_OFFLINE);

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub send_slave_delay {
    my ($self) = @_;

    EventLog( EVENT_DEBUG, MYNAMELINE );

    $self->udp_client_send($MSG_SLAVE_DELAY);

}

#-------------------------------------------------------
# Get SLAVE Status
#-------------------------------------------------------
sub update_slave_status {
    my ($self) = @_;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SHOW SLAVE STATUS "
      ;

    if ( $self->sqlexecute($sql) ) {
        my $ref = $self->sth->fetchrow_hashref();
        if ( ( $ref->{'Slave_IO_Running'} =~ /Yes/i )
            && ( $ref->{'Slave_SQL_Running'} =~ /Yes/i ) ) {
            if ( $ref->{'Seconds_Behind_Master'} > 0 ) {
                $self->send_slave_delay;
            }
            else {
                $self->send_slave_ok;
            }
        }
        else {
            $self->send_slave_offline;
        }
    }
    else {
        $self->send_slave_unknown;
    }

    $ret;
}

#-------------------------------------------------------
# Get Mac
#-------------------------------------------------------
sub get_next_add_mac {
    my ( $self, $offset, $order_by_date ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_ADD_MAC_ID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_MAC_MAC}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_MAC_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_ADD_MAC
      . ' ORDER BY '
      . ( ($order_by_date) ?
          ( $column_names{$DB_COL_BUF_ADD_MAC_ID} . " ASC " )
        : ( $column_names{$DB_COL_BUF_ADD_MAC_LASTSEEN} . " DESC " )
      )
      . " LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_ADD_MAC_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_MAC_MAC}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_MAC_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Mac
#-------------------------------------------------------
sub get_next_radiusaudit {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_ADD_RA_ID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_MACID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_SWPID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_TYPE}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_CAUSE}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_OCTIN}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_OCTOUT}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_PACIN}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_PACOUT}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_RA_AUDITTIME}
      . ' FROM '
      . $DB_BUF_TABLE_ADD_RADIUSAUDIT
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_ADD_RA_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_ADD_RA_ID}        = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_MACID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_SWPID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_TYPE}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_CAUSE}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_OCTIN}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_OCTOUT}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_PACIN}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_PACOUT}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_RA_AUDITTIME} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switch
#-------------------------------------------------------
sub get_next_add_switch {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_ADD_SWITCH_ID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_SWITCH_IP}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_SWITCH_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_ADD_SWITCH
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_ADD_SWITCH_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_ADD_SWITCH_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_SWITCH_IP}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_SWITCH_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switch
#-------------------------------------------------------
sub get_next_add_switchport {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_ID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_SWITCHID}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME}
      . ', '
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_ADD_SWITCHPORT
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_ADD_SWITCHPORT_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_SWITCHPORT_SWITCHID} = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME} = $answer[ $col++ ];
            $h{$DB_COL_BUF_ADD_SWITCHPORT_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get switchportstate
#-------------------------------------------------------
sub get_next_switchportstate {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_SWPS_SWPID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_LASTUPDATE}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_MACID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_MAC}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_CLASSID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VGID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VLANID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_TEMPID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VMACID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VMAC}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VCLASSID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VVGID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VVLANID}
      . ', '
      . $column_names{$DB_COL_BUF_SWPS_VTEMPID}
      . ' FROM '
      . $DB_BUF_TABLE_SWITCHPORTSTATE
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_SWPS_SWPID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_SWPS_SWPID}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_LASTUPDATE} = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_MACID}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_MAC}        = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_CLASSID}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VGID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VLANID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_TEMPID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VMACID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VMAC}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VCLASSID}   = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VVGID}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VVLANID}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_SWPS_VTEMPID}    = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get mac
#-------------------------------------------------------
sub get_next_lastseen_location {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_LOCATION
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_LOCATION_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get mac
#-------------------------------------------------------
sub get_next_lastseen_mac {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_MAC
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_MAC_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_MAC_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get
#-------------------------------------------------------
sub get_lastseen_location {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $id ) || ( !isdigit($id) ) ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_LOCATION
      . ' WHERE '
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_ID}
      . " = $id "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_LOCATION_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_LOCATION_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Mac
#-------------------------------------------------------
sub get_lastseen_mac {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $id ) || ( !isdigit($id) ) ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_MAC
      . ' WHERE '
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_ID}
      . " = $id "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_MAC_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_MAC_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switch
#-------------------------------------------------------
sub get_next_lastseen_switch {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_SWITCH
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_SWITCH_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switch
#-------------------------------------------------------
sub get_lastseen_switch {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $id ) || ( !isdigit($id) ) ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_SWITCH
      . ' WHERE '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_ID}
      . " = $id "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_SWITCH_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_SWITCH_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switchport
#-------------------------------------------------------
sub get_next_lastseen_switchport {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_SWITCHPORT
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Switch
#-------------------------------------------------------
sub get_lastseen_switchport {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $id ) || ( !isdigit($id) ) ) {
        confess;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}
      . ', '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN}
      . ' FROM '
      . $DB_BUF_TABLE_LASTSEEN_SWITCHPORT
      . ' WHERE '
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}
      . " = $id "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}       = $answer[ $col++ ];
            $h{$DB_COL_BUF_LASTSEEN_SWITCHPORT_LASTSEEN} = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Get Eventlog
#-------------------------------------------------------
sub get_next_eventlog {
    my ( $self, $offset ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( ( !defined $offset ) || ( !isdigit($offset) ) ) {
        $offset = 0;
    }

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_EVENTLOG_ID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_TIME}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_TYPE}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_CLASSID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_LOCID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_MACID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_M2CID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_P2CID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_SWID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_SW2VID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_TEMPID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_TEMP2VGID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_VGID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_VG2VID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_VLANID}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_IP}
      . ', '
      . $column_names{$DB_COL_BUF_EVENTLOG_DESC}
      . ' FROM '
      . $DB_BUF_TABLE_EVENTLOG
      . ' ORDER BY '
      . $column_names{$DB_COL_BUF_EVENTLOG_ID}
      . " ASC LIMIT $offset, 1 "
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( my @answer = $self->sth->fetchrow_array() ) {
            my %h;
            my $col = 0;
            $h{$DB_COL_BUF_EVENTLOG_ID}        = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_TIME}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_TYPE}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_CLASSID}   = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_LOCID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_MACID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_M2CID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_P2CID}     = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_SWID}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_SW2VID}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_TEMPID}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_TEMP2VGID} = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_VGID}      = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_VG2VID}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_VLANID}    = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_IP}        = $answer[ $col++ ];
            $h{$DB_COL_BUF_EVENTLOG_DESC}      = $answer[ $col++ ];
            return \%h;
        }
    }

    $ret;
}

#-------------------------------------------------------
# Add Mac
#-------------------------------------------------------
sub add_mac {
    my ( $self, $mac ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_INFO, MYNAMELINE() . " called $mac" );

    if ( !verify_mac($mac) ) {
        EventLog( EVENT_ERR, MYNAMELINE() . " BAD MAC '$mac'" );
    }
    else {

        my $sql = "SELECT * FROM "
          . $DB_BUF_TABLE_ADD_MAC
          . ' WHERE '
          . $column_names{$DB_COL_BUF_ADD_MAC_MAC}
          . " = '$mac' "
          ;

        if ( $self->sqlexecute($sql) ) {
            if ( !( $self->sth->fetchrow_array() ) ) {

                $sql = "INSERT INTO "
                  . $DB_BUF_TABLE_ADD_MAC
                  . ' ( '
                  . $column_names{$DB_COL_BUF_ADD_MAC_MAC}
                  . " ) VALUES ( "
                  . " '$mac' "
                  . " ) "
                  ;

                if ( $self->sqldo($sql) ) {
                    $ret++;
                    EventLog( EVENT_INFO, MYNAMELINE() . " BUFFER ADD MAC: $mac" );
                }

            }
        }
        else {
            $ret++;
        }

        $self->send_add_mac_update;
    }

    $ret;
}

#-------------------------------------------------------
# Add Switch
#-------------------------------------------------------
sub add_switch {
    my ( $self, $ip ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_INFO, MYNAMELINE() . " called" );

    my $sql = 'SELECT * FROM '
      . $DB_BUF_TABLE_ADD_SWITCH
      . ' WHERE '
      . $column_names{$DB_COL_BUF_ADD_SWITCH_IP}
      . " = '$ip' ";

    if ( $self->sqlexecute($sql) ) {
        if ( !( my @answer = $self->sth->fetchrow_array() ) ) {

            $sql = 'INSERT INTO '
              . $DB_BUF_TABLE_ADD_SWITCH
              . ' ( '
              . $column_names{$DB_COL_BUF_ADD_SWITCH_IP}
              . ' ) VALUES ( '
              . "'$ip'"
              . ' ) ';

            if ( $self->sqldo($sql) ) {
                $ret++;
                EventLog( EVENT_INFO, MYNAMELINE() . " BUFFER ADD SWITCH IP: $ip" );
            }

        }
    }
    else {
        $ret++;
    }

    $self->send_add_switch_update;

    $ret;
}

#-------------------------------------------------------
# Add SwitchPort
#-------------------------------------------------------
sub add_switchport {
    my ( $self, $switchid, $portname ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_INFO, MYNAMELINE() . " called" );

    my $sql = "SELECT * FROM "
      . $DB_BUF_TABLE_ADD_SWITCHPORT
      . ' WHERE '
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_SWITCHID}
      . " = $switchid "
      . ' AND '
      . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME}
      . " = '$portname' ";

    if ( $self->sqlexecute($sql) ) {
        if ( !( my @answer = $self->sth->fetchrow_array() ) ) {

            $sql = 'INSERT INTO '
              . $DB_BUF_TABLE_ADD_SWITCHPORT
              . ' ( '
              . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_SWITCHID}
              . ', '
              . $column_names{$DB_COL_BUF_ADD_SWITCHPORT_PORTNAME}
              . ' ) VALUES ( '
              . " $switchid, '$portname' "
              . ' )';

            if ( $self->sqldo($sql) ) {
                $ret++;
                EventLog( EVENT_INFO, MYNAMELINE() . " BUFFER ADD SWITCHPORT: $portname, SWITCHID: " . '[' . $switchid . ']' );
            }

        }
    }
    else {
        $ret++;
    }

    $self->send_add_switchport_update;

    $ret;
}

#-------------------------------------------------------
# Function Can FAIL, it is not critical to the operation of Authentication, Just notate the error in the logs
#-------------------------------------------------------
sub add_radiusaudit {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_INFO, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess Dumper @_; }
    if ( ref($parm_ref) ne 'HASH' ) { confess Dumper @_; }
    if ( defined $parm_ref->{$DB_COL_BUF_ADD_RA_MACID}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_ADD_RA_MACID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_ADD_RA_SWPID}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_ADD_RA_SWPID} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_ADD_RA_OCTIN}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_ADD_RA_OCTIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_ADD_RA_OCTOUT} && ( !isdigit( $parm_ref->{$DB_COL_BUF_ADD_RA_OCTOUT} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_ADD_RA_PACIN}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_ADD_RA_PACIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_ADD_RA_PACOUT} && ( !isdigit( $parm_ref->{$DB_COL_BUF_ADD_RA_PACOUT} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_BUF_ADD_RA_TYPE} || ( $parm_ref->{$DB_COL_BUF_ADD_RA_TYPE} eq '' ) ) { confess Dumper $parm_ref; }

    my $macid        = $parm_ref->{$DB_COL_BUF_ADD_RA_MACID};
    my $switchportid = $parm_ref->{$DB_COL_BUF_ADD_RA_SWPID};
    my $type         = $parm_ref->{$DB_COL_BUF_ADD_RA_TYPE};
    my $cause        = ( $parm_ref->{$DB_COL_BUF_ADD_RA_CAUSE} ) ? $parm_ref->{$DB_COL_BUF_ADD_RA_CAUSE} : '';
    my $octetsin     = ( $parm_ref->{$DB_COL_BUF_ADD_RA_OCTIN} ) ? $parm_ref->{$DB_COL_BUF_ADD_RA_OCTIN} : 0;
    my $octetsout    = ( $parm_ref->{$DB_COL_BUF_ADD_RA_OCTOUT} ) ? $parm_ref->{$DB_COL_BUF_ADD_RA_OCTOUT} : 0;
    my $packetsin    = ( $parm_ref->{$DB_COL_BUF_ADD_RA_PACIN} ) ? $parm_ref->{$DB_COL_BUF_ADD_RA_PACIN} : 0;
    my $packetsout   = ( $parm_ref->{$DB_COL_BUF_ADD_RA_PACOUT} ) ? $parm_ref->{$DB_COL_BUF_ADD_RA_PACOUT} : 0;

    my $sql;

    $sql = "INSERT INTO $DB_BUF_TABLE_ADD_RADIUSAUDIT "

      . " ( macid, swpid, type, cause, octetsin, octetsout, packetsin, packetsout ) "
      . " VALUES ( $macid, $switchportid, '$type', '$cause', $octetsin, $octetsout, $packetsin, $packetsout )";

    if ( !( $self->sqldo($sql) ) ) {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    $self->send_radius_update;

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub add_eventlog {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess Dumper @_; }
    if ( ref($parm_ref) ne 'HASH' ) { confess Dumper @_; }
    if ( !defined $parm_ref->{$DB_COL_BUF_EVENTLOG_TYPE} ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_CLASSID}   && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_CLASSID} ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_LOCID}     && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_LOCID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_MACID}     && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_MACID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_M2CID}     && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_M2CID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_P2CID}     && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_P2CID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_SWID}      && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_SWID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_SWPID}     && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_SWPID} ) ) )     { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_SW2VID}    && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_SW2VID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_TEMPID}    && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_TEMPID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_TEMP2VGID} && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_TEMP2VGID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_VGID}      && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_VGID} ) ) )      { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_VG2VID}    && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_VG2VID} ) ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_EVENTLOG_VLANID}    && !( isdigit( $parm_ref->{$DB_COL_BUF_EVENTLOG_VLANID} ) ) )    { confess Dumper $parm_ref; }

    my $type      = $parm_ref->{$DB_COL_BUF_EVENTLOG_TYPE};
    my $classid   = $parm_ref->{$DB_COL_BUF_EVENTLOG_CLASSID};
    my $locid     = $parm_ref->{$DB_COL_BUF_EVENTLOG_LOCID};
    my $macid     = $parm_ref->{$DB_COL_BUF_EVENTLOG_MACID};
    my $m2cid     = $parm_ref->{$DB_COL_BUF_EVENTLOG_M2CID};
    my $p2cid     = $parm_ref->{$DB_COL_BUF_EVENTLOG_P2CID};
    my $swid      = $parm_ref->{$DB_COL_BUF_EVENTLOG_SWID};
    my $swpid     = $parm_ref->{$DB_COL_BUF_EVENTLOG_SWPID};
    my $sw2vid    = $parm_ref->{$DB_COL_BUF_EVENTLOG_SW2VID};
    my $tempid    = $parm_ref->{$DB_COL_BUF_EVENTLOG_TEMPID};
    my $temp2vgid = $parm_ref->{$DB_COL_BUF_EVENTLOG_TEMP2VGID};
    my $vlanid    = $parm_ref->{$DB_COL_BUF_EVENTLOG_VLANID};
    my $vgid      = $parm_ref->{$DB_COL_BUF_EVENTLOG_VGID};
    my $vg2vid    = $parm_ref->{$DB_COL_BUF_EVENTLOG_VG2VID};
    my $ip        = $parm_ref->{$DB_COL_BUF_EVENTLOG_IP};
    my $desc      = $parm_ref->{$DB_COL_BUF_EVENTLOG_DESC};

    $desc = '' if !defined $desc;
    $desc =~ s/\'/\\'/g;
    $desc =~ s/\"/\\"/g;

    my $sql;

    $sql = "INSERT INTO $DB_BUF_TABLE_EVENTLOG "
      . ' ( ' . $column_names{$DB_COL_BUF_EVENTLOG_TYPE}
      . ( ( defined $classid )   ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_CLASSID} )   : '' )
      . ( ( defined $locid )     ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_LOCID} )     : '' )
      . ( ( defined $macid )     ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_MACID} )     : '' )
      . ( ( defined $m2cid )     ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_M2CID} )     : '' )
      . ( ( defined $p2cid )     ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_P2CID} )     : '' )
      . ( ( defined $swid )      ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_SWID} )      : '' )
      . ( ( defined $swpid )     ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_SWPID} )     : '' )
      . ( ( defined $sw2vid )    ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_SW2VID} )    : '' )
      . ( ( defined $tempid )    ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_TEMPID} )    : '' )
      . ( ( defined $temp2vgid ) ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_TEMP2VGID} ) : '' )
      . ( ( defined $vgid )      ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_VGID} )      : '' )
      . ( ( defined $vg2vid )    ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_VG2VID} )    : '' )
      . ( ( defined $vlanid )    ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_VLANID} )    : '' )
      . ( ( defined $ip )        ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_IP} )        : '' )
      . ( ( defined $desc )      ? ( ', ' . $column_names{$DB_COL_BUF_EVENTLOG_DESC} )      : '' )
      . " ) VALUES ( "
      . "'$type'"
      . ( ( defined $classid )   ? ", $classid "   : '' )
      . ( ( defined $locid )     ? ", $locid "     : '' )
      . ( ( defined $macid )     ? ", $macid "     : '' )
      . ( ( defined $m2cid )     ? ", $m2cid "     : '' )
      . ( ( defined $p2cid )     ? ", $p2cid "     : '' )
      . ( ( defined $swid )      ? ", $swid "      : '' )
      . ( ( defined $swpid )     ? ", $swpid "     : '' )
      . ( ( defined $sw2vid )    ? ", $sw2vid "    : '' )
      . ( ( defined $tempid )    ? ", $tempid "    : '' )
      . ( ( defined $temp2vgid ) ? ", $temp2vgid " : '' )
      . ( ( defined $vgid )      ? ", $vgid "      : '' )
      . ( ( defined $vg2vid )    ? ", $vg2vid "    : '' )
      . ( ( defined $vlanid )    ? ", $vlanid "    : '' )
      . ( ( defined $ip )        ? ", '$ip' "      : '' )
      . ( ( defined $desc )      ? ", '$desc' "    : '' )
      . " )";

    EventLog( EVENT_INFO, MYNAMELINE() . $sql );

    if ( !( $self->sqldo($sql) ) ) {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }
    else {
        $ret++;
        $self->send_eventlog_update;
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub delete_eventlog_id {
    my ( $self, $id ) = @_;
    my $ret = 0;

    EventLog( EVENT_INFO, MYNAMELINE() . " called" );

    if ( !defined $id )  { confess Dumper @_; }
    if ( !isdigit($id) ) { confess Dumper @_; }

    my $sql = 'DELETE FROM '
      . $DB_BUF_TABLE_EVENTLOG
      . ' WHERE '
      . $column_names{$DB_COL_BUF_EVENTLOG_ID}
      . ' = '
      . $id
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub _delete_addtable_id {
    my ( $self, $table, $col, $id ) = @_;
    my $ret = 0;

    EventLog( EVENT_INFO, MYNAMELINE() . " called" );

    if ( !defined $table || !defined $col || !defined $id ) { confess Dumper @_; }

    # if ( !defined $tablenames{$table} || ( !( $table =~ /_add_/i ) ) ) { confess "Table:$table " . Dumper @_; }
    # if ( !defined $column_names{$col} || ( !( $col =~ /_ADD_/i && $col =~ /_ID/ ) ) ) { confess Dumper @_; }
    if ( !isdigit($id) ) { confess Dumper @_; }

    my $sql = 'DELETE FROM '
      . $table
      . ' WHERE '
      . $col
      . ' = '
      . $id
      ;

    if ( $self->sqldo($sql) ) {
        $ret++;
    }

    $ret;
}

#-------------------------------------------------------
# Delete Add_Mac
#-------------------------------------------------------
sub delete_mac_id {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    $self->_delete_addtable_id( $DB_BUF_TABLE_ADD_MAC, $column_names{$DB_COL_BUF_ADD_MAC_ID}, $id );
}

#-------------------------------------------------------
# Delete Add_Radiusaudit
#-------------------------------------------------------
sub delete_radiusaudit_id {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    $self->_delete_addtable_id( $DB_BUF_TABLE_ADD_RADIUSAUDIT, $column_names{$DB_COL_BUF_ADD_RA_ID}, $id );
}

#-------------------------------------------------------
# Delete Add_Switch
#-------------------------------------------------------
sub delete_switch_id {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    $self->_delete_addtable_id( $DB_BUF_TABLE_ADD_SWITCH, $column_names{$DB_COL_BUF_ADD_SWITCH_ID}, $id );
}

#-------------------------------------------------------
# Delete Add_Switchport
#-------------------------------------------------------
sub delete_switchport_id {
    my ( $self, $id ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    $self->_delete_addtable_id( $DB_BUF_TABLE_ADD_SWITCHPORT, $column_names{$DB_COL_BUF_ADD_SWITCHPORT_ID}, $id );
}

#-------------------------------------------------------
# Update Mac lastseen
# Add MAC if it does not exist yet
#-------------------------------------------------------
sub update_lastseen_mac {
    my ( $self, $mac ) = @_;
    my $ret   = 0;
    my $macid = 0;

    $self->reseterr;

    if ( ( !defined $mac ) || ( $macid eq "" ) ) { confess Dumper @_; }

    EventLog( EVENT_INFO, MYNAMELINE() . " called $mac" );

    my %parm = ();
    $parm{$DB_COL_MAC_MAC} = $mac;
    if ( !$self->DBRO->get_mac( \%parm ) ) {
        $ret = $self->add_mac($mac);
    }
    else {
        $macid = $parm{$DB_COL_MAC_ID};

        if ($macid) {
            $ret = $self->update_lastseen_macid($macid);
        }
    }

    $ret;
}

#-------------------------------------------------------
# Update Macid lastseen
#-------------------------------------------------------
sub update_lastseen_macid {
    my ( $self, $macid ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $macid ) || ( !isdigit($macid) ) ) { confess Dumper @_; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called $macid" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_ID}
      . " FROM "
      . $DB_BUF_TABLE_LASTSEEN_MAC
      . " WHERE "
      . $column_names{$DB_COL_BUF_LASTSEEN_MAC_ID}
      . " = $macid ";

    if ( $self->sqlexecute($sql) ) {
        if ( !( my @answer = $self->sth->fetchrow_array() ) ) {
            $sql = "INSERT INTO $DB_BUF_TABLE_LASTSEEN_MAC ( macid ) VALUES ( $macid ) ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }

        }
        else {
            $sql = "UPDATE $DB_BUF_TABLE_LASTSEEN_MAC SET lastseen = NOW() WHERE macid = $macid ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }
        }
    }

    $self->send_lastseen_mac_update($macid);

    $ret;
}

#-------------------------------------------------------
# Update Switch lastseen
#-------------------------------------------------------
sub update_lastseen_switchid {
    my ( $self, $swid ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $swid ) || ( !isdigit($swid) ) ) { confess Dumper @_; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_ID}
      . " FROM "
      . $DB_BUF_TABLE_LASTSEEN_SWITCH
      . " WHERE "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCH_ID}
      . " = $swid ";

    if ( $self->sqlexecute($sql) ) {
        if ( !( my @answer = $self->sth->fetchrow_array() ) ) {
            $sql = "INSERT INTO $DB_BUF_TABLE_LASTSEEN_SWITCH ( switchid ) VALUES ( $swid ) ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }

        }
        else {
            $sql = "UPDATE $DB_BUF_TABLE_LASTSEEN_SWITCH SET lastseen = NOW() WHERE switchid = $swid ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }
        }
    }

    $self->send_lastseen_switch_update($swid);

    $ret;
}

#-------------------------------------------------------
# Update Switchport lastseen
#-------------------------------------------------------
sub update_lastseen_switchportid {
    my ( $self, $swpid ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $swpid ) || ( !isdigit($swpid) ) ) { confess Dumper @_; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}
      . " FROM "
      . $DB_BUF_TABLE_LASTSEEN_SWITCHPORT
      . " WHERE "
      . $column_names{$DB_COL_BUF_LASTSEEN_SWITCHPORT_ID}
      . " = $swpid ";

    if ( $self->sqlexecute($sql) ) {
        if ( !( my @answer = $self->sth->fetchrow_array() ) ) {
            $sql = "INSERT INTO $DB_BUF_TABLE_LASTSEEN_SWITCHPORT ( switchportid ) VALUES ( $swpid ) ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }

        }
        else {
            $sql = "UPDATE $DB_BUF_TABLE_LASTSEEN_SWITCHPORT SET lastseen = NOW() WHERE switchportid = $swpid ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }
        }
    }

    $self->send_lastseen_switchport_update($swpid);

    $ret;
}

#-------------------------------------------------------
# Update location lastseen
#-------------------------------------------------------
sub update_lastseen_locationid {
    my ( $self, $locid ) = @_;
    my $ret = 0;

    if ( ( !defined $locid ) || ( !isdigit($locid) ) ) { confess Dumper @_; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_ID}
      . " FROM "
      . $DB_BUF_TABLE_LASTSEEN_LOCATION
      . " WHERE "
      . $column_names{$DB_COL_BUF_LASTSEEN_LOCATION_ID}
      . " = $locid ";

    if ( $self->sqlexecute($sql) ) {
        if ( !( my @answer = $self->sth->fetchrow_array() ) ) {
            $sql = "INSERT INTO $DB_BUF_TABLE_LASTSEEN_LOCATION ( locid ) VALUES ( $locid ) ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }

        }
        else {
            $sql = "UPDATE $DB_BUF_TABLE_LASTSEEN_LOCATION SET lastseen = NOW() WHERE locid = $locid ";

            if ( $self->sqldo($sql) ) {
                $ret++;
            }
        }
    }

    $self->send_lastseen_location_update($locid);

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub switchportstate_exists {
    my ( $self, $swpid ) = @_;
    my $ret = 0;

    $self->reseterr;

    if ( ( !defined $swpid ) || ( !isdigit($swpid) ) ) { confess Dumper @_; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    my $sql = "SELECT "
      . $column_names{$DB_COL_BUF_SWPS_SWPID}
      . " FROM "
      . $DB_BUF_TABLE_SWITCHPORTSTATE
      . " WHERE "
      . $column_names{$DB_COL_BUF_SWPS_SWPID}
      . " = $swpid ";

    if ( $self->sqlexecute($sql) ) {
        if ( $self->sth->fetchrow_array() ) {
            $ret++;
        }
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;
    my $id;
    my $macid;
    my $mac;
    my $macid_gtz;
    my $classid;
    my $vgid;
    my $vlanid;
    my $tempid;
    my $ip;
    my $vmacid;
    my $vmac;
    my $vmacid_gtz;
    my $vclassid;
    my $vvgid;
    my $vvlanid;
    my $vtempid;
    my $vip;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }

    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( defined $parm_ref->{$HASH_REF} && ( ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} && !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID} && !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_MACID} ) ) ) { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};

    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) { $id = $parm_ref->{$DB_COL_BUF_SWPS_SWPID} }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID}  && $parm_ref->{$DB_COL_BUF_SWPS_MACID} > -1 )  { $macid  = $parm_ref->{$DB_COL_BUF_SWPS_MACID} }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID} && $parm_ref->{$DB_COL_BUF_SWPS_VMACID} > -1 ) { $vmacid = $parm_ref->{$DB_COL_BUF_SWPS_VMACID} }

    # my $where = 0;

    $self->reseterr;

    my $sql = "SELECT switchportid,lastupdate,"
      . "macid,mac,ip,classid,templateid,vlangroupid,vlanid, "
      . "vmacid,vmac,vip,vclassid,vtemplateid,vvlangroupid,vvlanid "
      . " FROM switchportstate "
      . ' WHERE '
      . ( ( defined $id ) ? " switchportid = $id " : '' )
      . ( ( defined $id && defined $macid ) ? " AND " : '' )
      . ( ( defined $macid ) ? " macid = $macid " : '' )
      . ( ( ( defined $id || defined $macid ) && defined $vmacid ) ? " AND " : '' )
      . ( ( defined $vmacid ) ? " vmacid = $vmacid " : '' )
      ;

    EventLog( EVENT_DEBUG, MYNAMELINE() . "SQL:$sql" );

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @row = $self->sth->fetchrow_array() ) {
                my %s;
                my $col = 0;
                $hash_ref->{ $row[0] }          = \%s;
                $s{$DB_COL_BUF_SWPS_SWPID}      = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_LASTUPDATE} = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_MACID}      = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_MAC}        = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_IP}         = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_CLASSID}    = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_TEMPID}     = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VGID}       = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VLANID}     = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VMACID}     = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VMAC}       = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VIP}        = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VCLASSID}   = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VTEMPID}    = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VVGID}      = $row[ $col++ ];
                $s{$DB_COL_BUF_SWPS_VVLANID}    = $row[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @row = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_BUF_SWPS_SWPID}      = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_LASTUPDATE} = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_MACID}      = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_MAC}        = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_IP}         = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_CLASSID}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_TEMPID}     = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VGID}       = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VLANID}     = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VMACID}     = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VMAC}       = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VIP}        = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VCLASSID}   = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VTEMPID}    = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VVGID}      = $row[ $col++ ];
                $parm_ref->{$DB_COL_BUF_SWPS_VVLANID}    = $row[ $col++ ];
                $ret++;
            }
        }
    }

    # EventLog( EVENT_DEBUG, MYNAMELINE() . "Total: $ret" );
    $ret;
}

#-------------------------------------------------------
#
# NOTE
# Need to update the DB table to allow NULLs and only update
# if the field is not NULL.
#
#-------------------------------------------------------
sub add_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess Dumper @_; }
    if ( ref($parm_ref) ne 'HASH' ) { confess Dumper @_; }
    if ( !defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} || ( !( isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) ) ) { confess Dumper $parm_ref; }

    my $swpid = $parm_ref->{$DB_COL_BUF_SWPS_SWPID};

    if ( $self->switchportstate_exists($swpid) ) {
        EventLog( EVENT_ERR, MYNAMELINE() . " switchport exists " );
        return;
    }

    #
    # Get a local copy of SWPS if it exists
    #
    my %ro_parm = ();

    # HERE
    # $ro_parm{$DB_COL_SWPS_SWPID} = $swpid;
    # $self->DBRO->get_switchportstate(\$ro_parm);

    my $macid        = $parm_ref->{$DB_COL_BUF_SWPS_MACID};
    my $mac          = $parm_ref->{$DB_COL_BUF_SWPS_MAC};
    my $ip           = $parm_ref->{$DB_COL_BUF_SWPS_IP};
    my $classid      = $parm_ref->{$DB_COL_BUF_SWPS_CLASSID};
    my $vlangroupid  = $parm_ref->{$DB_COL_BUF_SWPS_VGID};
    my $vlanid       = $parm_ref->{$DB_COL_BUF_SWPS_VLANID};
    my $tempid       = $parm_ref->{$DB_COL_BUF_SWPS_TEMPID};
    my $vmacid       = $parm_ref->{$DB_COL_BUF_SWPS_VMACID};
    my $vmac         = $parm_ref->{$DB_COL_BUF_SWPS_VMAC};
    my $vip          = $parm_ref->{$DB_COL_BUF_SWPS_VIP};
    my $vclassid     = $parm_ref->{$DB_COL_BUF_SWPS_VCLASSID};
    my $vvlangroupid = $parm_ref->{$DB_COL_BUF_SWPS_VVGID};
    my $vvlanid      = $parm_ref->{$DB_COL_BUF_SWPS_VVLANID};
    my $vtempid      = $parm_ref->{$DB_COL_BUF_SWPS_VTEMPID};
    my $sql;

    if ( !defined $macid ) {
        $macid = ( defined $ro_parm{$DB_COL_SWPS_MACID} ) ? $ro_parm{$DB_COL_SWPS_MACID} : -1;
    }

    if ( !defined $mac ) {
        $mac = '';
    }

    if ( !defined $vmacid ) {
        $vmacid = ( defined $ro_parm{$DB_COL_SWPS_VMACID} ) ? $ro_parm{$DB_COL_SWPS_VMACID} : -1;
    }

    if ( !defined $vmac ) {
        $vmac = '';
    }

    if ( !defined $classid ) {
        $classid = ( defined $ro_parm{$DB_COL_SWPS_CLASSID} ) ? $ro_parm{$DB_COL_SWPS_CLASSID} : 0;
    }

    if ( !defined $vclassid ) {
        $vclassid = ( defined $ro_parm{$DB_COL_SWPS_VCLASSID} ) ? $ro_parm{$DB_COL_SWPS_VCLASSID} : 0;
    }

    if ( !defined $vlanid ) {
        $vlanid = ( defined $ro_parm{$DB_COL_SWPS_VLANID} ) ? $ro_parm{$DB_COL_SWPS_VLANID} : 0;
    }

    if ( !defined $vvlanid ) {
        $vvlanid = ( defined $ro_parm{$DB_COL_SWPS_VVLANID} ) ? $ro_parm{$DB_COL_SWPS_VVLANID} : 0;
    }

    if ( !defined $vlangroupid ) {
        $vlangroupid = ( defined $ro_parm{$DB_COL_SWPS_VGID} ) ? $ro_parm{$DB_COL_SWPS_VGID} : 0;
    }

    if ( !defined $vvlangroupid ) {
        $vvlangroupid = ( defined $ro_parm{$DB_COL_SWPS_VVGID} ) ? $ro_parm{$DB_COL_SWPS_VVGID} : 0;
    }

    if ( !defined $tempid ) {
        $tempid = ( defined $ro_parm{$DB_COL_SWPS_TEMPID} ) ? $ro_parm{$DB_COL_SWPS_TEMPID} : 0;
    }

    if ( !defined $vtempid ) {
        $vtempid = ( defined $ro_parm{$DB_COL_SWPS_VTEMPID} ) ? $ro_parm{$DB_COL_SWPS_VTEMPID} : 0;
    }

    $sql = "INSERT INTO $DB_TABLE_SWITCHPORTSTATE ( "
      . ' switchportid, macid, mac, classid, templateid, vlangroupid, vlanid'
      . ( ( defined $ip ) ? ', ip' : '' )
      . ', vmacid, vmac, vclassid, vtemplateid, vvlangroupid, vvlanid'
      . ( ( defined $vip ) ? ', vip' : '' )
      . " ) "
      . " VALUES ( "
      . " $swpid, $macid, '$mac', $classid, $tempid, $vlangroupid, $vlanid "
      . ( ( defined $ip ) ? ", '$ip'" : '' )
      . ", $vmacid, '$vmac', $vclassid, $vtempid, $vvlangroupid, $vvlanid "
      . ( ( defined $vip ) ? ", '$vip'" : '' )
      . ' )';

    EventLog( EVENT_INFO, MYNAMELINE() . $sql );

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

    $self->send_switchportstate_update($swpid);

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub update_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my $ret = 0;

    $self->reseterr;

    EventLog( EVENT_INFO, MYNAMELINE() . " called " );

    if ( !defined $parm_ref ) { confess; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID}    && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) )          { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID}    && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_MACID} ) ) ) )   { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_CLASSID}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_CLASSID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VGID}     && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_VGID} ) ) )           { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VLANID}   && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_VLANID} ) ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_TEMPID}   && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_TEMPID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID}   && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_VMACID} ) ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VCLASSID} && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_VCLASSID} ) ) )       { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VVGID}    && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_VVGID} ) ) )          { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VVLANID}  && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_VVLANID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VTEMPID}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_VTEMPID} ) ) )        { confess Dumper $parm_ref; }

    my $swpid    = $parm_ref->{$DB_COL_BUF_SWPS_SWPID};
    my $macid    = $parm_ref->{$DB_COL_BUF_SWPS_MACID};
    my $mac      = $parm_ref->{$DB_COL_BUF_SWPS_MAC};
    my $ip       = $parm_ref->{$DB_COL_BUF_SWPS_IP};
    my $classid  = $parm_ref->{$DB_COL_BUF_SWPS_CLASSID};
    my $vgid     = $parm_ref->{$DB_COL_BUF_SWPS_VGID};
    my $vlanid   = $parm_ref->{$DB_COL_BUF_SWPS_VLANID};
    my $tempid   = $parm_ref->{$DB_COL_BUF_SWPS_TEMPID};
    my $vmacid   = $parm_ref->{$DB_COL_BUF_SWPS_VMACID};
    my $vmac     = $parm_ref->{$DB_COL_BUF_SWPS_VMAC};
    my $vip      = $parm_ref->{$DB_COL_BUF_SWPS_VIP};
    my $vclassid = $parm_ref->{$DB_COL_BUF_SWPS_VCLASSID};
    my $vvgid    = $parm_ref->{$DB_COL_BUF_SWPS_VVGID};
    my $vvlanid  = $parm_ref->{$DB_COL_BUF_SWPS_VVLANID};
    my $vtempid  = $parm_ref->{$DB_COL_BUF_SWPS_VTEMPID};

    # if ( !( defined $swpid || defined $macid || defined $vmacid ) ) { confess; }

    my %get = ();
    if    ( defined $swpid )  { $get{$DB_COL_BUF_SWPS_SWPID}  = $swpid; }
    elsif ( defined $macid )  { $get{$DB_COL_BUF_SWPS_MACID}  = $macid; }
    elsif ( defined $vmacid ) { $get{$DB_COL_BUF_SWPS_VMACID} = $vmacid; }
    else                      { confess Dumper @_; }

    if ( !$self->get_switchportstate( \%get ) ) {
        EventLog( EVENT_INFO, MYNAMELINE() . " ADD SWPS SWPID:$swpid MACID:$macid" );
        $ret = $self->add_switchportstate($parm_ref);
    }
    else {
        EventLog( EVENT_INFO, MYNAMELINE() . " UPDATE SWPS SWPID:$swpid MACID:$macid" );
        my $comma = 0;
        my $sql   = "UPDATE $DB_TABLE_SWITCHPORTSTATE SET ";

        $sql .= " lastupdate = NOW()";
        $comma++;

        if ( ( defined $macid ) && ( $macid != $get{$DB_COL_BUF_SWPS_MACID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " macid = $macid";
            $comma++;
        }

        if ( ( defined $mac ) && ( $mac ne $get{$DB_COL_BUF_SWPS_MAC} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " mac = '$mac'";
            $comma++;
        }

        if ( ( defined $ip ) && ( $ip != $get{$DB_COL_BUF_SWPS_IP} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " ip = $ip";
            $comma++;
        }

        if ( ( defined $classid ) && ( $classid != $get{$DB_COL_BUF_SWPS_CLASSID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " classid = $classid";
            $comma++;
        }

        if ( ( defined $vgid ) && ( $vgid != $get{$DB_COL_BUF_SWPS_VGID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vlangroupid = $vgid";
            $comma++;
        }

        if ( ( defined $vlanid ) && ( $vlanid != $get{$DB_COL_BUF_SWPS_VLANID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vlanid = $vlanid";
            $comma++;
        }

        if ( ( defined $vmac ) && ( $vmac ne $get{$DB_COL_BUF_SWPS_VMAC} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vmac = '$vmac'";
            $comma++;
        }

        if ( ( defined $tempid ) && ( $tempid != $get{$DB_COL_BUF_SWPS_TEMPID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " templateid = $tempid";
            $comma++;
        }

        if ( ( defined $vmacid ) && ( $vmacid != $get{$DB_COL_BUF_SWPS_VMACID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vmacid = $vmacid";
            $comma++;
        }

        if ( ( defined $vip ) && ( $vip != $get{$DB_COL_BUF_SWPS_VIP} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vip = $vip";
            $comma++;
        }

        if ( ( defined $vclassid ) && ( $vclassid != $get{$DB_COL_BUF_SWPS_VCLASSID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vclassid = $vclassid";
            $comma++;
        }

        if ( ( defined $vvgid ) && ( $vvgid != $get{$DB_COL_BUF_SWPS_VVGID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vvlangroupid = $vvgid";
            $comma++;
        }

        if ( ( defined $vvlanid ) && ( $vvlanid != $get{$DB_COL_BUF_SWPS_VVLANID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vvlanid = $vvlanid";
            $comma++;
        }

        if ( ( defined $vtempid ) && ( $vtempid != $get{$DB_COL_BUF_SWPS_VTEMPID} ) ) {
            $sql .= ( ( $comma++ ) ? ', ' : '' );
            $sql .= " vtemplateid = $vtempid";

            # $comma++;
        }

        $sql .= " WHERE switchportid = $swpid ";

        if ($comma) {
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
        }
        else {
            EventLog( EVENT_ERR, MYNAMELINE() . " sqldo() NO UPDATE NEEDED:" . $sql );
        }

    }

    EventLog( EVENT_INFO, MYNAMELINE() . " FINISHED " );

    $self->send_switchportstate_update($swpid);

    $ret;

}

#-------------------------------------------------------
#
# Find Switch port and DMAC records
# Same ID, update - Else shutdown MAC port, log, and move to new port
#
#-------------------------------------------------------
sub set_data_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my %parm = ();
    my $ret  = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} || ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_BUF_SWPS_MACID} || ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_MACID} ) ) ) { confess Dumper $parm_ref; }

    my $swpid = $parm_ref->{$DB_COL_BUF_SWPS_SWPID};
    my $macid = $parm_ref->{$DB_COL_BUF_SWPS_MACID};

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called SWPID:$swpid, MACID:$macid " );

    if ( !$self->switchportstate_exists($swpid) ) {
        $ret = $self->add_switchportstate($parm_ref);
    }
    else {
        $ret = $self->update_switchportstate($parm_ref);
    }

    $ret;

}

#-------------------------------------------------------
#
# Find Switch port and VMAC records
# Same ID, update - Else shutdown MAC port, log, and move to new port
#
#-------------------------------------------------------
sub set_voice_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my %parm = ();
    my $ret  = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref ) { confess Dumper @_; }
    if ( !defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID}  || ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) )  { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID} || ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_VMACID} ) ) ) { confess Dumper $parm_ref; }

    my $swpid  = $parm_ref->{$DB_COL_BUF_SWPS_SWPID};
    my $vmacid = $parm_ref->{$DB_COL_BUF_SWPS_VMACID};

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called SWPID:$swpid, MACID:$vmacid " );

    if ( $self->switchportstate_exists($swpid) ) {
        $ret = $self->update_switchportstate($parm_ref);
    }
    else {
        $ret = $self->add_switchportstate($parm_ref);
    }

    $ret;

}

#-------------------------------------------------------
#
# Clear MACID for DATA
#-------------------------------------------------------
sub clear_data_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my $ret      = 0;
    my $data_mac = 0;

    $self->reseterr;

    NACSyslog::ActivateDebug();

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess @_; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) )        { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID} && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_MACID} ) ) ) ) { confess Dumper $parm_ref; }

    # Clear by SWPID or MACID
    my $swpid = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ? $parm_ref->{$DB_COL_BUF_SWPS_SWPID} : 0 );
    my $macid = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID} ) ? $parm_ref->{$DB_COL_BUF_SWPS_MACID} : 0 );

    if ( !( $swpid || $macid ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " CLEAR DATA SWITCHPORTSTATE  PORT:[$swpid]" );
    EventLog( EVENT_INFO,  MYNAMELINE . " CLEAR DATA SWITCHPORTSTATE  PORT:[$swpid]" );

    my %clear_swp = ();
    my %parm      = ();
    $parm{EVENT_PARM_TYPE}          = 'EVENT_AUTH_CLEAR';
    $parm{EVENT_PARM_MACID}         = ( $macid > 0 ) ? $macid : 0;
    $parm{EVENT_PARM_IP}            = 0;
    $parm{EVENT_PARM_SWPID}         = $swpid;
    $parm{EVENT_PARM_CLASSID}       = 0;
    $parm{EVENT_PARM_TEMPID}        = 0;
    $parm{EVENT_PARM_VGID}          = 0;
    $parm{EVENT_PARM_VLANID}        = 0;
    $parm{EVENT_PARM_DESC}          = '';
    $parm{$DB_COL_BUF_SWPS_MACID}   = -1;
    $parm{$DB_COL_BUF_SWPS_MAC}     = '';
    $parm{$DB_COL_BUF_SWPS_IP}      = 0;
    $parm{$DB_COL_BUF_SWPS_CLASSID} = 0;
    $parm{$DB_COL_BUF_SWPS_VGID}    = 0;
    $parm{$DB_COL_BUF_SWPS_VLANID}  = 0;
    $parm{$DB_COL_BUF_SWPS_TEMPID}  = 0;

    if ($swpid) {
        %clear_swp = ();
        $clear_swp{$DB_COL_BUF_SWPS_SWPID} = $swpid;
        if ( !$self->get_switchportstate( \%clear_swp ) ) {

            # Add SWPS if it does not exist
            $parm{$DB_COL_BUF_SWPS_VMACID}   = -1;
            $parm{$DB_COL_BUF_SWPS_VMAC}     = '';
            $parm{$DB_COL_BUF_SWPS_VIP}      = 0;
            $parm{$DB_COL_BUF_SWPS_VCLASSID} = 0;
            $parm{$DB_COL_BUF_SWPS_VVGID}    = 0;
            $parm{$DB_COL_BUF_SWPS_VVLANID}  = 0;
            $parm{$DB_COL_BUF_SWPS_VTEMPID}  = 0;
            $ret                             = $self->add_switchportstate( \%clear_swp );
            return $ret;
        }
        else {
            $data_mac                       = $clear_swp{$DB_COL_BUF_SWPS_MACID};
            $parm{$DB_COL_BUF_SWPS_MACID}   = -1;
            $parm{$DB_COL_BUF_SWPS_MAC}     = '';
            $parm{$DB_COL_BUF_SWPS_IP}      = 0;
            $parm{$DB_COL_BUF_SWPS_CLASSID} = 0;
            $parm{$DB_COL_BUF_SWPS_VGID}    = 0;
            $parm{$DB_COL_BUF_SWPS_VLANID}  = 0;
            $parm{$DB_COL_BUF_SWPS_TEMPID}  = 0;
            $parm{$DB_COL_BUF_SWPS_SWPID}   = $clear_swp{$DB_COL_BUF_SWPS_SWPID};
            $parm{$EVENT_PARM_MACID}        = $data_mac;
            $parm{$EVENT_PARM_SWPID}        = $clear_swp{$DB_COL_BUF_SWPS_SWPID};
            $ret                            = $self->update_switchportstate( \%parm );
        }
    }
    else {
        %clear_swp = ();
        $clear_swp{$DB_COL_BUF_SWPS_MACID} = $macid;
        if ( $self->get_switchportstate( \%clear_swp ) ) {
            $data_mac                       = $clear_swp{$DB_COL_BUF_SWPS_MACID};
            $parm{$DB_COL_BUF_SWPS_MACID}   = -1;
            $parm{$DB_COL_BUF_SWPS_MAC}     = '';
            $parm{$DB_COL_BUF_SWPS_IP}      = 0;
            $parm{$DB_COL_BUF_SWPS_CLASSID} = 0;
            $parm{$DB_COL_BUF_SWPS_VGID}    = 0;
            $parm{$DB_COL_BUF_SWPS_VLANID}  = 0;
            $parm{$DB_COL_BUF_SWPS_TEMPID}  = 0;
            $parm{$DB_COL_BUF_SWPS_SWPID}   = $clear_swp{$DB_COL_BUF_SWPS_SWPID};
            $parm{$EVENT_PARM_MACID}        = $data_mac;
            $parm{$EVENT_PARM_SWPID}        = $clear_swp{$DB_COL_BUF_SWPS_SWPID};
            $ret                            = $self->update_switchportstate( \%parm );
        }
    }

    $ret;

}

#-------------------------------------------------------
#
# Clear MACID for VOICE & DATA (if VOICE is cleared, assume data is gone too)
#-------------------------------------------------------
sub clear_voice_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my $ret       = 0;
    my $voice_mac = 0;
    my $data_mac  = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called " );

    if ( !defined $parm_ref ) { confess @_; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID} && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_VMACID} ) ) ) ) { confess Dumper $parm_ref; }

    # Clear by SWPID or VMACID
    my $swpid  = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} )  ? $parm_ref->{$DB_COL_BUF_SWPS_SWPID}  : 0 );
    my $vmacid = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID} ) ? $parm_ref->{$DB_COL_BUF_SWPS_VMACID} : 0 );

    if ( !( $swpid || $vmacid ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " CLEAR VOICE SWITCHPORTSTATE  PORT:[$swpid]" );

    EventLog( EVENT_INFO, MYNAMELINE . " CLEAR VOICE SWITCHPORTSTATE  PORT:[$swpid]" );

    my %clear_swp = ();
    my %parm      = ();
    $parm{EVENT_PARM_TYPE}           = 'EVENT_AUTH_CLEAR';
    $parm{EVENT_PARM_MACID}          = ( $vmacid > 0 ) ? $vmacid : 0;
    $parm{EVENT_PARM_IP}             = 0;
    $parm{EVENT_PARM_SWPID}          = $swpid;
    $parm{EVENT_PARM_CLASSID}        = 0;
    $parm{EVENT_PARM_TEMPID}         = 0;
    $parm{EVENT_PARM_VGID}           = 0;
    $parm{EVENT_PARM_VLANID}         = 0;
    $parm{EVENT_PARM_DESC}           = '';
    $parm{$DB_COL_BUF_SWPS_VMACID}   = -1;
    $parm{$DB_COL_BUF_SWPS_VIP}      = 0;
    $parm{$DB_COL_BUF_SWPS_VCLASSID} = 0;
    $parm{$DB_COL_BUF_SWPS_VVGID}    = 0;
    $parm{$DB_COL_BUF_SWPS_VVLANID}  = 0;
    $parm{$DB_COL_BUF_SWPS_VTEMPID}  = 0;

    if ($swpid) {
        %clear_swp = ();
        $clear_swp{$DB_COL_BUF_SWPS_SWPID} = $swpid;
        if ( !$self->get_switchportstate( \%clear_swp ) ) {

            # Add SWPS if it does not exist
            $parm{$DB_COL_BUF_SWPS_MACID}   = -1;
            $parm{$DB_COL_BUF_SWPS_IP}      = 0;
            $parm{$DB_COL_BUF_SWPS_CLASSID} = 0;
            $parm{$DB_COL_BUF_SWPS_VGID}    = 0;
            $parm{$DB_COL_BUF_SWPS_VLANID}  = 0;
            $parm{$DB_COL_BUF_SWPS_TEMPID}  = 0;
            $ret                            = $self->add_switchportstate( \%clear_swp );
            return $ret;
        }
        else {
            $self->clear_switchportstate( \%clear_swp );
        }
    }
    else {
        %clear_swp = ();
        $clear_swp{$DB_COL_BUF_SWPS_VMACID} = $vmacid;
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
sub clear_switchportstate {
    my ( $self, $parm_ref ) = @_;
    my $ret       = 0;
    my $voice_mac = 0;
    my $data_mac  = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess Dumper @_; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID}  && ( !isdigit( $parm_ref->{$DB_COL_BUF_SWPS_SWPID} ) ) )         { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID}  && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_MACID} ) ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID} && ( !isdigit( abs( $parm_ref->{$DB_COL_BUF_SWPS_VMACID} ) ) ) ) { confess Dumper $parm_ref; }

    # Clear by SWPID or VMACID
    my $swpid  = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_SWPID} )  ? $parm_ref->{$DB_COL_BUF_SWPS_SWPID}  : 0 );
    my $macid  = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_MACID} )  ? $parm_ref->{$DB_COL_BUF_SWPS_MACID}  : 0 );
    my $vmacid = ( ( defined $parm_ref->{$DB_COL_BUF_SWPS_VMACID} ) ? $parm_ref->{$DB_COL_BUF_SWPS_VMACID} : 0 );

    if ( !( $swpid || $macid || $vmacid ) ) { confess Dumper $parm_ref; }

    EventLog( EVENT_DEBUG, MYNAMELINE . " CLEAR VOICE SWITCHPORTSTATE  PORT:[$swpid]" );

    my %clear_swp = ();
    my %parm      = ();
    $parm{EVENT_PARM_TYPE}           = 'EVENT_AUTH_CLEAR';
    $parm{EVENT_PARM_SWPID}          = $swpid;
    $parm{EVENT_PARM_MACID}          = ( ($macid) ? $macid : ( ( $vmacid > 0 ) ? $vmacid : 0 ) );
    $parm{EVENT_PARM_IP}             = 0;
    $parm{EVENT_PARM_CLASSID}        = 0;
    $parm{EVENT_PARM_TEMPID}         = 0;
    $parm{EVENT_PARM_VGID}           = 0;
    $parm{EVENT_PARM_VLANID}         = 0;
    $parm{EVENT_PARM_DESC}           = '';
    $parm{$DB_COL_BUF_SWPS_VMACID}   = -1;
    $parm{$DB_COL_BUF_SWPS_VIP}      = 0;
    $parm{$DB_COL_BUF_SWPS_VCLASSID} = 0;
    $parm{$DB_COL_BUF_SWPS_VVGID}    = 0;
    $parm{$DB_COL_BUF_SWPS_VVLANID}  = 0;
    $parm{$DB_COL_BUF_SWPS_VTEMPID}  = 0;

    %clear_swp = ();
    if ($swpid) {
        $clear_swp{$DB_COL_BUF_SWPS_SWPID} = $swpid;
        $parm{$DB_COL_BUF_SWPS_SWPID}      = $swpid;
    }
    elsif ($macid) {
        $clear_swp{$DB_COL_BUF_SWPS_MACID} = $macid;
    }
    elsif ($vmacid) {
        $clear_swp{$DB_COL_BUF_SWPS_SWPID} = $vmacid;
    }

    $parm{$DB_COL_BUF_SWPS_MACID}    = -1;
    $parm{$DB_COL_BUF_SWPS_IP}       = 0;
    $parm{$DB_COL_BUF_SWPS_CLASSID}  = 0;
    $parm{$DB_COL_BUF_SWPS_VGID}     = 0;
    $parm{$DB_COL_BUF_SWPS_VLANID}   = 0;
    $parm{$DB_COL_BUF_SWPS_TEMPID}   = 0;
    $parm{$DB_COL_BUF_SWPS_VMACID}   = -1;
    $parm{$DB_COL_BUF_SWPS_VIP}      = 0;
    $parm{$DB_COL_BUF_SWPS_VCLASSID} = 0;
    $parm{$DB_COL_BUF_SWPS_VVGID}    = 0;
    $parm{$DB_COL_BUF_SWPS_VVLANID}  = 0;
    $parm{$DB_COL_BUF_SWPS_VTEMPID}  = 0;

    if ( !$self->get_switchportstate( \%clear_swp ) ) {

        # Add SWPS if it does not exist
        if ($swpid) {
            $ret = $self->add_switchportstate( \%parm );
        }
    }
    else {
        $parm{$DB_COL_BUF_SWPS_SWPID} = $clear_swp{$DB_COL_BUF_SWPS_SWPID};
        $ret = $self->update_switchportstate( \%parm );
    }

    # EventLog( EVENT_INFO, MYNAMELINE . " FINISHED PORT:[$swpid]" );

    $ret;

}

#-----------------------------------------------------------
sub EventDBLog {
    my ( $self, $parm_ref ) = @_;
    my %eventlog = ();
    my $text_message;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess @_; }
    if ( ref($parm_ref) ne 'HASH' ) { confess @_; }

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

    $eventlog{$DB_COL_BUF_EVENTLOG_TYPE} = $eventtype;

    my $syslog_text = '';
    my $db_text;

    if ( defined $logline ) {
        $syslog_text = ( ( caller(1) )[3] ) . ":" . ( ( caller(1) )[2] ) . ':';
        $desc = "File: " . ( ( caller(1) )[3] ) . "\nLine:" . ( ( caller(1) )[2] ) . ':' . $desc;
    }

    if ( defined $classid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_CLASSID} = $classid;
        $syslog_text .= "CLASSID:$classid ";
    }
    if ( defined $locid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_LOCID} = $locid;
        $syslog_text .= "LOCID:$locid ";
    }
    if ( defined $macid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_MACID} = $macid;
        $syslog_text .= "MACID:$macid ";
    }
    if ( defined $m2cid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_M2CID} = $m2cid;
        $syslog_text .= "M2CID:$m2cid ";
    }
    if ( defined $p2cid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_P2CID} = $p2cid;
        $syslog_text .= "P2CID:$p2cid ";
    }
    if ( defined $swid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_SWID} = $swid;
        $syslog_text .= "SWID:$swid ";
    }
    if ( defined $swpid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_SWPID} = $swpid;
        $syslog_text .= "SWPID:$swpid ";
    }
    if ( defined $sw2vid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_SW2VID} = $sw2vid;
        $syslog_text .= "SW2VID:$sw2vid ";
    }
    if ( defined $tempid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_TEMPID} = $tempid;
        $syslog_text .= "TEMPID:$tempid ";
    }
    if ( defined $temp2vgid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_TEMP2VGID} = $temp2vgid;
        $syslog_text .= "T2VGID:$temp2vgid ";
    }
    if ( defined $vgid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_VGID} = $vgid;
        $syslog_text .= "VGID:$vgid ";
    }
    if ( defined $vg2vid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_VG2VID} = $vg2vid;
        $syslog_text .= "VG2VID:$vg2vid ";
    }
    if ( defined $vlanid ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_VLANID} = $vlanid;
        $syslog_text .= "VLANID:$vlanid ";
    }
    if ( defined $ip ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_IP} = $ip;
        $syslog_text .= "IP:$ip ";
    }
    if ( defined $desc ) {
        $eventlog{$DB_COL_BUF_EVENTLOG_DESC} = $desc;
        $syslog_text .= $desc;
    }

    #    eval {
    $self->add_eventlog( \%eventlog );

    #    };
    #    if ($@) {
    #        LOGEVALFAIL();
    #    }

    EventLog( $eventtype, $syslog_text );

}

#-----------------------------------------------------------
#
#-----------------------------------------------------------
sub EventDBLogBuf ($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %eventlog = ();
    my $text_message;

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

        my $syslog_text = 'BUF: ';
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
    if ($@) {
        LOGEVALFAIL();
    }
}

1;

