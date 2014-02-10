#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: 1750 $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/Misc.pm $:
#
#---------------------------------------------------------------------------

#---------------------------------------------------------------------------
package NAC::Misc;
#use lib "$ENV{HOME}/lib/perl5";
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Data::Dumper;
use Carp;
use POSIX;
use NAC::Constants;
use NAC::Syslog;
use warnings;
use strict;

sub become_daemon;
sub write_pid_file($);
sub get_current_timestamp();
sub extract_mac_from_line($);
sub format_mac($);
sub verify_mac($);

our @EXPORT = qw (
  become_daemon
  write_pid_file
  get_current_timestamp
  extract_mac_from_line
  format_mac
  verify_mac
);

#---------------------------------------------------------------------------
sub verify_mac($) {
    my ($mac) = @_;
    my $ret = 0;

    $mac =~ tr/A-F/a-f/;
    if ( $mac =~ /[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}:[0-9a-f]{2}/ ) {
        $ret = 1;
    }
    $ret;
}

#--------------------------------------------------------------------------------
sub format_mac($) {
    my $mac = shift;
    my $ret = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE . "($mac)" );

    if ( ( defined $mac ) && ( $mac ne '' ) ) {
        $mac =~ s/\s+//g;
        $mac =~ tr/A-F/a-f/;
        $mac =~ s/[^0-9a-f]//g;

        my @v = split( //, $mac );
        if ( 12 >= scalar(@v) ) {
            $ret = $v[0] . $v[1] . ':'
              . $v[2] . $v[3] . ':'
              . $v[4] . $v[5] . ':'
              . $v[6] . $v[7] . ':'
              . $v[8] . $v[9] . ':'
              . $v[10] . $v[11];
        }
        else {
            EventLog( EVENT_DEBUG, MYNAMELINE . " 12 > " . scalar(@v) . "\n" );
        }
    }
    else {
        EventLog( EVENT_DEBUG, MYNAMELINE . "($mac)" );
    }

    return $ret;
}

#--------------------------------------------------------------------------------
sub get_current_timestamp() {
    my @t   = localtime( time() );
    my $ret = sprintf( "%04d-%02d-%02d %02d:%02d:%02d",
        ( $t[5] + 1900 ), ( $t[4] + 1 ), $t[3], $t[2], $t[1], $t[0] );
    $ret;
}

#--------------------------------------------------------------------------------
sub become_daemon {

    my $parm_ref = shift;
    my $cwd      = ( defined $parm_ref->{'CWD'} ) ? $parm_ref->{'CWD'} : '/';
    my $dont_die = ( defined $parm_ref->{'DIE'} ) ? $parm_ref->{'DIE'} : 0;
    if ( defined $parm_ref ) {
        $cwd      = ( defined $parm_ref->{'CWD'} ) ? $parm_ref->{'CWD'} : '/';
        $dont_die = ( defined $parm_ref->{'DIE'} ) ? $parm_ref->{'DIE'} : 0;
    }
    my $ret = 0;
    my $pid;
    my $sig;

    $pid = fork();
    if ( !defined $pid ) {
        if ($dont_die) {
            EventLog( EVENT_WARN, MYNAMELINE . "fork() FAILED, RETURNING: $!" );
            return $ret;
        }
        else {
            EventLog( EVENT_FUNC_FAIL, MYNAMELINE . "Fork() FAILED, EXITING: $!" );
            confess;
        }
    }
    elsif ($pid) {

        # Parent
        EventLog( EVENT_DEBUG, MYNAMELINE . "Fork() parent exiting" );
        exit 0;
    }
    else {

        # Child
        EventLog( EVENT_DEBUG, MYNAMELINE . "Fork() child forked sucessfully: $pid" );
    }

    #
    # First-generation child.
    #
    setpgrp;
    open my $devnull, '+>', '/dev/null';

    # dup2( STDOUT, $devnull );
    dup2( 1, $devnull );

    # dup2( STDIN,  $devnull );
    dup2( 0, $devnull );

    # dup2( STDERR, $devnull );
    dup2( 2, $devnull );
    chdir $cwd;
    umask 0;
    for (qw(TSTP TTIN TTOU)) { $SIG{$_} = 'IGNORE' if ( exists $SIG{$_} ) }

    $sig = $SIG{HUP};
    $SIG{HUP} = 'IGNORE';

    $pid = undef;
    $pid = fork();
    if ( !defined $pid ) {
        if ($dont_die) {
            EventLog( EVENT_WARN, "second fork() FAILED, RETURNING: $!" );
            return $ret;
        }
        else {
            EventLog( EVENT_FUNC_FAIL, "second Fork() FAILED, EXITING: $!" );
            confess;
        }
    }
    elsif ($pid) {

        # Parent
        EventLog( EVENT_DEBUG, "second Fork() parent exiting" );
        exit 0;
    }
    else {

        # Child
        EventLog( EVENT_DEBUG, "second Fork() child forked sucessfully: $pid" );
    }

    $SIG{HUP} = $sig;
    $ret++;
    $ret;
}

#--------------------------------------------------------------------------------
#
# write_pid_file(file_name) - writes a one line file that contains
# the current process id.
#
sub write_pid_file($) {
    my $name = shift;
    my $fh = new FileHandle "$name", "w";

    if ( defined($fh) ) {
        print $fh "$$\n";
        $fh->close;
    }
    else {
        EventLog( EVENT_WARN, MYNAMELINE . " cannot write pid file named $name: $!" );
    }
}

#--------------------------------------------------------------------------------
# Pulls MAC address from a line, expects the MAC to be the beginning of the line
# with no white space.
# Translates all CAPs to lowercase
# Returns undef on Error
# Return 0 for no MAC
# Otherwise it returns the mac in the format 00:11:22:33:44:55
#--------------------------------------------------------------------------------
sub extract_mac_from_line($) {
    my $line = shift;
    my $ret  = 0;
    my $mac  = 0;

    # Remove LF and CR
    if ( $line =~ /\r/ ) { $line =~ s/\r//; }
    if ( $line =~ /\n/ ) { $line =~ s/\n//; }

    # Remove leading white space
    if ( $line =~ /^\s/ ) { $line =~ s/^\s+//; }

    # Skip Blank Lines
    if ( $line =~ /^$/ ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . "blank line" );
        goto DONE;
    }

    if ( $line =~ /^#/ ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . "comment line" );
        goto DONE;
    }

    # Strip the line down to just alpha-numeric, lower case, no white space

    EventLog( EVENT_DEBUG, MYNAMELINE . "LINE:$line" );

    $line =~ tr/A-Z/a-z/;
    $line =~ s/://g;
    $line =~ s/-//g;
    $line =~ s/\.//g;

    EventLog( EVENT_DEBUG, MYNAMELINE . "LINE:$line" );

    if ( !( $line =~ /([0-9a-f]{12})/ ) ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . "Bad Charachters:$line" );
        goto DONE;
    }

    $mac = $1;

    if ( 12 != length($mac) ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . "Bad length:$mac" );
        goto DONE;
    }

    my @mac = split( //, $mac );
    $ret = "$mac[0]$mac[1]:$mac[2]$mac[3]:$mac[4]$mac[5]:$mac[6]$mac[7]:$mac[8]$mac[9]:$mac[10]$mac[11]";

  DONE:

    EventLog( EVENT_DEBUG, MYNAMELINE . "Return MAC:'$mac'" );
    return $ret;

}

#--------------------------------------------------------------------------------
# Pulls VLANGROUP NAME from a line
# with no white space.
# Translates all LC to CAPS
# Returns undef on Error
# Return 0 for no NAME
#--------------------------------------------------------------------------------
sub extract_vlangroup_line($) {
    my $line      = shift;
    my $vlangroup = 0;

    # Remove LF and CR
    if ( $line =~ /\r/ ) { $line =~ s/\r//; }
    if ( $line =~ /\n/ ) { $line =~ s/\n//; }

    # Remove leading white space
    if ( $line =~ /^\s/ ) { $line =~ s/^\s+//; }

    # Skip Blank Lines
    if ( $line =~ /^$/ ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . "blank line" );
        goto DONE;
    }

    if ( $line =~ /^#/ ) {
        EventLog( EVENT_DEBUG, MYNAMELINE . "comment line" );
        goto DONE;
    }

    # Strip the line down to just alpha-numeric, lower case, no white space

    EventLog( EVENT_DEBUG, MYNAMELINE . "LINE:$line" );

    # Shrink all multi white space to one
    $line =~ s/\s+/ /g;

    EventLog( EVENT_DEBUG, MYNAMELINE . "LINE:$line" );

    # Convert to upper case
    $line =~ tr/a-z/A-Z/;

    EventLog( EVENT_DEBUG, MYNAMELINE . "LINE:'$line'" );

    if ( $line =~ /^([\-\w]+)\s*/ ) {
        $vlangroup = $1;
    }

  DONE:

    EventLog( EVENT_DEBUG, MYNAMELINE . "Return VG:'$vlangroup'" );

    return $vlangroup;
}

1;

