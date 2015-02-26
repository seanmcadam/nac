#!/usr/bin/perl

package NAC::Worker::Function::GetLocalSQL;

use Data::Dumper;
use Carp;
use DBI;
use FindBin;
use lib "$FindBin::Bin/../../..";
use NAC::DataRequest::SQL;
use NAC::DataResponse::GetLocalSQL;
use NAC::Worker::Function;
use strict;

our @ISA = qw(NAC::Worker::Function);

use constant GET_LOCAL_SQL_FUNCTION => 'get_local_sql';

my $user = 'nacro';
my $pass = 'nacro';
my $host = 'n02';
my $port = 3306;
my $db   = 'nacaudit';

my $db_source = "dbi:mysql:"
  . "dbname=$db;"
  . "host=$host;"
  . "port=$port;"
  ;

my $dbh;

sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new( GET_LOCAL_SQL_FUNCTION, \&function );
    bless $self, $class;
    $self;
}

#
#
#
sub function {
    my ($request) = @_;

    if ( !defined $dbh ) {
        if ( !( $dbh = DBI->connect(
                    $db_source,
                    $user,
                    $pass,
                    {
                        PrintError => 1,
                        RaiseError => 1,
                        AutoCommit => 1,
                    },
                ) ) ) { confess $DBI::Error . "\n"; }
    }

    if ( ref($request) ne 'NAC::DataRequest::SQL' ) { confess; }

    my $sql = $request->{SQL_STMT};

    my $sth = $dbh->prepare($sql) || confess $dbh->errstr . "\n";

    $NAC::LOG_INFO->( $sql );

    my $count = 0;
    foreach my $b ( @{ $request->{SQL_BIND} } ) {
        $sth->bind_param( ++$count, $b );
    }

    $sth->execute;

    my $response = NAC::DataResponse::GetLocalSQL->new( { SQL_SELECT => $sth->fetchrow_hashref, },);

    $response;

}

1;
