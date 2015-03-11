#!/usr/bin/perl

package NAC::DataRequest::Get;

# use base qw( Exporter );
use Exporter qw(import);
use Data::Dumper;
use Carp;
use POSIX;
use FindBin;
use lib "$FindBin::Bin/../..";
use strict;

use constant 'GET_DATA'          => 'GET_DATA';
use constant 'GET_CONDITION'     => 'GET_CONDITION';
use constant 'GET_TABLE'         => 'GET_TABLE';
use constant 'GET_LIMIT'         => 'GET_LIMIT';
use constant 'GET_ORDER'         => 'GET_ORDER';
use constant 'GET_DATA_COLUMN'   => 'DATA_COLUMN';
use constant 'GET_DATA_COUNT'    => 'DATA_COUNT';
use constant 'GET_DATA_ALIAS'    => 'DATA_ALIAS';
use constant 'GET_DATA_OP_PLUS'  => 'DATA_OP_PLUS';
use constant 'GET_DATA_OP_MINUS' => 'DATA_OP_MINUS';
use constant 'GET_DATA_OP_MULT'  => 'DATA_OP_MULT';
use constant 'GET_DATA_OP_DIV'   => 'DATA_OP_DIV';
use constant 'GET_DATA_VALUE'    => 'DATA_VALUE';
use constant 'GET_COND_COL_EQ'   => 'COND_COL_EQ';
use constant 'GET_COND_COL_NEQ'  => 'COND_COL_NEQ';
use constant 'GET_COND_COL_GT'   => 'COND_COL_GT';
use constant 'GET_COND_COL_GTE'  => 'COND_COL_GTE';
use constant 'GET_COND_COL_LT'   => 'COND_COL_LT';
use constant 'GET_COND_COL_LTE'  => 'COND_COL_LTE';
use constant 'GET_COND_VAL_EQ'   => 'COND_VAL_EQ';
use constant 'GET_COND_VAL_NEQ'  => 'COND_VAL_NEQ';
use constant 'GET_COND_VAL_GT'   => 'COND_VAL_GT';
use constant 'GET_COND_VAL_GTE'  => 'COND_VAL_GTE';
use constant 'GET_COND_VAL_LT'   => 'COND_VAL_LT';
use constant 'GET_COND_VAL_LTE'  => 'COND_VAL_LTE';
use constant 'GET_COND_VAL_LIKE' => 'COND_VAL_LIKE';
use constant 'GET_LIMIT_ORIGIN'  => 'LIMIT_ORIGIN';
use constant 'GET_LIMIT_LENGTH'  => 'LIMIT_LENGTH';
use constant 'GET_ORDER_COLUMN'  => 'ORDER_COLUMN';
use constant 'GET_ORDER_DIR'     => 'ORDER_DIR';

#
# GET_DATA => [ {
#		GET_DATA_COLUMN   => db.table.column,
#			or
#		GET_DATA_COUNT    => db.table.column,
#		GET_DATA_ALIAS    => alias,
#		GET_DATA_OPERATOR => value,
#		},...
#	]
#
# GET_CONDITION => [ {
#		GET_COND_COL_EQ  => [db.table.column,db.table.column],
#		GET_COND_COL_NEQ => [db.table.column,db.table.column],
#		GET_COND_COL_GT  => [db.table.column,db.table.column],
#		GET_COND_COL_LT  => [db.table.column,db.table.column],
#		GET_COND_VAL_EQ  => [db.table.column,val],
#		GET_COND_VAL_NEQ => [db.table.column,val],
#		GET_COND_VAL_GT  => [db.table.column,val],
#		GET_COND_VAL_LT  => [db.table.column,val],
#		}, ...
#	]
#
# Not used for now
# GET_TABLE => {
#	implied based on COLUMNS and CONDITIONS
#	}
#
# GET_LIMIT => {
#	GET_LIMIT_ORIGIN => rownum,
#	GET_LIMIT_LENGTH => length,
#	}
#
# GET_ORDER => {
#	GET_ORDER_COLUMN => db.table.column
#	GET_ORDER_DIR    => [ASC, DESC]
#	}
#
#

my @EXPORT = qw(
  GET_DATA
  GET_CONDITION
  GET_LIMIT
  GET_ORDER
  GET_DATA_COLUMN
  GET_DATA_COUNT
  GET_DATA_ALIAS
  GET_DATA_OPERATOR
  GET_DATA_VALUE
  GET_COND_COL_EQ
  GET_COND_COL_NEQ
  GET_COND_COL_GT
  GET_COND_COL_GTE
  GET_COND_COL_LT
  GET_COND_COL_LTE
  GET_COND_VAL_EQ
  GET_COND_VAL_NEQ
  GET_COND_VAL_GT
  GET_COND_VAL_GTE
  GET_COND_VAL_LT
  GET_COND_VAL_LTE
  GET_COND_VAL_LIKE
  GET_LIMIT_ORIGIN
  GET_LIMIT_LENGTH
  GET_ORDER_COLUMN
  GET_ORDER_DIR
);

my %ops = (
    GET_COND_COL_EQ   => ' = ',
    GET_COND_COL_NEQ  => ' <> ',
    GET_COND_COL_GT   => ' > ',
    GET_COND_COL_GTE  => ' >= ',
    GET_COND_COL_LT   => ' < ',
    GET_COND_COL_LTE  => ' <= ',
    GET_COND_VAL_EQ   => ' = ',
    GET_COND_VAL_NEQ  => ' <> ',
    GET_COND_VAL_GT   => ' > ',
    GET_COND_VAL_GTE  => ' >= ',
    GET_COND_VAL_LT   => ' < ',
    GET_COND_VAL_LTE  => ' <= ',
    GET_COND_VAL_LIKE => ' LIKE ',
);

our @ISA     = qw(NAC::DataRequest);
our $request = 1;

# ----------------------------------------------------------------
#
#
# ----------------------------------------------------------------
sub new {
    my ( $class, $dataref ) = @_;

    if ( !defined $dataref ) {
        confess;
    }

    my %data = ();

    confess Dumper @_ if ( ( !defined $dataref->{GET_DATA} ) || ( !_verify_data_array( $dataref->{GET_DATA} ) ) );
    confess Dumper @_ if ( ( defined $dataref->{GET_CONDITION} ) && ( !_verify_condition( $dataref->{GET_CONDITION} ) ) );
    confess Dumper @_ if ( ( defined $dataref->{GET_LIMIT} )     && ( !_verify_limit( $dataref->{GET_LIMIT} ) ) );
    confess Dumper @_ if ( ( defined $dataref->{GET_ORDER} )     && ( !_verify_order( $dataref->{GET_ORDER} ) ) );

    $data{GET_DATA} = $dataref->{GET_DATA};

    if ( defined $dataref->{GET_CONDITION} ) {
        $data{GET_CONDITION} = $dataref->{GET_CONDITION};
    }

    if ( defined $dataref->{GET_LIMIT} ) {
        $data{GET_LIMIT} = $dataref->{GET_LIMIT};
    }

    if ( defined $dataref->{GET_ORDER} ) {
        $data{GET_ORDER} = $dataref->{GET_ORDER};
    }

    my $self = $class->SUPER::new( $class, \%data );
    bless $self, $class;
    $self;
}

# --------------------------------------------
#
# --------------------------------------------
sub sql {
    my ($self) = @_;
    my $sql;
    my $dataref = $self->data();

    #
    # SELECT ... columns
    #

    #
    # Columns:  COL1 AS COL1A, COL2 AS COL2A, ...
    #
    $sql .= join( ', ', ( map {
                my $colref = $_;
                my $s      = '';
                if ( defined $colref->{GET_DATA_COLUMN} ) {
                    $s .= get_column_dbname( $colref->{GET_DATA_COLUMN} );
                }
                elsif ( defined $colref->{GET_DATA_COUNT} ) {
                    $s .= "COUNT( " . get_column_dbname( $colref->{GET_DATA_COLUMN} ) . " )";
                }

                if ( defined $colref->{GET_DATA_ALIAS} ) {
                    $s .= " AS " . get_column_alias( $colref->{GET_DATA_COLUMN} );
                }
                $s;
    } @{ $dataref->{GET_DATA} } ) );

    #
    # FROM ... tables
    #
    my $tableref = $self->list_tables;

    $sql .= join( ', ', ( map { get_table_dbname($_) . " AS " . get_table_alias($_); } @{$tableref} ) );

    #
    # WHERE .. conditions
    #
    $sql .= join( "\nAND\n", ( map {
                my $condref = $_;
                my $s       = '';

                my ($op) = keys( %{$condref} );
                my $op1  = @{ $condref->{$op} }[0];
                my $op2  = @{ $condref->{$op} }[1];
                my $q = ( quote_column_datatype($op1) ) ? "'" : '';

                $s = $q . $op1 . $q
                  . $ops{$op}
                  . $q . $op2 . $q;

    } @{ $dataref->{GET_CONDITION} } ) );

HERE - Add Logging too.


    #
    # ORDER .. column, dir
    #

    #
    # LIMIT .. limits
    #


    $sql;
}

# --------------------------------------------
#
# --------------------------------------------
sub list_tables {
    my ($self) = @_;
    my %tables = ();
    my @tables = ();

    my $dataref = $self->data()->{GET_DATA};
    my $condref = $self->data()->{GET_CONDITION};

    foreach my $col (@$dataref) {
        if ( defined $col->{DATA_COLUMN} ) {
            $tables{ get_column_table( $col->{DATA_COLUMN} ) }++;
        }
        elsif ( defined $dataref->{DATA_COUNT} ) {
            $tables{ get_column_table( $col->{DATA_COUNT} ) }++;
        }
    }

    if ( defined $condref ) {
        foreach my $cond (@$dataref) {
            if ( defined $cond->{COND_COL_EQ} ) {
                $tables{ get_column_table( { $cond->{COND_COL_EQ} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{COND_COL_EQ} }->[1] ) }++;
            }
            elsif ( defined $cond->{COND_COL_NEQ} ) {
                $tables{ get_column_table( { $cond->{COND_COL_NEQ} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{COND_COL_NEQ} }->[1] ) }++;
            }
            elsif ( defined $cond->{COND_COL_GT} ) {
                $tables{ get_column_table( { $cond->{COND_COL_GT} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{COND_COL_GT} }->[1] ) }++;
            }
            elsif ( defined $cond->{COND_COL_LT} ) {
                $tables{ get_column_table( { $cond->{COND_COL_LT} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{COND_COL_LT} }->[1] ) }++;
            }
            elsif ( defined $cond->{COND_VAL_EQ} ) {
                $tables{ get_column_table( { $cond->{COND_VAL_EQ} }->[0] ) }++;
            }
            elsif ( defined $cond->{COND_VAL_NEQ} ) {
                $tables{ get_column_table( { $cond->{COND_VAL_NEQ} }->[0] ) }++;
            }
            elsif ( defined $cond->{COND_VAL_GT} ) {
                $tables{ get_column_table( { $cond->{COND_VAL_GT} }->[0] ) }++;
            }
            elsif ( defined $cond->{COND_VAL_LT} ) {
                $tables{ get_column_table( { $cond->{COND_VAL_LT} }->[0] ) }++;
            }
        }
    }

    foreach my $t ( keys(%tables) ) {
        push( @tables, $t );
    }

    \@tables;

}

# --------------------------------------------
sub _verify_data_array {
    my $ret = 0;
    my ($dataref) = @_;
    if ( 'ARRAY' ne ref($dataref) ) {
        goto RETURN;
    }
    foreach my $h (@$dataref) {
        if ( !_verify_data($h) ) {
            goto RETURN;
        }
        $ret = 1;
    }

  RETURN:
    $ret;
}

# --------------------------------------------
sub _verify_data {
    my $ret = 0;
    my ($dataref) = @_;
    if ( 'HASH' ne ref($dataref) ) {
        goto RETURN;
    }

    if ( !( defined $dataref->{DATA_COLUMN} || defined $dataref->{DATA_COUNT} ) ) {
        goto RETURN;
    }

    if ( defined $dataref->{DATA_COLUMN} ) {
    }

    if ( defined $dataref->{DATA_COUNT} ) {
    }

    if ( defined $dataref->{DATA_ALIAS} ) {

        # Check on alias name
    }

    if ( defined $dataref->{DATA_OP_PLUS}
        || defined $dataref->{DATA_OP_MINUS}
        || defined $dataref->{DATA_OP_MULT}
        || defined $dataref->{DATA_OP_DIV}
      ) {

        # Check on alias name
    }

    $ret = 1;

  RETURN:
    $ret;
}

# --------------------------------------------
sub _verify_condition_array {
    my $ret = 0;
    my ($condref) = @_;
    if ( 'ARRAY' eq ref($condref) ) {
        $ret = 1;
    }
    $ret;
}

# --------------------------------------------
sub _verify_limit {
    my $ret = 0;
    my ($limitref) = @_;
    if ( 'HASH' eq ref($limitref) ) {
        $ret = 1;
    }
    $ret;
}

# --------------------------------------------
sub _verify_order {
    my $ret = 0;
    my ($orderref) = @_;
    if ( 'HASH' eq ref($orderref) ) {
        $ret = 1;
    }
    $ret;
}

1;

