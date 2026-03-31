use strict;
use warnings;
use ExtUtils::MakeMaker;

my $version = MM->parse_version('lib/Safe/Hole.pm');

WriteMakefile(
    NAME             => 'Safe::Hole',
    VERSION_FROM     => 'lib/Safe/Hole.pm',
    ABSTRACT_FROM    => 'lib/Safe/Hole.pm',
    LICENSE          => 'perl_5',
    AUTHOR           => [
        'Sey Nakajima <nakajima@netstock.co.jp>',
        'Brian McCauley <nobull@cpan.org>',
        'Todd Rinaldo <toddr@cpan.org>',
    ],
    MIN_PERL_VERSION => '5.014',
    INC              => '-I.',
    TEST_REQUIRES    => {
        'Test::More' => '0.40',
    },
    META_ADD => {
        provides => {
            'Safe::Hole' => {
                file    => 'lib/Safe/Hole.pm',
                version => $version,
            },
        },
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            homepage   => 'https://github.com/cpan-authors/Safe-Hole',
            bugtracker => {
                web => 'https://github.com/cpan-authors/Safe-Hole/issues',
            },
            repository => {
                type => 'git',
                url  => 'https://github.com/cpan-authors/Safe-Hole.git',
                web  => 'https://github.com/cpan-authors/Safe-Hole',
            },
        },
    },
    clean => { FILES => 'Safe-Hole-* *.o' },
);
