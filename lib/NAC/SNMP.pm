#!/usr/bin/perl
# SVN: $Id: NACDBBuffer.pm 1538 2012-10-16 14:11:02Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-16 10:11:02 -0400 (Tue, 16 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/trunk/dev-db-split-2.1/lib/NACDBBuffer.pm $:
#
#
#
# Author: Sean McAdam
#
#
# Purpose: Provide SNMP Access to the switches
#
#
# Created: 2012-11-07 - RSM - Initial code
#
#  Next Update :
#
#
#
# Perl Rocks!
#
#------------------------------------------------------
# Notes:
# CISCO-MAC-AUTH-BYPASS-MIB
# 1.3.6.1.4.1.9.9.654
# 1.3.6.1.4.1.9.9.654.1.1.1.1.1 - Auth Enabled (0/1)
# 1.3.6.1.4.1.9.9.654.1.1.1.1.2 - Auth Method ( 1 - radius, 2 - eap )
# 1.3.6.1.4.1.9.9.654.1.2.1.1.1 - Session ID (NOT USED)
# 1.3.6.1.4.1.9.9.654.1.2.1.1.2 - MAC Address(es) (list of active MACs)
# 1.3.6.1.4.1.9.9.654.1.2.1.1.3 - State other(1), initialize(2), acquiring(3), authorizing(4), terminate(5)
# 1.3.6.1.4.1.9.9.654.1.2.1.1.4 - Status authorized(1), unauthorized(2)
#
# CISCO-AUTH-FRAMEWORK-MIB
# 1.3.6.1.4.1.9.9.656
#
#  CiscoAuthControlledDirections - Specifies the controlled direction of this port
#  1.3.6.1.4.1.9.9.656.1.2.1.1.1.
#	0: Both
#	1: In
#
#  CiscoAuthHostMode - Specifies the authentication host mode for this port
#  1.3.6.1.4.1.9.9.656.1.2.1.1.3.
#	1:singleHost
#	2:multiHost
#	3:multiAuth
#	4:multiDomain
#
#  cafPortPreAuthOpenAccess - Specifies if the Pre-Authentication Open Access feature allows clients/devices to gain network access before authentication is performed
#  1.3.6.1.4.1.9.9.656.1.2.1.1.4.
#	true: access prior to authentication
#	false: no access until authentication
#
#  cafPortAuthorizeControl - Specifies the authorization control for this port
#  1.3.6.1.4.1.9.9.656.1.2.1.1.5.
#	1:forceUnauthorized
#	2:auto
#	3:forceAuthorized
#
#  cafPortReauthEnabled - Specifies if reauthentication is enabled for this port
#  1.3.6.1.4.1.9.9.656.1.2.1.1.6.
#
#  cafPortReauthInterval - Specifies the reauthentication interval
#  1.3.6.1.4.1.9.9.656.1.2.1.1.7.
#	0: Server specified
#	n: reauth time
#
#  cafPortRestartInterval - Specifies the interval after which a further authentication attempt should be made to this port if it is not authorized
#  1.3.6.1.4.1.9.9.656.1.2.1.1.8.
#	0: No authentication attempt will be made
#	n: reauth time
#
#  cafPortInactivityTimeout - Specifies the period of time that a client associating with this port is allowed to be inactive before being terminated
#  1.3.6.1.4.1.9.9.656.1.2.1.1.9.
#	-1: timeout is from the server
#	0: disabled
#	n: timeout
#
#  cafPortViolationAction - Specifies the action to be taken due to a security violation occurs on this port
#  1.3.6.1.4.1.9.9.656.1.2.1.1.10.
#	1 : restrict
#	2 : shutdown
#	3 : protect
#	4 : replace
#
#
# SNMPv2-MIB::system.sysUpTime.0
# 1.3.6.1.2.1.1.3.0
#
# my $sysUpTime = '1.3.6.1.2.1.1.3.0';
# my $sysName = '1.3.6.1.2.1.1.5.0';
# my $oid_ifTable = '1.3.6.1.2.1.2.2';
# my $oid_ifIndex = '1.3.6.1.2.1.2.2.1.1';
# my $oid_ifdescr = '1.3.6.1.2.1.2.2.1.2.';
# my $oid_ifoperstatus = '1.3.6.1.2.1.2.2.1.8.';
# my $oid_iflastchange = '1.3.6.1.2.1.2.2.1.9.';
# my $oid_ifadminstatus = '1.3.6.1.2.1.2.2.1.7.';
#
#------------------------------------------------------

package NAC::SNMP;
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Carp;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck);
use Net::SNMP;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::DBConsts;
use NAC::Constants;
use NAC::Misc;
use strict;

#
#
Readonly our $SNMP_OID_SYSUPTIME => '.1.3.6.1.2.1.1.3.0';
Readonly our $SNMP_OID_SYSNAME   => '.1.3.6.1.2.1.1.5.0';

#
# The Whole interface shebang
#
Readonly our $SNMP_OID_IF_TABLE => '.1.3.6.1.2.1.2.2';

#
# INDEX = index number for the interface
#
Readonly our $SNMP_OID_IF_INDEX => '.1.3.6.1.2.1.2.2.1.1';

#
# DESCR = GigabitEthernet1/0/1 # Name of the interface
#
Readonly our $SNMP_OID_IF_DESCR             => '.1.3.6.1.2.1.2.2.1.2';
Readonly our $SNMP_OID_IF_OPERSTATUS        => '.1.3.6.1.2.1.2.2.1.8';
Readonly our $CISCO_MAC_OPER_STATUS_UP      => 1;
Readonly our $CISCO_MAC_OPER_STATUS_DOWN    => 2;
Readonly our $CISCO_MAC_OPER_STATUS_TESTING => 3;

Readonly our $SNMP_OID_IF_ADMINSTATUS        => '.1.3.6.1.2.1.2.2.1.7';
Readonly our $CISCO_MAC_ADMIN_STATUS_UP      => 1;
Readonly our $CISCO_MAC_ADMIN_STATUS_DOWN    => 2;
Readonly our $CISCO_MAC_ADMIN_STATUS_TESTING => 3;

# TimeTicks
Readonly our $SNMP_OID_IF_LASTCHANGE => '.1.3.6.1.2.1.2.2.1.9';

#
#
# The Whole MAB shebang
#
Readonly our $SNMP_OID_CISCO_MAC_AUTH_BYPASS => '.1.3.6.1.4.1.9.9.654';

#
# If the Interface is enabled
#
Readonly our $SNMP_OID_CISCO_MAC_AUTH_ENABLED => '.1.3.6.1.4.1.9.9.654.1.1.1.1.1';
Readonly our $CISCO_MAC_AUTH_ENABLED          => 1;
Readonly our $CISCO_MAC_AUTH_NOT_ENABLED      => 0;

#
# Method used
#
Readonly our $SNMP_OID_CISCO_MAC_AUTH_METHOD => '.1.3.6.1.4.1.9.9.654.1.1.1.1.2';
Readonly our $CISCO_MAC_AUTH_METHOD_RADIUS   => 1;
Readonly our $CISCO_MAC_AUTH_METHOD_EAP      => 2;

# Not used
## Readonly our $SNMP_OID_CISCO_MAC_AUTH_SESSIONID => '.1.3.6.1.4.1.9.9.654.1.2.1.1.1';
#
# Table of MACs on the interface
#
Readonly our $SNMP_OID_CISCO_MAC_AUTH_MAC => '.1.3.6.1.4.1.9.9.654.1.2.1.1.2';

#
# Table of States
# 1.3.6.1.4.1.9.9.654.1.2.1.1.3 - State other(1), initialize(2), acquiring(3), authorizing(4), terminate(5)
Readonly our $SNMP_OID_CISCO_MAC_AUTH_STATE    => '.1.3.6.1.4.1.9.9.654.1.2.1.1.3';
Readonly our $CISCO_MAC_AUTH_STATE_OTHER       => 1;
Readonly our $CISCO_MAC_AUTH_STATE_INITIALIZE  => 2;
Readonly our $CISCO_MAC_AUTH_STATE_ACQUIRING   => 3;
Readonly our $CISCO_MAC_AUTH_STATE_AUTHORIZING => 4;
Readonly our $CISCO_MAC_AUTH_STATE_TERMINATE   => 5;

#
# Table of the authorizations
# 1.3.6.1.4.1.9.9.654.1.2.1.1.4 - Status authorized(1), unauthorized(2)
Readonly our $SNMP_OID_CISCO_MAC_AUTH_AUTH => '.1.3.6.1.4.1.9.9.654.1.2.1.1.4';
Readonly our $CISCO_MAC_AUTH_AUTHORIZED    => 1;
Readonly our $CISCO_MAC_AUTH_UNAUTHORIZED  => 2;

Readonly our $SNMP_OID_VLAN_INFO => '.1.3.6.1.2.1.47.1.2.1.1.2';

Readonly our $SNMP_SESSION   => 'NAC::SNMP_SESSION';
Readonly our $SNMP_HOSTNAME  => 'NAC::SNMP_HOSTNAME';
Readonly our $SNMP_COMMUNITY => 'NAC::SNMP_COMMUNICATY';
Readonly our $SNMP_PORT      => 'NAC::SNMP_PORT';

our @EXPORT = qw (
  $SNMP_HOSTNAME
  $SNMP_COMMUNITY
  $SNMP_PORT
  $CISCO_MAC_AUTH_ENABLED
  $CISCO_MAC_AUTH_NOT_ENABLED
  $CISCO_MAC_AUTH_METHOD_RADIUS
  $CISCO_MAC_AUTH_METHOD_EAP
  $CISCO_MAC_AUTH_STATE_OTHER
  $CISCO_MAC_AUTH_STATE_INITIALIZE
  $CISCO_MAC_AUTH_STATE_ACQUIRING
  $CISCO_MAC_AUTH_STATE_AUTHORIZING
  $CISCO_MAC_AUTH_STATE_TERMINATE
  $CISCO_MAC_AUTH_AUTHORIZED
  $CISCO_MAC_AUTH_UNAUTHORIZED
);

my $snmp_string;

#BEGIN {
{
    my $config;
    if ( !( $config = NAC::ConfigDB->new() ) ) {
        warn "NAC::SNMP Cannot open ConfigDB\n";
    }
    else {
        $snmp_string = $config->nac_switch_snmp_string;
    }
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
# new() expects host and port to be fed in via parameter
#---------------------------------------------------------------------------
sub new {
    my ( $class, $ref ) = @_;

    # EventLog( EVENT_START, MYNAME . "() started " . ( Dumper $ref) );

    my $self = {
        $SNMP_COMMUNITY => ( ( ( defined $ref ) && ( defined $ref->{$SNMP_COMMUNITY} ) ) ? $ref->{$SNMP_COMMUNITY} : $snmp_string ),
        $SNMP_HOSTNAME  => ( ( ( defined $ref ) && ( defined $ref->{$SNMP_HOSTNAME} ) )  ? $ref->{$SNMP_HOSTNAME}  : undef ),
        $SNMP_PORT      => ( ( ( defined $ref ) && ( defined $ref->{$SNMP_PORT} ) )      ? $ref->{$SNMP_PORT}      : undef ),
    };

    bless $self, $class;

    if ( defined $self->{$SNMP_HOSTNAME} ) {
        $self->open_host_session;
    }
    else {
        print "no open session\n";
    }

    # print Dumper $self;

    $self;
}

#---------------------------------------------------------------------------
sub open_host_session {
    my ( $self, $hostname ) = @_;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . " Open SNMP Session with $hostname " );

    if ( defined $hostname ) {
        $self->{$SNMP_HOSTNAME} = $hostname;
    }
    elsif ( !defined $self->{$SNMP_HOSTNAME} ) {
        confess MYNAMELINE() . " No Hostname Defined";
    }

    if ( defined $self->{$SNMP_SESSION} ) {
        undef $self->{$SNMP_SESSION};
    }

    #
    # print "open_host_session HOST: " . $self->{$SNMP_HOSTNAME} . " COMM '" . $self->{$SNMP_COMMUNITY} . "'\n";
    #

    if ( defined( $self->{$SNMP_SESSION} = Net::SNMP->session(
                -hostname  => $self->{$SNMP_HOSTNAME},
                -community => $self->{$SNMP_COMMUNITY},
                -version   => 'snmpv2',
              ) ) ) {
        $ret = 1;
    }
    else {
        EventLog( EVENT_WARN, MYNAMELINE . " Failed to Open SNMP Session with $hostname: " . Net::SNMP->error );
    }

    $ret;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_system_uptime_str {
    my ($self) = @_;
    my $ret = $self->snmp_get_request($SNMP_OID_SYSUPTIME);
    $ret->{$SNMP_OID_SYSUPTIME};
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_system_name_str {
    my ($self) = @_;
    my $ret = $self->snmp_get_request($SNMP_OID_SYSNAME);
    $ret->{$SNMP_OID_SYSNAME};
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_name_to_index_ref {
    my ($self) = @_;
    my %ret;

    EventLog( EVENT_INFO, MYNAMELINE . " Called" );

    my $ref = $self->get_if_descr_ref();

    if ( !defined $ref ) {
        EventLog( EVENT_ERR, MYNAMELINE . " Failed to get_if_descr_ref for '$self->{$SNMP_HOSTNAME}'" );
        return undef;
    }

    foreach my $i ( keys(%$ref) ) {
        my $idx  = $i;
        my $name = $ref->{$i};

        if (
            ( $name =~ /^Async/i )
            || ( $name =~ /^DSO Group/i )
            || ( $name =~ /^Control/i )
            || ( $name =~ /^EOBC/i )
            || ( $name =~ /^Group-Async/i )
            || ( $name =~ /^Loopback/i )
            || ( $name =~ /mpls$/i )
            || ( $name =~ /^NDE/i )
            || ( $name =~ /^Null/i )
            || ( $name =~ /^NVI/i )
            || ( $name =~ /^Port-channel/i )
            || ( $name =~ /^POS/i )
            || ( $name =~ /^Serial/i )
            || ( $name =~ /^SPAN/i )
            || ( $name =~ /^Stack/i )
            || ( $name =~ /^T3/i )
            || ( $name =~ /^T1/i )
            || ( $name =~ /^Tunnel/i )
            || ( $name =~ /^unrouted/i )
            || ( $name =~ /^Vlan/i )
            || ( $name =~ /^Voice/i )
            || ( $name =~ /^VoIP/i )
          ) {
            next;
        }

        if ( ( $name =~ /^GigabitEthernet/i ) || ( $name =~ /^FastEthernet/i ) || ( $name =~ /^TenGigabitEthernet/i ) ) {
            $idx  =~ s/$SNMP_OID_IF_DESCR\.//;
            $name =~ tr/A-Z/a-z/;
            $ret{$name} = $idx;
        }
        else {
            print "Skip '$name'\n";
        }
    }
    \%ret;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_index_to_name_ref {
    my ($self) = @_;
    my %ret;

    my $ref = $self->get_name_to_index();

    foreach my $i ( keys(%$ref) ) {
        my $idx  = $ref->{$i};
        my $name = $i;
        $ret{$idx} = $name;
    }

    \%ret;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_vlan_list_ref {
    my ($self) = @_;
    my $ref = $self->snmp_get_table_ref($SNMP_OID_VLAN_INFO);
    my @ret;

    foreach my $i ( keys(%$ref) ) {
        my $vlan = $ref->{$i};

        if ( $vlan =~ /^vlan(\d+)/ ) {
            my $v = $1;
            if ( $v == 1 || ( $v >= 1002 && $v <= 1005 ) ) {
                next;
            }
            push( @ret, $v );
        }
    }

    \@ret;
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_if_table_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_IF_TABLE);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_if_index_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_IF_INDEX);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_if_descr_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_IF_DESCR);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_if_operstatus_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_IF_OPERSTATUS);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_if_lastchange_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_IF_LASTCHANGE);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_if_adminstatus_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_IF_ADMINSTATUS);
}

#---------------------------------------------------------------------------
# Whole MAB Table
#---------------------------------------------------------------------------
sub get_mac_auth_bypass_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_BYPASS);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_enabled_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_ENABLED);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_enabled_index {
    my ( $self, $idx ) = @_;
    my $oid = $SNMP_OID_CISCO_MAC_AUTH_ENABLED . '.' . $idx;
    my $ret = $self->snmp_get_request($oid);
    $ret->{$oid};
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_method_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_METHOD);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_method_index {
    my ( $self, $idx ) = @_;
    my $oid = $SNMP_OID_CISCO_MAC_AUTH_METHOD . '.' . $idx;
    my $ret = $self->snmp_get_request($oid);
    $ret->{$oid};
}

# #---------------------------------------------------------------------------
# #---------------------------------------------------------------------------
# sub get_mac_auth_sessionid_ref {
#     my ($self) = @_;
#     $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_SESSIONID);
# }
#
# #---------------------------------------------------------------------------
# #---------------------------------------------------------------------------
# sub get_mac_auth_sessionid_index_ref {
#     my ($self,$idx) = @_;
#     my $oid = $SNMP_OID_CISCO_MAC_AUTH_SESSIONID . '.' . $idx;
#     $self->snmp_get_table_ref($oid);
# }

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_mac_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_MAC);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_mac_index_ref {
    my ( $self, $idx ) = @_;
    my $oid = $SNMP_OID_CISCO_MAC_AUTH_MAC . '.' . $idx;
    $self->snmp_get_table_ref($oid);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_state_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_STATE);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_state_index_ref {
    my ( $self, $idx ) = @_;
    my $oid = $SNMP_OID_CISCO_MAC_AUTH_STATE . '.' . $idx;
    $self->snmp_get_table_ref($oid);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_auth_ref {
    my ($self) = @_;
    $self->snmp_get_table_ref($SNMP_OID_CISCO_MAC_AUTH_AUTH);
}

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub get_mac_auth_auth_index_ref {
    my ( $self, $idx ) = @_;
    my $oid = $SNMP_OID_CISCO_MAC_AUTH_AUTH . '.' . $idx;
    $self->snmp_get_table_ref($oid);
}

#---------------------------------------------------------------------------
sub snmp_get_request {
    my ( $self, $oid ) = @_;

    #
    # print "snmp_get_request\n";
    #

    if ( !defined $oid ) {
        confess;
    }

    my $result = $self->session->get_request( -varbindlist => [$oid], );
    if ( !defined $result ) {
        $self->session->close();
        my $hostname = $self->{$SNMP_HOSTNAME};
        EventLog( EVENT_ERR, MYNAMELINE . " No Result for $oid -> '$hostname' " . cluck );
        $result = undef;
    }

    $result;
}

#---------------------------------------------------------------------------
sub snmp_get_table_ref {
    my ( $self, $oid ) = @_;

    EventLog( EVENT_INFO, MYNAMELINE . " Called" );

    if ( !defined $oid ) {
        confess;
    }

    if ( !defined $self->session ) {
        EventLog( EVENT_ERR, MYNAMELINE . " No Session for $oid -> '$self->{$SNMP_HOSTNAME}' " );
        return undef;
    }

    my $raw_result = $self->session->get_table( $oid, );
    if ( !defined $raw_result ) {
        $self->session->close();

        # my $hostname  = $self->{$SNMP_HOSTNAME};
        EventLog( EVENT_ERR, MYNAMELINE . " No Result for $oid -> '$self->{$SNMP_HOSTNAME}' " . cluck );
        return undef;
    }

    my %result = ();
    foreach my $key ( keys(%$raw_result) ) {
        my $val = $raw_result->{$key};
        $key =~ s/$oid\.//;
        $result{$key} = $val;
    }
    \%result;
}

#---------------------------------------------------------------------------
sub session {
    my ($self) = @_;

    # EventLog( EVENT_INFO, MYNAMELINE . " Called: $self->{$SNMP_HOSTNAME}" );

    if ( !defined $self->{$SNMP_SESSION} ) {
        if ( defined $self->{$SNMP_HOSTNAME} ) {
            $self->open_host_session;
        }
        else {
            confess MYNAMELINE() . " No Hostname Defined";
        }
    }

    $self->{$SNMP_SESSION};
}
1;
