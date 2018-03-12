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

my $dir     = 't/sandbox';
my $git_d   = "$dir/.git";
my $tball   = "$git_d.tar";

-d $dir
or BAIL_OUT "Bogus release: missing '$dir'";

$ENV{ TEST_EXTRACT }
and system "rm -rf $git_d";

if( -d $git_d )
{
    pass "Existing sandbox: '$dir'";
}
elsif( -e $tball )
{
    diag "Recover $dir/.git using '$tball'.";

    my $tar = Archive::Tar->new;

    eval
    {
        my $base    = 

        chdir $dir
        or die "Failed chdir: '$dir', $!.\n";
            
        $tar->extract_archive( basename $tball )
        or die 'Failed extract: ' . $tar->error;

        note "Extracted $tball -> $git_d";
        
        1
    }
    ? pass "Prepared sandbox: '$git_d'"
    : fail "Failed extract: Git.pm tests will be skipped\n$@"
    ;
}
else
{
    fail "Missing sandbox: $git_d";
    diag "Git.pm tests will skip: missing '$git_d' and '$tball'.";
}

for my $output  ( qx{ 't/bin/make-tests' )
{
    $?
    ? fail "Failed generate tests: $output."
    : pass 'Dynamic tests generated.'
}

done_testing;
__END__
