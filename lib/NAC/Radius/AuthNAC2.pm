#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: 1750 $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/dev-rel-2.1/lib/Radius/AuthNAC2.pm $:
#
#
# Author: Sean McAdam
#
#
# Purpose: Plugin Module for Radiator, provides integration of cisco MAB services
#	to custom build database system
#
#
# Update :
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------
# AuthNAC2.pm
#
# You can use $self->log to log messages to the logfile, and any
# other modules you see fit.
#
#

package NAC::Radius::AuthNAC2;
use FindBin;
use lib "$FindBin::Bin/../lib";

@ISA = qw(Radius::AuthGeneric);
use Radius::AuthGeneric;
use POSIX;
use Carp;
use Data::Dumper;
use Thread::Semaphore;
use Readonly;
use NAC::DBReadOnly;
use NAC::DBBuffer;
use NAC::DBMagic;
use NAC::Constants;
use NAC::DBConsts;
use NAC::Syslog;
use strict;
no strict "subs";

Readonly our $DEBUG              => 0;
Readonly our $BLDG               => 'BLDG';
Readonly our $LOCATION           => 'LOCATION';
Readonly our $LOCID              => 'LOCID';
Readonly our $MAC                => 'MAC';
Readonly our $MACID              => 'MACID';
Readonly our $MAC_COE            => 'MAC-COE';
Readonly our $PORTNAME           => 'PORTNAME';
Readonly our $SITE               => 'SITE';
Readonly our $SWITCHID           => 'SWITCHID';
Readonly our $SWITCHNAME         => 'SWITCHNAME';
Readonly our $SWITCHPORTID       => 'SWITCHPORTID';
Readonly our $NAS_IP_ADDRESS     => 'NAS-IP-Address';
Readonly our $CALLING_STATION_ID => 'Calling-Station-Id';
Readonly our $NAS_PORT_ID        => 'NAS-Port-Id';
Readonly our $USER_NAME          => 'User-Name';
Readonly our $ACCESS_REQUEST     => 'Access-Request';
Readonly our $ACCESS_REJECT      => 'Access-Reject';
Readonly our $ACCOUNTING_REQUEST => 'Accounting-Request';

# Defaults
# NAC::Syslog::ActivateDatabaseLog();
# NAC::Syslog::ActivateSyslog();
# NAC::Syslog::DeactivateStdout();
# NAC::Syslog::DeactivateStderr();
my $hostname = NAC::Syslog::hostname();

# NAC::Syslog::ActivateDebug();
NAC::Syslog::DeactivateDebug();

#
# Percent randomness for reauthentication time outs.
# Helps spread out the timeouts in case several switches/ports all
# come online at once.
#
use constant REAUTHPERCENT => 5;

# RCS version number of this module
$Radius::AuthNAC2::VERSION = '$Revision: 1750 $';

my %dbr_pool;
my %dbw_pool;
my %dbm_pool;
my $dbr_count = 0;
my $dbw_count = 0;
my $dbm_count = 0;
my $sem;

if ( !( $sem = new Thread::Semaphore(1) ) ) {
    EventLog( EVENT_FUNC_FAIL, MYNAMELINE . " Unable to create Semaphore: " . $! );
    confess;
}

#####################################################################
# Constructs a new handler
# This will be called one for each <Realm ...> that specifies
# <AuthNAC ...>
# $file is the file we are currently parsing, it should be
# passed to the superclass Configurable, which will call
# the keyword and object routines here whenever it sees
# those things in the config file.
# You should set up any permanent state here, such as a cached
# user name file, or open a database etc
#
# If your 'new' constructor does not do anything other than calling
# the superclass, you can omit it.
#
# This instance will be destroyed when the server is reinitialised
#####################################################################
sub new
{
    my ( $class, @args ) = @_;

    EventLog( EVENT_START, MYNAME . "() started" );

    my $self = $class->SUPER::new(@args);

    LOGEVALFAIL if ($@);

    bless $self, $class;

    return $self;
}

#--------------------------------------------------------------------------------
# Local Master (RO)
#--------------------------------------------------------------------------------
sub dbr {
    my ($self) = (@_);

    if ( !defined $dbr_pool{$$} ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . " $$ " );
        $sem->down();
        $dbr_pool{$$} = _get_nacdb_read_dbh();
        $sem->up();
    }

    $dbr_pool{$$};

}

#--------------------------------------------------------------------------------
# Buffer (W)
#--------------------------------------------------------------------------------
sub dbw {
    my ($self) = (@_);

    if ( !defined $dbw_pool{$$} ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . " $$ " );
        $sem->down();
        $dbw_pool{$$} = _get_nacdb_buffer_dbh();
        $sem->up();
    }

    $dbw_pool{$$};
}

#--------------------------------------------------------------------------------
# Magic (RO)
#--------------------------------------------------------------------------------
sub dbm {
    my ($self) = (@_);

    if ( !defined $dbm_pool{$$} ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . " $$ " );
        $sem->down();
        $dbm_pool{$$} = _get_nacdb_magic_obj();
        $sem->up();
    }

    $dbm_pool{$$};
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub _get_nacdb_read_dbh {
    my $nacdb = undef;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called" );

    $nacdb = NAC::DBReadOnly->new();
    if ( ref($nacdb) ne 'NAC::DBReadOnly' ) { confess MYNAMELINE . " NAC::DBReadOnly->new() FAILED\n"; }

    $dbr_count++;
    $nacdb;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub _get_nacdb_buffer_dbh {
    my $nacdb = undef;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called" );

    $nacdb = NAC::DBBuffer->new();
    if ( ref($nacdb) ne 'NAC::DBBuffer' ) { confess MYNAMELINE . " NAC::DBBuffer->new() FAILED\n"; }

    $dbw_count++;
    $nacdb;
}

#--------------------------------------------------------------------------------
#
#--------------------------------------------------------------------------------
sub _get_nacdb_magic_obj {
    my $nacdb = undef;

    EventLog( EVENT_DEBUG, MYNAMELINE . " called" );

    $nacdb = NAC::DBMagic->new();
    if ( ref($nacdb) ne 'NAC::DBMagic' ) { confess MYNAMELINE . " NAC::DBMagic->new() FAILED\n"; }

    $dbm_count++;
    $nacdb;
}

#####################################################################
# Do per-instance state (re)creation.
# This wil be called after the instance is created and after parameters have
# been changed during online reconfiguration.
# If it doesnt do anything, you can omit it.
#####################################################################
sub activate
{
    my ($self) = @_;
    $self->SUPER::activate();

    NAC::Syslog::ActivateDebug() if $DEBUG;

    EventLog( EVENT_INFO, MYNAMELINE . "() called" );
}

#####################################################################
# Do per-instance default initialization
# This is called by Configurable during Configurable::new before
# the config file is parsed. Its a good place initialize instance
# variables
# that might get overridden when the config file is parsed.
# If it doesnt do anything, you can omit it.
#####################################################################
sub initialize
{
    my ($self) = @_;

    my @index = ();

    $self->SUPER::initialize;

    EventLog( EVENT_INFO, MYNAMELINE . "() called" );
}

#####################################################################
# Handle a request
# This function is called for each packet. $p points to a Radius::
# packet containing the original request. $p->{rp} is a reply packet
# you can use to reply, or else fill with attributes and get
# the caller to reply for you.
# $extra_checks is an AttrVal containing check items that
# we must check for, regardless what other check items we might
# find for the user. This is most often used for cascading
# authentication wuth Auth-Type .
# In this test module, Accounting is ignored
# It is expected to (eventually) reply to Access-Request packets
# with either Access-Accept or Access-Reject
# Accounting-Request will automatically be replied to by the
# Realm object
# so there is no need to reply to them, although they might be forwarded
# logged in a site-specific fashion, or something else.
#
# The return value significant:
# If false, a generic reply will be constructed by Realm, else no reply will
# be sent to the requesting client. In general, you should always
# handle at least Access-Request and return 0
# Also returns an optional reason message for rejects

# $p->{}
#Key: EAPMessageAuthenticator,
#Key: StatsTrail, ARRAY
#Key: RecvTime,
#Key: OriginalUserName,
#Key: RecvFromAddress,
#Key: Handler, Radius::Realm
#Key: RecvSocket,
#Key: Dict, Radius::RDict
#Key: Client, Radius::Client
#Key: RecData,
#Key: RecvFromPort,
#Key: replyFn, ARRAY
#Key: CachedAttrs, HASH
#Key: Code,
#Key: Attributes, ARRAY
#Key: Identifier,
#Key: DupCacheKey,
#Key: Authenticator,
#Key: RecvFrom,
#Key: rp, Radius::Radius

# $p->{'Attributes'} is an array of attributes from the client

# if ( $p->code eq $ACCESS-REQUEST )
# Pull out attributes to work with.

#####################################################################
#
# Three main vaiables used in this routine are
#    $parm{$MAC}        = $p->get_attr($CALLING-STATION-ID);
#    $parm{$SWITCHIP}   = $p->get_attr($NAS_IP_ADDRESS);
#    $parm{$PORTNAME}   = $p->get_attr($NAS_PORT_ID);
#
#
# Others are passed in for debugging and logging purposes
#
#####################################################################
sub handle_request {
    my ( $self, $p, $dummy, $extra_checks ) = @_;
    my %parm  = ();
    my $ret   = ($main::ACCEPT);
    my $index = -1;

    # EventLog( EVENT_INFO, MYNAMELINE . " called" );

    # NAC::Syslog::ActivateDebug();

    eval {

        #
        # Local checking to see if I am alive.
        # I dont care what I return, just that I return something to prove I am alive
        #
        my $myip = $p->get_attr($NAS_IP_ADDRESS);
        if ( $myip =~ /^127/ ) {
            EventLog( EVENT_INFO, "PING:" . $hostname );
            $ret = ($main::ACCEPT);
            goto EXITFUNCTION;
        }

        # Convert 00-1B-78-4F-2B-E6 ==>> 00:1b:78:4f:2b:e6
        my $pcode    = $p->code;
        my $switchip = $p->get_attr($NAS_IP_ADDRESS);
        my $mac      = $p->get_attr($CALLING_STATION_ID);
        my $portname = $p->get_attr($NAS_PORT_ID);
        my $username = $p->get_attr($USER_NAME);
        my $switchid = 0;
        my $swpid    = 0;
        my $macid    = 0;
        my $locid    = 0;
        $mac      =~ tr/A-F/a-f/;
        $mac      =~ s/-/:/g;
        $portname =~ tr/A-Z/a-z/;

        #
        # Skip if it is a bogus switch IP
        #
        if ( $switchip =~ /^255/ ) {
            EventLog( EVENT_WARN, "Bad Switch IP:$switchip MAC:$mac PORT:$portname" );
            $ret = ($main::REJECT);
            goto EXITFUNCTION;
        }

        #
        # Update local Switch Lastseen Data Once
        #
        elsif ( $switchip =~ /(\d+\.\d+\.\d+\.\d+)/ ) {
            %parm = ();
            $parm{$DB_COL_SW_IP} = $switchip;

            EventLog( EVENT_DEBUG, "HANDLE REQUEST for IP: $switchip" );

            if ( $self->dbr->get_switch( \%parm ) ) {
                if ( !isdigit( $parm{$DB_COL_SW_ID} ) ) { confess "BAD SWITCH ID Returned, '" . $parm{$DB_COL_SW_ID} . "'"; }
                $switchid = $p->{$SWITCHID} = $parm{$DB_COL_SW_ID};

                # EventLog( EVENT_INFO, "Switch IP:$switchip ID: $switchid" );

                $locid = $p->{$LOCID} = $parm{$DB_COL_SW_LOCID};
                $p->{$SWITCHNAME} = $parm{$DB_COL_SW_NAME};

            }
            else {
                EventLog( EVENT_DEBUG, "UNKNOWN Switch IP: $switchip MAC:$mac PORT:$portname" );
                $ret = ($main::REJECT);
                goto EXITFUNCTION;
            }
        }
        else {
            EventLog( EVENT_WARN, "NO Switch IP: MAC:$mac PORT:$portname" );
        }

        $self->dbw->update_lastseen_switchid($switchid) if ($switchid);

        #
        # No port or MAC, This is a test query, Return Accept
        #
        if ( $username =~ /radiustest/ ) {
            EventLog( EVENT_DEBUG, "NAC2 Test Query: IP:$switchip UN:$username" );
            $ret = ($main::ACCEPT);
            goto EXITFUNCTION;
        }

        #
        # No port or MAC, This is a test query, Return Accept
        #
        if ( ( $username ne '' ) && ( $portname eq '' ) && ( $mac eq '' ) ) {
            EventLog( EVENT_INFO, "Assuming a Test Query: IP:$switchip UN:$username MAC and PORT empty" );
            $ret = ($main::ACCEPT);
            goto EXITFUNCTION;
        }

        #
        # No port or MAC, This is a test query, Return Accept
        #
        if ( ( $portname eq '' ) && ( $mac eq '' ) ) {
            EventLog( EVENT_INFO, "Assuming a Test Query: IP:$switchip UN:$username MAC and PORT empty" );
            $ret = ($main::ACCEPT);
            goto EXITFUNCTION;
        }

        #
        # No Portname, this is a problem, return REJECT
        #
        if ( $portname eq '' ) {
            EventLog( EVENT_WARN, "No PORTNAME: IP:$switchip MAC:$mac USERNAME:$username PORT empty" );
            $ret = ($main::ACCEPT);
            goto EXITFUNCTION;
        }

        #
        # No MAC, this is a problem, return REJECT
        #
        if ( $mac eq '' ) {
            EventLog( EVENT_WARN, "No MAC: IP:$switchip PORTNAME:$portname USERNAME:$username MAC empty" );
            $ret = ($main::ACCEPT);
            goto EXITFUNCTION;
        }

        EventLog( EVENT_INFO, "REQUEST: Code: '$pcode', MAC:'$mac', SWITHCIP:'$switchip', PORT:'$portname'" );

        # Need SWITCHID SWITCHPORTID and MACID
        # from SWITCHIP PORTNAME and MAC
        # for all requests
        #
        # Check Switch      - NAS-IP-Address 10.20.1.123
        # Check Switch Port - NAS-Port-Id  FastEthernet0/1
        # Check MAC         - Calling-Station-Id 00-1B-78-4F-2B-E6

        #
        # Get MAC Data
        #
        %parm                  = ();
        $parm{$DB_COL_MAC_MAC} = $mac;
        $p->{$MAC}             = $mac;
        if ( !( $self->dbr->get_mac( \%parm ) ) ) {
            EventLog( EVENT_INFO, "REQUEST ADD MAC: Code: '$pcode', MAC:'$mac', SWITHCIP:'$switchip', PORT:'$portname'" );
            $self->dbw->add_mac($mac);
        }
        else {
            $macid = $p->{$MACID} = $parm{$DB_COL_MAC_ID};
            $p->{$MAC_COE} = $parm{$DB_COL_MAC_COE};
            EventLog( EVENT_DEBUG, "GOT MACID: " . $p->{$MACID} );
        }

        $self->dbw->update_lastseen_macid($macid) if ($macid);

        #
        # No sense continuing, the switch is not in the system yet.
        # If the system is severed from the master then it will not work
        # If the system is normal, then the next time around the switch should be in there
        # But the required data is not in there anyway.
        #
        if ( !$switchid ) {
            EventLog( EVENT_INFO, "No SWITCHID for SWITHCIP:'$switchip', SKIPPING..." );
            $self->dbw->add_switch($switchip);
            $ret = ($main::REJECT);
            goto EXITFUNCTION;
        }

        #
        # Get location data, But carry on with out it if need be
        #
        %parm = ();
        $parm{$DB_COL_LOC_ID} = $locid;
        if ( $self->dbr->get_location( \%parm ) ) {
            $p->{$SITE}     = $parm{$DB_COL_LOC_SITE};
            $p->{$BLDG}     = $parm{$DB_COL_LOC_BLDG};
            $p->{$LOCATION} = $parm{$DB_COL_LOC_SHORTNAME};
            EventLog( EVENT_DEBUG, "GOT LOCID: " . $locid . ' ' . $parm{$DB_COL_LOC_SITE} . '-' . $parm{$DB_COL_LOC_BLDG} );
        }
        else {
            EventLog( EVENT_WARN, "NO LOCATION for LOCID: " . $locid );
        }

        $self->dbw->update_lastseen_locationid($locid) if ($locid);

        #
        # Get Switch Port Data
        # Uses SWITCHID, and PORTNAME
        #
        %parm                   = ();
        $parm{$DB_COL_SWP_NAME} = $portname;
        $parm{$DB_COL_SWP_SWID} = $p->{$SWITCHID};
        if ( !$self->dbr->get_switchport( \%parm ) ) {
            EventLog( EVENT_INFO, "NO SWP FOUND: for $portname " );

            my $timestring = localtime(time);
            $parm{$DB_COL_SWP_DESC} = "Switch Port $portname Switch:$switchip added by " . __PACKAGE__ . ':' . $timestring;
            my $msg = "Adding Switchport: $switchip, $portname";
            $self->dbw->add_switchport( $switchid, $portname );
        }
        else {
            $swpid = $p->{$SWITCHPORTID} = $parm{$DB_COL_SWP_ID};
            $p->{$PORTNAME} = $portname;
            EventLog( EVENT_DEBUG, "GOT SWPID: " . $p->{$SWITCHPORTID} );
        }

        $self->dbw->update_lastseen_switchportid($swpid) if ($swpid);

        # EventLog( EVENT_INFO, MYNAMELINE
        #	. "$pcode IDs: MACID:$p->{$MACID}, SWITHCID:$p->{$SWITCHID}, LOCID:$locid, PORTID:"
        #	. $p->{$SWITCHPORTID} );

        #----------------
        # Access-Request
        #----------------
        if ( $pcode eq $ACCESS_REQUEST ) {
            EventLog( EVENT_INFO, MYNAMELINE . '--> ' . $pcode
                  . " IDs: MACID:$macid, SWITHCID:$switchid, LOCID:$locid, PORTID:$swpid" );

            #
            # Check first to see if the Port is MAGIC if the MAC is defined
            # Skips if the main DB is not available
            #
            if ( defined $p->{'MACID'} && defined $p->{$SWITCHPORTID} ) {
                $self->dbm->check_magic_port( $swpid, $macid );
            }

            #
            # Process the access request
            #
            $ret = $self->access_request($p);

        }

        #----------------
        # Accounting-Request (Most likley), but no MAC ID yet, so skip it
        # Sending reject will leave it in the local challenge network
        #----------------
        elsif ( !$macid ) {
            EventLog( EVENT_WARN, MYNAMELINE . "IGNORE Request No MACID for MAC:$mac" );
            $ret = ($main::REJECT);
            goto EXITFUNCTION;
        }

        #----------------
        # Accounting-Request
        #----------------
        elsif ( $pcode eq $ACCOUNTING_REQUEST ) {

            my $type = $p->get_attr('Acct-Status-Type');

            #
            # Skip recording Alive Messages
            #
            if ( 'Alive' ne $type ) {
                EventLog( EVENT_INFO, '--> ' . $pcode . " $type "
                      . " IDs: MACID:$macid, SWITHCID:$switchid, LOCID:$locid, PORTID:$swpid" );

                # EventLog( EVENT_INFO, MYNAMELINE . "Accounting-Request for MAC:$mac" );
                $ret = $self->accounting_request($p);

            }
            else {
                EventLog( EVENT_DEBUG, "Accounting-Request SKIP Request Type: $type" );
                $ret = ($main::ACCEPT);
                goto EXITFUNCTION;
            }

        }

        #----------------
        # Everything Else
        #----------------
        else
        {
            EventLog( EVENT_ERR, MYNAMELINE
                  . "UNKNOWN REQUEST: MACID:$p->{'MACID'}, SWITHCID:$p->{'SWITCHID'}, LOCID:$p->{'LOCID'}, PORTID:$p->{$SWITCHPORTID}" );

            # Handler will construct a generic reply for us
            $ret = ($main::REJECT);
            goto EXITFUNCTION;
        }
    };
    LOGEVALFAIL() if ($@);

  EXITFUNCTION:

    EventLog( EVENT_DEBUG, MYNAMELINE . " .. FINISHED .." );

    $ret;
}

#####################################################################
# Start or Stop packets
#####################################################################
sub accounting_request() {
    my ( $self, $p ) = @_;

    # For debugging and logging
    my $DBHR        = $self->dbr;
    my $DBHW        = $self->dbw;
    my $switchname  = $p->{$SWITCHNAME};
    my $portname    = $p->{$PORTNAME};
    my $swpid       = $p->{$SWITCHPORTID};
    my $macid       = $p->{$MACID};
    my $mac         = $p->{$MAC};
    my $type        = $p->get_attr('Acct-Status-Type');
    my $voice_macid = 0;
    my $data_macid  = 0;

    my %parm = ();
    $parm{$DB_COL_BUF_ADD_RA_SWPID} = $swpid;
    $parm{$DB_COL_BUF_ADD_RA_MACID} = $macid;

    # $parm{$DB_COL_BUF_ADD_RA_AUDIT_SRV} = $hostname;
    $parm{$DB_COL_BUF_ADD_RA_TYPE} = $type;
    if ( $type eq 'Stop' ) {
        $parm{$DB_COL_BUF_ADD_RA_CAUSE}  = $p->get_attr('Acct-Terminate-Cause');
        $parm{$DB_COL_BUF_ADD_RA_OCTIN}  = $p->get_attr('Acct-Input-Octets');
        $parm{$DB_COL_BUF_ADD_RA_OCTOUT} = $p->get_attr('Acct-Output-Octets');
        $parm{$DB_COL_BUF_ADD_RA_PACIN}  = $p->get_attr('Acct-Input-Packets');
        $parm{$DB_COL_BUF_ADD_RA_PACOUT} = $p->get_attr('Acct-Output-Packets');
    }

    #
    # my $log = "Acct: MACID: " . $macid
    #   . " SPID: " . $swpid
    #   . " TYPE: " . $type;
    #
    # EventLog( EVENT_INFO, $log );
    #

    #Attributes:
    #        Acct-Session-Id = "00000501"
    #        User-Name = "001b784f2be6" <- the MAC ACCRESS, also calling-station-id
    #        Acct-Authentic = RADIUS
    #        Acct-Terminate-Cause = Idle-Timeout
    #        Acct-Session-Time = 92
    #        Acct-Input-Octets = 1600
    #        Acct-Output-Octets = 6448
    #        Acct-Input-Packets = 22
    #        Acct-Output-Packets = 79
    #        Acct-Status-Type = Stop
    #        NAS-Port-Type = Ethernet
    #        NAS-Port = 50001
    #        NAS-Port-Id = "GigabitEthernet0/1"
    #        Called-Station-Id = "00-21-1C-D7-03-01"
    #        Calling-Station-Id = "00-1B-78-4F-2B-E6" <- MAC Address
    #        Service-Type = Framed-User
    #        NAS-IP-Address = 10.20.1.123
    #        Acct-Delay-Time = 0
    #
    #
    #
    #

    $DBHW->add_radiusaudit( \%parm );

    my $msg = "HOST:'$hostname' MAC:'$mac'" . '[' . $macid . ']' . " SW:'$switchname'" . '[' . $swpid . ']' . " PORT:'$portname'";
    my $eventtype = ( $type eq 'Stop' ) ? EVENT_ACCT_STOP : EVENT_ACCT_START;
    EventLog( $eventtype, $msg );

    # Only concerned with STOPs
    if ( $type eq 'Stop' ) {
        my %state = ();
        $state{$DB_COL_BUF_SWPS_SWPID} = $swpid;
        if ( $DBHW->get_switchportstate( \%state ) ) {
            if ( $macid == $state{$DB_COL_BUF_SWPS_MACID} ) {
                $data_macid = $macid;
            }
            elsif ( $macid == $state{$DB_COL_BUF_SWPS_VMACID} ) {
                $voice_macid = $macid;
            }
            else {
                EventLog( EVENT_WARN, MYNAMELINE() . "Switchport $swpid MAC $macid, $mac does not match " );
            }

            # EventLog( EVENT_INFO, MYNAMELINE() . "Accounting Got STATE OK" );

            if ($data_macid) {
                $DBHW->clear_data_switchportstate( \%state );
            }
            elsif ($voice_macid) {
                $DBHW->clear_voice_switchportstate( \%state );
            }
            else {
                EventLog( EVENT_INFO, MYNAMELINE() . "UNKNOWN MAC to CLEAR from switchport" );
            }

        }
        else {

            #
            # Switchport buffer not found so add it.
            # Should consult RO table -- WORK HERE
            #
            $DBHW->add_switchportstate( \%state );
        }
    }

    # EventLog( EVENT_INFO, MYNAMELINE() . "Accounting Return OK" );

    $self->adjustReply($p);

    # Just say OK...
    return ($main::ACCEPT);

}

#####################################################################
#
#
#   ** Warning ** This needs to remove the vlangroups from the loop.
#	the called subroutine no longer calulates them, and only returns VLANs.
#
# Logic Flow:
#    Get LocationID based on SwitchID (no location, fall though to challenge)
#	Get Switchid
#	Get Location
#	Get MACID
#
#    MAC to MACID (cache needed - put in database )
#    SWITCHIP to SWITCHID (cache needed - put in database )
#    SWITCHID:SWITCHPORTNAME to SWITCHPORTID (cache needed - put in database )
#	All of these values should not change very often.
#
#	Step 1 )
#	Call mysql_get_class_mac_port(), which returns the list of potential VLANs
#		Using MACID and SWITCHID
#
#	Step 2 )
#	Loop though the sorted results
#		Check VLAN, VLANGROUP, TEMPLATE, DEFAULT in order
#		If there is a VLAN Hit, pop out of the loop
#
#	Step 3 )
#	Check VLANID
#		If no VLANID, goto challenge network
#
#	Step 4 )
#	Still no VLANID, Error out, and goto VLAN1
#
#	Step 5 )
#	Figure out VLAN from VLANID and return it.
#
#
#####################################################################
sub access_request() {
    my ( $self, $p ) = @_;
    my %parm                = ();
    my $DBHR                = $self->dbr;
    my $DBHW                = $self->dbw;
    my $switchportid        = $p->{$SWITCHPORTID};
    my $switchid            = $p->{$SWITCHID};
    my $locid               = $p->{$LOCID};
    my $locname             = $p->{$LOCATION};
    my $macid               = $p->{$MACID};
    my $mac                 = $p->{$MAC};
    my $switchname          = $p->{$SWITCHNAME};
    my $portname            = $p->{$PORTNAME};
    my $site                = $p->{$SITE};
    my $bldg                = $p->{$BLDG};
    my $mac_coe             = ( defined $p->{$MAC_COE} && $p->{$MAC_COE} ) ? 1 : 0;
    my $mac_coe_ticketref   = 0;
    my $vlanname            = 'unknown';
    my $vlantype            = 'unknown';
    my $active_data_vlanid  = 0;
    my $active_voice_vlanid = 0;
    my $voice               = 0;
    my $reauthtime          = 0;
    my $idletimeout         = 0;
    my $vgid                = 0;
    my $vgname              = '';
    my $tempid              = 0;
    my $tempname            = '';
    my %swps                = ();

    my $event_hdr = "MAC:'$mac'"
      . "[$macid], "
      . "SWITCH:'$switchname'"
      . "[$switchid], "
      . "PORT:'$portname'"
      . "[$switchportid], "
      . "LOC:'$locname'"
      . "[$locid]";

    if ( !defined $macid ) {
        EventLog( EVENT_WARN, MYNAMELINE() . "$event_hdr NO MACID for $mac" );
        $macid = 0;
    }
    elsif ( !isdigit($macid) ) {
        EventLog( EVENT_LOGIC_FAIL, MYNAMELINE() . "$event_hdr Bad MACID passed in" );
        confess;
    }

    if ( !defined $switchid ) {
        EventLog( EVENT_WARN, MYNAMELINE() . "$event_hdr no SWITCHID passed in" );
        $switchid = 0;
    }
    elsif ( !isdigit($switchid) ) {
        EventLog( EVENT_LOGIC_FAIL, MYNAMELINE() . "$event_hdr Bad SWITCHID passed in" );
        confess;
    }

    if ( !defined $switchportid ) {
        EventLog( EVENT_WARN, MYNAMELINE() . "$event_hdr NO SWITCHPORTID passed, ID:'$switchportid'" );
        $switchportid = 0;
    }
    elsif ( !isdigit($switchportid) ) {
        EventLog( EVENT_LOGIC_FAIL, MYNAMELINE() . "$event_hdr Bad SWITCHPORTID passed, ID:'$switchportid'" );
        confess;
    }

    if ( !defined $locid ) {
        EventLog( EVENT_WARN, MYNAMELINE() . "$event_hdr NO LOCID passed'" );
        $locid = 0;
    }
    elsif ( !isdigit($locid) ) {
        EventLog( EVENT_LOGIC_FAIL, MYNAMELINE() . "$event_hdr Bad LOCID passed, ID:'$locid'" );
        confess;
    }

    # EventLog( EVENT_INFO, MYNAMELINE() . "$event_hdr" );

    my $authtype  = '';           #
    my $eventtype = 'UNKNOWN';    # EVENT_AUTH_PORT or EVENT_AUTH_MAC;

    # Set this if a rule for a MAC was found (Used with the challenge_error)
    my $mac_rule_found = 0;

    # 1 Step away from the answer
    my $vlanid = 0;

    # The actual answer we are looking for
    my $vlan = 0;

    my $classid   = 0;
    my $classname = '';

    # GET CLASS MAC PORT DATA
    %parm = ();
    my %results = ();
    $parm{$DB_COL_CMP_SWPID} = $switchportid;
    $parm{$DB_COL_CMP_SWID}  = $switchid;
    $parm{$DB_COL_CMP_MACID} = $macid;
    $parm{$DB_COL_CMP_LOCID} = $locid;
    $parm{$HASH_REF}         = \%results;

    #--------------------------------------
    #       Here it is, the big decision
    # -->>  The real Magic happens here   <<--
    #
    #--------------------------------------
    #*********
    # Step 1 )
    #*********

    #
    # Locid could be 0, if so don't bother checking the DB
    #
    if ( $locid && $macid && $switchid && $switchportid ) {
        $DBHR->get_class_mac_port( \%parm );
    }

    # Returns priority has of VLANID, GROUPID, TEMPLATEID, DEFAULT, but all as VLANIDs
    #

    #
    # If there are results process them
    #
    if ( scalar( keys(%results) ) ) {

        #        foreach my $sortpri ( sort { $b <=> $a } ( keys(%results) ) ) {
        #            my $result_ref = $results{$sortpri};
        #            my $l_pri      = $result_ref->{$DB_COL_CMP_PRI};
        #            my $l_subpri   = $result_ref->{$DB_COL_CMP_SUBPRI};
        #            my $l_hashpri  = $result_ref->{$DB_COL_CMP_HASHPRI};
        #            my $l_vlan     = $result_ref->{$DB_COL_CMP_VLAN};
        #            my $l_vlantype = $result_ref->{$DB_COL_CMP_VLANTYPE};
        #            my $l_authtype = $result_ref->{$DB_COL_CMP_AUTHTYPE};
        #
        #            EventLog( EVENT_INFO, MYNAMELINE() . "SORTINFO:$sortpri PRI:$l_pri SUB:$l_subpri HASH:$l_hashpri AUTH:$l_authtype VLANTYPE:$l_vlantype" );
        #        }

        foreach my $sortpri ( sort { $b <=> $a } ( keys(%results) ) ) {
            my $result_ref = $results{$sortpri};

            my $l_pri         = $result_ref->{$DB_COL_CMP_PRI};
            my $l_subpri      = $result_ref->{$DB_COL_CMP_SUBPRI};
            my $l_randpri     = $result_ref->{$DB_COL_CMP_RANDPRI};
            my $l_vlan        = $result_ref->{$DB_COL_CMP_VLAN};
            my $l_vlanid      = $result_ref->{$DB_COL_CMP_VLANID};
            my $l_vlanname    = $result_ref->{$DB_COL_CMP_VLANNAME};
            my $l_vlan_coe    = $result_ref->{$DB_COL_CMP_COE};
            my $l_authtype    = $result_ref->{$DB_COL_CMP_AUTHTYPE};
            my $l_recid       = $result_ref->{$DB_COL_CMP_RECID};
            my $l_classid     = $result_ref->{$DB_COL_CMP_CLASSID};
            my $l_classname   = $result_ref->{$DB_COL_CMP_CLASSNAME};
            my $l_locked      = $result_ref->{$DB_COL_CMP_LOCKED};
            my $l_comment     = $result_ref->{$DB_COL_CMP_COM};
            my $l_vlantype    = $result_ref->{$DB_COL_CMP_VLANTYPE};
            my $l_reauthtime  = $result_ref->{$DB_COL_CMP_REAUTH};
            my $l_idletimeout = $result_ref->{$DB_COL_CMP_IDLE};
            my $l_vgid        = $result_ref->{$DB_COL_CMP_VGID};
            my $l_vgname      = $result_ref->{$DB_COL_CMP_VGNAME};
            my $l_tempid      = $result_ref->{$DB_COL_CMP_TEMPID};
            my $l_tempname    = $result_ref->{$DB_COL_CMP_TEMPNAME};

            EventLog( EVENT_INFO, " ->CHECKING $event_hdr" );

            #------------------------------------------------------------------
            # FUTURE FUTURE FUTURE is HERE
            #
            # Block non-COE MACs from getting on COE VLANs Here
            #------------------------------------------------------------------
            #
            #	if( $l_vlan_coe && ! $mac_coe ) {
            #       my %p = ();
            #       $p{$DB_COL_DME_MACID} = $macid;
            #       if( !$mysql->get_coe_mac_exception(\%p)) {
            #		next;
            #	    }
            #       $mac_coe_ticketref = $p{$DB_COL_DME_TICKETREF};
            #	}
            #

            # Track for later, if no locations match then there is an error
            if ( $l_classname eq $CLASS_NAME_BLOCK ) {
                $eventtype = EVENT_AUTH_BLOCK;
            }
            elsif ( $l_classname eq $CLASS_NAME_CHALLENGE ) {
                $eventtype = EVENT_AUTH_CHALLENGE;
            }
            elsif ( ( $l_classname eq $CLASS_NAME_GUEST )
                || ( $l_classname eq $CLASS_NAME_GUESTFALLBACK )
                || ( $l_classname eq $CLASS_NAME_GUESTCHALLENGE ) ) {
                $eventtype = EVENT_AUTH_GUEST;
            }
            elsif ( $l_vlantype =~ /^VOICE/ ) {
                $mac_rule_found++;
                $voice     = 1;
                $eventtype = EVENT_AUTH_VOICE;
            }
            elsif ( $l_authtype =~ /^MAC/ ) {
                $mac_rule_found++;
                $eventtype = EVENT_AUTH_MAC;
            }
            elsif ( $l_authtype =~ /^PORT/ ) {
                $eventtype = EVENT_AUTH_PORT;
            }
            else {
                $eventtype = EVENT_CHALLENGE_ERR;
                EventLog( EVENT_ERR, MYNAMELINE() . "VLANID:'$l_vlanid': CLASS:'$l_classname' VLANTYPE:'$l_vlantype' AUTHTYPE:'$l_authtype'" );
                next;
            }

            # EventLog( EVENT_INFO, MYNAMELINE() . "EVENT TYPE $eventtype" );

            if ( ( isdigit($l_vlanid) ) && ( isdigit($vlan) ) && ( $l_vlan > 1 ) && ( $l_vlan < 4096 ) ) {
                $authtype    = $l_authtype;
                $classid     = $l_classid;
                $classname   = $l_classname;
                $vlan        = $l_vlan;
                $vlanid      = $l_vlanid;
                $vlanname    = $l_vlanname;
                $vlantype    = $l_vlantype;
                $reauthtime  = $l_reauthtime;
                $idletimeout = $l_idletimeout;
                $vgid        = $l_vgid;
                $vgname      = $l_vgname;
                $tempid      = $l_tempid;
                $tempname    = $l_tempname;
                EventLog( EVENT_INFO, " ->FOUND SORT:$sortpri PRI:$l_pri SUB:$l_subpri RAND:$l_randpri AUTH:$l_authtype VLANTYPE:$l_vlantype" );

                if ( $l_vlan_coe && !$mac_coe ) {
                    eval {
                        my %p = ();
                        $p{$DB_COL_DME_MACID} = $macid;
                        if ( $self->dbr->get_coe_mac_exception( \%p ) ) {
                            $mac_coe_ticketref = $p{$DB_COL_DME_TICKETREF};
                            EventLog( EVENT_INFO, " ->COE VLAN EXCEPTION FOUND TICKET:'$mac_coe_ticketref' MAC:$mac VLAN:$vlanname" );
                        }
                        else {
                            EventLog( EVENT_WARN, " ->COE WARNING ** NON-COE MAC:$mac on COE VLAN:$vlanname" );
                        }
                    };
                    LOGEVALFAIL if ($@);
                }
                elsif ($l_vlan_coe) {
                    EventLog( EVENT_INFO, " ->COE VLAN ASSIGNMENT MAC:$mac VLAN:$vlanname" );
                }

                last;

            }
            else {
                EventLog( EVENT_WARN, MYNAMELINE() . " ->SKIP $event_hdr, skip record, VLANID:'$l_vlanid', VLAN:'$l_vlan'" );
                next;
            }
        }
    }

    # EventLog( EVENT_INFO, MYNAMELINE() . "VLAN VERIFIED $vlan" );

    # ********
    # Step 4 )
    # ********
    # Get Challenge VLAN Here and return it.
    # VLANGROUPNAME
    # LOCID
    # -> VLANID

    if ( !$vlanid && $locid ) {

        EventLog( EVENT_WARN, "$event_hdr No VLAN found!, goto CHALLENGE" );

        %parm = ();
        $parm{$DB_COL_VG_NAME} = $VG_NAME_CHALLENGE;

        # $parm{$DB_COL_VG_NAME} = $VG_NAME_GUESTCHALLENGE;

        if ( $DBHR->get_vlangroup( \%parm ) ) {
            my %results;
            my $challenge_vgid = $parm{$DB_COL_VG_ID};

            %parm                     = ();
            $parm{$DB_COL_VG2V_VGID}  = $challenge_vgid;
            $parm{$DB_COL_VLAN_LOCID} = $locid;
            $parm{$HASH_REF}          = \%results;

            if ( $DBHR->get_vlan_for_locid_vlangroupid( \%parm ) ) {
                foreach my $r ( keys(%results) ) {
                    if ( $results{$r}->{$DB_COL_VLAN_ACT} ) {
                        $vlanid   = $r;
                        $vlan     = $results{$r}->{$DB_COL_VLAN_VLAN};
                        $vlanname = $results{$r}->{$DB_COL_VLAN_NAME};
                        my $msg = "$event_hdr -> CHALLENGE VLAN:'$vlanname' LOCID:'$locid'";
                        $eventtype = EVENT_AUTH_CHALLENGE;
                        EventLog( EVENT_NOTICE, $msg );
                    }
                    else {
                        EventLog( EVENT_INFO, "$event_hdr Skipping INACTIVE VLAN $results{$r}" );
                    }
                }
            }
        }
        else {

            # my $msg = "$event_hdr Could not find 'CHALLENGE VLAN ID' for Switch at LOCID: $locid";
            # EventLog( EVENT_LOGIC_FAIL, $msg );
        }
    }

    # Failed, no vlanid found, return '1'
    if ( !$vlanid ) {

        EventLog( EVENT_INFO, MYNAMELINE() . "NO VLANID " );

        $eventtype = 'EVENT_CHALLENGE_ERR';
        my $idle_timeout    = $MINIMUM_IDLE_TIMEOUT;
        my $session_timeout = $MINIMUM_SESSION_TIMEOUT;
        $p->{rp}->add_attr( 'Session-Timeout',         $session_timeout );
        $p->{rp}->add_attr( 'Idle-Timeout',            $idle_timeout );
        $p->{rp}->add_attr( 'Termination-Action',      'RADIUS-Request' );
        $p->{rp}->add_attr( 'Tunnel-Type',             13 );
        $p->{rp}->add_attr( 'Tunnel-Medium-Type',      6 );
        $p->{rp}->add_attr( 'Tunnel-Private-Group-ID', 1 );

        my $msg = "$event_hdr VLAN:X-X-1-X VG: TYPE: CLASS: RE: No Challenge Network";

        EventLog( $eventtype, $msg );

        my %state = ();
        $state{$DB_COL_BUF_SWPS_SWPID} = $switchportid;
        $state{EVENT_PARM_TYPE}        = 'EVENT_CHALLENGE_ERR';
        $state{EVENT_PARM_MACID}       = $macid;
        $state{EVENT_PARM_SWPID}       = $switchportid;
        $state{EVENT_PARM_CLASSID}     = $classid;
        $state{EVENT_PARM_TEMPID}      = $tempid;
        $state{EVENT_PARM_VGID}        = $vgid;
        $state{EVENT_PARM_VLANID}      = $vlanid;
        $state{EVENT_PARM_DESC}        = $msg;

        if ($voice) {
            $state{$DB_COL_BUF_SWPS_VMACID}   = $macid;
            $state{$DB_COL_BUF_SWPS_VMAC}     = $mac;
            $state{$DB_COL_BUF_SWPS_VCLASSID} = 0;
            $state{$DB_COL_BUF_SWPS_VTEMPID}  = 0;
            $state{$DB_COL_BUF_SWPS_VVGID}    = 0;
            $state{$DB_COL_BUF_SWPS_VVLANID}  = -1;

            eval {
                $DBHW->set_voice_switchportstate( \%state );
            };
            LOGEVALFAIL if ($@);
        }
        else {
            $state{$DB_COL_BUF_SWPS_MACID}   = $macid;
            $state{$DB_COL_BUF_SWPS_MAC}     = $mac;
            $state{$DB_COL_BUF_SWPS_CLASSID} = 0;
            $state{$DB_COL_BUF_SWPS_TEMPID}  = 0;
            $state{$DB_COL_BUF_SWPS_VGID}    = 0;
            $state{$DB_COL_BUF_SWPS_VLANID}  = -1;
            eval {
                $DBHW->set_data_switchportstate( \%state );
            };
            LOGEVALFAIL if ($@);
        }

        EventLog( EVENT_INFO, MYNAMELINE() . "RETURN VLAN1 " );

        $self->adjustReply($p);
        return ( $main::ACCEPT, "No VLAN Found, Using VLAN1" );

        #
        # RETURN VLAN 1 - RETURN 'SUCCESS' but it is a FAILURE
        #

    }

    # ********
    # Step 5 )
    # ********

    #
    # Set Reauthentication parameter
    # This is Session-Timeout Attr[27] -> (3600)
    #
    my $session_timeout = ($reauthtime) ? $reauthtime : $DEFAULT_SESSION_TIMEOUT;
    $session_timeout = $session_timeout - int( rand( $session_timeout * REAUTHPERCENT / 100 ) );

    # Set the min to 1 min.
    if ( $session_timeout < $MINIMUM_SESSION_TIMEOUT ) {
        $session_timeout = $MINIMUM_SESSION_TIMEOUT;
    }

    $p->{rp}->add_attr( 'Session-Timeout', $session_timeout );

    #
    # Set  Idle Parameter
    # This is Idle-Timeout Attr[28] -> (21000)
    #
    my $idle_timeout = ($idletimeout) ? $idletimeout : $DEFAULT_IDLE_TIMEOUT;
    $p->{rp}->add_attr( 'Idle-Timeout', $idle_timeout );

    #
    # Terminate Action
    # This is Terminate-Action Attr[29] -> 'RADIUS-Request'
    # This tell the switch what to do when the timer expires, which is to immediatly reauthenticate
    #
    $p->{rp}->add_attr( 'Termination-Action', 'RADIUS-Request' );

    #
    # Set VLAN ID HERE
    #
    # This 'VLAN' Attr[64] -> (13)
    $p->{rp}->add_attr( 'Tunnel-Type', 13 );

    # This is IEEE-802 Attr[] -> (6)
    $p->{rp}->add_attr( 'Tunnel-Medium-Type', 6 );

    # This is the VLAN identifier
    $p->{rp}->add_attr( 'Tunnel-Private-Group-ID', $vlan );

    my $msg = '';
    if ($voice) {
        $p->{rp}->add_attr( 'cisco-avpair', 'device-traffic-class=voice' );
        $msg = "HOST:$hostname VOICE MAC:$mac SW:$switchname PORT:$portname VLAN:$vlanname - $vlan - VG:$vgname TYPE:$authtype CLASS:$classname";
    }
    else {
        $msg = "HOST:$hostname MAC:$mac SW:$switchname PORT:$portname VLAN:$vlanname VG:$vgname TYPE:$authtype CLASS:$classname";
    }

    my %s = ();
    $s{$DB_COL_BUF_SWPS_SWPID} = $switchportid;
    if ($voice) {
        $s{$DB_COL_BUF_SWPS_VMACID}   = $macid;
        $s{$DB_COL_BUF_SWPS_VMAC}     = $mac;
        $s{$DB_COL_BUF_SWPS_VCLASSID} = $classid;
        $s{$DB_COL_BUF_SWPS_VTEMPID}  = $tempid;
        $s{$DB_COL_BUF_SWPS_VVGID}    = $vgid;
        $s{$DB_COL_BUF_SWPS_VVLANID}  = $vlanid;
    }
    else {
        $s{$DB_COL_BUF_SWPS_MACID}   = $macid;
        $s{$DB_COL_BUF_SWPS_MAC}     = $mac;
        $s{$DB_COL_BUF_SWPS_CLASSID} = $classid;
        $s{$DB_COL_BUF_SWPS_TEMPID}  = $tempid;
        $s{$DB_COL_BUF_SWPS_VGID}    = $vgid;
        $s{$DB_COL_BUF_SWPS_VLANID}  = $vlanid;
    }
    $s{EVENT_PARM_TYPE}    = $eventtype;
    $s{EVENT_PARM_SWPID}   = $switchportid;
    $s{EVENT_PARM_SWID}    = $switchid;
    $s{EVENT_PARM_MACID}   = $macid;
    $s{EVENT_PARM_CLASSID} = $classid;
    $s{EVENT_PARM_TEMPID}  = $tempid;
    $s{EVENT_PARM_VGID}    = $vgid;
    $s{EVENT_PARM_VLANID}  = $vlanid;
    $s{EVENT_PARM_DESC}    = $msg;

    eval {
        if ($voice) {
            $DBHW->set_voice_switchportstate( \%s );
        }
        else {
            $DBHW->set_data_switchportstate( \%s );
        }
    };
    LOGEVALFAIL if ($@);

    EventLog( EVENT_INFO, "$eventtype: $mac $switchname $portname --> RETURN VLAN:$vlan VLANTYPE:$vlantype" );

    $self->adjustReply($p);
    return ( $main::ACCEPT, "Accepted - VLAN:$vlan" );

    #
    # RETURN SUCCESS
    #

}
1;

