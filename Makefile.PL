
use 5.006;
use strict;
use version;

use ExtUtils::MakeMaker;

my $path    = 'lib/Module/FromPerlVer.pm';
my $version = '0.4.4'; 

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
);

__END__
