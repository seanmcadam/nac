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
package NAC::IBWAPI;
use FindBin;
use lib "$FindBin::Bin/..";

use base qw( Exporter );

use Carp;
use warnings;
use Data::Dumper;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use Readonly;
use strict;

Readonly our $IB_USERID => 'IB-USERID';
Readonly our $IB_PASSWORD => 'IB-PASSWORD';
Readonly our $IB_HOSTNAME => 'IB-HOSTNAME';

#---------------------------------------------------------------------------
sub new() {
    my $class    = shift;
    my $parm_ref = shift;
    my $self;
    my %h;
    $self = \%h;

    EventLog( EVENT_DEBUG, MYNAME . "() started" );

    my $config = NAC::ConfigDB->new();
	$self->{$IB_USERID} = $config->nac_ib_user;
	$self->{$IB_PASSWORD} = $config->nac_ib_pass;
	$self->{$IB_HOSTNAME} = $config->nac_ib_hostname;

    bless $self, $class;

    $self;
}



#-----------------------------------------------------------



1;
