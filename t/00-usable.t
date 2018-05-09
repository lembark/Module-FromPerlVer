use 5.006;
use strict;

use Test::More;

use Cwd             qw( getcwd              );
use File::Basename  qw( basename dirname    );
use File::Find      qw( find                );

# check the working directory, quick check is whether 
# 'lib' exists on the path.

my $cwd         = getcwd;

diag "Working dir: '$cwd'";
diag "Executable:  '$0'";

-e 'lib'
? diag "Found 'lib' directory"
: diag "Missing 'lib' directory"
;

my $wanted
= sub
{
    -f or return;

    my $path    = $File::Find::name;
    my $base    = basename $path;
    my $dir1    = basename dirname $path;
    my $name    = "$dir1/$base";

    if( open my $fh, '<', $_ )
    {
        local $/    = "\n";

        while( my $line = readline $fh )
        {
            -1 < index  $line, 'File::Copy::Recursive'
            and
            diag "$name  $. : '$line'";
        }
    }
    else
    {
        diag "Failed open: '$path', $!";
    }
};

diag "Search: '$cwd' for files with 'File::Copy::Recursive'";
find $wanted, $cwd;

my $madness = 'Module::FromPerlVer';

require_ok $madness
or BAIL_OUT "$madness is not usable.";

use_ok $madness;

my $version = eval { $madness->VERSION };

ok $madness->can( 'VERSION' ),  "$madness can 'VERSION'";
ok $version,                    "$madness has a VERSION ($version)";

done_testing;
__END__
