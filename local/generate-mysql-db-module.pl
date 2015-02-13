#!/usr/bin/perl

use Perl::Tidy;
use Data::Dumper;
use Carp;
use Readonly;
use DBI;
use Getopt::Std;
use strict;

Readonly our $OUTPUT_FILENAME     => 'OUTPUT_FILENAME';
Readonly our $SCHEMA_NAME         => 'SCHEMA_NAME';
Readonly our $SCHEMA_TABLES       => 'SCHEMA_TABLES';
Readonly our $SCHEMA_PACKAGE_NAME => 'SCHEMA_PACKAGE_NAME';
Readonly our $TABLE_NAME          => 'TABLE_NAME';
Readonly our $TABLE_DB_NAME       => 'TABLE_DB_NAME';
Readonly our $TABLE_COLUMNS       => 'TABLE_COLUMNS';
Readonly our $COLUMN_NAME         => 'COLUMN_NAME';
Readonly our $COLUMN_DB_NAME      => 'COLUMN_DB_NAME';
Readonly our $COLUMN_KEY          => 'COLUMN_KEY';
Readonly our $COLUMN_DATA         => 'COLUMN_DATA';
Readonly our $COLUMN_TYPE         => 'COLUMN_TYPE';
Readonly our $DATA_TYPE           => 'DATA_TYPE';

my $progname = ( split( /\//, $0 ) )[-1];

my $DEBUG = 0;
my $DELIM = '_';

#
#
# Args
# DB Login into
# Package Name
# optional table list
#
our $opt_d = 0;
our $opt_h = 0;
our $opt_s = 0;
our $opt_u = 0;
our $opt_p = 0;
our $opt_P = 0;
our $opt_O = 0;

my $server_port  = "localhost:3306";
my $username     = '';
my $password     = '';
my $package_name = '';
my $output_dir   = '';

getopts('dhs:u:p:P:O:');

if ($opt_d) {
    $DEBUG = 1;
}

if ($opt_h) {
    print_usage();
}

if ($opt_s) {
    $server_port = $opt_s;
}

if ($opt_u) {
    $username = $opt_u;
}
else {
    print "Missing username\n";
    print_usage();
}

if ($opt_p) {
    $password = $opt_p;
}
else {
    print "Missing password\n";
    print_usage();
}

if ($opt_P) {
    $package_name = $opt_P;
}
else {
    $package_name = "DB";
}

if ($opt_O) {
    $output_dir = $opt_O;
}
else {
    $output_dir = '.';
}

my ( $server_name, $port ) = split( /:/, $server_port );
if ( !$port ) {
    $port = 3306;
}

#  nacconfig nacaudit nacbuffer nacconfig naceventlog nacradiusaudit nacsessions nacstatus nacuser

my @my_packages;

my %my_schema_dbnames;
my %my_table_dbnames;
my %my_column_dbnames;
my %my_schema_names;
my %my_table_names;
my %my_column_names;

foreach my $a (@ARGV) {
    $my_schema_dbnames{$a} = 1;
}

my $db = 'mysql';
my $dbh;
connect_to_db();

# ---------------------
# ---------------------
# ---------------------

my %mysql_data_types = (
    'char'      => 'DATATYPE_CHAR',
    'datestamp' => 'DATATYPE_DATESTAMP',
    'enum'      => 'DATATYPE_ENUM',
    'int'       => 'DATATYPE_INT',
    'mediumint' => 'DATATYPE_MEDUMINT',
    'smallint'  => 'DATATYPE_SMALLINT',
    'text'      => 'DATATYPE_TEXT',
    'tinyint'   => 'DATATYPE_TINYINT',
    'timestamp' => 'DATATYPE_TIMESTAMP',
    'varchar'   => 'DATATYPE_VARCHAR',
);

my %data_types = (
    'DATATYPE_CHAR'      => 'char',
    'DATATYPE_DATESTAMP' => 'datestamp',
    'DATATYPE_ENUM'      => 'enum',
    'DATATYPE_INT'       => 'int',
    'DATATYPE_MEDUMINT'  => 'mediumint',
    'DATATYPE_SMALLINT'  => 'smallint',
    'DATATYPE_TEXT'      => 'text',
    'DATATYPE_TINYINT'   => 'tinyint',
    'DATATYPE_TIMESTAMP' => 'timestamp',
    'DATATYPE_VARCHAR'   => 'varchar',
);

my $date              = localtime(time);
my %schemas           = ();                # Pulled from the database
my %db                = ();                # Created locally with the schemas we want
my %consts            = ();
my $constants_all     = '';
my $constants_exports = '';

$consts{'DATATYPE_CHAR'}      = 'CHAR';
$consts{'DATATYPE_DATESTAMP'} = 'DATESTAMP';
$consts{'DATATYPE_ENUM'}      = 'ENUM';
$consts{'DATATYPE_INT'}       = 'INT';
$consts{'DATATYPE_MEDUMINT'}  = 'MEDUMINT';
$consts{'DATATYPE_SMALLINT'}  = 'SMALLINT';
$consts{'DATATYPE_TEXT'}      = 'TEXT';
$consts{'DATATYPE_TINYINT'}   = 'TINYINT';
$consts{'DATATYPE_TIMESTAMP'} = 'TIMESTAMP';
$consts{'DATATYPE_VARCHAR'}   = 'VARCHAR';

my $schema_ref = get_schemas();

foreach my $schema ( keys(%$schema_ref) ) {
    if ( $schema eq 'mysql'
        || $schema eq 'information_schema'
        || !defined $my_schema_dbnames{$schema}
      ) { next; }

    my $D = $schema;
    $D =~ tr/a-z/A-Z/;
    $db{$schema} = {};
    my $sref = $db{$schema};

    my $db_package = $schema;
    $db_package =~ /^(.)/;
    my $first_letter = $1;
    $first_letter =~ tr/a-z/A-Z/;
    $db_package   =~ s/^./$first_letter/;
    my $db_package_name = $package_name . '::' . $db_package;

    push( @my_packages, $db_package_name );

    $sref->{$SCHEMA_NAME}         = $D . $DELIM . "DB";
    $sref->{$SCHEMA_TABLES}       = {};
    $sref->{$SCHEMA_PACKAGE_NAME} = $db_package_name;

    my $table_ref = get_tables($schema);
    foreach my $table ( keys(%$table_ref) ) {
        my $DT = $D . $DELIM . $table;
        $DT =~ tr/a-z/A-Z/;
        $sref->{$SCHEMA_TABLES}{$table} = {};
        my $tref = $sref->{$SCHEMA_TABLES}{$table};

        $tref->{$TABLE_NAME}    = $DT . $DELIM . "TABLE";
        $tref->{$TABLE_COLUMNS} = {};

        my $column_ref = get_columns( $schema, $table );
        foreach my $column ( keys(%$column_ref) ) {
            my $DTC = $DT . $DELIM . $column;
            $DTC =~ tr/a-z/A-Z/;
            $tref->{$TABLE_COLUMNS}{$column} = {};
            my $cref = $tref->{$TABLE_COLUMNS}{$column};
            $cref->{$COLUMN_NAME} = $DTC . $DELIM . "COLUMN";
            $cref->{$COLUMN_DATA} = $column_ref->{$column};
        }
    }
}

my $formatted_file = '';

my $file = "#!/usr/bin/perl
#
# ------------------------
# Auto Generated File
# BY: $progname
# ON: $date
# ------------------------
# 
#

package $package_name;
use Data::Dumper;
use Carp;
use base qw( Exporter );
use FindBin;
use lib \"\$FindBin::Bin\/.\";
use strict;
";

$file .= gen_database_files();
$file .= gen_db_file();

    Perl::Tidy::perltidy(
        source      => \$file,
        destination => \$formatted_file,
        argv        => " -l=0 -anl -fnl ",
    );

print $formatted_file;

# ------------------------------------------------------------------
# ------------------------------------------------------------------
# ------------------------------------------------------------------
sub gen_database_files {
    my $ret;
    my $format;

    foreach my $schema ( sort( keys(%db) ) ) {
        my $c_all     = '';
        my $c_exports = '';

        my $sref                = $db{$schema};
        my $schema_name         = $sref->{$SCHEMA_NAME};
        my $schema_package_name = $sref->{$SCHEMA_PACKAGE_NAME};
        my $schema_table_ref    = $sref->{$SCHEMA_TABLES};
        $c_all             .= "use constant '" . $schema_name . "' => '$schema_name';\n";
        $c_exports         .= "$schema_name\n";
        $constants_exports .= "$schema_name\n";

        my $schemadb = $schema . "_DB_DBNAME";
        $schemadb =~ tr/a-z/A-Z/;
        $c_all             .= "use constant '" . $schemadb . "' => '$schema';\n";
        $c_exports         .= "$schemadb\n";
        $constants_exports .= "$schemadb\n";

	$my_schema_dbnames{ $schema } = $schema_name;
	$my_schema_names{ $schema_name } = $schema;

        foreach my $table ( sort( keys(%$schema_table_ref) ) ) {
            my $tref       = $schema_table_ref->{$table};
            my $table_name = $tref->{$TABLE_NAME};
            my $column_ref = $tref->{$TABLE_COLUMNS};
            $c_all             .= "use constant '" . $table_name . "' => '$table_name';\n";
            $c_exports         .= "$table_name\n";
            $constants_exports .= "$table_name\n";

            my $table_db_name = $tref->{$TABLE_NAME};
            my $tabledb       = $table_name . "_DBNAME";
            $c_all             .= "use constant '" . $tabledb . "' => '$schema.$table';\n";
            $c_exports         .= "$tabledb\n";
            $constants_exports .= "$tabledb\n";
            $tref->{$TABLE_DB_NAME} = $schema . '.' . $table_db_name;

	    $my_table_dbnames{ $schema . '.' . $table } = $table_name;
	    $my_table_names{ $table_name } = $schema . '.' . $table;

            my $primary_key_count       = 0;
            my $primary_key_name        = '';
            my $primary_key_column_name = '';

            foreach my $column ( sort( keys(%$column_ref) ) ) {
                my $cref        = $column_ref->{$column};
                my $column_name = $cref->{$COLUMN_NAME};
                $c_all             .= "use constant '" . $column_name . "' => '$column_name';\n";
                $c_exports         .= "$column_name\n";
                $constants_exports .= "$column_name\n";

                my $dref      = $cref->{$COLUMN_DATA};
                my $data_type = $cref->{$DATA_TYPE};
                my $data      = $column_name . "_DATATYPE";
                $c_all             .= "use constant '" . $data . "' => '$data';\n";
                $c_exports         .= "$data\n";
                $constants_exports .= "$data\n";

                my $column_db_name = $dref->{$COLUMN_NAME};
                my $coldb          = $column_name . "_DBNAME";
                $c_all             .= "use constant '" . $coldb . "' => '$schema.$table.$column_db_name';\n";
                $c_exports         .= "$coldb\n";
                $constants_exports .= "$coldb\n";
                $dref->{$COLUMN_DB_NAME} = $schema . '.' . $table_db_name . '.' . $column_db_name;

	    $my_column_dbnames{ $schema . '.' . $table . '.' . $column } = $column_name;
	    $my_column_names{ $column_name } = $schema . '.' . $table . '.' . $column;

                #
                # enum(\'EVENT_START\',\'EVENT_STOP\'...
                #
                my $column_type = $dref->{$COLUMN_TYPE};    # Used for ENUM
                if ( $column_type =~ /^enum/ ) {
                    $column_type =~ s/^enum\(//;
                    $column_type =~ s/\)$//;
                    $column_type =~ s/\'//g;
                    foreach my $enum ( split( /,/, $column_type ) ) {
                        my $ENUM = $enum;
                        $ENUM =~ tr/a-z/A-Z/;
                        my $enum_name    = $column_name . $DELIM . $ENUM . "_ENUM";
                        my $enum_db_name = $column_name . $DELIM . $ENUM . "_ENUM_DBNAME";
                        $c_all             .= "use constant '" . $enum_name . "' => '$enum_name';\n";
                        $c_exports         .= "$enum_name\n";
                        $constants_exports .= "$enum_name\n";
                        $c_all             .= "use constant '" . $enum_db_name . "' => '$enum';\n";
                        $c_exports         .= "$enum_db_name\n";
                        $constants_exports .= "$enum_db_name\n";
                    }
                }

                if ( 'PRI' eq $dref->{$COLUMN_KEY} ) {
                    $primary_key_count++;
                    $primary_key_name        = $table_name . "_PRIKEY";
                    $primary_key_column_name = $column_name;
                }

            }

            if ( $primary_key_count == 1 ) {
                $c_all             .= "use constant '" . $primary_key_name . "' => $primary_key_column_name;\n";
                $c_exports         .= "$primary_key_name\n";
                $constants_exports .= "$primary_key_name\n";
            }

        }

        # print Dumper \$db{$schema};

        $ret .= << "EODBPACKAGE"
$c_all
EODBPACKAGE

    }
$ret;
}

#
# ------------------------------------------------------------------
sub gen_db_file {
    my $ret;
    my $format;

    $ret = << "EODBS"

EODBS
      ;

$ret .= "my %schema_dbnames = ( \n";
foreach my $s (sort(keys(%my_schema_dbnames))) {
	$ret .= '"' . $s . '" => ' . $my_schema_dbnames{$s} . ",\n";
}
$ret .= ");\n";

$ret .= "my %table_dbnames = ( \n";
foreach my $t (sort(keys(%my_table_dbnames))) {
	$ret .= '"' . $t . '" => ' . $my_table_dbnames{$t} . ",\n";
}
$ret .= ");\n";

$ret .= "my %column_dbnames = ( \n";
foreach my $c (sort(keys(%my_column_dbnames))) {
	$ret .= '"' . $c . '" => ' . $my_column_dbnames{$c} . ",\n";
}
$ret .= ");\n";

$ret .= "my %schema_names = ( \n";
foreach my $s (sort(keys(%my_schema_names))) {
	$ret .= $s . ' => "' . $my_schema_names{$s} . '"' . ",\n";
}
$ret .= ");\n";

$ret .= "my %table_names = ( \n";
foreach my $t (sort(keys(%my_table_names))) {
	$ret .= $t . ' => "' . $my_table_names{$t} . '"' . ",\n";
}
$ret .= ");\n";
$ret .= "my %column_names = ( \n";
foreach my $c (sort(keys(%my_column_names))) {
	$ret .= $c . ' => "' . $my_column_names{$c} . '"' . ",\n";
}
$ret .= ");\n";


    $ret .= << "EODBS1"

our \@EXPORT = qw(
verify_db_name 
verify_table_name 
verify_column_name 
verify_db_dbname 
verify_table_dbname 
verify_column_dbname 
get_db_dbname 
get_table_dbname 
get_column_dbname 
$constants_exports);

sub new {
    my (\$class) = \@_;
    my \$self = {};
    bless \$self,\$class;
    \$self;
}

sub verify_db_name {
    my (\$dbname) = \@_;
    if( defined \$schema_names{\$dbname} ) {
	return 1;
	}
return 0;
}
sub verify_table_name {
    my (\$table) = \@_;
    if( defined \$table_names{\$table} ) {
	return 1;
	}
return 0;
}
sub verify_column_name {
    my (\$column) = \@_;
    if( defined \$column_names{\$column} ) {
	return 1;
	}
return 0;
}
sub verify_db_dbname {
    my (\$dbname) = \@_;
    if( defined \$schema_dbnames{\$dbname} ) {
	return 1;
	}
return 0;
}
sub verify_table_dbname {
    my (\$table) = \@_;
    if( defined \$table_dbnames{\$table} ) {
	return 1;
	}
return 0;
}
sub verify_column_dbname {
    my (\$column) = \@_;
    if( defined \$column_dbnames{\$column} ) {
	return 1;
	}
return 0;
}
sub get_db_dbname {
    my (\$db) = \@_;
    if( ! verify_schema_name(\$db) ) { confess Dumper \@_; }
    return \$schema_names{\$db};
}
sub get_table_dbname {
    my (\$table) = \@_;
    if( ! verify_table_name(\$table) ) { confess Dumper \@_; }
    return \$table_names{\$table};
}
sub get_column_dbname {
    my (\$column) = \@_;
    if( ! verify_column_name(\$column) ) { confess Dumper \@_; }
    return \$column_names{\$column};
}

1;

EODBS1
      ;

    $ret;
}

# ------------------------------------------------------------------
sub get_schemas {
    my $ret = 0;
    my $sql = "SELECT * FROM information_schema.schemata";
    my $sth = $dbh->prepare($sql) || confess $dbh->errstr;
    if ( !( $ret = $sth->execute() ) ) {
        confess $dbh->errstr;
    }

    $sth->fetchall_hashref($SCHEMA_NAME);
}

# ------------------------------------------------------------------
sub get_tables {
    my ($schema) = @_;
    my $ret = 0;

    my $sql = "SELECT * FROM information_schema.tables WHERE table_schema = '$schema'";
    my $sth = $dbh->prepare($sql) || confess $dbh->errstr;
    if ( !( $ret = $sth->execute() ) ) {
        confess $dbh->errstr;
    }

    $sth->fetchall_hashref($TABLE_NAME);
}

# ------------------------------------------------------------------
sub get_columns {
    my ( $schema, $table ) = @_;
    my $ret = 0;
    my $sql = "SELECT * FROM information_schema.columns WHERE table_schema = '$schema' AND table_name = '$table'";

    my $sth = $dbh->prepare($sql) || confess $dbh->errstr;
    if ( !( $ret = $sth->execute() ) ) {
        confess $dbh->errstr;
    }

    $sth->fetchall_hashref($COLUMN_NAME);
}

# ------------------------------------------------------------------
sub connect_to_db {

    my $db_source = "dbi:mysql:"
      . "dbname=$db;"
      . "host=$server_name;"
      . "port=$port;"
      ;

    if ( !( $dbh = DBI->connect(
                $db_source,
                $username,
                $password,
                {
                    PrintError => 1,
                    RaiseError => 1,
                    AutoCommit => 1,
                },
            ) ) ) {
        confess "Could not connect to DB\n";
    }

}

# ------------------------------------------------------------------
sub print_usage {
    print "$progname -s server[:port] -u user -p pass -P perl-package-name -O outputdir \n";
    exit;
}

