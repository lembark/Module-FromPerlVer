#######################################################################
# housekeeping
########################################################################

use 5.006;
use strict;
use version;

use ExtUtils::MakeMaker;
my $mm_ver = ExtUtils::MakeMaker->VERSION;

########################################################################
# package variables
########################################################################

my $path    = 'lib/Module/FromPerlVer.pm';
my $version = '0.5.7'; 

########################################################################
# set up sandbox & version directory, generate dynamic tests
########################################################################

system "rm -rf ./t/version t/dynamic t/sandbox/.git"
and print "Failed rm: '$?' ($!)";

for my $base 
(
    qw
    (
        make-version-dir
        make-sandbox-dir
        make-tests
    )
)
{
    my $path    = "t/bin/$base";

    print "Setup: '$path'";

    system "/bin/env perl $path";
    my $err = $!;

    print "$path fails: $err"
    if $err;
}

my @test_spec = 
(
    test =>
    {
        TESTS => 't/*.t t/*/*.t'
    }
);

my @dist_spec =
(
    dist =>
    {
        # the local_repo.tar is *not* in the MANIFEST.
        # it is used here for validating the POD
        # telling people how to make a tarball.

        PREOP =>
        q{ cd t/sandbox/ && /bin/tar cvf .git.tar .git },
    }
);

my @merge_spec
= do
{
    if( $mm_ver < 6.46 )
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
    ABSTRACT_FROM   => $path,
    VERSION         => version->parse( $version )->numify,
    AUTHOR     	    => 'Steven Lembark <lembark@wrkhors.com>',
    LICENSE         => 'perl',
    PREREQ_PM       =>
    {
        # standard distro, particular versions 
        # are unlikely to cause pain.
        #
        # note: Cwd has a fix that may avoid 
        # infinite looping in test for "abs_path '//'".
        # hopefully adding that here will fix the issue.

		qw
        (
            Cwd                     3.73

            Archive::Tar            0
            Carp                    0
            File::Basename          0
            File::Copy::Recursive   0
            File::Find              0
            FindBin                 0
            List::Util              0
            NEXT                    0
            Scalar::Util            0
            Symbol                  0
            Test::More              0
            parent                  0
            strict                  0
            version                 0

        ),

    },

    @dist_spec,
    @test_spec,
    @merge_spec,

);

__END__
