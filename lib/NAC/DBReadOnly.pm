#!/usr/bin/perl
# SVN: $Id: NACDBReadOnly.pm 1525 2012-10-12 13:34:59Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-12 09:34:59 -0400 (Fri, 12 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/DBReadOnly.pm $:
#
#
#
# Author: Sean McAdam
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBReadOnly;
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Carp qw(confess cluck);
use POSIX;
use NAC::DB2;
use NAC::DBSql;
use NAC::DBConsts;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use NAC::Misc;
use strict;

our @ISA = qw ( NAC::DB2 );

#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
#---------------------------------------------------------------------------
sub new() {
    my ($class) = @_;
    my $self = shift;

    EventLog( EVENT_START, MYNAME . "() started" );

    eval {
        my %parms  = ();
        my $config = NAC::ConfigDB->new();

        $parms{$SQL_DB}        = $config->nac_local_readonly_db;
        $parms{$SQL_HOST}      = $config->nac_local_readonly_hostname;
        $parms{$SQL_PORT}      = $config->nac_local_readonly_port;
        $parms{$SQL_USER}      = $config->nac_local_readonly_user;
        $parms{$SQL_PASS}      = $config->nac_local_readonly_pass;
        $parms{$SQL_READ_ONLY} = 1;
        $parms{$SQL_CLASS}     = $class;

        $self = $class->SUPER::new( \%parms );

    };
    if ($@) {
        LOGEVALFAIL();
        confess( MYNAMELINE . "$@" );
    }

    bless $self, $class;
}

