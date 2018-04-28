
# this is the minimum version guaranteed to work with
# File::Copy and FindBin::libs;

use 5.008;
use strict;
use version;

my $version = version->parse( 'v0.20.1' )->numify;

use ExtUtils::MakeMaker;

my $version = 'v0.20.1';

my $path    = 'lib/Module/FromPerlVer.pm';
my $mm_v
= version->parse( ExtUtils::MakeMaker->VERSION )->numify;

WriteMakefile
(
    NAME            => 'Module::FromPerlVer',
    ABSTRACT_FROM   => $path,
    VERSION         => version->parse( $version )->numify,
    LICENSE         => 'perl',
	AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM       =>
    {
        # fixes issue with parsing used to test
        # filesystem.

        'Cwd'
        => version->parse( '3.73'  )->numify,

        # contains uniq.

        'List::Util'
        => version->parse( '1.46' )->numify,

        # standard distro, particular versions
        # are unlikely to cause pain.

		qw
        (
            version                 0.9918

            Archive::Tar            0
            Carp                    0
            File::Basename          0
            File::Find              0
            File::Spec::Functions   0
            FindBin                 0
            List::Util              0
            List::MoreUtils         0
            Symbol                  0
            Test::More              0
            strict                  0
            version                 0
        )
    },

    $mm_v < 6.046
    ? ()
    : do
    {
        META_MERGE =>
        {
            'meta-spec' =>
            {
                version => 2
            },

            dynamic_config => 1,

            test =>
            {
                TESTS => 't/*.t t/*/*.t'
            },

            config_requires =>
            {
                qw
                (
                    strict  0
                    version 0

                    ExtUtils::MakeMaker 0
                )
            },

            TEST_REQUIRES =>
            {
                'Cwd'
                => version->parse( 'v3.73' )->numify,

                'List::Util'
                => version->parse( 'v1.46' )->numify,
                qw
                (
                    lib                     0
                    strict                  0
                    version                 0
                    warnings                0

                    Archive::Tar            0
                    File::Basename          0
                    File::Find              0
                    File::Spec::Functions   0
                    File::Temp              0
                    FindBin                 0
                    List::MoreUtils         0
                    Symbol                  0
                    Test::Deep              0
                    Test::More              0
                )
            },

            CONFIGURE_REQUIRES =>
            {
                qw
                (
                    strict
                    version

                    ExtUtils::MakeMaker
                )
            },
        }
    },

);

__END__
