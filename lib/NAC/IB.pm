#!/usr/bin/perl
# SVN: $Id: NACDB.pm 1406 2012-05-06 00:18:59Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-05-05 20:18:59 -0400 (Sat, 05 May 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/IB.pm $:
#
#
#
# Author: Sean McAdam
#
#
# Purpose: Provide controlled access to the Infoblox devices
#
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
package NAC::IB;
use lib "$ENV{HOME}/lib/perl5";
use base qw( Exporter );

#use Infoblox;
use Carp;
use warnings;
use Data::Dumper;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use strict;

#---------------------------------
sub get_default_view_object();
sub IBGetAllFixedAddrObjects($);
sub IBGetAllLeaseObjects($);
sub IBGetAllNetworkObjects($);
sub IBGetAllRangeObjects($);
sub IBGetAllSharedNetworkObjects($);
sub IBGetLeaseObjectsByMAC($);
sub IBGetLeaseObjectsByIP($);
sub IBGetFixedAddrObjectsByMAC($);
sub IBGetFixedAddrObjectsByIP($);
sub IBGetEA($);
sub IBSearchEA($);
sub IBOpen();
sub IBRemoveObj($);

#---------------------------------
# These may go away, they are used for legacy IB filters, that were never really turned on
#
use constant IBTIMEOUT => 180;

our @EXPORT = qw (
  IBGetAllFixedAddrObjects
  IBGetAllNetworkObjects
  IBGetAllRangeObjects
  IBGetAllSharedNetworkObjects
  IBGetAllLeaseObjects
  IBGetLeaseObjectsByMAC
  IBGetLeaseObjectsByIP
  IBGetFixedAddrObjectsByMAC
  IBGetFixedAddrObjectsByIP
  IBGetEA
  IBSearchEA
  IBOpen
  IBRemoveObj
  IBModifyObj
);

my $err_txt = '';
my $session = undef;

#-----------------------------------------------------------
sub IBOpen() {
    my $ret = 0;
    $err_txt = '';

    my $config = NACConfigDB->new();

    my $server = $config->get_infoblox_server();
    my $user   = $config->get_infoblox_user;
    my $pass   = $config->get_infoblox_pass;

    if ( !defined $server || $server eq '' ) {
        confess "Bad IB Server defined '$server'";
    }
    if ( !defined $user || $user eq '' ) {
        confess "Bad IB Username defined '$user'";
    }
    if ( !defined $pass || $pass eq '' ) {
        confess "Bad IB Password defined 'xxxxx'";
    }

    # EventLog( EVENT_INFO, MYNAMELINE . "IB Connection to '$server'" );

    eval {
        $session = Infoblox::Session->new(
            "master"   => $server,
            "username" => $user,
            "password" => $pass,
            "timeout"  => IBTIMEOUT,
        );

        if ( !$session ) {
            $err_txt =
              'Infoblox object creation failed '
              . Infoblox::status_code() . ": "
              . Infoblox::status_detail();
            confess $err_txt;
        }

        if ( $session->status_code() ) {
            $err_txt =
              'Infoblox returned error '
              . $session->status_code() . ": "
              . $session->status_detail();

            # print Dumper $ret;
            confess $err_txt;
        }

        if ( !$session->server_version() ) {
            $err_txt =
              MYNAME . "()"
              . "Error: connecting to Infoblox, check your user ID and password\n"
              . "status_code:"
              . Infoblox::status_code() . "\n"
              . "status_detail:"
              . Infoblox::status_detail();
            confess $err_txt;
        }

        $ret = $session;

    };    # EVAL
    if ($@) {
        $err_txt = "EVAL Failed in " . MYNAME . ": $@";
        $ret     = 0;
        $session = undef;
    }

    if ( !$ret ) {
        EventLog( EVENT_ERR,
            "Error opening up Infoblox, Server: '$server', User: '$user', $err_txt"
        );
        print "$err_txt\n";
    }

    return $ret;
}

#-----------------------------------------------------------
sub IBGetAllNetworkObjects($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'ARRAY'} || $parm->{'ARRAY'} eq '' ) { confess; }
    my $arr_ref = $parm->{'ARRAY'};

    eval {

        @$arr_ref = $session->search(
            object  => "Infoblox::DHCP::Network",
            network => "1.*",

            #        network_view => $nview,
            network_view => "default",
        );

        if ( $session->status_code() ) {
            confess MYNAME . "() "
              . $session->status_code() . ":"
              . $session->status_detail() . "\n";
        }

        $ret = scalar(@$arr_ref);

    };    # EVAL
    if ($@) {
        confess "EVAL Failed in " . MYNAME . ": $@";
    }

    # Error handling here

    $ret;
}

#-----------------------------------------------------------
sub IBGetAllRangeObjects($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'ARRAY'} || $parm->{'ARRAY'} eq '' ) { confess; }
    my $arr_ref = $parm->{'ARRAY'};

    eval {

        @$arr_ref = $session->search(
            object => "Infoblox::DHCP::Range",

            # network => "1.*",
            # network_view => $nview,
            network_view => "default",
        );

        if ( $session->status_code() ) {
            confess MYNAME . "() "
              . $session->status_code() . ":"
              . $session->status_detail() . "\n";
        }

        $ret = scalar(@$arr_ref);

    };    # EVAL
    if ($@) {
        confess "EVAL Failed in " . MYNAME . ": $@";
    }

    # Error handling here

    $ret;
}

#-----------------------------------------------------------
sub IBGetAllSharedNetworkObjects($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'ARRAY'} || $parm->{'ARRAY'} eq '' ) { confess; }
    my $arr_ref = $parm->{'ARRAY'};

    @$arr_ref = $session->search(
        object => "Infoblox::DHCP::SharedNetwork",
        name   => ".*",

        #   network_view => "default"
    );

    # Error handling here
    if ( $session->status_code() ) {
        confess $session->status_code() . ":"
          . $session->status_detail() . "\n";
    }

    $ret = scalar(@$arr_ref);

    $ret;

}

#-----------------------------------------------------------
sub IBGetAllFixedAddrObjects($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'ARRAY'} || $parm->{'ARRAY'} eq '' ) { confess; }

    my $arr_ref = $parm->{'ARRAY'};

    my ($nview) = $session->get(
        object => "Infoblox::DHCP::View",
        name   => 'default',
    );

    @$arr_ref = $session->search(
        object => "Infoblox::DHCP::FixedAddr",

        #   network      => "1.*",
        network_view => $nview,
    );

    if ( $session->status_code() ) {
        EventLog( EVENT_FATAL,
            MYNAMELINE
              . $session->status_code() . ":"
              . $session->status_detail() );
        confess;
    }

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
sub IBGetLeaseObjectsByMAC($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'MAC'} || $parm->{'MAC'} eq '' ) { confess; }
    if ( !defined $parm->{'ARRAY'} ) { confess; }
    my $mac     = $parm->{'MAC'};
    my $arr_ref = $parm->{'ARRAY'};

    my ($nview) = $session->get(
        object => "Infoblox::DHCP::View",
        name   => 'default',
    );

    @$arr_ref = $session->search(
        object => "Infoblox::DHCP::Lease",
        mac    => $mac,
    );

    # network_view => $nview,

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
sub IBGetLeaseObjectsByIP($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'IP'} || $parm->{'IP'} eq '' ) { confess; }
    if ( !defined $parm->{'ARRAY'} ) { confess; }
    my $ip      = $parm->{'IP'};
    my $arr_ref = $parm->{'ARRAY'};

    my ($nview) = $session->get(
        object => "Infoblox::DHCP::View",
        name   => 'default',
    );

    @$arr_ref = $session->search(
        object       => "Infoblox::DHCP::Lease",
        ipv4addr     => $ip,
        network_view => $nview,
    );

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
sub IBGetFixedAddrObjectsByMAC($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'MAC'} || $parm->{'MAC'} eq '' ) { confess; }
    if ( !defined $parm->{'ARRAY'} ) { confess; }
    my $mac     = $parm->{'MAC'};
    my $arr_ref = $parm->{'ARRAY'};

    my ($nview) = $session->get(
        object => "Infoblox::DHCP::View",
        name   => 'default',
    );

    @$arr_ref = $session->search(
        object       => "Infoblox::DHCP::FixedAddr",
        mac          => $mac,
        network_view => $nview,
    );

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
#
# IB software does not return a single record when you search or get... it is borken.
#
#-----------------------------------------------------------
sub IBGetFixedAddrObjectsByIP($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'IP'} || $parm->{'IP'} eq '' ) { confess; }
    if ( !defined $parm->{'ARRAY'} ) { confess; }
    my $ip      = $parm->{'IP'};
    my $arr_ref = $parm->{'ARRAY'};

    my ($nview) = $session->get(
        object => "Infoblox::DHCP::View",
        name   => 'default',
    );

    @$arr_ref = $session->get(
        object       => "Infoblox::DHCP::FixedAddr",
        ipv4addr     => $ip,
        network_view => $nview,
    );

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
sub IBGetAllLeaseObjects($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'ARRAY'} || $parm->{'ARRAY'} eq '' ) { confess; }
    my $arr_ref = $parm->{'ARRAY'};

    my $ipv4addr = "^1*";
    @$arr_ref = $session->search(
        object   => "Infoblox::DHCP::Lease",
        ipv4addr => $ipv4addr,
    );

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
sub IBRemoveObj($) {
    my $obj = shift;
    my $ret = 0;
    $session->remove($obj);
    if ( !$session->status_code() ) {
        $ret = 1;
    }

    $ret;
}

#-----------------------------------------------------------
sub IBModifyObj($) {
    my $obj = shift;
    my $ret = 0;
    $session->modify($obj);
    if ( !$session->status_code() ) {
        $ret = 1;
    }

    $ret;
}

#-----------------------------------------------------------
sub IBSearchEA($) {
    my $parm = shift;
    my $ret  = 0;

    confess "Work this function some more";

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'ARRAY'} || $parm->{'ARRAY'} eq '' ) { confess; }
    my $arr_ref = $parm->{'ARRAY'};

    my @arr_ref = $session->search(
        object => "Infoblox::Grid::ExtensibleAttributeDef",
        name   => 'SITE.*',
    );

    if ( $session->status_code() ) {
        confess MYNAME . "() "
          . $session->status_code() . ":"
          . $session->status_detail() . "\n";
    }

    $ret = scalar(@$arr_ref);

    $ret;
}

#-----------------------------------------------------------
sub IBGetEA($) {
    my $parm = shift;
    my $ret  = 0;

    if ( !defined $session ) { confess "No session created yet for " . MYNAME; }
    if ( !defined $parm )    { confess; }
    if ( ref($parm) ne 'HASH' ) { confess; }
    if ( !defined $parm->{'EA_NAME'} || $parm->{'EA_NAME'} eq '' ) { confess; }
    my $name = $parm->{'EA_NAME'};

    my $ea = $session->get(
        object => "Infoblox::Grid::ExtensibleAttributeDef",
        name   => $name,
    );

    if ( $session->status_code() ) {
        confess MYNAME . "() "
          . $session->status_code() . ":"
          . $session->status_detail() . "\n";
    }

    $ea;
}

#-----------------------------------------------------------
sub get_default_view_object() {

    return Infoblox::DHCP::View->new( name => 'default', );

}

1;
