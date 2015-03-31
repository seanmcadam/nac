#!/usr/bin/perl

package NAC::DataResponse::SQL;

use Data::Dumper;
use POSIX;
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::DataResponse;
use strict;


use constant 'SQL_RESPONSE_NUM' => 'SQL_RESPONSE_NUM';
use constant 'SQL_RESPONSE_PID' => 'SQL_RESPONSE_PID';
use constant 'SQL_SELECT'       => 'SQL_SELECT';
use constant 'SQL_INSERT'       => 'SQL_INSERT';
use constant 'SQL_UPDATE'       => 'SQL_UPDATE';
use constant 'SQL_DELETE'       => 'SQL_DELETE';
use constant 'SQL_ERROR'        => 'SQL_ERROR';

my @EXPORT = qw(
  SQL_RESPONSE_NUM
  SQL_RESPONSE_PID
  SQL_SELECT
  SQL_INSERT
  SQL_UPDATE
  SQL_DELETE
  SQL_ERROR
);

our @ISA = qw(NAC::DataResponse);

sub new {
    my ( $class, $parms ) = @_;

    if( ! defined $parms ) {
	$LOGGER_FATAL->( "NO PARMS DEFINED" );
    }
    
    my %data;
    my $self = $class->SUPER::new(\%data);

    if ( !defined $parms->{SQL_RESPONSE_NUM} || !isdigit( $parms->{SQL_RESPONSE_NUM} ) ) {
        $LOGGER_ERROR->("BAD SQL_RESPONSE_NUM VALUE\n" . Dumper $parms );
        $self->{SQL_RESPONSE_NUM} = 0;
    }
    else {
        $self->{SQL_RESPONSE_NUM} = $parms->{SQL_RESPONSE_NUM};
    }

    if ( !defined $parms->{SQL_RESPONSE_PID} || !isdigit( $parms->{SQL_RESPONSE_PID} ) ) {
        $LOGGER_ERROR->("BAD SQL_RESPONSE_PID VALUE");
        $self->{SQL_RESPONSE_PID} = 0;
    }
    else {
        $self->{SQL_RESPONSE_PID} = $parms->{SQL_RESPONSE_PID};
    }

    if ( defined $parms->{SQL_ERROR} ) {
        $self->{SQL_ERROR} = $parms->{SQL_ERROR};
    }
    elsif ( defined $parms->{SQL_SELECT} ) {
        $self->{SQL_SELECT} = $parms->{SQL_SELECT};
    }
    elsif ( defined $parms->{SQL_INSERT} ) {
        $self->{SQL_INSERT} = $parms->{SQL_INSERT};
    }
    elsif ( defined $parms->{SQL_UPDATE} ) {
        $self->{SQL_UPDATE} = $parms->{SQL_UPDATE};
    }
    elsif ( defined $parms->{SQL_DELETE} ) {
        $self->{SQL_DELETE} = $parms->{SQL_DELETE};
    }
    else {
        $LOGGER_ERROR->("NO SQL COMMAND ");
        $self->{SQL_ERROR} = "NO SQL COMMAND";
	}

    bless $self, $class;

    $self;
}

sub error {
    my ($self) = @_;
    ( defined $self->{SQL_ERROR} ) ? $self->{SQL_ERROR} : 0;
}

sub select {
    my ($self) = @_;
    $self->{SQL_SELECT};
}

sub insert {
    my ($self) = @_;
    $self->{SQL_INSERT};
}

sub update {
    my ($self) = @_;
    $self->{SQL_UPDATE};
}

sub delete {
    my ($self) = @_;
    $self->{SQL_DELETE};
}

sub response_num {
    my ($self) = @_;
    $self->{SQL_RESPONSE_NUM};
}

sub response_pid {
    my ($self) = @_;
    $self->{SQL_RESPONSE_PID};
}

1;
