
# this is the minimum version guaranteed to work with
# File::Copy and FindBin::libs;

use 5.008;
use strict;

my $vers    = version->parse( 0.010 )->numify;

use ExtUtils::MakeMaker;

my $path    = 'lib/Module/FromPerlVer.pm';

WriteMakefile
(
    NAME            => 'Module::FromPerlVer',
    ABSTRACT_FROM   => $path,
    VERSION         => $vers,
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
            FindBin                 0
            List::Util              0
            Symbol                  0
            Test::More              0
            strict                  0
            version                 0
        )
    },
);

__END__
