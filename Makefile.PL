use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'minerl',
    AUTHOR           => q{neevek <i@neevek.net>},
    VERSION_FROM     => 'lib/minerl.pm',
    ABSTRACT_FROM    => 'lib/minerl.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.10.0,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'File::Path' => 2.08_01,
        'File::Copy' => 0,
        'File::Basename' => 0,
        'File::Find' => 0,
        'Config::IniFiles' => 0,
        'HTML::Template' => 2.94,
        'Text::Template' => 1.46,
        'Text::MultiMarkdown' => 0,
        'Getopt::Compact::WithCmd' => 0,
        'HTTP::Server::Brick' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'minerl-*' },
);
