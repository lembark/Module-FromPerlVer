use 5.006;

use Test::More;
use Archive::Tar;
use File::Basename  qw( basename );

for my $madness
(
    qw
    (
        Module::FromPerlVer::Util
        Module::FromPerlVer::Extract
        Module::FromPerlVer::Dir
        Module::FromPerlVer::Git
        Module::FromPerlVer
    )
)
{
    diag "Verify: '$madness'";

    require_ok $madness
    or BAIL_OUT "$madness is not usable.";

    # verify that the package is spelled properly,
    # that a version is installed.

    ok $madness->can( 'VERSION' ), "$madness can 'VERSION'"
    or BAIL_OUT "$madness cannot 'VERSION'", 1;

    my $ver = $madness->VERSION;

    diag "Version: '$madness', $ver";

    ok $ver, "$madness has VERSION '$ver'";
}

done_testing;
__END__
