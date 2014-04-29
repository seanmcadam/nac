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

Readonly our $_IB_HTTPS                  => 'https://';
Readonly our $_IB_JSON                   => 'json';
Readonly our $_IB_USERID                 => 'IB-USERID';
Readonly our $_IB_PASSWORD               => 'IB-PASSWORD';
Readonly our $_IB_HOSTNAME               => 'IB-HOSTNAME';
Readonly our $_IB_URL                    => 'IB-URL';
Readonly our $_IB_URI                    => '/wapi/v1.2/';
Readonly our $_IB_DEFAULT_MAX_RESULTS => 5000;
Readonly our $_IB_REF		=> '_ref';
Readonly our $_IB_OPTIONS		=> 'options';
Readonly our $_IB_EXTATTRS		=> 'extattrs';

Readonly our $IB_MAX_RESULTS        => 'IB_MAX_RESULTS';
Readonly our $IB_RETURN_TYPE           => 'IB_RETURN_TYPE';
Readonly our $IB_RETURN_FIELDS         => 'IB_RETURN_FIELDS';
Readonly our $IB_RETURN_FIELD_EXTATTRS => 'IB_FIELD_EXTATTRS';
Readonly our $IB_RETURN_FIELD_OPTIONS  => 'IB_FIELD_OPTIONS';
Readonly our $IB_OBJECT                => 'IB_OBJECT';
Readonly our $IB_OBJECT_NETWORK        => 'IB_OBJECT_NETWORK';

sub not_impl;

our @EXPORT = qw (
  $IB_MAX_RESULTS
  $IB_RETURN_TYPE
  $IB_RETURN_FIELDS
  $IB_RETURN_FIELD_EXTATTRS
  $IB_RETURN_FIELD_OPTIONS
  $IB_OBJECT
  $IB_OBJECT_NETWORK
);

our %_IB_OBJECTS = (
    $IB_OBJECT_NETWORK => 'network',
);

our %_IB_VARIABLES = (
    $IB_MAX_RESULTS => '_max_results',
    $IB_RETURN_TYPE    => '_return_type',
    $IB_RETURN_FIELDS  => '_return_fields',
);

our %_IB_PARAMETERS = (
    $IB_OBJECT_NETWORK => 'network',
    $IB_MAX_RESULTS => '_return_results',
    $IB_RETURN_TYPE    => '_return_type',
    $IB_RETURN_FIELDS  => '_return_fields',
    $IB_RETURN_FIELD_EXTATTRS => 'extattrs',
    $IB_RETURN_FIELD_OPTIONS  => 'options',
);

#---------------------------------------------------------------------------
sub new() {
    my ( $class, $parm_ref ) = @_;
    my $self;
    my %h;
    $self = \%h;

    EventLog( EVENT_DEBUG, MYNAME . "() started" );

    my $config = NAC::ConfigDB->new();
    $self->{$_IB_USERID}   = $config->nac_ib_user;
    $self->{$_IB_PASSWORD} = $config->nac_ib_pass;
    $self->{$_IB_HOSTNAME} = $config->nac_ib_hostname;

    $self->{$_IB_URL} = $_IB_HTTPS
      . $self->{$_IB_USERID}
      . ':'
      . $self->{$_IB_PASSWORD}
      . '@'
      . $self->{$_IB_HOSTNAME}
      . $_IB_URI
      ;

    bless $self, $class;

    $self;
}

#-----------------------------------------------------------
sub _get_return_variable {
    my ( $self, $var ) = @_;
    $_IB_VARIABLES{$var};
}

#-----------------------------------------------------------
sub _get {
    my ( $self, $object, $type, $count, $parm ) = @_;

    my $url = $self->{$_IB_URL}
      . $object
      . '?'
      . $self->_get_return_variable($IB_RETURN_TYPE)
      . '='
      . $type
      . '&'
      . $self->_get_return_variable($IB_MAX_RESULTS)
      . '='
      . $count
      ;

    foreach my $p ( sort( keys(%$parm) ) ) {
        $url .= '&'
	  . $_IB_PARAMETERS{ $p }
          . '='
          . $parm->{$p}
          ;
    }

    print "URL = $url\n";

    my $ret = get $url;

    print Dumper from_json( $ret );
    exit;

}

#-----------------------------------------------------------
sub GET {
    my ( $self, $parm_ref ) = @_;
    my %parm = ();

    if ( !defined $parm_ref->{$IB_OBJECT}
        || !defined $_IB_OBJECTS{ $parm_ref->{$IB_OBJECT} } ) { confess @_ }

    my $parm = \%parm;

    my $object = $_IB_OBJECTS{ $parm_ref->{$IB_OBJECT} };

    my $type = ( defined $parm_ref->{$IB_RETURN_TYPE} )
      ? $parm_ref->{$IB_RETURN_TYPE}
      : $_IB_JSON
      ;

    my $count = $parm_ref->{$IB_MAX_RESULTS}
      ? $parm_ref->{$IB_MAX_RESULTS}
      : $_IB_DEFAULT_MAX_RESULTS
      ;

    foreach my $p ( sort( keys(%$parm_ref) ) ) {
        if ( $p eq $IB_OBJECT ) { next; }
        if ( $p eq $IB_MAX_RESULTS ) { next; }
        if ( $p eq $IB_RETURN_TYPE )    { next; }

        if ( $p eq $IB_RETURN_FIELDS )    { 
		my $fields = "";
        	my $arr_ref = $parm_ref->{$p};
		if( ref( $arr_ref ) ne 'ARRAY' ) { confess Dumper $parm_ref };
		foreach my $a (@$arr_ref) {	
			$fields .= ($fields ne '')?',':'';
        		$fields .= $_IB_PARAMETERS{ $a };
		}
        	$parm{$p} = $fields;
		next;
	}

        $parm{$p} = $parm_ref->{$p};

    }

    $self->_get( $object, $type, $count, $parm );

}

# -------------------------------------------------------------------
sub not_impl {
    EventLog( EVENT_DEBUG, MYNAME . "() - not implemented yet" );
    return undef;
}

1;
