#!/usr/bin/perl
# SVN: $Id: NACDBMagic.pm 1529 2012-10-13 17:22:52Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-13 13:22:52 -0400 (Sat, 13 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBMagic.pm $:
#
#
#
# Author: Sean McAdam
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBMagic;
use lib "$ENV{HOME}/lib/perl5";

use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Carp qw(confess cluck);
use POSIX;
use NAC::Syslog;
use NAC::Constants;
use NAC::DBConsts;
use NAC::ConfigDB;
use NAC::DBAudit;
use NAC::DBReadOnly;
use NAC::DBBuffer;
use strict;

Readonly our $MAGIC_DB  => 'MAGIC_DB';
Readonly our $MAGIC_RO  => 'MAGIC_RO';
Readonly our $MAGIC_BUF => 'MAGIC_BUF';

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub new() {
    my ( $class, $parm_ref ) = @_;
    my $self;

    if ( ( defined $parm_ref ) && ( ref($parm_ref) ne 'HASH' ) ) { confess; }

    EventLog( EVENT_START, MYNAME . "() started" );

    $self = {
        $MAGIC_DB  => NAC::DBAudit->new(),
        $MAGIC_RO  => NAC::DBReadOnly->new(),
        $MAGIC_BUF => NAC::DBBuffer->new(),
    };

    bless $self, $class;

    $self;
}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub DB {
    my ($self) = @_;

    if ( !defined( $self->{$MAGIC_DB} ) ) {
        confess;
    }

    if ( !$self->{$MAGIC_DB}->sql_connected() ) {
        if ( !( $self->{$MAGIC_DB}->connect ) ) {
            return 0;
        }
    }

    return $self->{$MAGIC_DB};
}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub RO {
    my ($self) = @_;

    if ( !defined( $self->{$MAGIC_RO} ) ) {
        confess;
    }

    # print Dumper $self;

    if ( !$self->{$MAGIC_RO}->sql_connected() ) {
        if ( !( $self->{$MAGIC_RO}->connect ) ) {
            return 0;
        }
    }

    return $self->{$MAGIC_RO};
}

#---------------------------------------------------------------------------
#
#---------------------------------------------------------------------------
sub BUF {
    my ($self) = @_;

    if ( !defined( $self->{$MAGIC_BUF} ) ) {
        confess;
    }

    if ( !$self->{$MAGIC_BUF}->sql_connected() ) {
        if ( !( $self->{$MAGIC_BUF}->connect ) ) {
            return 0;
        }
    }

    return $self->{$MAGIC_BUF};
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
sub check_magic_port {
    my ( $self, $swpid, $macid ) = @_;
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

    if ( !defined $swpid || ( !isdigit($swpid) ) ) { confess Dumper $swpid; }
    if ( !defined $macid || ( !isdigit($macid) ) ) { confess Dumper $macid; }

    EventLog( EVENT_DEBUG, MYNAMELINE() . " MAGIC PORT Called" );

    %magic_parm                      = ();
    $magic_parm{$DB_COL_MAGIC_SWPID} = $swpid;
    $magic_parm{$HASH_REF}           = \%new_magic;
    if ( !$self->RO->get_magicport( \%magic_parm ) ) {
        EventLog( EVENT_DEBUG, MYNAMELINE() . " SWPID: $swpid not found" );
        return $ret;
    }

    %mac_parm = ();
    $mac_parm{$DB_COL_MAC_ID} = $macid;
    if ( !$self->RO->get_mac( \%mac_parm ) ) {
        EventLog( EVENT_INFO, MYNAMELINE() . " MACID: $macid not found" );
        return $ret;
    }

    #
    # Check to see if MAC is already online and active
    # Only Magicport the MAC if it is just coming online, otherwise it is just reauthing on the port
    #
    %swps_parm = ();
    $swps_parm{$DB_COL_BUF_SWPS_MACID} = $macid;
    if ( $self->BUF->get_switchportstate( \%swps_parm ) ) {
        EventLog( EVENT_INFO, MYNAMELINE() . "SKIP MAGIC PORT MACID: $macid already online in SWPID:" . $swps_parm{$DB_COL_SWPS_SWPID} );
        return $ret;
    }

    #
    # Get Switch Name
    #
    %swp_parm = ();
    $swp_parm{$DB_COL_SWP_ID} = $swpid;
    if ( $self->RO->get_switchport( \%swp_parm ) ) {
        $swpname                = $swp_parm{$DB_COL_SWP_NAME};
        $swid                   = $swp_parm{$DB_COL_SWP_SWID};
        $sw_parm{$DB_COL_SW_ID} = $swid;
        if ( $self->RO->get_switch( \%sw_parm ) ) {
            $swname = $sw_parm{$DB_COL_SW_NAME};
        }
        else {
            $self->BUF->EventDBLog( {
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

    #
    # Verify that the Database is accessable
    #
    if ( !( $self->DB->force_reconnect ) ) {
        $self->BUF->EventDBLog( {
                $EVENT_PARM_PRIO  => EVENT_ERR,
                $EVENT_PARM_TYPE  => EVENT_MAGIC_PORT,
                $EVENT_PARM_MACID => $macid,
                $EVENT_PARM_SWPID => $swpid,
                $EVENT_PARM_SWID  => $swid,
                $EVENT_PARM_DESC  => "Database Unavailable, Skipping...",
        } );
        EventLog( EVENT_INFO, MYNAMELINE() . "SKIP MAGIC PORT Main DB Not Avaialble" );
        return $ret;
    }

    #
    # We Are going in!
    #
    $comment .= "SW:$swname PORT:$swpname";

    $self->BUF->EventDBLog( {
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
        if ( $self->DB->get_mac2class( \%parm ) ) {

            # Replace, so remove existing M2C Records
            my %rm_parm = ();
            $rm_parm{$DB_COL_M2C_MACID} = $macid;
            if ( !$self->DB->remove_mac2class( \%rm_parm ) ) {
                $self->BUF->EventDBLog( {
                        $EVENT_PARM_PRIO  => EVENT_ERR,
                        $EVENT_PARM_TYPE  => EVENT_MAGIC_PORT,
                        $EVENT_PARM_MACID => $macid,
                        $EVENT_PARM_SWPID => $swpid,
                        $EVENT_PARM_DESC  => "Failed to remove mac2class settings for MAGIC_PORT operation on " . $mac_parm{$DB_COL_MAC_ID},
                } );
                goto DONE;
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
            $self->BUF->EventDBLog( {
                    $EVENT_PARM_PRIO  => EVENT_ERR,
                    $EVENT_PARM_TYPE  => EVENT_MAGIC_PORT,
                    $EVENT_PARM_MACID => $macid,
                    $EVENT_PARM_SWPID => $swpid,
                    $EVENT_PARM_DESC  => "No CLASSID defined for MAGICID: $magicid, SWPID: $swpid, on MACID: $macid",
            } );
            goto DONE;
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
        if ( $self->RO->get_mac2class( \%parm ) ) {

            # Append it to the priority list
            foreach my $id ( keys(%m2c) ) {
                my $p = $m2c{$id}->{$DB_COL_M2C_PRI};

                if ( $pri <= $p ) {
                    $pri = $p + 1;
                }

                if ( $classid == $m2c{$id}->{$DB_COL_M2C_CLASSID} ) {
                    if ($tempid) {
                        if ( $tempid == $m2c{$id}->{$DB_COL_M2C_TEMPID} ) {
                            print "SKIP - TEMPID DUPLICATE " . Dumper $m2c{$id};
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

        if ( !$self->DB->add_mac2class( \%newm2c ) ) {
            $self->BUF->EventDBLog( {
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
            $ret = 0;
            goto DONE;
        }
        else {
            $self->BUF->EventDBLog( {
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

    if ($ret) {

        my $date    = NACMisc::get_current_timestamp();
        my $comment = "MAGICPORTed at $date";
        my %p       = ();
        $p{$DB_COL_MAC_ID}  = $macid;
        $p{$DB_COL_MAC_COM} = $comment;
        $self->DB->update_mac_comment_insert( \%p );
    }

  DONE:

    return $ret;
}

1;
