use 5.006;

use Test::More;
use Archive::Tar;
use File::Basename  qw( basename );

for my $madness
(
    qw
    (
        Module::FromPerlVer::Extract
        Module::FromPerlVer::Dir
        Module::FromPerlVer::Git
        Module::FromPerlVer
    )
)
{
    require_ok $madness
    or BAIL_OUT "$madness is not usable.";

    # verify that the package is spelled properly,
    # that a version is installed.

    ok $madness->can( 'VERSION' ), "$madness can 'VERSION'"
    or BAIL_OUT "$madness cannot 'VERSION'", 1;

    my $ver = $madness->VERSION;

    ok $ver, "$madness has VERSION '$ver'";
}

for( qx{git --version} )
{
    if( my $status = $? )
    {
        fail "git --version returns $?, git tests will be skipped.";
    }
    else
    {
        chomp;

        pass "Git version: '$_'";
    }
}

done_testing;
__END__
