use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Email::Handle',
    AUTHOR              => 'Naoya Ito <naoya@bloghackers.net>',
    VERSION_FROM        => 'lib/Email/Handle.pm',
    ABSTRACT_FROM       => 'lib/Email/Handle.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'UNIVERSAL::require' => 0.10,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Email-Handle-*' },
);
