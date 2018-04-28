
# this is the minimum version guaranteed to work with
# File::Copy and FindBin::libs;

use 5.008;
use strict;

my $version = version->parse( 'v0.2.1' )->numify;

use ExtUtils::MakeMaker;

my $path    = 'lib/Module/FromPerlVer.pm';
my $mm_v    
= version->parse( ExtUtils::MakeMaker->VERSION )->numify;

my @merge_spec
= do
{
    if( $mm_v < 6.052 )
    {
        ()
    }
    else
    {
        META_MERGE => 
        {
            'meta-spec' =>
            {
                version => 2
            },

            dynamic_config => 1,

            CONFIGURE_REQUIRES =>
            {
                qw
                (
                    strict  0
                    version 0

                    ExtUtils::MakeMaker
                )
            },

            TEST_REQUIRES =>
            {
                Cwd => version->parse( '3.73'  )->numify,
                qw
                (
                    lib     0
                    strict  0
                    version 0

                    Archive::Tar            0
                    File::Basename          0
                    File::Find              0
                    File::Spec::Functions   0
                    File::Temp              0
                    FindBin                 0
                    List::MoreUtils         0
                    List::Util              0
                    Symbol                  0
                    Test::Deep              0
                    Test::More              0
                )
            },
        }
    }
};

WriteMakefile
(
    NAME            => 'Module::FromPerlVer',
    ABSTRACT_FROM   => $path,
    VERSION         => $version,
    LICENSE         => 'perl',
	AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    PREREQ_PM       =>
    {
        # fixes issue with parsing used to test
        # filesystem.

        Cwd => version->parse( '3.73'  )->numify,

        # standard distro, particular versions 
        # are unlikely to cause pain.

		qw
        (
            File::Basename          0
            File::Copy::Recursive   0
            File::Find              0
            File::Spec::Functions   0
            FindBin                 0
            List::Util              0
            Symbol                  0
            Test::More              0
            strict                  0
            version                 0
        )
    },

    test =>
    {
        TESTS => 't/*.t t/dynamic/*.t'
    },

    @merge_spec
);

__END__
