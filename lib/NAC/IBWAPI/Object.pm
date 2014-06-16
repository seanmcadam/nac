#!/usr/bin/perl

package NAC::IBWAPI::Object;
use FindBin;
use Readonly;
use lib "$FindBin::Bin/../..";
use base qw( Exporter );
our @ISA = qw(NAC::IBWAPI);

Readonly our $_TYPE     => 'OBJECT_TYPE';
Readonly our $_DATA     => 'OBJECT_DATA';
Readonly our $_REF      => 'OBJECT_REF';
Readonly our $_MODIFIED => 'OBJECT_MODIFIED';

our @EXPORT = qw (
);

# List out Return Types

sub new() {
    my ( $class, $type, $data_ref ) = @_;
    my $self;
    $self = $class->SUPER::new( \%parms );

    # Verify Type
    # Verify Data Ref

    my %data = ();
    $self->{$_MODIFIED} = 0;
    $self->{$_TYPE}     = $type;
    $self->{$_REF}      = undef;
    $self->{$_DATA}     = \%data;

    # Process data

    bless $self, $class;
}

# --------------------------------------
sub ref {
    my ($self) = @_;
    $self->{$_REF};
}

# --------------------------------------
sub type {
    my ($self) = @_;
    $self->{$_TYPE};
}

# --------------------------------------
sub modified {
    my ($self) = @_;
    $self->{$_MODIFIED};
}

# --------------------------------------
sub update {
    my ($self) = @_;

    # Push object back to IB
    $self->{$_MODIFIED} = 0;
}

1;
