#!/usr/bin/perl
# SVN: $Id:  $:
#
# version       $Revision: 1750 $:
# lastmodified  $Date: $:
# modifiedby    $LastChangedBy: $:
# URL           $URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/Audit.pm $:
#
#
# Author: Sean McAdam
# Purpose: Provide controlled access to the NAC database.
#
#
# Perl Rocks!
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::Audit;

#use lib "$ENV{HOME}/lib/perl5";
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Data::Dumper;
use Carp qw(confess cluck);
use NAC::DBConsts;
use NAC::DBRadiusAudit;
use NAC::Syslog;
use NAC::Constants;
use strict;

my $DAYOFFSET = 0;

#-------------------------------------------------------
#
# Get Current date
# Select unique MACID/SWPID audit records with todays date
# Process each MACID
# 	Get Unique switchports for MACID
#	Rollup Starts to earliest
#	Rollup Stops to Latest (with accumulated stats)
#
#-------------------------------------------------------
sub audit_daily_rollup() {
    my @d;
    my $db;

    $db = NAC::DBRadiusAudit->new();

    my $t = time() - ( ( 24 * 60 * 60 ) * ($DAYOFFSET) );

    @d = localtime($t);
    my $starttime = sprintf( "%d-%02d-%02d 00:00:00", ( $d[5] + 1900 ), ( $d[4] + 1 ), $d[3] );
    @d = localtime( $t + ( 24 * 60 * 60 ) );
    my $endtime = sprintf( "%d-%02d-%02d 00:00:00", ( $d[5] + 1900 ), ( $d[4] + 1 ), $d[3] );

    print "Start: $starttime\n";
    print "Stop: $endtime\n";

    my %ra;
    my %macid_swpid;
    my %parm;

    # $parm{$DB_STARTTIME} = $starttime;
    # $parm{$DB_ENDTIME}   = $endtime;
    $parm{$DB_COL_RA_AUDIT_TIME_GT} = $starttime;
    $parm{$DB_COL_RA_AUDIT_TIME_LT} = $endtime;
    $parm{$HASH_REF}                = \%ra;

    my $ret = $db->get_radiusaudit( \%parm );
    if ($ret) {

        foreach my $raid ( keys(%ra) ) {
            $macid_swpid{ $ra{$raid}->{$DB_COL_RA_MACID} . ":" . $ra{$raid}->{$DB_COL_RA_SWPID} }++;
        }

        # Have the Unique MACs now
        foreach my $m_s ( keys(%macid_swpid) ) {

            my ( $macid, $swpid ) = split( /:/, $m_s );

            print "$m_s | MACID: $macid, SWPID: $swpid count: $macid_swpid{$m_s}\n";
            my $octetsin      = 0;
            my $octetsout     = 0;
            my $packetsin     = 0;
            my $packetsout    = 0;
            my $start         = undef;
            my $stop          = undef;
            my @del_start_ids = ();
            my @del_stop_ids  = ();

            foreach my $r ( keys(%ra) ) {

                if ( ( $macid != $ra{$r}->{$DB_COL_RA_MACID} )
                    || ( $swpid != $ra{$r}->{$DB_COL_RA_SWPID} ) ) {
                    next;
                }

                my $raref = $ra{$r};
                my $type  = $raref->{$DB_COL_RA_TYPE};
                my $id    = $raref->{$DB_COL_RA_ID};

                # print "Working on $type: $id \n";

                if ( $type eq 'Start' ) {
                    if ( !defined $start ) {
                        $start = $raref;
                    }
                    elsif ( $id < $start->{$DB_COL_RA_ID} ) {
                        push( @del_start_ids, $start->{$DB_COL_RA_ID} );
                        $start = $raref;
                    }
                    else {
                        push( @del_start_ids, $id );
                    }
                }
                elsif ( $type eq 'Stop' ) {
                    $octetsin   += $raref->{$DB_COL_RA_OCTIN};
                    $octetsout  += $raref->{$DB_COL_RA_OCTOUT};
                    $packetsin  += $raref->{$DB_COL_RA_PACIN};
                    $packetsout += $raref->{$DB_COL_RA_PACOUT};
                    if ( !defined $stop ) {
                        $stop = $raref;
                    }
                    elsif ( $id > $stop->{$DB_COL_RA_ID} ) {
                        push( @del_stop_ids, $stop->{$DB_COL_RA_ID} );
                        $stop = $raref;
                    }
                    else {
                        push( @del_stop_ids, $id );
                    }
                }
            }

            if ( defined $start ) {
                print "Keep Start ID: " . $start->{$DB_COL_RA_ID} . "\n";
                foreach my $s (@del_start_ids) {

                    # print "Delete Start $s\n";
                    my %p;
                    $p{$DB_COL_RA_ID} = $s;
                    $db->remove_radiusaudit( \%p );
                }
            }

            if ( defined $stop ) {
                print "Keep Stop ID: " . $stop->{$DB_COL_RA_ID} . "\n";
                print " Oct in: $octetsin\n";
                print " Oct out: $octetsout\n";
                print " Pac in: $packetsin\n";
                print " Pac out: $packetsout\n";
                my %upd;
                $upd{$DB_COL_RA_ID}     = $stop->{$DB_COL_RA_ID};
                $upd{$DB_COL_RA_OCTIN}  = $octetsin;
                $upd{$DB_COL_RA_OCTOUT} = $octetsout;
                $upd{$DB_COL_RA_PACIN}  = $packetsin;
                $upd{$DB_COL_RA_PACOUT} = $packetsout;

                $db->update_radiusaudit( \%upd );
                foreach my $s (@del_stop_ids) {

                    # print "Delete Stop $s\n";
                    my %p;
                    $p{$DB_COL_RA_ID} = $s;
                    $db->remove_radiusaudit( \%p );
                }
            }
        }
    }

}

1;
