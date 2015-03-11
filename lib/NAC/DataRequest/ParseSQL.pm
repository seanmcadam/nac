#!/usr/bin/perl

package NAC::DataRequest::ParseSQL;

# use base qw( Exporter );
use Exporter qw(import);
use Data::Dumper;
use Carp;
use POSIX;
# use lib "$findBin::Bin../../../../../perl5/lib/perl5";
use lib "/home/mcadam/perl5/lib/perl5";
use SQL::Abstract::More;
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::Client::Logger;
use NAC::DB;
use strict;

use constant 'NEWLINE' => "\n";

use constant '_SQL_ABSTRACT'       => 'SQL_ABSTRACT';
use constant '_SQL_TYPE'           => 'SQL_TYPE';
use constant '_SQL_TYPE_SELECT'    => 'SELECT';
use constant '_SQL_TYPE_INSERT'    => 'INSERT';
use constant '_SQL_TYPE_UPDATE'    => 'UPDATE';
use constant '_SQL_TYPE_DELETE'    => 'DELETE';
use constant '_SQL_PARM_COLUMNS'   => '-columns';
use constant '_SQL_PARM_COUNT'     => '-count';
use constant '_SQL_PARM_DISTINCT'  => '-distinct';
use constant '_SQL_PARM_EXCEPT'    => '-except';
use constant '_SQL_PARM_FROM'      => '-from';
use constant '_SQL_PARM_INTERSECT' => '-intersect';
use constant '_SQL_PARM_JOIN'      => '-join';
use constant '_SQL_PARM_LIMIT'     => '-limit';
use constant '_SQL_PARM_MINUS'     => '-minus';
use constant '_SQL_PARM_OFFSET'    => '-offset';
use constant '_SQL_PARM_UNION'     => '-union';
use constant '_SQL_PARM_UNION_ALL' => '-union_all';
use constant '_SQL_PARM_WHERE'     => '-where';
use constant 'SQL_PARM_COLUMNS'    => 'SQL_PARM_COLUMNS';
use constant 'SQL_PARM_COUNT'      => 'SQL_PARM_COUNT';
use constant 'SQL_PARM_DISTINCT'   => 'SQL_PARM_DISTINCT';
use constant 'SQL_PARM_EXCEPT'     => 'SQL_PARM_EXCEPT';
use constant 'SQL_PARM_FROM'       => 'SQL_PARM_FROM';
use constant 'SQL_PARM_INTERSECT'  => 'SQL_PARM_INTERSECT';
use constant 'SQL_PARM_JOIN'       => 'SQL_PARM_JOIN';
use constant 'SQL_PARM_LIMIT'      => 'SQL_PARM_LIMIT';
use constant 'SQL_PARM_MINUS'      => 'SQL_PARM_MINUS';
use constant 'SQL_PARM_OFFSET'     => 'SQL_PARM_OFFSET';
use constant 'SQL_PARM_SELECT'     => 'SQL_PARM_SELECT';
use constant 'SQL_PARM_UNION'      => 'SQL_PARM_UNION';
use constant 'SQL_PARM_UNION_ALL'  => 'SQL_PARM_UNION_ALL';
use constant 'SQL_PARM_WHERE'      => 'SQL_PARM_WHERE';
use constant 'SQL_OP_PLUS'         => 'SQL_OP_PLUS';
use constant 'SQL_OP_MINUS'        => 'SQL_OP_MINUS';
use constant 'SQL_OP_MULT'         => 'SQL_OP_MULT';
use constant 'SQL_OP_DIV'          => 'SQL_OP_DIV';
use constant 'SQL_OP_MOD'          => 'SQL_OP_MOD';
use constant 'SQL_OP_EQUAL'        => 'SQL_OP_EQUAL';
use constant 'SQL_EMPTY_STRING'    => 'SQL_EMPTY_STRING';
use constant 'SQL_ALIAS_DELIM'     => '|';

use constant SQL_FUNCTION => 'nac_sql_function';

my $ESCAPED_ALIAS_DELIM = "\\" . SQL_ALIAS_DELIM;

my @export = qw(
  SQL_FUNCTION
  SQL_ALIAS_DELIM
  SQL_PARM_COLUMNS
  SQL_PARM_COUNT
  SQL_PARM_DISTINCT
  SQL_PARM_EXCEPT
  SQL_PARM_FROM
  SQL_PARM_INTERSECT
  SQL_PARM_JOIN
  SQL_PARM_LIMIT
  SQL_PARM_OFFSET
  SQL_PARM_SELECT
  SQL_PARM_UNION
  SQL_PARM_WHERE
  SQL_OP_PLUS
  SQL_OP_MINUS
  SQL_OP_MULT
  SQL_OP_DIV
  SQL_OP_MOD
  SQL_OP_EQUAL
  SQL_EMPTY_STRING
);

our @EXPORT = ( @export, @NAC::DB::EXPORT );

my %ops = (
    SQL_OP_PLUS  => ' + ',
    SQL_OP_MINUS => ' - ',
    SQL_OP_MULT  => ' * ',
    SQL_OP_DIV   => ' / ',
    SQL_OP_MOD   => ' % ',
    SQL_OP_EQUAL => ' = ',
);

my %check_functions = (
    SQL_PARM_COLUMNS   => \&_check_columns,
    SQL_PARM_EXCEPT    => \&_check_except,
    SQL_PARM_FROM      => \&_check_from,
    SQL_PARM_INTERSECT => \&_check_intersect,
    SQL_PARM_JOIN      => \&_check_join,
    SQL_PARM_LIMIT     => \&_check_limit,
    SQL_PARM_MINUS     => \&_check_minus,
    SQL_PARM_OFFSET    => \&_check_offset,
    SQL_PARM_UNION     => \&_check_union,
    SQL_PARM_UNION_ALL => \&_check_union_all,
    SQL_PARM_WHERE     => \&_check_where,
);

my %parm_functions = (
    SQL_PARM_COLUMNS   => \&columns,
    SQL_PARM_EXCEPT    => \&except,
    SQL_PARM_FROM      => \&from,
    SQL_PARM_INTERSECT => \&intersect,
    SQL_PARM_JOIN      => \&join,
    SQL_PARM_LIMIT     => \&limit,
    SQL_PARM_MINUS     => \&minus,
    SQL_PARM_OFFSET    => \&offset,
    SQL_PARM_UNION     => \&union,
    SQL_PARM_UNION_ALL => \&union_all,
    SQL_PARM_WHERE     => \&where,
);

my %parm_to_args = (
    SQL_PARM_COLUMNS   => _SQL_PARM_COLUMNS,
    SQL_PARM_COUNT     => _SQL_PARM_COUNT,
    SQL_PARM_DISTINCT  => _SQL_PARM_DISTINCT,
    SQL_PARM_EXCEPT    => _SQL_PARM_EXCEPT,
    SQL_PARM_FROM      => _SQL_PARM_FROM,
    SQL_PARM_INTERSECT => _SQL_PARM_INTERSECT,
    SQL_PARM_JOIN      => _SQL_PARM_JOIN,
    SQL_PARM_LIMIT     => _SQL_PARM_LIMIT,
    SQL_PARM_MINUS     => _SQL_PARM_MINUS,
    SQL_PARM_OFFSET    => _SQL_PARM_OFFSET,
    SQL_PARM_UNION     => _SQL_PARM_UNION,
    SQL_PARM_UNION_ALL => _SQL_PARM_UNION_ALL,
    SQL_PARM_WHERE     => _SQL_PARM_WHERE,
);

our @ISA = qw(NAC::DataRequest);

# ----------------------------------------------------------------
#
#
# ----------------------------------------------------------------
sub new {
    my ( $class, $parms ) = @_;

    # my $self = $class->SUPER::new($parms);
    my $self = {};

    $self->{_SQL_ABSTRACT} = SQL::Abstract::More->new();
    $self->{_SQL_TYPE}     = '';

    bless $self, $class;
    $self;
}

# ----------------------------------------------------------------
sub _verify_op_name {
    my ($opname) = @_;
    if ( defined $ops{$opname} ) {
        return 1;
    }
    return 0;
}

# ----------------------------------------------------------------
sub _get_op_name {
    my ($opname) = @_;
    $ops{$opname};
}

# ----------------------------------------------------------------
sub select {
    my ( $self, $parm_ref ) = @_;

    # print Dumper \@{ $self->prepare_select_args($parm_ref) };

    $self->{_SQL_ABSTRACT}->select( @{ $self->prepare_select_args($parm_ref) } );
}

# ----------------------------------------------------------------
# Takes a hash with the various componants of the query string
# ----------------------------------------------------------------
sub prepare_select_args {
    my ( $self, $parm_ref ) = @_;
    $self->{_SQL_TYPE} = _SQL_TYPE_SELECT;
    my @args = ();

    if ( defined $parm_ref ) {
        if ( 'HASH' eq ref($parm_ref) ) {
            foreach my $p ( keys(%$parm_ref) ) {
                if ( !defined $parm_functions{$p} ) {
                    confess "FUNCTION '$p' Not Defined\n" . Dumper $parm_ref ;
                }
                push( @args, $parm_to_args{$p}, $parm_functions{$p}->( $self, $parm_ref->{$p} ) );
            }
        }
        else {
            confess "PARM not a HASH REF " . Dumper @_;
        }
    }

    if ( defined $self->{SQL_PARM_LIMIT} xor defined $self->{SQL_PARM_OFFSET} ) {
        confess "Limit and Offset required " . Dumper @_;
    }

# print Dumper \@args;

    return \@args;
}

# ----------------------------------------------------------------
# Create a \@Columns
# from
#	Fixed Value
#	$COL_NAME
#	[$COL_NAME, OP, VALUE,]
#	[$COL_NAME, OP, [$COL_NAME, OP, VALUE],]
#	{ $COL_NAME => ALIAS }
#	{ [$COL_NAME, OP, VALUE,] => ALIAS }
#	[ $COL_NAME, $COL_NAME,... ]
#	[ $COL_NAME, { $COL_NAME => ALIAS },... ]
#	[ $COL_NAME, { [$COL_NAME, OP, VALUE,] => ALIAS },... ]
# ----------------------------------------------------------------
sub columns {
    my ( $self, $parm ) = @_;
    my $arrref = ();

    if ( '' eq ref($parm) ) {
        $arrref = [ $self->columns_scalar($parm), ];
    }
    elsif ( $parm eq SQL_EMPTY_STRING ) {
        $arrref = [ '""', ];
    }
    elsif ( 'ARRAY' eq ref($parm) ) {
        $arrref = $self->columns_array($parm);
    }
    elsif ( 'HASH' eq ref($parm) ) {
        $arrref = [ $self->columns_hash($parm), ];
    }
    else {
        confess Dumper @_;
    }

# print Dumper $arrref;

    $arrref;
}

# ----------------------------------------------------------------
#	$COL_NAME, OP, STRING
# ----------------------------------------------------------------
sub columns_scalar {
    my ( $self, $col ) = @_;
    my $ret;

    if ( verify_column_name($col) ) {
        # $ret = get_column_dbname($col);
        $ret = get_column_alias($col);
    }
    elsif ( _verify_op_name($col) ) {
        $ret = _get_op_name($col);
    }
    elsif ( $col eq SQL_EMPTY_STRING ) {
        $ret = '""';
    }
    elsif ( isdigit($col) ) {
        $ret = $col;
    }
    elsif ( $col =~ /^[\w\-\s]+$/ ) {
        $ret = '"' . $col . '"';
    }
    else {
        confess "COLUMNS_SCALAR() Error:" . Dumper $col;
    }

    $ret;
}

# ----------------------------------------------------------------
# ----------------------------------------------------------------
sub columns_array {
    my ( $self, $arr ) = @_;
    my $array = ();

    #
    # FOR  [ SQL_PARM_COUNT => [ NACAUDIT_VLANGROUP2VLAN_PRIORITY_COLUMN, ] },
    #
    if ( SQL_PARM_COUNT eq $arr->[0] ||  SQL_PARM_DISTINCT eq $arr->[0] ) {
	shift( @$arr );
	$array = [ $parm_to_args{$arr->[0]} . '( ' . (join(', ', @{$self->columns_array( $arr )})) . ' )', ]
	}
    #
    # FOR  { xxxx => [ 400, SQL_OP_PLUS, NACAUDIT_VLANGROUP2VLAN_PRIORITY_COLUMN ] },
    #
    elsif ( ( 3 == scalar(@$arr) ) && ( _verify_op_name( $arr->[1] ) ) ) {
        my $a = $self->columns_scalar( $arr->[0] );
        my $b = _get_op_name( $arr->[1] );
        my $c;
        if ( 'ARRAY' eq ref( $arr->[2] ) ) {
            $c = $self->columns_array( $arr->[2] )->[0];
        }
        else {
            $c = $self->columns_scalar( $arr->[2] );
        }
        push( @$array, '( ' . join( ' ', $a, $b, $c, ) . ' )' );

    }
    else {
        foreach my $a (@$arr) {
            push( @$array, @{ $self->columns($a) } );
        }
    }

    $array;
}

# ----------------------------------------------------------------
# ----------------------------------------------------------------
sub columns_hash {
    my ( $self, $hash ) = @_;
    my $ret;

    foreach my $k ( keys(%$hash) ) {
        my $v = $hash->{$k};
        if ( 'ARRAY' eq ref($v) ) {
            $ret = join( ' ', @{ $self->columns_array($v) } ) . SQL_ALIAS_DELIM . $k;
        }
        else {
            $ret = join( ' ', @{ $self->columns($v) } ) . SQL_ALIAS_DELIM . $k;
        }
    }

    $ret;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub except {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub from {
    my ( $self, $parm ) = @_;
    my $arrref;

    if ( '' eq ref($parm) ) {
        $arrref = [ $parm, ];
    }
    elsif ( 'ARRAY' eq ref($parm) ) {
        $arrref = $parm;
    }
    else {
        confess Dumper @_;
    }

    $check_functions{SQL_PARM_FROM}->($arrref);

    my $tabref = ();
    foreach my $tab (@$arrref) {
        push( @$tabref, get_table_dbname($tab) . " AS " . get_table_alias($tab) );
    }

# print Dumper $tabref;

    $tabref;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub intersect {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub join {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub limit {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub minus {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub offset {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub union {
    my ( $self, $parm ) = @_;
    my $arrref = $self->prepare_select_args($parm);

    # print "PARMS " . Dumper $arrref;
    $arrref;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub union_all {
    my ( $self, $parm ) = @_;
    confess Dumper @_;
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub where {
    my ( $self, $parm ) = @_;
    my %where;
    if ( 'HASH' eq ref($parm) ) {

        # $check_functions{SQL_PARM_WHERE}->($parm);

        foreach my $k ( keys(%$parm) ) {
            my $v = $parm->{$k};

            if ( verify_column_name($k) ) {
                # $k = get_column_dbname($k);
                $k = get_column_alias($k);
            }
            elsif ( SQL_PARM_SELECT eq $k ) {
                if ( 'ARRAY' eq ref($v) ) {
                    my $a = $self->columns_scalar( $v->[0] );
                    my $b = _get_op_name( $v->[1] );
                    my ( $sql, @bind ) = $self->select( $v->[2] );

                    $where{$a} = "$b $sql";
                }
                else {
                    confess "WHERE SUBQUERY FAILED:" . Dumper $parm;
                }

            }
            else {
                confess "WHERE FAILED:" . Dumper $parm;
            }

            if ( 'SCALAR' eq ref $v ) {
                my $ref = "= " . ( isdigit($$v) ? $$v : '"' . $$v . '"' );
                $where{$k} = \$ref;
            }
            elsif ( verify_column_name($v) ) {
                # $v = "= " . get_column_dbname($v);
                $v = "= " . get_column_alias($v);
                $where{$k} = \$v;
            }
            else {
                $where{$k} = $v;
            }
        }

    }
    else {
        confess Dumper @_;
    }

# print Dumper \%where;

    \%where;
}

# ##########################################################
# VERIFY FUNCTIONS
# ##########################################################
# ---------------------------------------------------------
sub _check_columns {
    my ($parm) = @_;
    if ( 'ARRAY' ne ref($parm) ) {
        confess Dumper @_;
    }

    foreach my $col (@$parm) {
        if ( 'HASH' eq ref($col) ) {
            my ($k) = keys(%$col);
            if ( '' ne ref($k) ) {
                confess Dumper @_;
            }
        }
        elsif ( '' ne ref($col) ) {
            confess Dumper @_;
        }
    }
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_except {
    my ($parm) = @_;
    confess Dumper @_;
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_from {
    my ($parm) = @_;
    if ( 'ARRAY' ne ref($parm) ) {
        confess Dumper @_;
    }
    foreach my $tab_name (@$parm) {
        if ( !verify_table_name($tab_name) ) {
            confess Dumper @_;
        }
    }
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_intersect {
    my ($parm) = @_;
    confess Dumper @_;
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_join {
    my ($parm) = @_;
    confess Dumper @_;
}

# ---------------------------------------------------------
# Numeric and Limit > 0
# ----------------------------------------------------------------
sub _check_limit {
    my ($parm) = @_;
    if ( !isdigit($parm) && $parm ) {
        confess Dumper @_;
    }
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_minus {
    my ($parm) = @_;
    confess Dumper @_;
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_offset {
    my ($parm) = @_;
    if ( !isdigit($parm) ) {
        confess Dumper @_;
    }
}

# ----------------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_union {
    my ($parm) = @_;
    confess Dumper @_;
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_union_all {
    my ($parm) = @_;
    confess Dumper @_;
}

# ---------------------------------------------------------
#
# ----------------------------------------------------------------
sub _check_where {
    my ($parm) = @_;
    if ( 'HASH' ne ref($parm) ) {
        confess Dumper @_;
    }
    foreach my $col_name ( keys(%$parm) ) {
        if ( ( 'HASH' ne ref($col_name) ) && ( !verify_column_name($col_name) ) ) {
            confess "Column Name: '$col_name' " . Dumper @_;
        }
    }
}

1;
