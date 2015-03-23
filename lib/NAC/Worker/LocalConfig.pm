#!/usr/bin/perl

package NAC::Worker::LocalConfig;

use FindBin;
use Env qw(HOME);
use lib "$FindBin::Bin/../..";
use NAC::LocalLogger;
use NAC::Worker;
use NAC::Worker::DB;
use NAC::Worker::Function::LocalConfigData;
use strict;

use constant DEFAULT_NACCONFIGDB => 'nacconfig';
use constant DEFAULT_NACHOST     => 'localhost';
use constant DEFAULT_NACPORT     => 3306;
use constant DEFAULT_NACUSER     => 'nacconfig';
use constant DEFAULT_NACPASS     => '*** some default password ***';
use constant NACRC_FILENAME      => '.nacconfig';
use constant NACRC_HOST          => 'HOST';
use constant NACRC_PORT          => 'PORT';
use constant NACRC_PASS          => 'PASS';
use constant NACRC_USER          => 'USER';
use constant NACRC_CONFIGDB      => 'DB';
use constant NACCONFIGDB         => 'NAC-CONFIG-DB';
use constant NACHOST             => 'NAC-CONFIG-HOST';
use constant NACPORT             => 'NAC-CONFIG-PORT';
use constant NACUSER             => 'NAC-CONFIG-USER';
use constant NACPASS             => 'NAC-CONFIG-PASS';

our @ISA = qw(NAC::Worker);

sub new {
    my ( $class, $parms ) = @_;
    $class = __PACKAGE__;

    $LOGGER_DEBUG_2->(EVENT_START);

    if ( !defined $parms ) {
        $parms = {};
        $parms->{WORKER_PARM_SERVER} = WORKER_SERVER_LOCALHOST;
    }

    my $self = $class->SUPER::new($parms);

    # Open .nacconfig

    my $config_file = $HOME . '/' . NACRC_FILENAME;
    if ( open( NACCONFIG, $config_file ) ) {
        while (<NACCONFIG>) {
            chop;
            my $line = $_;
            my ( $n, $v );
            if ( ( $n, $v ) = split( '=', $line ) ) {
		if ( ! defined $n || '' eq $n ) { next; }
                $n =~ s/\s//g;
                $v =~ s/\s//g;
                if ( $n =~ /^NACRC_HOST/ ) {
                    $self->{NACHOST} = $v;
                }
                elsif ( $n =~ /^NACRC_PORT/ ) {
                    $self->{NACPORT} = $v;
                }
                elsif ( $n =~ /^NACRC_USER/ ) {
                    $self->{NACUSER} = $v;
                }
                elsif ( $n =~ /^NACRC_PASS/ ) {
                    $self->{NACPASS} = $v;
                }
                elsif ( $n =~ /^NACRC_CONFIGDB/ ) {
                    $self->{NACCONFIGDB} = $v;
                }
                else {
                    $LOGGER_WARN->("Unknown RC line: '$line'");
                }
            }
        }
        close NACCONFIG;

    }
    else {
        $LOGGER_WARN->("No config file: $config_file");
    }


    $self->{NACCONFIGDB} = DEFAULT_NACCONFIGDB if !defined $self->{NACCONFIGDB};
    $self->{NACHOST}     = DEFAULT_NACHOST     if !defined $self->{NACHOST};
    $self->{NACPORT}     = DEFAULT_NACPORT     if !defined $self->{NACPORT};
    $self->{NACUSER}     = DEFAULT_NACUSER     if !defined $self->{NACUSER};
    $self->{NACPASS}     = DEFAULT_NACPASS     if !defined $self->{NACPASS};

    $LOGGER_DEBUG_9->( "NACCONFIGDB:" . $self->{NACCONFIGDB} );
    $LOGGER_DEBUG_9->( "NACHOST:" . $self->{NACHOST} );
    $LOGGER_DEBUG_9->( "NACPORT:" . $self->{NACPORT} );
    $LOGGER_DEBUG_9->( "NACUSER:" . $self->{NACUSER} );
    $LOGGER_DEBUG_9->( "NACPASS:" . $self->{NACPASS} );

    #
    # Replace with Get Config
    #
    NAC::Worker::DB::dbh_init( {
            DB_SERVER => $self->{NACHOST},
            DB_PORT   => $self->{NACPORT},
            DB_USER   => $self->{NACUSER},
            DB_PASS   => $self->{NACPASS},
            DB_NAME   => $self->{NACCONFIGDB},
    } );

    $self->add_worker_function( NAC::Worker::Function::LocalConfigData->new() );

    bless $self, $class;
    $self;
}

1;

