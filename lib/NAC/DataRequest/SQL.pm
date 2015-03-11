#!/usr/bin/perl

package NAC::DataRequest::SQL;

# use base qw( Exporter );
use Exporter qw(import);
use Data::Dumper;
use Carp;
use POSIX;
use SQL::Parser;
use SQL::Statement;
use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

use constant 'SQL_REQUEST_NUM' => 'SQL_REQUEST_NUM';
use constant 'SQL_REQUEST_PID' => 'SQL_REQUEST_PID';
use constant 'SQL_STMT'        => 'SQL_STMT';
use constant 'SQL_BIND'        => 'SQL_BIND';
use constant 'SQL_TYPE'        => 'SQL_TYPE';
use constant 'SELECT'          => 'SELECT';
use constant 'INSERT'          => 'INSERT';
use constant 'UPDATE'          => 'UPDATE';
use constant 'DELETE'          => 'DELETE';

my %types = (
    SELECT => SELECT,
    INSERT => INSERT,
    UPDATE => UPDATE,
    DELETE => DELETE,
);

my @EXPORT = qw(
);

our @ISA     = qw(NAC::DataRequest);
our $request = 1;

my $parser = SQL::Parser->new( 'AnyData', { RaiseError => 1, PrintError => 0 }, );

# ----------------------------------------------------------------
#
#
# ----------------------------------------------------------------
sub new {
    my ( $class, $stmt, $bind ) = @_;

    my $data = {};

    my ($type) = split( / /, $stmt );
    $type =~ tr/a-z/A-Z/;

    if ( !defined $types{$type} ) {
        confess;
    }

    $data->{SQL_STMT}        = $stmt;
    $data->{SQL_BIND}        = $bind;
    $data->{SQL_TYPE}        = $type;
    $data->{SQL_REQUEST_NUM} = $request++;
    $data->{SQL_REQUEST_PID} = $$;


# print $stmt;

    my $stmt = SQL::Statement->new($stmt,$parser);
    print Dumper $stmt;
exit;

    my $self = $class->SUPER::new( $class, $data );
    bless $self, $class;
    $self;
}

# ----------------------------------------------------------------
sub type {
    my ($self) = @_;
    $self->data->{SQL_TYPE};
}

# ----------------------------------------------------------------
sub sql {
    my ($self) = @_;
    $self->data->{SQL_STMT};
}

# ----------------------------------------------------------------
sub bind {
    my ($self) = @_;
    $self->data->{SQL_BIND};
}

# ----------------------------------------------------------------
sub request_num {
    my ($self) = @_;
    $self->data->{SQL_REQUEST_NUM};
}

# ----------------------------------------------------------------
sub request_pid {
    my ($self) = @_;
    $self->data->{SQL_REQUEST_PID};
}

1;

