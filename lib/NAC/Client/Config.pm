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

use constant CONFIG_RESULT                  => 'CONFIG_RESULT';
use constant CONFIG_ID                      => 'CONFIG_ID';
use constant CONFIG_NAME                    => 'CONFIG_NAME';
use constant CONFIG_VALUE                   => 'CONFIG_VALUE';
use constant CONFIG_HOSTNAME                => 'CONFIG_HOSTNAME';
use constant CONFIG_ID_COL                  => 0;
use constant CONFIG_HOSTNAME_COL            => 1;
use constant CONFIG_NAME_COL                => 2;
use constant CONFIG_VALUE_COL               => 3;
use constant HOSTNAME_BLANK                 => 'HOSTNAME_BLANK';
use constant NAC_MASTER_WRITE_HOSTNAME      => 'NAC_MASTER_WRITE_HOSTNAME';
use constant NAC_MASTER_WRITE_PORT          => 'NAC_MASTER_WRITE_PORT';
use constant NAC_MASTER_WRITE_DB            => 'NAC_MASTER_WRITE_DB';
use constant NAC_MASTER_WRITE_USER          => 'NAC_MASTER_WRITE_USER';
use constant NAC_MASTER_WRITE_PASS          => 'NAC_MASTER_WRITE_PASS';
use constant NAC_EVENTLOG_WRITE_HOSTNAME    => 'NAC_EVENTLOG_WRITE_HOSTNAME';
use constant NAC_EVENTLOG_WRITE_PORT        => 'NAC_EVENTLOG_WRITE_PORT';
use constant NAC_EVENTLOG_WRITE_DB          => 'NAC_EVENTLOG_WRITE_DB';
use constant NAC_EVENTLOG_WRITE_USER        => 'NAC_EVENTLOG_WRITE_USER';
use constant NAC_EVENTLOG_WRITE_PASS        => 'NAC_EVENTLOG_WRITE_PASS';
use constant NAC_RADIUSAUDIT_WRITE_HOSTNAME => 'NAC_RADIUSAUDIT_WRITE_HOSTNAME';
use constant NAC_RADIUSAUDIT_WRITE_PORT     => 'NAC_RADIUSAUDIT_WRITE_PORT';
use constant NAC_RADIUSAUDIT_WRITE_DB       => 'NAC_RADIUSAUDIT_WRITE_DB';
use constant NAC_RADIUSAUDIT_WRITE_USER     => 'NAC_RADIUSAUDIT_WRITE_USER';
use constant NAC_RADIUSAUDIT_WRITE_PASS     => 'NAC_RADIUSAUDIT_WRITE_PASS';
use constant NAC_LOCAL_READONLY_HOSTNAME    => 'NAC_LOCAL_READONLY_HOSTNAME';
use constant NAC_LOCAL_READONLY_PORT        => 'NAC_LOCAL_READONLY_PORT';
use constant NAC_LOCAL_READONLY_DB          => 'NAC_LOCAL_READONLY_DB';
use constant NAC_LOCAL_READONLY_USER        => 'NAC_LOCAL_READONLY_USER';
use constant NAC_LOCAL_READONLY_PASS        => 'NAC_LOCAL_READONLY_PASS';
use constant NAC_LOCAL_BUFFER_HOSTNAME      => 'NAC_LOCAL_BUFFER_HOSTNAME';
use constant NAC_LOCAL_BUFFER_PORT          => 'NAC_LOCAL_BUFFER_PORT';
use constant NAC_LOCAL_BUFFER_DB            => 'NAC_LOCAL_BUFFER_DB';
use constant NAC_LOCAL_BUFFER_USER          => 'NAC_LOCAL_BUFFER_USER';
use constant NAC_LOCAL_BUFFER_PASS          => 'NAC_LOCAL_BUFFER_PASS';
use constant NAC_SLAVE_HOSTNAME             => 'NAC_SLAVE_HOSTNAME';
use constant NAC_IB_HOSTNAME                => 'NAC_IB_HOSTNAME';
use constant NAC_IB_USER                    => 'NAC_IB_USER';
use constant NAC_IB_PASS                    => 'NAC_IB_PASS';
use constant NAC_SWITCH_SNMP_STRING         => 'NAC_SWITCH_SNMP_STRING';
use constant NAC_SNMP_HOSTNAME              => 'SNMP_HOSTNAME';
use constant NAC_SNMP_COMMUNITY             => 'SNMP_COMMUNITY';
use constant NAC_SNMP_PORT                  => 'SNMP_PORT';
use constant NAC_SNMP_SESSION               => 'SNMP_SESSION';

our @EXPORT = qw (
  NAC_MASTER_WRITE_HOSTNAME
  NAC_MASTER_WRITE_PORT
  NAC_MASTER_WRITE_USER
  NAC_MASTER_WRITE_PASS
  NAC_MASTER_WRITE_DB
  NAC_MASTER_WRITE_DB_AUDIT
  NAC_MASTER_WRITE_DB_EVENTLOG
  NAC_MASTER_WRITE_DB_RADIUSAUDIT
  NAC_MASTER_WRITE_DB_STATUS
  NAC_MASTER_WRITE_DB_USER
  NAC_SLAVE_HOSTNAME
  NAC_SLAVE_PORT
  NAC_SLAVE_USER
  NAC_SLAVE_PASS
  NAC_SLAVE_DB_AUDIT
  NAC_SLAVE_DB_CONFIG
  NAC_SLAVE_DB_EVENTLOG
  NAC_SLAVE_DB_RADIUSAUDIT
  NAC_SLAVE_DB_STATUS
  NAC_SLAVE_DB_USER
  NAC_EVENTLOG_WRITE_HOSTNAME
  NAC_EVENTLOG_WRITE_PORT
  NAC_EVENTLOG_WRITE_DB
  NAC_EVENTLOG_WRITE_USER
  NAC_EVENTLOG_WRITE_PASS
  NAC_RADIUSAUDIT_WRITE_HOSTNAME
  NAC_RADIUSAUDIT_WRITE_PORT
  NAC_RADIUSAUDIT_WRITE_DB
  NAC_RADIUSAUDIT_WRITE_USER
  NAC_RADIUSAUDIT_WRITE_PASS
  NAC_LOCAL_READONLY_HOSTNAME
  NAC_LOCAL_READONLY_PORT
  NAC_LOCAL_READONLY_USER
  NAC_LOCAL_READONLY_PASS
  NAC_LOCAL_READONLY_DB
  NAC_LOCAL_READONLY_DB_AUDIT
  NAC_LOCAL_READONLY_DB_CONFIG
  NAC_LOCAL_BUFFER_HOSTNAME
  NAC_LOCAL_BUFFER_PORT
  NAC_LOCAL_BUFFER_DB
  NAC_LOCAL_BUFFER_USER
  NAC_LOCAL_BUFFER_PASS
  NAC_IB_HOSTNAME
  NAC_IB_USER
  NAC_IB_PASS
  NAC_SWITCH_SNMP_STRING
  NAC_SNMP_HOSTNAME
  NAC_SNMP_COMMUNITY
  NAC_SNMP_PORT
  NAC_SNMP_SESSION
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

    if ( !( $self->{CONFIG_RESULT} = $self->SUPER::do( GET_CONFIG_DATA_FUNCTION, $sqlobj ) ) ) {
        $LOGGER_FATAL->("UNABLE TO GET CONFIG DATA");
    }

}

# ---------------------------------------------
sub get_id_value {
    my ( $self, $id ) = @_;

    if ( !defined $id || isdigit($id) ) {
        $LOGGER_FATAL->("BAD ID PROVIDED, '$id'");
    }

    my ($row) = @{ $self->get( { CONFIG_ID => $id } ) };

    if ( !defined $row ) {
        $LOGGER_WARN->("ID PROVIDED DOES NOT EXIST, $id");
    }

    return ( defined $row ) ? $row->[CONFIG_VALUE_COL] : undef;
}

# ---------------------------------------------
sub get_value {
    my ( $self, $parms ) = @_;

    if ( defined $parms && ( 'HASH' ne ref($parms) ) ) {
        $LOGGER_FATAL->("PARM NOT HASH");
    }

    my ($row) = @{ $self->get($parms) };

    if ( !defined $row ) {
        $LOGGER_DEBUG_1->("PARMS PROVIDED DOES NOT EXIST");
    }

    return ( defined $row ) ? $row->[CONFIG_VALUE_COL] : undef;
}

# ---------------------------------------------
sub get_id {
    my ( $self, $parms ) = @_;

    if ( defined $parms && ( 'HASH' ne ref($parms) ) ) {
        $LOGGER_FATAL->("PARM NOT HASH");
    }

    my ($row) = @{ $self->get($parms) };

    if ( !defined $row ) {
        $LOGGER_DEBUG_1->("PARMS PROVIDED DO NOT EXIST");
    }

    return ( defined $row ) ? $row->[CONFIG_ID_COL] : undef;
}

# ---------------------------------------------
sub get_ids {
    my ( $self, $parms ) = @_;

    if ( defined $parms && ( 'HASH' ne ref($parms) ) ) {
        $LOGGER_FATAL->("PARM NOT HASH");
    }

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

    if ( defined $parms && ( 'HASH' ne ref($parms) ) ) {
        $LOGGER_FATAL->("PARM NOT HASH");
    }

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

    print Dumper $self->_result;
    exit;
    $self->_result->set_first_row();

    while ( my $row = $self->_result->next_row() ) {
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
