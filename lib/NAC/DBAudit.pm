#!/usr/bin/perl
# SVN: $Id: NACDB.pm 1529 2012-10-13 17:22:52Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-13 13:22:52 -0400 (Sat, 13 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBAudit.pm $:
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

package NAC::DBAudit;
use FindBin;
use lib "$FindBin::Bin/..";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Sys::Syslog qw(:standard :macros);
use Carp qw(confess cluck);
use lib qw( /opt/nac/lib );
use NAC::DB2;
use NAC::DBSql;
use NAC::DBConsts;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use NAC::Misc;
use strict;

our @ISA = qw(NAC::DB2);

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

    my %parms = ();
    my $config = NAC::ConfigDB->new() || return 0;

    $parms{$SQL_DB}    = $config->nac_master_write_db_audit;
    $parms{$SQL_HOST}  = $config->nac_master_write_hostname;
    $parms{$SQL_PORT}  = $config->nac_master_write_port;
    $parms{$SQL_USER}  = $config->nac_master_write_user;
    $parms{$SQL_PASS}  = $config->nac_master_write_pass;
    $parms{$SQL_CLASS} = $class;

    $self = $class->SUPER::new( \%parms );

    bless $self, $class;

    $self;
}

