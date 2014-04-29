#!/usr/bin/perl
#
#
#
#
#

package NAC::IBWAPI::Network;
use FindBin;
use Readonly;
use lib "$FindBin::Bin/../..";
use base qw( Exporter );

Readonly our $authority                           => 'authority';
Readonly our $auto_create_reversezone             => 'auto_create_reversezone';
Readonly our $bootfile                            => 'bootfile';
Readonly our $bootserver                          => 'bootserver';
Readonly our $comment                             => 'comment';
Readonly our $ddns_domainname                     => 'ddns_domainname';
Readonly our $ddns_generate_hostname              => 'ddns_generate_hostname';
Readonly our $ddns_server_always_updates          => 'ddns_server_always_updates';
Readonly our $ddns_ttl                            => 'ddns_ttl';
Readonly our $ddns_update_fixed_addresses         => 'ddns_update_fixed_addresses';
Readonly our $ddns_use_option81                   => 'ddns_use_option81';
Readonly our $deny_bootp                          => 'deny_bootp';
Readonly our $disable                             => 'disable';
Readonly our $email_list                          => 'email_list';
Readonly our $enable_ddns                         => 'enable_ddns';
Readonly our $enable_dhcp_thresholds              => 'enable_dhcp_thresholds';
Readonly our $enable_email_warnings               => 'enable_email_warnings';
Readonly our $enable_ifmap_publishing             => 'enable_ifmap_publishing';
Readonly our $enable_snmp_warnings                => 'enable_snmp_warnings';
Readonly our $extattrs                            => 'extattrs';
Readonly our $high_water_mark                     => 'high_water_mark';
Readonly our $high_water_mark_reset               => 'high_water_mark_reset';
Readonly our $ignore_dhcp_option_list_request     => 'ignore_dhcp_option_list_request';
Readonly our $ipv4addr                            => 'ipv4addr';
Readonly our $lease_scavenge_time                 => 'lease_scavenge_time';
Readonly our $low_water_mark                      => 'low_water_mark';
Readonly our $low_water_mark_reset                => 'low_water_mark_reset';
Readonly our $members                             => 'members';
Readonly our $netmask                             => 'netmask';
Readonly our $network                             => 'network';
Readonly our $network_container                   => 'network_container';
Readonly our $network_view                        => 'network_view';
Readonly our $nextserver                          => 'nextserver';
Readonly our $options                             => 'options';
Readonly our $pxe_lease_time                      => 'pxe_lease_time';
Readonly our $recycle_leases                      => 'recycle_leases';
Readonly our $template                            => 'template';
Readonly our $update_dns_on_lease_renewal         => 'update_dns_on_lease_renewal';
Readonly our $use_authority                       => 'use_authority';
Readonly our $use_bootfile                        => 'use_bootfile';
Readonly our $use_bootserver                      => 'use_bootserver';
Readonly our $use_ddns_domainname                 => 'use_ddns_domainname';
Readonly our $use_ddns_generate_hostname          => 'use_ddns_generate_hostname';
Readonly our $use_ddns_ttl                        => 'use_ddns_ttl';
Readonly our $use_ddns_update_fixed_addresses     => 'use_ddns_update_fixed_addresses';
Readonly our $use_ddns_use_option81               => 'use_ddns_use_option81';
Readonly our $use_deny_bootp                      => 'use_deny_bootp';
Readonly our $use_email_list                      => 'use_email_list';
Readonly our $use_enable_ddns                     => 'use_enable_ddns';
Readonly our $use_enable_dhcp_thresholds          => 'use_enable_dhcp_thresholds';
Readonly our $use_enable_ifmap_publishing         => 'use_enable_ifmap_publishing';
Readonly our $use_ignore_dhcp_option_list_request => 'use_ignore_dhcp_option_list_request';
Readonly our $use_lease_scavenge_time             => 'use_lease_scavenge_time';
Readonly our $use_nextserver                      => 'use_nextserver';
Readonly our $use_options                         => 'use_options';
Readonly our $use_recycle_leases                  => 'use_recycle_leases';
Readonly our $use_update_dns_on_lease_renewal     => 'use_update_dns_on_lease_renewal';
Readonly our $use_zone_associations               => 'use_zone_associations';
Readonly our $zone_associations                   => 'zone_associations';

our @ISA    = qw(NAC::IBWAPI);
our @EXPORT = qw (
);

#
# Optionl point to a JSON object from a get for a network object
#
sub new() {
    my ( $class, $parm_ref ) = @_;
    my $self;
    $self = $class->SUPER::new( \%parms );

    $self->{$authority}                           = undef;
    $self->{$auto_create_reversezone}             = undef;
    $self->{$bootfile}                            = undef;
    $self->{$bootserver}                          = undef;
    $self->{$comment}                             = undef;
    $self->{$ddns_domainname}                     = undef;
    $self->{$ddns_generate_hostname}              = undef;
    $self->{$ddns_server_always_updates}          = undef;
    $self->{$ddns_ttl}                            = undef;
    $self->{$ddns_update_fixed_addresses}         = undef;
    $self->{$ddns_use_option81}                   = undef;
    $self->{$deny_bootp}                          = undef;
    $self->{$disable}                             = undef;
    $self->{$email_list}                          = undef;
    $self->{$enable_ddns}                         = undef;
    $self->{$enable_dhcp_thresholds}              = undef;
    $self->{$enable_email_warnings}               = undef;
    $self->{$enable_ifmap_publishing}             = undef;
    $self->{$enable_snmp_warnings}                = undef;
    $self->{$extattrs}                            = undef;
    $self->{$high_water_mark}                     = undef;
    $self->{$high_water_mark_reset}               = undef;
    $self->{$ignore_dhcp_option_list_request}     = undef;
    $self->{$ipv4addr}                            = undef;
    $self->{$lease_scavenge_time}                 = undef;
    $self->{$low_water_mark}                      = undef;
    $self->{$low_water_mark_reset}                = undef;
    $self->{$members}                             = undef;
    $self->{$netmask}                             = undef;
    $self->{$network}                             = undef;
    $self->{$network_container}                   = undef;
    $self->{$network_view}                        = undef;
    $self->{$nextserver}                          = undef;
    $self->{$options}                             = undef;
    $self->{$pxe_lease_time}                      = undef;
    $self->{$recycle_leases}                      = undef;
    $self->{$template}                            = undef;
    $self->{$update_dns_on_lease_renewal}         = undef;
    $self->{$use_authority}                       = undef;
    $self->{$use_bootfile}                        = undef;
    $self->{$use_bootserver}                      = undef;
    $self->{$use_ddns_domainname}                 = undef;
    $self->{$use_ddns_generate_hostname}          = undef;
    $self->{$use_ddns_ttl}                        = undef;
    $self->{$use_ddns_update_fixed_addresses}     = undef;
    $self->{$use_ddns_use_option81}               = undef;
    $self->{$use_deny_bootp}                      = undef;
    $self->{$use_email_list}                      = undef;
    $self->{$use_enable_ddns}                     = undef;
    $self->{$use_enable_dhcp_thresholds}          = undef;
    $self->{$use_enable_ifmap_publishing}         = undef;
    $self->{$use_ignore_dhcp_option_list_request} = undef;
    $self->{$use_lease_scavenge_time}             = undef;
    $self->{$use_nextserver}                      = undef;
    $self->{$use_options}                         = undef;
    $self->{$use_recycle_leases}                  = undef;
    $self->{$use_update_dns_on_lease_renewal}     = undef;
    $self->{$use_zone_associations}               = undef;
    $self->{$zone_associations}                   = undef;

    EventLog( EVENT_DEBUG, MYNAME . "() started" );

    bless $self, $class;

    $self;

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
