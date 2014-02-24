#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: 1750 $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/Syslog.pm $:
#
#
# Author: Sean McAdam
# Purpose: Provide standaed Logging and alert system
#
#---------------------------------------------------------------------------
#
#
#---------------------------------------------------------------------------

package NAC::Syslog;
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Sys::Syslog qw(:standard :macros);
use Sys::Hostname;
use Data::Dumper;
use Carp;
use warnings;
use POSIX;
use NAC::Constants;
use strict;

#------------
# LOG_EMERG
# LOG_ALERT
# LOG_CRIT
# LOG_ERR
# LOG_WARNING
# LOG_NOTICE
# LOG_INFO
# LOG_DEBUG
#------------

sub MYNAME;
sub MYNAMELINE;
sub LOGEVALFAIL;
sub EventLog($$;$);

my $PRINT_DEBUG  = 0;
my $PRINT_LOG    = 1;          # By default log to Syslog
my $PRINT_STDOUT = 0;
my $PRINT_HTML   = 0;
my $PRINT_STDERR = 0;
my $hostname     = hostname;

#--------------------------------------------------------------------------------

#--------------------------------------------------------------------------------
use constant {
};

our @EXPORT = qw (
  MYNAME
  MYNAMELINE
  LOGEVALFAIL
  EventLog
  ActivateDebug
  DeactivateDebug
  ActivateSyslog
  DeactivateSyslog
  ActivateStdout
  DeactivateStdout
  ActivateStderr
  DeactivateStderr
  ActivateHTML
);

# Default is LOG_INFO
my %type_2_prio = ();
$type_2_prio{EVENT_START}              = LOG_NOTICE;
$type_2_prio{EVENT_AUTH_CHALLENGE}     = LOG_NOTICE;
$type_2_prio{EVENT_CIDR_ADD}           = LOG_NOTICE;
$type_2_prio{EVENT_CIDR_DEL}           = LOG_NOTICE;
$type_2_prio{EVENT_FIXEDIP_ADD}        = LOG_NOTICE;
$type_2_prio{EVENT_FIXEDIP_DEL}        = LOG_NOTICE;
$type_2_prio{EVENT_FIXEDIP_UPD}        = LOG_NOTICE;
$type_2_prio{EVENT_LOC_ADD}            = LOG_NOTICE;
$type_2_prio{EVENT_LOC_DEL}            = LOG_NOTICE;
$type_2_prio{EVENT_MAC_ADD}            = LOG_NOTICE;
$type_2_prio{EVENT_MAC_DEL}            = LOG_NOTICE;
$type_2_prio{EVENT_MAC_UPD}            = LOG_NOTICE;
$type_2_prio{EVENT_MAC2CLASS_ADD}      = LOG_NOTICE;
$type_2_prio{EVENT_MAC2CLASS_DEL}      = LOG_NOTICE;
$type_2_prio{EVENT_MAC2CLASS_UPD}      = LOG_NOTICE;
$type_2_prio{EVENT_SWITCH_ADD}         = LOG_NOTICE;
$type_2_prio{EVENT_SWITCH_DEL}         = LOG_NOTICE;
$type_2_prio{EVENT_SWITCH_UPD}         = LOG_NOTICE;
$type_2_prio{EVENT_SWITCHPORT_ADD}     = LOG_NOTICE;
$type_2_prio{EVENT_SWITCHPORT_DEL}     = LOG_NOTICE;
$type_2_prio{EVENT_SWITCH2VLAN_ADD}    = LOG_NOTICE;
$type_2_prio{EVENT_SWITCH2VLAN_DEL}    = LOG_NOTICE;
$type_2_prio{EVENT_VLAN_ADD}           = LOG_NOTICE;
$type_2_prio{EVENT_VLAN_DEL}           = LOG_NOTICE;
$type_2_prio{EVENT_VLANGROUP_ADD}      = LOG_NOTICE;
$type_2_prio{EVENT_VLANGROUP_DEL}      = LOG_NOTICE;
$type_2_prio{EVENT_VLANGROUP2VLAN_ADD} = LOG_NOTICE;
$type_2_prio{EVENT_VLANGROUP2VLAN_DEL} = LOG_NOTICE;
$type_2_prio{EVENT_NOTICE}             = LOG_NOTICE;
$type_2_prio{EVENT_DB_WARN}            = LOG_WARNING;
$type_2_prio{EVENT_WARN}               = LOG_WARNING;
$type_2_prio{EVENT_MEMCACHE_WARN}      = LOG_WARNING;
$type_2_prio{EVENT_ERR}                = LOG_ERR;
$type_2_prio{EVENT_MEMCACHE_ERR}       = LOG_ERR;
$type_2_prio{EVENT_NOLOCATION}         = LOG_ERR;
$type_2_prio{EVENT_CHALLENGE_ERR}      = LOG_ERR;
$type_2_prio{EVENT_SMTP_FAIL}          = LOG_CRIT;
$type_2_prio{EVENT_DB_ERR}             = LOG_CRIT;
$type_2_prio{EVENT_FATAL}              = LOG_CRIT;
$type_2_prio{EVENT_LOGIC_FAIL}         = LOG_CRIT;
$type_2_prio{EVENT_EVAL_FAIL}          = LOG_CRIT;
$type_2_prio{EVENT_FUNC_FAIL}          = LOG_CRIT;
$type_2_prio{EVENT_DEBUG}              = LOG_DEBUG;

my $progname = ( split( /\//, $0 ) )[-1];
openlog( $progname, "ndelay,pid", LOG_LOCAL0 );

#--------------------------------------------------------------------------------
sub MYNAME() { ( ( caller(1) )[3] ) . ' ' }
sub MYLINE() { ( ( caller(1) )[2] ) . ' ' }

#--------------------------------------------------------------------------------
sub MYNAMELINE() {
    if ( defined caller(1) ) {
        ( ( ( caller(1) )[3] ) . ' line:' . ( ( caller(0) )[2] ) . " " );
    }
    else {
        ( ( (caller)[1] ) . ' line:' . ( (caller)[2] ) ) . " ";
    }
}

#--------------------------------------------------------------------------------
sub ActivateDebug() {
    $PRINT_DEBUG = 1;
}

#--------------------------------------------------------------------------------
sub DeactivateDebug() {
    $PRINT_DEBUG = 0;
}

#--------------------------------------------------------------------------------
sub ActivateSyslog() {
    $PRINT_LOG = 1;
}

#--------------------------------------------------------------------------------
sub DeactivateSyslog() {
    $PRINT_LOG = 0;
}

#--------------------------------------------------------------------------------
sub ActivateStdout() {
    $PRINT_STDOUT = 1;
}

#--------------------------------------------------------------------------------
sub DeactivateStdout() {
    $PRINT_STDOUT = 0;
}

#--------------------------------------------------------------------------------
sub ActivateStderr() {
    $PRINT_STDERR = 1;
}

#--------------------------------------------------------------------------------
sub DeactivateStderr() {
    $PRINT_STDERR = 0;
}

#--------------------------------------------------------------------------------
sub ActivateHTML() {
    $PRINT_HTML = 1;
}

#--------------------------------------------------------------------------------
sub LOGEVALFAIL() {
    my $n = ( caller(1) )[3];
    my $l = ( caller(1) )[2];
    my $f = ( caller(1) )[1];
    EventLog( EVENT_EVAL_FAIL, Carp::longmess( "Host: $hostname, File:$f Sub:$n Line:$l: " . "\n" . $@ ) );
}

#-----------------------------------------------------------
sub EventLog ($$;$) {
    my $type    = shift;
    my $message = shift;
    my $data    = shift;

    if ( !defined $data ) {
        my %d;
        $data = \%d;
    }
    if ( !defined $message ) {
        confess;
        $message = 'No Message';
    }

    if ( ( $type eq EVENT_DEBUG ) && ( !$PRINT_DEBUG ) ) { return; }

    my $prio = ( defined $type_2_prio{$type} ) ? $type_2_prio{$type} : LOG_INFO;

    $message = "$type: $message";
    if ($PRINT_LOG) {
        syslog( $prio, $message );
    }

    print STDOUT ( $message . ( ($PRINT_HTML) ? '<BR>' : '' ) . "\n" ) if ($PRINT_STDOUT);
    print STDERR ( $message . ( ($PRINT_HTML) ? '<BR>' : '' ) . "\n" ) if ($PRINT_STDERR);

    $data->{EVENT_PARM_MSG} = $message;

    if ( $prio == LOG_NOTICE ) {
        $data->{EVENT_TYPE} = EVENT_TYPE_NOTICE;

    }
    elsif ( $prio == LOG_WARNING ) {
        $data->{EVENT_TYPE} = EVENT_TYPE_WARNING;

    }
    elsif ( $prio == LOG_ERR ) {
        $data->{EVENT_TYPE} = EVENT_TYPE_ERROR;
    }
    elsif ( $prio == LOG_CRIT ) {
        $data->{EVENT_TYPE} = EVENT_TYPE_CRIT;
    }
    else {

        # print "No Msg sent for TYPE:$type PRIO:$prio\n";
    }

    if ( $type eq EVENT_FATAL ) { confess "Caught a FATAL Event" }

}

1;
