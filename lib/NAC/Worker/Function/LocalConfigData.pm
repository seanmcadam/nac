#!/usr/bin/perl

package NAC::Worker::Function::LocalConfigData;

use Carp;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::Worker::Function;
use NAC::Worker::DB;
use NAC::DataRequest::Config;
use NAC::DataResponse::Config;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( GET_CONFIG_DATA_FUNCTION, \&function );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;
    my $response;

    $LOGGER_DEBUG_9->();

    if ( ref($request) ne 'NAC::DataRequest::Config' ) { confess; }

    my $sql    = $request->sql;
    my $pid    = $request->pid;
    my $reqnum = $request->count;

    my $sth = DBH()->prepare($sql) || $LOGGER_FATAL->( DBH()->errstr );

    my $count = 0;
    foreach my $b ( @{ $request->{SQL_BIND} } ) {
        $sth->bind_param( ++$count, $b );
    }

    eval {
        $sth->execute;
        my $row_count = $sth->rows();

        $LOGGER_DEBUG_3->(" SQL SELECT SUCCESS ROW: $row_count PID:$pid, REQUEST:$reqnum");

        my $row_arrref = (( $row_count) ? $sth->fetchall_arrayref() : undef );
	my $columns = $request->get_column_alias_ref;
        $response = NAC::DataResponse::Config->new(
            { GET_COUNT => $row_count,
                GET_DATA => ( ($row_count) ? $row_arrref : undef ),
                GET_REQUEST => $reqnum,
                GET_COLUMNS => $columns,
                GET_PID     => $pid,
                GET_SQL     => $sql,
            }, );

    };

    if ($@) {
        $LOGGER_CRIT->( "STH EVAL ERROR: " . $@ );
        $response = NAC::DataResponse::Config->new(
            { GET_ERROR => "GET CONFIG DB ERROR '" . $@ . "'",
                GET_SQL     => $sql,
                GET_PID     => $pid,
                GET_REQUEST => $reqnum,
            }, );
    }

    $response;

}

1;
