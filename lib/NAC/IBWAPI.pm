#!/usr/bin/perl
# SVN: $Id: NACDB.pm 1406 2012-05-06 00:18:59Z sean $
#
# version	$Revision: 1750 $:
# lastmodified	$Date: 2012-05-05 20:18:59 -0400 (Sat, 05 May 2012) $:
# modifiedby	$LastChangedBy: sean $:
# URL       	$URL: svn://svn/nac/release/dev-rel-2.1/lib/NAC/IB.pm $:
#
#
#
# Author: Sean McAdam
#
#
# Purpose: Provide controlled access to the Infoblox devices
#
#---------------------------------------------------------------------------
#
# new () - Create base WAPI object
# GET ( Object_type, Params ) - Get Object(s)
# POST ( Object_type, Params ) - Create new object
# PUT ( Object )
# DELETE ( Object )
#

#---------------------------------------------------------------------------
package NAC::IBWAPI;
use FindBin;
use lib "$FindBin::Bin/..";

use base qw( Exporter );

use Carp;
use warnings;
use Data::Dumper;
use LWP::Simple;
use JSON;
use NAC::Syslog;
use NAC::ConfigDB;
use NAC::Constants;
use Readonly;
use strict;

use Class::Inspector;

#---------------------------------------------------------------------------
# Global readonly variable setup
#---------------------------------------------------------------------------
Readonly our $PACKAGE                 => __PACKAGE__;
Readonly our $_IB_HTTPS               => 'https://';
Readonly our $_IB_JSON                => 'json';
Readonly our $_IB_URI                 => '/wapi/v1.2/';
Readonly our $_IB_REF                 => '_ref';
Readonly our $_IB_OPTIONS             => 'options';
Readonly our $_IB_EXTATTRS            => 'extattrs';
Readonly our $_IB_DEFAULT_MAX_RESULTS => 5000;

Readonly our $_IB_URL_REF           => '_IB_URL_REF_';
Readonly our $_IB_PARM_REF          => '_IB_PARM_REF_';
Readonly our $_IB_OBJECT_NAME       => '_IB_OBJECT_NAME_';
Readonly our $_IB_OBJECTS_REF       => '_IB_OBJECTS_REF_';
Readonly our $_OBJECT_RETURN_FIELDS => '_OBJECT_RETURN_FIELDS';

my $config = NAC::ConfigDB->new();
Readonly my $_IB_USERID   => $config->nac_ib_user;
Readonly my $_IB_PASSWORD => $config->nac_ib_pass;
Readonly my $_IB_HOSTNAME => $config->nac_ib_hostname;
$config = undef;

Readonly my $_IB_URL => $_IB_HTTPS
  . $_IB_USERID . ':'
  . $_IB_PASSWORD . '@'
  . $_IB_HOSTNAME
  . $_IB_URI;

#---------------------------------------------------------------------------

Readonly our $IB_URL_REF => 'IB_URL_REF';

Readonly our $IB_MAX_RESULTS           => 'IB_MAX_RESULTS';
Readonly our $IB_RETURN_TYPE           => 'IB_RETURN_TYPE';
Readonly our $IB_RETURN_FIELDS         => 'IB_RETURN_FIELDS';
Readonly our $IB_RETURN_FIELD_EXTATTRS => 'IB_FIELD_EXTATTRS';
Readonly our $IB_RETURN_FIELD_OPTIONS  => 'IB_FIELD_OPTIONS';
Readonly our $IB_OBJECT                => 'IB_OBJECT';

#
# IB Object Type Names
#
Readonly our $IB_FIXEDADDRESS         => 'IB_OBJECT_TYPE_FIXEDADDRESS';
Readonly our $IB_GRIP                 => 'IB_OBJECT_TYPE_GRIP';
Readonly our $IB_IPV4ADDRESS          => 'IB_OBJECT_TYPE_IPV4ADDRESS';
Readonly our $IB_IPV6ADDRESS          => 'IB_OBJECT_TYPE_IPV6ADDRESS';
Readonly our $IB_IPV6FIXEDADDRESS     => 'IB_OBJECT_TYPE_IPV6FIXEDADDRESS';
Readonly our $IB_IPV6NETWORK          => 'IB_OBJECT_TYPE_IPV6NETWORK';
Readonly our $IB_IPV6NETWORKCONTAINER => 'IB_OBJECT_TYPE_IPV6NETWORKCONTAINER';
Readonly our $IB_IPV6RANGE            => 'IB_OBJECT_TYPE_IPV6RANGE';
Readonly our $IB_LEASE                => 'IB_OBJECT_TYPE_LEASE';
Readonly our $IB_MACFILTERADDRESS     => 'IB_OBJECT_TYPE_MACFILTERADDRESS';
Readonly our $IB_MEMBER               => 'IB_OBJECT_TYPE_MEMBER';
Readonly our $IB_NAMEDACL             => 'IB_OBJECT_TYPE_NAMEDACL';
Readonly our $IB_NETWORK              => 'IB_OBJECT_TYPE_NETWORK';
Readonly our $IB_NETWORKCONTAINER     => 'IB_OBJECT_TYPE_NETWORKCONTAINER';
Readonly our $IB_NETWORKVIEW          => 'IB_OBJECT_TYPE_NETWORKVIEW';
Readonly our $IB_RANGE                => 'IB_OBJECT_TYPE_RANGE';
Readonly our $IB_RECORD_A             => 'IB_OBJECT_TYPE_RECORD_A';
Readonly our $IB_RECORD_AAAA          => 'IB_OBJECT_TYPE_RECORD_AAAA';
Readonly our $IB_RECORD_CNAME         => 'IB_OBJECT_TYPE_RECORD_CNAME';
Readonly our $IB_RECORD_HOST          => 'IB_OBJECT_TYPE_RECORD_HOST';
Readonly our $IB_RECORD_IPV4ADDR      => 'IB_OBJECT_TYPE_RECORD_HOST_IPV4ADDR';
Readonly our $IB_RECORD_IPV6ADDR      => 'IB_OBJECT_TYPE_RECORD_HOST_IPV6ADDR';
Readonly our $IB_RECORD_MX            => 'IB_OBJECT_TYPE_RECORD_MX';
Readonly our $IB_RECORD_PTR           => 'IB_OBJECT_TYPE_RECORD_PTR';
Readonly our $IB_RECORD_SRV           => 'IB_OBJECT_TYPE_RECORD_SRV';
Readonly our $IB_RECORD_TXT           => 'IB_OBJECT_TYPE_RECORD_TXT';
Readonly our $IB_RESTARTSERVICESTATUS => 'IB_OBJECT_TYPE_RESTARTSERVICESTATUS';
Readonly our $IB_SCHEDULEDTASK        => 'IB_OBJECT_TYPE_SCHEDULEDTASK';
Readonly our $IB_SEARCH               => 'IB_OBJECT_TYPE_SEARCH';
Readonly our $IB_VIEW                 => 'IB_OBJECT_TYPE_VIEW';
Readonly our $IB_ZONE_AUTH            => 'IB_OBJECT_TYPE_ZONE_AUTH';
Readonly our $IB_ZONE_DELEGATE        => 'IB_OBJECT_TYPE_ZONE_DELEGATE';
Readonly our $IB_ZONE_FORWARD         => 'IB_OBJECT_TYPE_ZONE_FORWARD';
Readonly our $IB_ZONE_STUB            => 'IB_OBJECT_TYPE_ZONE_STUB';

#
# Acceptable Object to Request
#
our %_IB_OBJECTS = (
    $IB_FIXEDADDRESS         => 'FixedAddress',
    $IB_GRIP                 => 'Grid',
    $IB_IPV4ADDRESS          => 'IPv4Address',
    $IB_IPV6ADDRESS          => 'IPv6Address',
    $IB_IPV6FIXEDADDRESS     => 'IPv6FixedAddress',
    $IB_IPV6NETWORK          => 'IPv6Network',
    $IB_IPV6NETWORKCONTAINER => 'IPv6NetworkContainer',
    $IB_IPV6RANGE            => 'IPv6Range',
    $IB_LEASE                => 'Lease',
    $IB_MACFILTERADDRESS     => 'MacFilterAddress',
    $IB_MEMBER               => 'Member',
    $IB_NAMEDACL             => 'NamedACL',
    $IB_NETWORK              => 'Network',
    $IB_NETWORKCONTAINER     => 'NetworkContainer',
    $IB_NETWORKVIEW          => 'NetworkView',
    $IB_RANGE                => 'Range',
    $IB_RECORD_A             => 'Record_A',
    $IB_RECORD_AAAA          => 'Record_AAAA',
    $IB_RECORD_CNAME         => 'Record_CNAME',
    $IB_RECORD_HOST          => 'Record_HOST',
    $IB_RECORD_IPV4ADDR      => 'Record_IPv4Addr',
    $IB_RECORD_IPV6ADDR      => 'Record_IPv6Addr',
    $IB_RECORD_MX            => 'Record_MX',
    $IB_RECORD_PTR           => 'Record_PTR',
    $IB_RECORD_SRV           => 'Record_SRV',
    $IB_RECORD_TXT           => 'Record_TXT',
    $IB_RESTARTSERVICESTATUS => 'RestartServiceStatus',
    $IB_SCHEDULEDTASK        => 'ScheduleTask',
    $IB_SEARCH               => 'Search',
    $IB_VIEW                 => 'View',
    $IB_ZONE_AUTH            => 'Zone_Auth',
    $IB_ZONE_DELEGATE        => 'Zone_Delegate',
    $IB_ZONE_FORWARD         => 'Zone_Forward',
    $IB_ZONE_STUB            => 'Zone_Stub',
);

#
# Return Fields
#
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

sub not_impl;

our @EXPORT = qw (
  $IB_MAX_RESULTS
  $IB_RETURN_TYPE
  $IB_RETURN_FIELDS
  $IB_RETURN_FIELD_EXTATTRS
  $IB_RETURN_FIELD_OPTIONS
  $IB_OBJECT
  $IB_NETWORK
  $authority
  $auto_create_reversezone
  $bootfile
  $bootserver
  $comment
  $ddns_domainname
  $ddns_generate_hostname
  $ddns_server_always_updates
  $ddns_ttl
  $ddns_update_fixed_addresses
  $ddns_use_option81
  $deny_bootp
  $disable
  $email_list
  $enable_ddns
  $enable_dhcp_thresholds
  $enable_email_warnings
  $enable_ifmap_publishing
  $enable_snmp_warnings
  $extattrs
  $high_water_mark
  $high_water_mark_reset
  $ignore_dhcp_option_list_request
  $ipv4addr
  $lease_scavenge_time
  $low_water_mark
  $low_water_mark_reset
  $members
  $netmask
  $network
  $network_container
  $network_view
  $nextserver
  $options
  $pxe_lease_time
  $recycle_leases
  $template
  $update_dns_on_lease_renewal
  $use_authority
  $use_bootfile
  $use_bootserver
  $use_ddns_domainname
  $use_ddns_generate_hostname
  $use_ddns_ttl
  $use_ddns_update_fixed_addresses
  $use_ddns_use_option81
  $use_deny_bootp
  $use_email_list
  $use_enable_ddns
  $use_enable_dhcp_thresholds
  $use_enable_ifmap_publishing
  $use_ignore_dhcp_option_list_request
  $use_lease_scavenge_time
  $use_nextserver
  $use_options
  $use_recycle_leases
  $use_update_dns_on_lease_renewal
  $use_zone_associations
  $zone_associations
);


our %_IB_VARIABLES = (
    $IB_MAX_RESULTS   => '_max_results',
    $IB_RETURN_TYPE   => '_return_type',
    $IB_RETURN_FIELDS => '_return_fields',
);


our %_IB_PARAMETERS = (
    $IB_NETWORK               => 'network',
    $IB_MAX_RESULTS           => '_max_results',
    $IB_RETURN_TYPE           => '_return_type',
    $IB_RETURN_FIELDS         => '_return_fields',
    $IB_RETURN_FIELD_EXTATTRS => 'extattrs',
    $IB_RETURN_FIELD_OPTIONS  => 'options',
);



#-----------------------------------------------------------
# Sets up connection to the server
#-----------------------------------------------------------
sub new {
    my ( $class, $parm_ref ) = @_;
    my $self;
    my %h;

    $self = \%h;

    $self->{$_IB_URL_REF}     = \$_IB_URL;
    $self->{$_IB_OBJECTS_REF} = \%_IB_OBJECTS;
    $self->{$IB_RETURN_TYPE}  = $_IB_JSON; 
    $self->{$IB_MAX_RESULTS}  = $_IB_DEFAULT_MAX_RESULTS;

    # Filled in by Child
    $self->{$IB_OBJECT}             = 0;
    $self->{$_OBJECT_RETURN_FIELDS} = 0;

    EventLog( EVENT_DEBUG, MYNAME . "() started" );

    bless $self, $class;

    return $self;
}

#-----------------------------------------------------------
#sub get_ib_object_name {
#    my ( $self, $obj_name ) = @_;
#    if( ! defined $self->{$IB_OBJECT} || ! $self->{$IB_OBJECT} ) { confess "No Object name Defined\n"; }
#    $name = $self->{$IB_OBJECT};
#    if( ! defined $self->{$_IB_OBJECTS_REF}->{$obj_name} ) { confess "Bad Name $obj_name\n"; }
#
#    return $self->{$_IB_OBJECTS_REF}->{$name};
#}

#-----------------------------------------------------------
# Gets Objects(s) Type, Param
# Returns Array of __PACKAGE__::Object
#-----------------------------------------------------------
sub GET {
    my ( $self, $obj_name, $parm_ref ) = @_;
    my $f = 'GET';
    my $ret;

    if ( ref($self) eq '' ) { confess @_; }

    if ( !defined $_IB_OBJECTS{$obj_name} ) { confess @_; }

    my $obj = $_IB_OBJECTS{$obj_name};
    my $p   = $PACKAGE . "::" . $obj;

    # eval "require $p;";
    eval "use $p;";

print "$p\n";
print "INSTALLED\n" if Class::Inspector->installed( $p );
print "LOADED\n" if Class::Inspector->loaded( $p );
print "FUNCTIONS: " . Dumper( Class::Inspector->functions( $p ));
print "METHODS: " . Dumper( Class::Inspector->methods( $p, "full" ));

print "FILENAME:" . Class::Inspector->filename( $p ) . "\n";
print "RESOLVED FILENAME:" . Class::Inspector->resolved_filename( $p ) . "\n";;

 


print "PACKAGE $p\n";
print "FUNCTION: $f\n";

    $ret = $p->$f($parm_ref);


$ret;

}

#-----------------------------------------------------------
# Creates Object Type, Param
#-----------------------------------------------------------
sub POST {
    my $class    = shift;
    my $obj_type = shift;
    my $dir      = $class;
    $dir =~ s/::/\//g;

    if ( !defined $_IB_OBJECTS{$obj_type} ) { confess "No object type $obj_type\n"; }

    #
    # Error Checking
    # Verify package exists
    #

    my $obj_name     = $_IB_OBJECTS{$obj_type};
    my $package_file = $dir . "/" . $obj_name . '.pm';
    my $new_class    = $class . "::" . $obj_name;

    require $package_file;

    # POST the request, and then GET it.

}

#-----------------------------------------------------------
# Update Object  Object::PUT(Object) or Object->PUT()
#-----------------------------------------------------------
sub PUT {
    my $class = shift;
    my $obj   = shift;
}

#-----------------------------------------------------------
# Deletes Object
#-----------------------------------------------------------
sub DELETE {
    my $class = shift;
    my $obj   = shift;
}

# -------------------------------------------------------------------
sub not_impl {
    EventLog( EVENT_DEBUG, MYNAME . "() - not implemented yet" );
    return undef;
}

#-----------------------------------------------------------
sub _object_name {
    my ($self) = @_;
    if ( !defined $self->{$_IB_OBJECT_NAME} ) { confess; }
    return $self->{$_IB_OBJECT_NAME};
}

#-----------------------------------------------------------
sub _get {
    my ($self) = @_;
    my $parm_ref = 0;

    if( ! defined $self->{$IB_OBJECT} || ! $self->{$IB_OBJECT} ) { confess Dumper @_; }

    if ( defined $self->{$_IB_PARM_REF} && $self->{$_IB_PARM_REF} ) {
        $parm_ref = $self->{$_IB_PARM_REF};
    }

    my $url =
      $_IB_URL
      . $self->{$IB_OBJECT}
      . '?'
      . $_IB_PARAMETERS{$IB_MAX_RESULTS} . '='
      . $self->{$IB_MAX_RESULTS}
      . '&'
      . $_IB_PARAMETERS{$IB_RETURN_TYPE} . '='
      . $self->{$IB_RETURN_TYPE}
      ;

    if( $parm_ref ) {
    	foreach my $p ( sort( keys(%$parm_ref) ) ) {
    	    $url .= '&' . $_IB_PARAMETERS{$p} . '=' . $parm_ref->{$p};
    	}
    }

    print "URL = $url\n";

    my $ret = get $url;

    print Dumper from_json($ret);
    exit;

}

#-----------------------------------------------------------

sub _verify_object_name {
    my ( $self, $obj ) = @_;
    confess Dumper @_ if ( !defined $self->{$_IB_OBJECTS_REF}->{$obj} );
    1;
}

#-----------------------------------------------------------
sub _get_return_variable {
    my ( $self, $var ) = @_;
    $_IB_VARIABLES{$var};
}
1;
