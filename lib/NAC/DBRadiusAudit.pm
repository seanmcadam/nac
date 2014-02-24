#!/usr/bin/perl
# SVN: $Id: NACDB.pm 1529 2012-10-13 17:22:52Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-10-13 13:22:52 -0400 (Sat, 13 Oct 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/nac-rel-2.0/lib/NACDBEventlog.pm $:
#
#
#
# Author: Sean McAdam
#
#------------------------------------------------------
# Notes:
#
#------------------------------------------------------

package NAC::DBRadiusAudit;
use FindBin;
use lib "$FindBin::Bin/../lib";
use base qw( Exporter );
use Readonly;
use Data::Dumper;
use Carp qw(confess cluck);
use POSIX;
use NAC::DBSql;
use NAC::DBConsts;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use NAC::Misc;
use strict;

our @ISA = qw(NAC::DBSql);

my ($VERSION) = '$Revision: 1750 $:' =~ m{ \$Revision:\s+(\S+) }x;

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

    my %parms  = ();
    my $config;
    if( ! $config = NAC::ConfigDB->new() ) {
	confess "Config DB not available\n";
	}

    # For backward compatibility
    $parms{$SQL_DB}        = ( defined $parm_ref->{$SQL_DB} )        ? $parm_ref->{$SQL_DB}        : $config->nac_radiusaudit_write_db;
    $parms{$SQL_HOST}      = ( defined $parm_ref->{$SQL_HOST} )      ? $parm_ref->{$SQL_HOST}      : $config->nac_radiusaudit_write_hostname;
    $parms{$SQL_PORT}      = ( defined $parm_ref->{$SQL_PORT} )      ? $parm_ref->{$SQL_PORT}      : $config->nac_radiusaudit_write_port;
    $parms{$SQL_USER}      = ( defined $parm_ref->{$SQL_USER} )      ? $parm_ref->{$SQL_USER}      : $config->nac_radiusaudit_write_user;
    $parms{$SQL_PASS}      = ( defined $parm_ref->{$SQL_PASS} )      ? $parm_ref->{$SQL_PASS}      : $config->nac_radiusaudit_write_pass;
    $parms{$SQL_READ_ONLY} = ( defined $parm_ref->{$SQL_READ_ONLY} ) ? $parm_ref->{$SQL_READ_ONLY} : undef;
    $parms{$SQL_CLASS}     = ( defined $parm_ref->{$SQL_CLASS} )     ? $parm_ref->{$SQL_CLASS}     : $class;

    $self = $class->SUPER::new( \%parms );

    bless $self, $class;

    $self;
}

#-------------------------------------------------------
# Function Can FAIL, it is not critical to the operation of Authentication, Just notate the error in the logs
#-------------------------------------------------------
sub add_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_RA_MACID} || ( !( isdigit( $parm_ref->{$DB_COL_RA_MACID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_RA_SWPID} || ( !( isdigit( $parm_ref->{$DB_COL_RA_SWPID} ) ) ) ) { confess Dumper $parm_ref; }
    if ( !defined $parm_ref->{$DB_COL_RA_TYPE} || ( $parm_ref->{$DB_COL_RA_TYPE} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTOUT} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_PACIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_PACOUT} ) ) ) { confess Dumper $parm_ref; }

    my $radiusauditid = $parm_ref->{$DB_COL_RA_ID};
    my $macid         = $parm_ref->{$DB_COL_RA_MACID};
    my $switchportid  = $parm_ref->{$DB_COL_RA_SWPID};
    my $type          = $parm_ref->{$DB_COL_RA_TYPE};
    my $cause         = ( $parm_ref->{$DB_COL_RA_CAUSE} ) ? $parm_ref->{$DB_COL_RA_CAUSE} : '';
    my $octetsin      = ( $parm_ref->{$DB_COL_RA_OCTIN} ) ? $parm_ref->{$DB_COL_RA_OCTIN} : 0;
    my $octetsout     = ( $parm_ref->{$DB_COL_RA_OCTOUT} ) ? $parm_ref->{$DB_COL_RA_OCTOUT} : 0;
    my $packetsin     = ( $parm_ref->{$DB_COL_RA_PACIN} ) ? $parm_ref->{$DB_COL_RA_PACIN} : 0;
    my $packetsout    = ( $parm_ref->{$DB_COL_RA_PACOUT} ) ? $parm_ref->{$DB_COL_RA_PACOUT} : 0;
    my $hostname      = ( defined $parm_ref->{$DB_COL_RA_AUDIT_SRV} ) ? "'" . $parm_ref->{$DB_COL_RA_AUDIT_SRV} . "'" : "'NULL'";

    my $sql;

    $sql = "INSERT INTO $DB_TABLE_RADIUSAUDIT "
      . ' ( '
      . ( ( defined $radiusauditid ) ? " radiusauditid, " : '' )
      . "macid, switchportid, auditserver, type, cause, octetsin, octetsout, packetsin, packetsout "
      . " ) VALUES ( "
      . ( ( defined $radiusauditid ) ? " $radiusauditid, " : '' )
      . " $macid, $switchportid, $hostname, '$type', '$cause', $octetsin, $octetsout, $packetsin, $packetsout "
      . ' ) '
      ;

    if ( $self->sqldo($sql) ) {
        if ( !defined $radiusauditid ) {
            if ( $self->dbh->{'mysql_insertid'} ) {
                $ret = $self->dbh->{'mysql_insertid'};
                $parm_ref->{$DB_COL_RA_ID} = $ret;
                $ret++;
            }
            else {
                EventLog( EVENT_DB_ERR, MYNAMELINE() . " Cannot assertain new INSERTed ID" );
                $self->seterr( MYNAMELINE() . " Cannot assertain new INSERTed ID" );
            }
        }
    }
    else {
        EventLog( EVENT_DB_ERR, MYNAMELINE() . " sqldo() FAILED:" . $sql );
        $self->seterr( MYNAMELINE() . " sqldo() FAILED:" . $sql );
    }

    $ret;
}

#-------------------------------------------------------
# Get radiusaudit record(s)
#-------------------------------------------------------
sub get_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    if ( defined $parm_ref->{$HASH_REF} && ref( $parm_ref->{$HASH_REF} ) ne 'HASH' ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_ID}    && !isdigit( $parm_ref->{$DB_COL_RA_ID} ) )    { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_MACID} && !isdigit( $parm_ref->{$DB_COL_RA_MACID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_SWPID} && !isdigit( $parm_ref->{$DB_COL_RA_SWPID} ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_AUDIT_TIME}    && ( $parm_ref->{$DB_COL_RA_AUDIT_TIME}    eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_AUDIT_TIME_LT} && ( $parm_ref->{$DB_COL_RA_AUDIT_TIME_LT} eq '' ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_AUDIT_TIME_GT} && ( $parm_ref->{$DB_COL_RA_AUDIT_TIME_GT} eq '' ) ) { confess Dumper $parm_ref; }

    # if ( defined $parm_ref->{$DB_ENDTIME}   && ( $parm_ref->{$DB_ENDTIME}   eq '' ) ) { confess Dumper $parm_ref; }

    my $hash_ref = $parm_ref->{$HASH_REF};
    my $id       = $parm_ref->{$DB_COL_RA_ID};
    my $macid    = $parm_ref->{$DB_COL_RA_MACID};
    my $swpid    = $parm_ref->{$DB_COL_RA_SWPID};
    my $time     = $parm_ref->{$DB_COL_RA_AUDIT_TIME};
    my $time_gt  = $parm_ref->{$DB_COL_RA_AUDIT_TIME_GT};
    my $time_lt  = $parm_ref->{$DB_COL_RA_AUDIT_TIME_LT};

    #my $starttime = $parm_ref->{$DB_STARTTIME};
    #my $endtime   = $parm_ref->{$DB_ENDTIME};
    my $where = 0;
    my $sort  = 0;

    if ( defined $time && ( defined $time_gt || defined $time_lt ) ) { confess Dumper $parm_ref; }

    my $sql = "SELECT radiusauditid,macid,switchportid,audittime,auditserver,type,cause,octetsin,octetsout,packetsin,packetsout "
      . " FROM radiusaudit "
      . ( ( defined $id )    ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " id = $id " )       : '' )
      . ( ( defined $macid ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " macid = $macid " ) : '' )
      . ( ( defined $swpid ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " swpid = $swpid " ) : '' )
      . ( ( defined $time_gt ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime > '$time_gt' " : '' )
      . ( ( defined $time_lt ) ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime < '$time_lt' " : '' )
      . ( ( defined $time )    ? ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime = '$time' "    : '' )

      #      . ( ( defined $starttime ) ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime > '$starttime' " ) : '' )
      #      . ( ( defined $endtime )   ? ( ( ( !$where++ ) ? 'WHERE' : 'AND' ) . " audittime < '$endtime' " )   : '' )
      ;

    if ( $self->sqlexecute($sql) ) {
        if ( defined $hash_ref ) {
            while ( my @answer = $self->sth->fetchrow_array() ) {
                my %h;
                my $col = 0;
                $hash_ref->{ $answer[0] } = \%h;
                $h{$DB_COL_RA_ID}         = $answer[ $col++ ];
                $h{$DB_COL_RA_MACID}      = $answer[ $col++ ];
                $h{$DB_COL_RA_SWPID}      = $answer[ $col++ ];
                $h{$DB_COL_RA_AUDIT_TIME} = $answer[ $col++ ];
                $h{$DB_COL_RA_AUDIT_SRV}  = $answer[ $col++ ];
                $h{$DB_COL_RA_TYPE}       = $answer[ $col++ ];
                $h{$DB_COL_RA_CAUSE}      = $answer[ $col++ ];
                $h{$DB_COL_RA_OCTIN}      = $answer[ $col++ ];
                $h{$DB_COL_RA_OCTOUT}     = $answer[ $col++ ];
                $h{$DB_COL_RA_PACIN}      = $answer[ $col++ ];
                $h{$DB_COL_RA_PACOUT}     = $answer[ $col++ ];
                $ret++;
            }
        }
        else {
            if ( my @answer = $self->sth->fetchrow_array() ) {
                my $col = 0;
                $parm_ref->{$DB_COL_RA_ID}         = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_MACID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_SWPID}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_AUDIT_TIME} = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_AUDIT_SRV}  = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_TYPE}       = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_CAUSE}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_OCTIN}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_OCTOUT}     = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_PACIN}      = $answer[ $col++ ];
                $parm_ref->{$DB_COL_RA_PACOUT}     = $answer[ $col++ ];
                $ret++;
            }
        }
    }

    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub get_radiusaudit_max_id {
    my $self = shift;
    my $ret  = 0;

    my $sql = "SELECT MAX(radiusauditid) FROM radiusaudit ";

    $self->sqlexecute($sql);
    if ( my @row = $self->sth->fetchrow_array() ) {
        $ret = ( $row[0] ) ? $row[0] : 0;
    }
    $ret;
}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub remove_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( ref($parm_ref) ne 'HASH' ) { confess; }

    if ( defined $parm_ref->{$DB_COL_RA_ID} && !isdigit( $parm_ref->{$DB_COL_RA_ID} ) ) { confess Dumper $parm_ref; }

    my %parm = ();
    $parm{$DB_TABLE_NAME} = $DB_TABLE_RADIUSAUDIT;
    $parm{$DB_KEY_NAME}   = $DB_KEY_RADIUSAUDITID;
    $parm{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_RA_ID};

    $ret = $self->__delete_record( \%parm );

}

#-------------------------------------------------------
#
#-------------------------------------------------------
sub update_radiusaudit($$) {
    my $self     = shift;
    my $parm_ref = shift;
    my %parm     = ();
    my $ret      = 0;

    $self->reseterr;

    EventLog( EVENT_DEBUG, MYNAMELINE() . " called" );

    if ( !defined $parm_ref ) { confess; }
    if ( !defined $parm_ref->{$DB_COL_RA_ID} || ( !isdigit( $parm_ref->{$DB_COL_RA_ID} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_OCTOUT} ) ) ) { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACIN}  && ( !isdigit( $parm_ref->{$DB_COL_RA_PACIN} ) ) )  { confess Dumper $parm_ref; }
    if ( defined $parm_ref->{$DB_COL_RA_PACOUT} && ( !isdigit( $parm_ref->{$DB_COL_RA_PACOUT} ) ) ) { confess Dumper $parm_ref; }

    #    if ( defined $parm_ref->{$DB_COL_RA_DEFVGID} && ( !( isdigit( $parm_ref->{$DB_COL_RA_DEFVGID} ) ) ) ) { confess Dumper $parm_ref; }
    #    if ( defined $parm_ref->{$DB_COL_RA_VGID}    && ( !( isdigit( $parm_ref->{$DB_COL_RA_VGID} ) ) ) )    { confess Dumper $parm_ref; }
    #    if ( defined $parm_ref->{$DB_COL_RA_VLANID}  && ( !( isdigit( $parm_ref->{$DB_COL_RA_VLANID} ) ) ) )  { confess Dumper $parm_ref; }

    $parm{$DB_TABLE_NAME} = $DB_TABLE_RADIUSAUDIT;
    $parm{$DB_KEY_NAME}   = $DB_KEY_RADIUSAUDITID;
    $parm{$DB_KEY_VALUE}  = $parm_ref->{$DB_COL_RA_ID};
    if ( defined $parm_ref->{$DB_COL_RA_OCTIN} )  { $parm{$DB_COL_RA_OCTIN}  = $parm_ref->{$DB_COL_RA_OCTIN}; }
    if ( defined $parm_ref->{$DB_COL_RA_OCTOUT} ) { $parm{$DB_COL_RA_OCTOUT} = $parm_ref->{$DB_COL_RA_OCTOUT}; }
    if ( defined $parm_ref->{$DB_COL_RA_PACIN} )  { $parm{$DB_COL_RA_PACIN}  = $parm_ref->{$DB_COL_RA_PACIN}; }
    if ( defined $parm_ref->{$DB_COL_RA_PACOUT} ) { $parm{$DB_COL_RA_PACOUT} = $parm_ref->{$DB_COL_RA_PACOUT}; }
    $ret = $self->__update_record_db_col( \%parm );

    $ret;

}

1;
