#!/usr/bin/perl

package NAC::DataRequest::Get;

# use base qw( Exporter );
use Exporter qw(import);
use Data::Dumper;
use Carp;
use POSIX;
use FindBin;
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::DataRequest;
use NAC::DB;
use strict;

use constant 'GET_DATA'          => 'GET_DATA';
use constant 'GET_CONDITION'     => 'GET_CONDITION';
use constant 'GET_TABLE'         => 'GET_TABLE';
use constant 'GET_LIMIT'         => 'GET_LIMIT';
use constant 'GET_ORDER'         => 'GET_ORDER';
use constant 'GET_DATA_COLUMN'   => 'GET_DATA_COLUMN';
use constant 'GET_DATA_COUNT'    => 'GET_DATA_COUNT';
use constant 'GET_DATA_ALIAS'    => 'GET_DATA_ALIAS';
use constant 'GET_DATA_OP_PLUS'  => 'GET_DATA_OP_PLUS';
use constant 'GET_DATA_OP_MINUS' => 'GET_DATA_OP_MINUS';
use constant 'GET_DATA_OP_MULT'  => 'GET_DATA_OP_MULT';
use constant 'GET_DATA_OP_DIV'   => 'GET_DATA_OP_DIV';
use constant 'GET_DATA_VALUE'    => 'GET_DATA_VALUE';
use constant 'GET_COND_COL_EQ'   => 'GET_COND_COL_EQ';
use constant 'GET_COND_COL_NEQ'  => 'GET_COND_COL_NEQ';
use constant 'GET_COND_COL_GT'   => 'GET_COND_COL_GT';
use constant 'GET_COND_COL_GTE'  => 'GET_COND_COL_GTE';
use constant 'GET_COND_COL_LT'   => 'GET_COND_COL_LT';
use constant 'GET_COND_COL_LTE'  => 'GET_COND_COL_LTE';
use constant 'GET_COND_VAL_EQ'   => 'GET_COND_VAL_EQ';
use constant 'GET_COND_VAL_NEQ'  => 'GET_COND_VAL_NEQ';
use constant 'GET_COND_VAL_GT'   => 'GET_COND_VAL_GT';
use constant 'GET_COND_VAL_GTE'  => 'GET_COND_VAL_GTE';
use constant 'GET_COND_VAL_LT'   => 'GET_COND_VAL_LT';
use constant 'GET_COND_VAL_LTE'  => 'GET_COND_VAL_LTE';
use constant 'GET_COND_VAL_LIKE' => 'GET_COND_VAL_LIKE';
use constant 'GET_LIMIT_ORIGIN'  => 'GET_LIMIT_ORIGIN';
use constant 'GET_LIMIT_LENGTH'  => 'GET_LIMIT_LENGTH';
use constant 'GET_ORDER_COLUMN'  => 'GET_ORDER_COLUMN';
use constant 'GET_ORDER_DIR'     => 'GET_ORDER_DIR';

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

    $LOGGER_DEBUG_8->( EVENT_START, );

    my %data = ();

    confess Dumper $dataref if ( ( !defined $dataref->{GET_DATA} ) || ( !_verify_data_array( $dataref->{GET_DATA} ) ) );
    confess Dumper $dataref if ( ( defined $dataref->{GET_CONDITION} ) && ( !_verify_condition( $dataref->{GET_CONDITION} ) ) );
    confess Dumper $dataref if ( ( defined $dataref->{GET_LIMIT} )     && ( !_verify_limit( $dataref->{GET_LIMIT} ) ) );
    confess Dumper $dataref if ( ( defined $dataref->{GET_ORDER} )     && ( !_verify_order( $dataref->{GET_ORDER} ) ) );

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

    my $self = $class->SUPER::new( { REQUEST_DATA => \%data } );
    bless $self, $class;
    $self;
}

# --------------------------------------------
#
# --------------------------------------------
sub sql {
    my ($self) = @_;
    my $dataref = $self->data();
    my $select;
    my $from;
    my $where;
    my $limit;
    my $order;

    #
    # SELECT ... columns
    # Columns:  COL1 AS COL1A, COL2 AS COL2A, ...
    #
    my $select_count = 0;
    $select = "SELECT " . join( ', ', ( map {
                my $colref = $_;
                my $s      = '';

                $LOGGER_DEBUG_9->( " SQL SELECT " . $select_count++ . "'" . "COLREF:" . ( Dumper $colref) . " DATA:" . ( Dumper keys(%$colref) ) );

                if ( defined $colref->{GET_DATA_COLUMN} ) {
                    $s .= get_column_alias( $colref->{GET_DATA_COLUMN} );
                }
                elsif ( defined $colref->{GET_DATA_COUNT} ) {
                    $s .= "COUNT( " . get_column_alias( $colref->{GET_DATA_COLUMN} ) . " )";
                }
                else {
                    $LOGGER_FATAL->( " SQL SELECT NO COLUMN DEFINED " . Dumper $colref );
                }

                if ( defined $colref->{GET_DATA_ALIAS} ) {
                    $s .= " AS '" . $colref->{GET_DATA_ALIAS} . "'";
                }

                ($s);

    } @{ $dataref->{GET_DATA} } ) );

    $LOGGER_DEBUG_4->( " SQL SELECT '" . $select . "'" );

    #
    # FROM ... tables
    #
    my $tableref = $self->list_tables;

    $from = " FROM " . join( ', ', ( map { get_table_dbname($_) . " AS " . get_table_alias($_); } @{$tableref} ) );

    $LOGGER_DEBUG_4->( " SQL FROM '" . $from . "'" );

    #
    # WHERE .. conditions
    #
    $where = join( "\nAND\n", ( map {
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

    if ( $where =~ /\w/ ) {
        $where = " WHERE " . $where;
    }

    $LOGGER_DEBUG_4->( " SQL WHERE '" . $where . "'" );

    #
    # ORDER .. column, dir
    #
    $order = '';

    #
    # LIMIT .. limits
    #
    $order = '';

    my $sql = join( ' ', ( $select, $from, $where, $limit, $order ) );

    $LOGGER_DEBUG_3->( " SQL: '" . $sql . "'" );

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
        if ( defined $col->{GET_DATA_COLUMN} ) {
            $tables{ get_column_table( $col->{GET_DATA_COLUMN} ) }++;
        }
        elsif ( defined $dataref->{GET_DATA_COUNT} ) {
            $tables{ get_column_table( $col->{GET_DATA_COUNT} ) }++;
        }
    }

    if ( defined $condref ) {
        foreach my $cond (@$dataref) {
            if ( defined $cond->{GET_COND_COL_EQ} ) {
                $tables{ get_column_table( { $cond->{GET_COND_COL_EQ} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{GET_COND_COL_EQ} }->[1] ) }++;
            }
            elsif ( defined $cond->{GET_COND_COL_NEQ} ) {
                $tables{ get_column_table( { $cond->{GET_COND_COL_NEQ} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{GET_COND_COL_NEQ} }->[1] ) }++;
            }
            elsif ( defined $cond->{GET_COND_COL_GT} ) {
                $tables{ get_column_table( { $cond->{GET_COND_COL_GT} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{GET_COND_COL_GT} }->[1] ) }++;
            }
            elsif ( defined $cond->{GET_COND_COL_LT} ) {
                $tables{ get_column_table( { $cond->{GET_COND_COL_LT} }->[0] ) }++;
                $tables{ get_column_table( { $cond->{GET_COND_COL_LT} }->[1] ) }++;
            }
            elsif ( defined $cond->{GET_COND_VAL_EQ} ) {
                $tables{ get_column_table( { $cond->{GET_COND_VAL_EQ} }->[0] ) }++;
            }
            elsif ( defined $cond->{GET_COND_VAL_NEQ} ) {
                $tables{ get_column_table( { $cond->{GET_COND_VAL_NEQ} }->[0] ) }++;
            }
            elsif ( defined $cond->{GET_COND_VAL_GT} ) {
                $tables{ get_column_table( { $cond->{GET_COND_VAL_GT} }->[0] ) }++;
            }
            elsif ( defined $cond->{GET_COND_VAL_LT} ) {
                $tables{ get_column_table( { $cond->{GET_COND_VAL_LT} }->[0] ) }++;
            }
        }
    }

    foreach my $t ( keys(%tables) ) {
        push( @tables, $t );
    }

    \@tables;

}

# --------------------------------------------
sub get_column_alias_ref {
    my ($self) = @_;
    my @col = map { $_->{GET_DATA_ALIAS} } @{ $self->data->{GET_DATA} };
    \@col;
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

    if ( !( defined $dataref->{GET_DATA_COLUMN} || defined $dataref->{GET_DATA_COUNT} ) ) {
        goto RETURN;
    }

    if ( defined $dataref->{GET_DATA_COLUMN} ) {
    }

    if ( defined $dataref->{GET_DATA_COUNT} ) {
    }

    if ( defined $dataref->{GET_DATA_ALIAS} ) {

        # Check on alias name
    }

    if ( defined $dataref->{GET_DATA_OP_PLUS}
        || defined $dataref->{GET_DATA_OP_MINUS}
        || defined $dataref->{GET_DATA_OP_MULT}
        || defined $dataref->{GET_DATA_OP_DIV}
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

