#!/usr/bin/perl
#
#
#
#
#

package NAC::IBWAPI::Network;
use FindBin;
use lib "$FindBin::Bin/../..";
use Readonly;
use strict;
use base qw( Exporter );
our @ISA = qw(NAC::IBWAPI);


sub GET;

our @EXPORT = qw (
GET
);

Readonly our %return_fields => (
    $authority                           => 'authority',
    $auto_create_reversezone             => 'auto_create_reversezone',
    $bootfile                            => 'bootfile',
    $bootserver                          => 'bootserver',
    $comment                             => 'comment',
    $ddns_domainname                     => 'ddns_domainname',
    $ddns_generate_hostname              => 'ddns_generate_hostname',
    $ddns_server_always_updates          => 'ddns_server_always_updates',
    $ddns_ttl                            => 'ddns_ttl',
    $ddns_update_fixed_addresses         => 'ddns_update_fixed_addresses',
    $ddns_use_option81                   => 'ddns_use_option81',
    $deny_bootp                          => 'deny_bootp',
    $disable                             => 'disable',
    $email_list                          => 'email_list',
    $enable_ddns                         => 'enable_ddns',
    $enable_dhcp_thresholds              => 'enable_dhcp_thresholds',
    $enable_email_warnings               => 'enable_email_warnings',
    $enable_ifmap_publishing             => 'enable_ifmap_publishing',
    $enable_snmp_warnings                => 'enable_snmp_warnings',
    $extattrs                            => 'extattrs',
    $high_water_mark                     => 'high_water_mark',
    $high_water_mark_reset               => 'high_water_mark_reset',
    $ignore_dhcp_option_list_request     => 'ignore_dhcp_option_list_request',
    $ipv4addr                            => 'ipv4addr',
    $lease_scavenge_time                 => 'lease_scavenge_time',
    $low_water_mark                      => 'low_water_mark',
    $low_water_mark_reset                => 'low_water_mark_reset',
    $members                             => 'members',
    $netmask                             => 'netmask',
    $network                             => 'network',
    $network_container                   => 'network_container',
    $network_view                        => 'network_view',
    $nextserver                          => 'nextserver',
    $options                             => 'options',
    $pxe_lease_time                      => 'pxe_lease_time',
    $recycle_leases                      => 'recycle_leases',
    $template                            => 'template',
    $update_dns_on_lease_renewal         => 'update_dns_on_lease_renewal',
    $use_authority                       => 'use_authority',
    $use_bootfile                        => 'use_bootfile',
    $use_bootserver                      => 'use_bootserver',
    $use_ddns_domainname                 => 'use_ddns_domainname',
    $use_ddns_generate_hostname          => 'use_ddns_generate_hostname',
    $use_ddns_ttl                        => 'use_ddns_ttl',
    $use_ddns_update_fixed_addresses     => 'use_ddns_update_fixed_addresses',
    $use_ddns_use_option81               => 'use_ddns_use_option81',
    $use_deny_bootp                      => 'use_deny_bootp',
    $use_email_list                      => 'use_email_list',
    $use_enable_ddns                     => 'use_enable_ddns',
    $use_enable_dhcp_thresholds          => 'use_enable_dhcp_thresholds',
    $use_enable_ifmap_publishing         => 'use_enable_ifmap_publishing',
    $use_ignore_dhcp_option_list_request => 'use_ignore_dhcp_option_list_request',
    $use_lease_scavenge_time             => 'use_lease_scavenge_time',
    $use_nextserver                      => 'use_nextserver',
    $use_options                         => 'use_options',
    $use_recycle_leases                  => 'use_recycle_leases',
    $use_update_dns_on_lease_renewal     => 'use_update_dns_on_lease_renewal',
    $use_zone_associations               => 'use_zone_associations',
    $zone_associations                   => 'zone_associations',
);

sub OBJECT_NAME {
    return $IB_NETWORK;
}

# -----------------------------------------
# Optional point to a JSON object from a get for a network object
# -----------------------------------------
sub new {
    my ( $class, $parm_ref ) = @_;
    my $self;

    print "new() $class\n";

    # $self = $class->SUPER::new();
    $self = NAC::IBWAPI->new();

    if( ref($self) ne 'NAC::IBWAPI' ) { confess; }

    bless $self, $class;

    # print "REF $class new(): " . ref($self) . "\n";

    $self->{$IB_OBJECT}             = $IB_NETWORK;
    $self->{$_OBJECT_RETURN_FIELDS} = \%return_fields;

    return $self;
}

# -----------------------------------------
sub GET {
    my ( $class, $parm_ref ) = @_;

    print "GET() $class\n";

    my $self = $class->new();

    print "GOT() $class DUMP:\n";
    print "REF $class new(): " . ref($self) . "\n";

    $self->{$_IB_PARM_REF} = \%parm_ref;

    $self->_get();
}

sub authority                           { not_impl; }
sub auto_create_reversezone             { not_impl; }
sub bootfile                            { not_impl; }
sub bootserver                          { not_impl; }
sub comment                             { not_impl; }
sub ddns_domainname                     { not_impl; }
sub ddns_generate_hostname              { not_impl; }
sub ddns_server_always_updates          { not_impl; }
sub ddns_ttl                            { not_impl; }
sub ddns_update_fixed_addresses         { not_impl; }
sub ddns_use_option81                   { not_impl; }
sub deny_bootp                          { not_impl; }
sub disable                             { not_impl; }
sub email_list                          { not_impl; }
sub enable_ddns                         { not_impl; }
sub enable_dhcp_thresholds              { not_impl; }
sub enable_email_warnings               { not_impl; }
sub enable_ifmap_publishing             { not_impl; }
sub enable_snmp_warnings                { not_impl; }
sub extattrs                            { not_impl; }
sub high_water_mark                     { not_impl; }
sub high_water_mark_reset               { not_impl; }
sub ignore_dhcp_option_list_request     { not_impl; }
sub ipv4addr                            { not_impl; }
sub lease_scavenge_time                 { not_impl; }
sub low_water_mark                      { not_impl; }
sub low_water_mark_reset                { not_impl; }
sub members                             { not_impl; }
sub netmask                             { not_impl; }
sub network                             { not_impl; }
sub network_container                   { not_impl; }
sub network_view                        { not_impl; }
sub nextserver                          { not_impl; }
sub options                             { not_impl; }
sub pxe_lease_time                      { not_impl; }
sub recycle_leases                      { not_impl; }
sub template                            { not_impl; }
sub update_dns_on_lease_renewal         { not_impl; }
sub use_authority                       { not_impl; }
sub use_bootfile                        { not_impl; }
sub use_bootserver                      { not_impl; }
sub use_ddns_domainname                 { not_impl; }
sub use_ddns_generate_hostname          { not_impl; }
sub use_ddns_ttl                        { not_impl; }
sub use_ddns_update_fixed_addresses     { not_impl; }
sub use_ddns_use_option81               { not_impl; }
sub use_deny_bootp                      { not_impl; }
sub use_email_list                      { not_impl; }
sub use_enable_ddns                     { not_impl; }
sub use_enable_dhcp_thresholds          { not_impl; }
sub use_enable_ifmap_publishing         { not_impl; }
sub use_ignore_dhcp_option_list_request { not_impl; }
sub use_lease_scavenge_time             { not_impl; }
sub use_nextserver                      { not_impl; }
sub use_options                         { not_impl; }
sub use_recycle_leases                  { not_impl; }
sub use_update_dns_on_lease_renewal     { not_impl; }
sub use_zone_associations               { not_impl; }
sub zone_associations                   { not_impl; }

1;
