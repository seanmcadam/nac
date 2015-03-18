#!/usr/bin/perl

package NAC::Client::Config;

use Data::Dumper;
use Carp;
use POSIX;
use base qw( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::Client;
use NAC::DB;
use NAC::DataRequest::Config;
use strict;

our @ISA = qw(NAC::Client);

use constant CONFIG_RESULT       => 'CONFIG_RESULT';
use constant CONFIG_ID           => 'CONFIG_ID';
use constant CONFIG_NAME         => 'CONFIG_NAME';
use constant CONFIG_VALUE        => 'CONFIG_VALUE';
use constant CONFIG_HOSTNAME     => 'CONFIG_HOSTNAME';
use constant CONFIG_ID_COL       => 0;
use constant CONFIG_HOSTNAME_COL => 1;
use constant CONFIG_NAME_COL     => 2;
use constant CONFIG_VALUE_COL    => 3;
use constant HOSTNAME_BLANK      => 'HOSTNAME_BLANK';

our @EXPORT = qw(
  HOSTNAME_BLANK
);

# ---------------------------------------------
sub new {
    my ( $class, $parms ) = @_;
    my $self = $class->SUPER::new($parms);

    $LOGGER_DEBUG_9->(EVENT_START);

    $self->do;

    $self;
}

# ---------------------------------------------
sub _result {
    my ($self) = @_;
    return $self->{CONFIG_RESULT};
}

# ---------------------------------------------
sub do {
    my ($self) = @_;

    $LOGGER_DEBUG_4->(" GET Config DO ");

    my $sqlobj = NAC::DataRequest::Config->new( {
            GET_DATA => [
                {    # 0
                    GET_DATA_COLUMN => NACCONFIG_CONFIG_CONFIGID_COLUMN,
                    GET_DATA_ALIAS  => CONFIG_ID,
                },
                {    # 1
                    GET_DATA_COLUMN => NACCONFIG_CONFIG_HOSTNAME_COLUMN,
                    GET_DATA_ALIAS  => CONFIG_HOSTNAME,
                },
                {    # 2
                    GET_DATA_COLUMN => NACCONFIG_CONFIG_NAME_COLUMN,
                    GET_DATA_ALIAS  => CONFIG_NAME,
                },
                {    # 3
                    GET_DATA_COLUMN => NACCONFIG_CONFIG_VALUE_COLUMN,
                    GET_DATA_ALIAS  => CONFIG_VALUE,
                },
            ],
    } );

    $self->{CONFIG_RESULT} = $self->SUPER::do( GET_CONFIG_DATA_FUNCTION, $sqlobj );

}

# ---------------------------------------------
sub get_value {
    my ( $self, $id ) = @_;

    if ( !defined $id || isdigit($id) ) {
        $LOGGER_FATAL->("BAD ID PROVIDED, '$id'");
    }

    my ($row) = @{ $self->get( { CONFIG_ID => $id } ) };

    if( ! defined $row ) {
        $LOGGER_WARN->("ID PROVIDED DOES NOT EXIST, $id");
	}

    $row->[CONFIG_VALUE_COL];
}

# ---------------------------------------------
sub get_ids {
    my ( $self, $parms ) = @_;

    my @ids = ();
    my $ref = $self->get($parms);

    foreach my $row ( @{$ref} ) {
        push( @ids, $row->[CONFIG_ID_COL] );
    }

    \@ids;
}

# ---------------------------------------------
sub get {
    my ( $self, $parms ) = @_;

    my $configid = 0;
    my $hostname = '';
    my $name     = '';
    my @col      = ();

    $LOGGER_DEBUG_4->(" GET Config Data ");

    # $LOGGER_DEBUG_9->( Dumper $self->{CONFIG_RESULT} );
    # $LOGGER_DEBUG_9->( Dumper $self->_result );

    if ( defined $parms->{CONFIG_ID} ) {
        $configid = $parms->{CONFIG_ID};
        $LOGGER_DEBUG_7->(" GET CONFIG_ID => $configid");
    }

    if ( defined $parms->{CONFIG_HOSTNAME} ) {
        $hostname = $parms->{CONFIG_HOSTNAME};
        $LOGGER_DEBUG_7->(" GET CONFIG_HOSTNAME => $hostname");
    }

    if ( defined $parms->{CONFIG_NAME} ) {
        $name = $parms->{CONFIG_NAME};
        $LOGGER_DEBUG_7->(" GET CONFIG_NAME => $name");
    }

    $self->_result()->set_first_row();

    while ( my $row = $self->_result()->next_row() ) {
        if ( ( !$configid || $configid == $row->[CONFIG_ID_COL] )
            && ( $hostname eq '' || $hostname eq $row->[CONFIG_HOSTNAME_COL]
                || ( $hostname eq HOSTNAME_BLANK
                    && ( '' eq $row->[CONFIG_HOSTNAME_COL] || !defined $row->[CONFIG_HOSTNAME_COL] )
                )
            )
            && ( $name eq '' || $name eq $row->[CONFIG_NAME_COL] )
          ) {
            push( @col, $row );
        }
        else {

            # $LOGGER_DEBUG_9->(" SKIP ROW:" . Dumper $row);
        }
    }

    \@col;
}

1;
