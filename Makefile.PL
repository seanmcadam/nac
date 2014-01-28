
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => "NAC",
    AUTHOR    => 'Sean McAdam (sean@fredcom.com)',
    INSTALL_BASE => "~",
    PREREQ_PM => {
        'Data::Dumper'        => 0,
        'Readonly'            => 0,
        'Net::Netmask'        => 0,
        'Net::SNMP'           => 0,
        'Radius::AuthGeneric' => 0,
        'Infoblox'            => 0,
    },
);
