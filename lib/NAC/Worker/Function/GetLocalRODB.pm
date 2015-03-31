#!/usr/bin/perl

package NAC::Worker::Function::GetLocalRODB;

use Data::Dumper;
use Carp;
use DBI;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::SQL;
use NAC::DataRequest::GetLocalSQL;
use NAC::DataResponse::GetLocalSQL;
use NAC::Worker::Function;
use NAC::Worker::DB;
use strict;

our @ISA = qw(NAC::Worker::Function);

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( GET_LOCAL_RODB_FUNCTION, \&function, $parms );
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

    if ( ref($request) ne 'NAC::DataRequest::SQL' ) { confess; }

    my $sql = $request->sql;
    my $pid = $request->request_pid;
    my $num = $request->request_num;

    $LOGGER_DEBUG_3->($sql);

    my $sth = DBH()->prepare($sql) || $LOGGER_FATAL->( DBH()->errstr );

    my $count = 0;
    foreach my $b ( @{ $request->{SQL_BIND} } ) {
        $sth->bind_param( ++$count, $b );
    }

    eval {
        $sth->execute;
    };
    if ($@) {
        $LOGGER_CRIT->( "STH EXECUTE ERROR STR: " . DBH()->errstr . "\nSQL: " . $sql );
        $response = NAC::DataResponse::GetLocalSQL->new( { SQL_ERROR => DBH()->errstr, SQL_RESPONSE_NUM => $num, SQL_RESPONSE_PID => $pid, }, );
    }
    else {
        $response = NAC::DataResponse::GetLocalSQL->new( { SQL_SELECT => $sth->fetchrow_hashref, SQL_RESPONSE_NUM => $num, SQL_RESPONSE_PID => $pid, }, );
    }

    $response;

}

1;
