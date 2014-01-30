
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => "NAC",
    AUTHOR       => 'Sean McAdam (sean@fredcom.com)',
    INSTALL_BASE => "~",
    PL_FILES     => {
        'bin/auditrollup.pl'                  => 'bin/auditrollup.pl',
        'bin/check-mysql-slave.pl'            => 'bin/check-mysql-slave.pl',
        'bin/nac-sync-buffer-daemon.pl'       => 'bin/nac-sync-buffer-daemon.pl',
        'bin/sync-lastseen-location-all.pl'   => 'bin/sync-lastseen-location-all.pl',
        'bin/sync-lastseen-mac-all.pl'        => 'bin/sync-lastseen-mac-all.pl',
        'bin/sync-lastseen-switch-all.pl'     => 'bin/sync-lastseen-switch-all.pl',
        'bin/sync-lastseen-switchport-all.pl' => 'bin/sync-lastseen-switchport-all.pl',
        'bin/sync-switchportstate-all.pl'     => 'bin/sync-switchportstate-all.pl',
        'bin/update-host-lastseen.pl'         => 'bin/update-host-lastseen.pl',
        'bin/update-slave-status.pl'          => 'bin/update-slave-status.pl',
        'sql/class-example.sql'               => 'sql/class-example.sql',
        'sql/nacbuffer.sql'                   => 'sql/nacbuffer.sql',
        'sql/naceventlog.sql'                 => 'sql/naceventlog.sql',
        'sql/nacstatus.sql'                   => 'sql/nacstatus.sql',
        'sql/nacaudit.sql'                    => 'sql/nacaudit.sql',
        'sql/nacconfig.sql'                   => 'sql/nacconfig.sql',
        'sql/nacradiusaudit.sql'              => 'sql/nacradiusaudit.sql',
        'sql/nacuser.sql'                     => 'sql/nacuser.sql',
        'sql/uisession.sql'                   => 'sql/uisession.sql',
        'sql/sql-create-backup.sh'            => 'sql/sql-create-backup.sh',
        'sql/sql-import-backup.sh'            => 'sql/sql-import-backup.sh',
    },
    PREREQ_PM => {
        'Data::Dumper'        => 0,
        'Readonly'            => 0,
        'Net::Netmask'        => 0,
        'Net::SNMP'           => 0,
        'Radius::AuthGeneric' => 0,
        'Infoblox'            => 0,
    },
);
