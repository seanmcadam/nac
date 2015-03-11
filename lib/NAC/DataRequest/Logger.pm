#!/usr/bin/perl

package NAC::DataRequest::Logger;

use base qw ( Exporter );
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::DataRequest;
use strict;

use constant LOG_PARM_LEVEL       => 'LOG_PARM_LEVEL';
use constant LOG_PARM_EVENT       => 'LOG_PARM_EVENT';
use constant LOG_PARM_MESSAGE     => 'LOG_PARM_MESSAGE';
use constant LOG_PARM_PACKAGE     => 'LOG_PARM_PACKAGE';
use constant LOG_PARM_PROGRAM     => 'LOG_PARM_PROGRAM';
use constant LOG_PARM_SUBROUTINE  => 'LOG_PARM_SUBROUTINE';
use constant LOG_PARM_HOSTNAME    => 'LOG_PARM_HOSTNAME';
use constant LOG_PARM_FILE        => 'LOG_PARM_FILE';
use constant LOG_PARM_LINE        => 'LOG_PARM_LINE';
use constant LOG_LEVEL_EVENT      => 'LOG_EVENT';
use constant LOG_LEVEL_FATAL      => 'LOG_FATAL';
use constant LOG_LEVEL_CRIT       => 'LOG_CRIT';
use constant LOG_LEVEL_ERROR      => 'LOG_ERROR';
use constant LOG_LEVEL_WARN       => 'LOG_WARN';
use constant LOG_LEVEL_NOTICE     => 'LOG_NOTICE';
use constant LOG_LEVEL_INFO       => 'LOG_INFO';
use constant LOG_LEVEL_DEBUG      => 'LOG_DEBUG';
use constant LOG_DEBUG_LEVEL      => 'LOG_DEBUG_LEVEL';
use constant LOG_DEBUG_LEVEL_NONE => 'DEBUG_LEVEL_NONE';
use constant LOG_DEBUG_LEVEL_0    => 'DEBUG_LEVEL_0';       # Tiny Debug
use constant LOG_DEBUG_LEVEL_1    => 'DEBUG_LEVEL_1';       # Sparse Debug
use constant LOG_DEBUG_LEVEL_2    => 'DEBUG_LEVEL_2';       # Light Debug
use constant LOG_DEBUG_LEVEL_3    => 'DEBUG_LEVEL_3';       # Moderate Debug
use constant LOG_DEBUG_LEVEL_4    => 'DEBUG_LEVEL_4';       # Medium Debug
use constant LOG_DEBUG_LEVEL_5    => 'DEBUG_LEVEL_5';       # Verbose Debug
use constant LOG_DEBUG_LEVEL_6    => 'DEBUG_LEVEL_6';       # Very Verbose Debug
use constant LOG_DEBUG_LEVEL_7    => 'DEBUG_LEVEL_7';       # Heavy Debug
use constant LOG_DEBUG_LEVEL_8    => 'DEBUG_LEVEL_8';       # Painful Debug
use constant LOG_DEBUG_LEVEL_9    => 'DEBUG_LEVEL_9';       # So Very Painful Debug

use constant EVENT_START                  => 'EVENT_START';
use constant EVENT_STOP                   => 'EVENT_STOP';
use constant EVENT_ACCT_STOP              => 'EVENT_ACCT_STOP';
use constant EVENT_ACCT_START             => 'EVENT_ACCT_START';
use constant EVENT_AUTH_CLEAR             => 'EVENT_AUTH_CLEAR';
use constant EVENT_AUTH_BLOCK             => 'EVENT_AUTH_BLOCK';
use constant EVENT_AUTH_CHALLENGE         => 'EVENT_AUTH_CHALLENGE';
use constant EVENT_AUTH_GUEST             => 'EVENT_AUTH_GUEST';
use constant EVENT_AUTH_MAC               => 'EVENT_AUTH_MAC';
use constant EVENT_AUTH_PORT              => 'EVENT_AUTH_PORT';
use constant EVENT_AUTH_VOICE             => 'EVENT_AUTH_VOICE';
use constant EVENT_AUTH_NAK               => 'EVENT_AUTH_NAK';
use constant EVENT_CHALLENGE_ERR          => 'EVENT_CHALLENGE_ERR';
use constant EVENT_CIDR_ADD               => 'EVENT_CIDR_ADD';
use constant EVENT_CIDR_DEL               => 'EVENT_CIDR_DEL';
use constant EVENT_CLASS_ADD              => 'EVENT_CLASS_ADD';
use constant EVENT_CLASS_DEL              => 'EVENT_CLASS_DEL';
use constant EVENT_CLASS_UPD              => 'EVENT_CLASS_UPD';
use constant EVENT_DB_ERR                 => 'EVENT_DB_ERR';
use constant EVENT_DB_WARN                => 'EVENT_DB_WARN';
use constant EVENT_FILTER_ADD             => 'EVENT_FILTER_ADD';
use constant EVENT_FILTER_DEL             => 'EVENT_FILTER_DEL';
use constant EVENT_FIXEDIP_ADD            => 'EVENT_FIXEDIP_ADD';
use constant EVENT_FIXEDIP_DEL            => 'EVENT_FIXEDIP_DEL';
use constant EVENT_FIXEDIP_UPD            => 'EVENT_FIXEDIP_UPD';
use constant EVENT_MAC2CLASS_ADD          => 'EVENT_MAC2CLASS_ADD';
use constant EVENT_MAC2CLASS_DEL          => 'EVENT_MAC2CLASS_DEL';
use constant EVENT_MAC2CLASS_UPD          => 'EVENT_MAC2CLASS_UPD';
use constant EVENT_MAC_ADD                => 'EVENT_MAC_ADD';
use constant EVENT_MAC_DEL                => 'EVENT_MAC_DEL';
use constant EVENT_MAC_UPD                => 'EVENT_MAC_UPD';
use constant EVENT_MAGIC_PORT             => 'EVENT_MAGIC_PORT';
use constant EVENT_MEMCACHE_ERR           => 'EVENT_MEMCACHE_ERR';
use constant EVENT_MEMCACHE_WARN          => 'EVENT_MEMCACHE_WARN';
use constant EVENT_LOC_ADD                => 'EVENT_LOC_ADD';
use constant EVENT_LOC_DEL                => 'EVENT_LOC_DEL';
use constant EVENT_LOC_UPD                => 'EVENT_LOC_UPD';
use constant EVENT_PORT_ADD               => 'EVENT_PORT_ADD';
use constant EVENT_PORT_DEL               => 'EVENT_PORT_DEL';
use constant EVENT_PORT2CLASS_ADD         => 'EVENT_PORT2CLASS_ADD';
use constant EVENT_PORT2CLASS_DEL         => 'EVENT_PORT2CLASS_DEL';
use constant EVENT_PORT2CLASS_UPD         => 'EVENT_PORT2CLASS_UPD';
use constant EVENT_SWITCH_ADD             => 'EVENT_SWITCH_ADD';
use constant EVENT_SWITCH_DEL             => 'EVENT_SWITCH_DEL';
use constant EVENT_SWITCH_UPD             => 'EVENT_SWITCH_UPD';
use constant EVENT_SWITCHPORT_ADD         => 'EVENT_SWITCHPORT_ADD';
use constant EVENT_SWITCHPORT_DEL         => 'EVENT_SWITCHPORT_DEL';
use constant EVENT_SWITCH2VLAN_ADD        => 'EVENT_SWITCH2VLAN_ADD';
use constant EVENT_SWITCH2VLAN_DEL        => 'EVENT_SWITCH2VLAN_DEL';
use constant EVENT_TEMPLATE_ADD           => 'EVENT_TEMPLATE_ADD';
use constant EVENT_TEMPLATE_DEL           => 'EVENT_TEMPLATE_DEL';
use constant EVENT_TEMPLATE2VLANGROUP_ADD => 'EVENT_TEMPLATE2VLANGROUP_ADD';
use constant EVENT_TEMPLATE2VLANGROUP_DEL => 'EVENT_TEMPLATE2VLANGROUP_DEL';
use constant EVENT_VLAN_ADD               => 'EVENT_VLAN_ADD';
use constant EVENT_VLAN_DEL               => 'EVENT_VLAN_DEL';
use constant EVENT_VLANGROUP_ADD          => 'EVENT_VLANGROUP_ADD';
use constant EVENT_VLANGROUP_DEL          => 'EVENT_VLANGROUP_DEL';
use constant EVENT_VLANGROUP2VLAN_ADD     => 'EVENT_VLANGROUP2VLAN_ADD';
use constant EVENT_VLANGROUP2VLAN_DEL     => 'EVENT_VLANGROUP2VLAN_DEL';
use constant EVENT_NOLOCATION             => 'EVENT_NOLOCATION';
use constant EVENT_SMTP_FAIL              => 'EVENT_SMTP_FAIL';
use constant EVENT_LOGIC_FAIL             => 'EVENT_LOGIC_FAIL';
use constant EVENT_EVAL_FAIL              => 'EVENT_EVAL_FAIL';
use constant EVENT_FUNC_FAIL              => 'EVENT_FUNC_FAIL';
use constant EVENT_CRIT                    => 'EVENT_CRIT';
use constant EVENT_ERR                    => 'EVENT_ERR';
use constant EVENT_WARN                   => 'EVENT_WARN';
use constant EVENT_NOTICE                 => 'EVENT_NOTICE';
use constant EVENT_INFO                   => 'EVENT_INFO';
use constant EVENT_DEBUG                  => 'EVENT_DEBUG';
use constant EVENT_FATAL                  => 'EVENT_FATAL';
use constant EVENT_DISTRESS               => 'EVENT_DISTRESS';

use constant LOG_DEFAULT_LEVEL       => LOG_LEVEL_DEBUG;
use constant LOG_DEFAULT_DEBUG_LEVEL => LOG_DEBUG_LEVEL_9;

our %log_events = (
    EVENT_START                  => EVENT_START,
    EVENT_STOP                   => EVENT_STOP,
    EVENT_ACCT_STOP              => EVENT_ACCT_STOP,
    EVENT_ACCT_START             => EVENT_ACCT_START,
    EVENT_AUTH_CLEAR             => EVENT_AUTH_CLEAR,
    EVENT_AUTH_BLOCK             => EVENT_AUTH_BLOCK,
    EVENT_AUTH_CHALLENGE         => EVENT_AUTH_CHALLENGE,
    EVENT_AUTH_GUEST             => EVENT_AUTH_GUEST,
    EVENT_AUTH_MAC               => EVENT_AUTH_MAC,
    EVENT_AUTH_PORT              => EVENT_AUTH_PORT,
    EVENT_AUTH_VOICE             => EVENT_AUTH_VOICE,
    EVENT_AUTH_NAK               => EVENT_AUTH_NAK,
    EVENT_CHALLENGE_ERR          => EVENT_CHALLENGE_ERR,
    EVENT_CIDR_ADD               => EVENT_CIDR_ADD,
    EVENT_CIDR_DEL               => EVENT_CIDR_DEL,
    EVENT_CLASS_ADD              => EVENT_CLASS_ADD,
    EVENT_CLASS_DEL              => EVENT_CLASS_DEL,
    EVENT_CLASS_UPD              => EVENT_CLASS_UPD,
    EVENT_DB_ERR                 => EVENT_DB_ERR,
    EVENT_DB_WARN                => EVENT_DB_WARN,
    EVENT_FILTER_ADD             => EVENT_FILTER_ADD,
    EVENT_FILTER_DEL             => EVENT_FILTER_DEL,
    EVENT_FIXEDIP_ADD            => EVENT_FIXEDIP_ADD,
    EVENT_FIXEDIP_DEL            => EVENT_FIXEDIP_DEL,
    EVENT_FIXEDIP_UPD            => EVENT_FIXEDIP_UPD,
    EVENT_MAC2CLASS_ADD          => EVENT_MAC2CLASS_ADD,
    EVENT_MAC2CLASS_DEL          => EVENT_MAC2CLASS_DEL,
    EVENT_MAC2CLASS_UPD          => EVENT_MAC2CLASS_UPD,
    EVENT_MAC_ADD                => EVENT_MAC_ADD,
    EVENT_MAC_DEL                => EVENT_MAC_DEL,
    EVENT_MAC_UPD                => EVENT_MAC_UPD,
    EVENT_MAGIC_PORT             => EVENT_MAGIC_PORT,
    EVENT_MEMCACHE_ERR           => EVENT_MEMCACHE_ERR,
    EVENT_MEMCACHE_WARN          => EVENT_MEMCACHE_WARN,
    EVENT_LOC_ADD                => EVENT_LOC_ADD,
    EVENT_LOC_DEL                => EVENT_LOC_DEL,
    EVENT_LOC_UPD                => EVENT_LOC_UPD,
    EVENT_PORT_ADD               => EVENT_PORT_ADD,
    EVENT_PORT_DEL               => EVENT_PORT_DEL,
    EVENT_PORT2CLASS_ADD         => EVENT_PORT2CLASS_ADD,
    EVENT_PORT2CLASS_DEL         => EVENT_PORT2CLASS_DEL,
    EVENT_PORT2CLASS_UPD         => EVENT_PORT2CLASS_UPD,
    EVENT_SWITCH_ADD             => EVENT_SWITCH_ADD,
    EVENT_SWITCH_DEL             => EVENT_SWITCH_DEL,
    EVENT_SWITCH_UPD             => EVENT_SWITCH_UPD,
    EVENT_SWITCHPORT_ADD         => EVENT_SWITCHPORT_ADD,
    EVENT_SWITCHPORT_DEL         => EVENT_SWITCHPORT_DEL,
    EVENT_SWITCH2VLAN_ADD        => EVENT_SWITCH2VLAN_ADD,
    EVENT_SWITCH2VLAN_DEL        => EVENT_SWITCH2VLAN_DEL,
    EVENT_TEMPLATE_ADD           => EVENT_TEMPLATE_ADD,
    EVENT_TEMPLATE_DEL           => EVENT_TEMPLATE_DEL,
    EVENT_TEMPLATE2VLANGROUP_ADD => EVENT_TEMPLATE2VLANGROUP_ADD,
    EVENT_TEMPLATE2VLANGROUP_DEL => EVENT_TEMPLATE2VLANGROUP_DEL,
    EVENT_VLAN_ADD               => EVENT_VLAN_ADD,
    EVENT_VLAN_DEL               => EVENT_VLAN_DEL,
    EVENT_VLANGROUP_ADD          => EVENT_VLANGROUP_ADD,
    EVENT_VLANGROUP_DEL          => EVENT_VLANGROUP_DEL,
    EVENT_VLANGROUP2VLAN_ADD     => EVENT_VLANGROUP2VLAN_ADD,
    EVENT_VLANGROUP2VLAN_DEL     => EVENT_VLANGROUP2VLAN_DEL,
    EVENT_NOLOCATION             => EVENT_NOLOCATION,
    EVENT_SMTP_FAIL              => EVENT_SMTP_FAIL,
    EVENT_LOGIC_FAIL             => EVENT_LOGIC_FAIL,
    EVENT_EVAL_FAIL              => EVENT_EVAL_FAIL,
    EVENT_FUNC_FAIL              => EVENT_FUNC_FAIL,
    EVENT_CRIT                   => EVENT_CRIT,
    EVENT_ERR                    => EVENT_ERR,
    EVENT_WARN                   => EVENT_WARN,
    EVENT_NOTICE                 => EVENT_NOTICE,
    EVENT_INFO                   => EVENT_INFO,
    EVENT_DEBUG                  => EVENT_DEBUG,
    EVENT_FATAL                  => EVENT_FATAL,
    EVENT_DISTRESS               => EVENT_DISTRESS,
);

our %logging_level = (
    LOG_LEVEL_EVENT  => 0,
    LOG_LEVEL_FATAL  => 0,
    LOG_LEVEL_CRIT   => 1,
    LOG_LEVEL_ERROR  => 2,
    LOG_LEVEL_WARN   => 3,
    LOG_LEVEL_NOTICE => 4,
    LOG_LEVEL_INFO   => 5,
    LOG_LEVEL_DEBUG  => 10,
);

our %debugging_level = (
    LOG_DEBUG_LEVEL_NONE => 0,
    LOG_DEBUG_LEVEL_0    => 1,
    LOG_DEBUG_LEVEL_1    => 2,
    LOG_DEBUG_LEVEL_2    => 3,
    LOG_DEBUG_LEVEL_3    => 4,
    LOG_DEBUG_LEVEL_4    => 5,
    LOG_DEBUG_LEVEL_5    => 6,
    LOG_DEBUG_LEVEL_6    => 7,
    LOG_DEBUG_LEVEL_7    => 8,
    LOG_DEBUG_LEVEL_8    => 9,
    LOG_DEBUG_LEVEL_9    => 10,
);

our @EXPORT = qw(
  %log_events
  %logging_level
  %debugging_level
  LOG_PARM_LEVEL
  LOG_PARM_EVENT
  LOG_PARM_MESSAGE
  LOG_PARM_PACKAGE
  LOG_PARM_PROGRAM
  LOG_PARM_SUBROUTINE
  LOG_PARM_FILE
  LOG_PARM_LINE
  LOG_LEVEL_EVENT
  LOG_LEVEL_FATAL
  LOG_LEVEL_CRIT
  LOG_LEVEL_ERROR
  LOG_LEVEL_WARN
  LOG_LEVEL_NOTICE
  LOG_LEVEL_INFO
  LOG_LEVEL_DEBUG
  LOG_DEFAULT_LEVEL
  LOG_DEFAULT_DEBUG_LEVEL
  LOG_DEBUG_LEVEL_0
  LOG_DEBUG_LEVEL_1
  LOG_DEBUG_LEVEL_2
  LOG_DEBUG_LEVEL_3
  LOG_DEBUG_LEVEL_4
  LOG_DEBUG_LEVEL_5
  LOG_DEBUG_LEVEL_6
  LOG_DEBUG_LEVEL_7
  LOG_DEBUG_LEVEL_8
  LOG_DEBUG_LEVEL_9
  LOG_DEBUG_LEVEL_NONE
  EVENT_START
  EVENT_STOP
  EVENT_ACCT_STOP
  EVENT_ACCT_START
  EVENT_AUTH_CLEAR
  EVENT_AUTH_BLOCK
  EVENT_AUTH_CHALLENGE
  EVENT_AUTH_GUEST
  EVENT_AUTH_MAC
  EVENT_AUTH_PORT
  EVENT_AUTH_VOICE
  EVENT_AUTH_NAK
  EVENT_CHALLENGE_ERR
  EVENT_CIDR_ADD
  EVENT_CIDR_DEL
  EVENT_CLASS_ADD
  EVENT_CLASS_DEL
  EVENT_CLASS_UPD
  EVENT_DB_ERR
  EVENT_DB_WARN
  EVENT_FILTER_ADD
  EVENT_FILTER_DEL
  EVENT_FIXEDIP_ADD
  EVENT_FIXEDIP_DEL
  EVENT_FIXEDIP_UPD
  EVENT_MAC2CLASS_ADD
  EVENT_MAC2CLASS_DEL
  EVENT_MAC2CLASS_UPD
  EVENT_MAC_ADD
  EVENT_MAC_DEL
  EVENT_MAC_UPD
  EVENT_MAGIC_PORT
  EVENT_MEMCACHE_ERR
  EVENT_MEMCACHE_WARN
  EVENT_LOC_ADD
  EVENT_LOC_DEL
  EVENT_LOC_UPD
  EVENT_PORT_ADD
  EVENT_PORT_DEL
  EVENT_PORT2CLASS_ADD
  EVENT_PORT2CLASS_DEL
  EVENT_PORT2CLASS_UPD
  EVENT_SWITCH_ADD
  EVENT_SWITCH_DEL
  EVENT_SWITCH_UPD
  EVENT_SWITCHPORT_ADD
  EVENT_SWITCHPORT_DEL
  EVENT_SWITCH2VLAN_ADD
  EVENT_SWITCH2VLAN_DEL
  EVENT_TEMPLATE_ADD
  EVENT_TEMPLATE_DEL
  EVENT_TEMPLATE2VLANGROUP_ADD
  EVENT_TEMPLATE2VLANGROUP_DEL
  EVENT_VLAN_ADD
  EVENT_VLAN_DEL
  EVENT_VLANGROUP_ADD
  EVENT_VLANGROUP_DEL
  EVENT_VLANGROUP2VLAN_ADD
  EVENT_VLANGROUP2VLAN_DEL
  EVENT_NOLOCATION
  EVENT_SMTP_FAIL
  EVENT_LOGIC_FAIL
  EVENT_EVAL_FAIL
  EVENT_FUNC_FAIL
  EVENT_CRIT
  EVENT_ERR
  EVENT_WARN
  EVENT_NOTICE
  EVENT_INFO
  EVENT_DEBUG
  EVENT_FATAL
  EVENT_DISTRESS
);

our @ISA = qw(NAC::DataRequest);

sub new {
    my ( $class, $parms ) = @_;

    my $level       = $parms->{LOG_PARM_LEVEL};
    my $debug_level = $parms->{LOG_PARM_LEVEL};
    my $event       = $parms->{LOG_PARM_EVENT};
    my $message     = $parms->{LOG_PARM_MESSAGE};
    my $program     = $parms->{LOG_PARM_PROGRAM};
    my $package     = $parms->{LOG_PARM_PACKAGE};
    my $hostname    = $parms->{LOG_PARM_HOSTNAME};
    my $file        = $parms->{LOG_PARM_FILE};
    my $line        = $parms->{LOG_PARM_LINE};
    my $sub         = $parms->{LOG_PARM_SUBROUTINE};

    my $data = {};
    $data->{LOG_LEVEL}       = $level;
    $data->{LOG_DEBUG_LEVEL} = $debug_level;
    $data->{LOG_EVENT}       = $event;
    $data->{LOG_MESSAGE}     = $message;
    $data->{LOG_HOSTNAME}    = $hostname;
    $data->{LOG_PROGRAM}     = $program;
    $data->{LOG_PACKAGE}     = $package;
    $data->{LOG_FILE}        = $file;
    $data->{LOG_LINE}        = $line;
    $data->{LOG_SUBROUTINE}  = $sub;

    my $self = $class->SUPER::new( $class, $data );
    bless $self, $class;
    $self;
}

# ----------------------------------
sub level {
    my ($self) = @_;
    $self->data->{LOG_LEVEL};
}

# ----------------------------------
sub debug_level {
    my ($self) = @_;
    $self->data->{LOG_DEBUG_LEVEL};
}

# ----------------------------------
sub event {
    my ($self) = @_;
    $self->data->{LOG_EVENT};
}

# ----------------------------------
sub message {
    my ($self) = @_;
    $self->data->{LOG_EVENT};
}

# ----------------------------------
sub hostname {
    my ($self) = @_;
    $self->data->{LOG_HOSTNAME};
}

# ----------------------------------
sub program {
    my ($self) = @_;
    $self->data->{LOG_PROGRAM};
}

# ----------------------------------
sub package {
    my ($self) = @_;
    $self->data->{LOG_PACKAGE};
}

# ----------------------------------
sub subroutine {
    my ($self) = @_;
    $self->data->{LOG_SUBROUTINE};
}

# ----------------------------------
sub file {
    my ($self) = @_;
    $self->data->{LOG_FILE};
}

# ----------------------------------
sub line {
    my ($self) = @_;
    $self->data->{LOG_LINE};
}

1;
