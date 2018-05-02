
# this is the minimum version guaranteed to work with
# File::Copy and FindBin::libs;

use 5.008;
use strict;

my $version = version->parse( 'v0.22.0' )->numify;

use ExtUtils::MakeMaker;

my $path    = 'lib/Module/FromPerlVer.pm';
my $mm_v    
= version->parse( ExtUtils::MakeMaker->VERSION )->numify;

my $mod2ver
= sub
{
$DB::single = 1;

    map
    {
        (
            $_->[0] => 
            version->parse( $_->[1] )->numify
        )
    }
    @_
};

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
                    Symbol                  0
                    Test::Deep              0
                    Test::More              0
                ),
                $mod2ver->
                (
                    [ qw( Cwd                               v3.73.0 ) ],
                    [ qw( List::Util                        v1.46.0 ) ],
                    [ qw( File::Copy::Recursive::Reduced    v0.2.0  ) ],
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
		qw
        (
            File::Basename          0
            File::Find              0
            File::Spec::Functions   0
            FindBin                 0
            Symbol                  0
            Test::More              0
            strict                  0
            version                 0
        ),
        $mod2ver->
        (
            [ qw( Cwd                               v3.73.0 ) ],
            [ qw( List::Util                        v1.46.0 ) ],
            [ qw( File::Copy::Recursive::Reduced    v0.2.0  ) ],
        )
    },

    test =>
    {
        TESTS => 't/*.t t/dynamic/*.t'
    },

    @merge_spec
);

__END__
