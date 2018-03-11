use 5.006;

use Test::More;
use Archive::Tar;

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

    ok my $v = $madness->VERSION, "$madness has a VERSION";

    note "Found version: '$v'";
}

my $dir     = 't/sandbox';
my $base    = '.git.tar';
my $path    = "$dir/$base";

if( -e "$dir/.git" )
{
    note 'Sandbox ready, Git tests are runable.';
}
elsif( -e $path )
{
    diag "Recover '$path' for Git.pm tests.";

    my $tar = Archive::Tar->new;

    eval
    {
        chdir $dir
        or die "Failed chdir: '$dir', $!.\n";
            
        $tar->extract_archive( $base )
        or die 'Failed extract: ' . $tar->error;
    }
    or diag "Failed extract: Git.pm tests will be skipped\n$@";
}
else
{
    diag "Git.pm tests will skip: missing '$base' and '$dir/.git'";
}

done_testing;
__END__
