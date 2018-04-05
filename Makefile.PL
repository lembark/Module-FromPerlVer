#######################################################################
# housekeeping
########################################################################

use 5.008;
use strict;
use version;

use ExtUtils::MakeMaker;

########################################################################
# package variables
########################################################################

$\          = "\n";

my $module  = 'lib/Module/FromPerlVer.pm';
my $version = '0.9.1'; 

########################################################################
# various things that may depend on the ExtUtils::MakeMaker version.
# the main hash gets messy enough as it is, keep the logic for these
# up here and just insert them into the write args, below.
########################################################################

my $mm_v    = ExtUtils::MakeMaker->VERSION;

my @test_spec = 
(
    test =>
    {
        TESTS => 't/*.t t/*/*.t'
    }
);

my @dist_spec =
(
# steps to execute prior to testing.
#
#    dist =>
#    {
#        # the local_repo.tar is *not* in the MANIFEST.
#        # it is used here for validating the POD
#        # telling people how to make a tarball.
#
#        PREOP =>
#        q{ cd sandbox/ && /bin/tar cvf .git.tar .git },
#    }
);

my @merge_spec
= do
{
    if( $mm_v < 6.46 )
    {
        ()
    }
    else
    {
        my $web = 'https://github.com/lembark/Module-FromPerlVer';
        my $url = $web . '.git';


        META_MERGE => 
        {
            'meta-spec' =>
            {
                version => 2
            },
            dynamic_config => 1,
            resources => 
            {
                repository => 
                {
                    web  => $web, 
                    url  => $url,
                    type => 'git',
                },
                bugtracker => 
                {
                    web => 'https://rt.cpan.org/Dist/Display.html?Name=Module-FromPerlVer',
                },
            },
        }
    }
};

WriteMakefile
(
    NAME            => 'Module::FromPerlVer',
    ABSTRACT_FROM   => $module,
    VERSION         => version->parse( $version )->numify,
    AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    LICENSE         => 'perl',
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.
        #
        # L::U 1.44 has uniq

		qw
        (
            version                 0.9918
            Cwd                     3.073
            List::Util              1.050

            Archive::Tar            0
            Carp                    0
            File::Basename          0
            File::Copy::Recursive   0
            File::Find              0
            File::Spec::Functions   0
            FindBin                 0
            List::MoreUtils         0
            NEXT                    0
            Scalar::Util            0
            Symbol                  0
            Test::Deep              0
            Test::More              0
            lib                     0
            parent                  0
            strict                  0
            version                 0
            warnings                0
        ),
    },

    @dist_spec,
    @test_spec,
    @merge_spec,
);

__END__
