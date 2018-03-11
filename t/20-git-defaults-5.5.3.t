use 5.006;
use version;

use Test::More;
use Test::Deep;

use File::Basename  qw( basename    );
use FindBin         qw( $Bin        );

use lib "$Bin/../lib";

my $madness = 'Module::FromPerlVer';
my $sandbox = "$Bin/sandbox";
my $perl_v  = 'v5.5.3';

SKIP:
{
    chomp( my $git = qx( git --version ) );

    note "git version: '$git'";

    like $git, qr{^ git }x, "Git version: '$git'"
    or skip 'Failed running git.', 1;

    chdir $sandbox
    or skip "Faild chdir '$sandbox', $!\n", 1;

    note "Test sandbox: '$sandbox'";
    
    # clean any previous test files.

    system '/bin/rm -rf *';

    local $numify   = version->parse( $perl_v )->numify
    or skip "Botched test version: '$perl_v' does not parse.", 1;

    local $ENV{ PERL_VERSION } = $perl_v;

    use_ok $madness => qw( use_git 1 )
    or BAIL_OUT "$madness is not usable.";

    for my $found ( $madness->source_prefix )
    {
        is $found, 'perl/', "Source prefix: '$found' (perl/)";
    }

    for my $found ( $madness->source_files )
    {
        note "Source files:\n", explain $found;

        fail "Found souce files: $found";
    }

    eval
    {
        my $v_string    = "perl/$perl_v";

        chomp( my $found = ( qx{ git branch } )[0] );

        my $rx  = qr{ [*] .+ $v_string }x;

        like $found, $rx, "Branch: '$found' ($v_string)";

        1
    }
    or fail "Unable to determine branch: $@";
}

done_testing;
__END__
