########################################################################
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
my $version = '0.5.1'; 

########################################################################
# set up sandbox & version directory, generate dynamic tests
########################################################################

$ENV{ TEST_EXTRACT }
and do
{
    system "rm -rf ./t/version t/sandbox/.git";
    my $err = $?;
    
    print "Failed rm: '$err' (TEST_EXTRACT)"
    if $err;
};

for my $base ( qw( make-version-dir make-sandbox-dir make-tests ) )
{
    my $path    = "t/bin/$base";

    print "Setup: '$path'";

    system "/bin/env perl $path";
    my $err = $!;

    print "$path fails: $err"
    if $err;
}

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

		qw
        (

            Archive::Tar            0
            Carp                    0
            Cwd                     0
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

    dist =>
    {
        # the local_repo.tar is *not* in the MANIFEST.
        # it is used here for validating the POD
        # telling people how to make a tarball.

        PREOP =>
        q{ cd t/sandbox/ && /bin/tar cvf .git.tar .git },
    },

    test =>
    {
        TESTS => 't/*.t t/*/*.t'
    },
    ($mm_ver < 6.46 ? () : (META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 1,
        resources => {
            repository => {
                url => 'https://github.com/lembark/Module-FromPerlVer.git',
                web => 'https://github.com/lembark/Module-FromPerlVer',
                type => 'git',
            },
            bugtracker => {
                web => 'https://rt.cpan.org/Dist/Display.html?Name=Module-FromPerlVer',
            },
        },
    })),
);

__END__
