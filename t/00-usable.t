use 5.006;

use Test::More;
use Archive::Tar;
use File::Basename  qw( basename );

use lib qw( lib t/lib );

for my $madness
(
    qw
    (
        Test::KwikHaks
        Module::FromPerlVer::Util
        Module::FromPerlVer::Extract
        Module::FromPerlVer::Dir
        Module::FromPerlVer::Git
        Module::FromPerlVer
    )
)
{
    require_ok $madness
    or BAIL_OUT "$madness is not usable.";

    # simple check: is there any method to the madness?
    # true => package is probably spelled correctly.

    ok $madness->can( 'VERSION' ), "$madness can 'VERSION'"
    or BAIL_OUT "$madness cannot 'VERSION'", 1;

    my $ver = $madness->VERSION;

    ok $ver, "$madness has VERSION '$ver'";

    diag "Version: '$madness', $ver";
}

for my $dir
(
    qw
    (
        t/version
        t/dynamic
        t/sandbox
    )
)
{
    ok -d $dir, "Found: '$dir'";

    my @filz    = ( glob( "$dir/*" ), glob( "$dir/.[a-z]*" ) );

    diag join "\n" => "Dir contents: '$dir'", explain \@filz;
}

done_testing;
__END__
