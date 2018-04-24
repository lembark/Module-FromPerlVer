########################################################################
# test using module with no args (all defaults) for perl version values.
########################################################################

use 5.008;
use strict;
use version;
use lib qw( lib t/lib );

use Test::More;
use Test::Deep;

use File::Basename  qw( basename    );
use File::Temp      qw( tempfile    );

my $madness = 'Module::FromPerlVer';

SKIP:
{
    require_ok $madness
    or BAIL_OUT "Failed require: '$madness'", 1;

    my @tmp_filz    = ();

    for my $pref ( '', 'v' )
    {
        for my $fmt
        (
            qw
            (
                5
                5.
                5.0
                5.%d%d
                5.%03d%03d
                5.%d.%d
                5.%03d.%03d
                5.%d_%d
                5.%03d_%03d
            )
        )
        {
            my $perl_v  = sprintf $pref . $fmt => 0, 0;

            my $use     = "no $perl_v;";

            note "Testing: '$use'";

            my $v_file
            = eval
            {
                if
                (
                    my ( $fh, $path ) 
                    = tempfile 'perl_version.XXXX'
                )
                {
                    print $fh $use . "\n"
                    or die "Failed print: '$path', $!\n";

                    close $fh
                    or die "Failed close: '$path', $!\n";

                    push @tmp_filz, $path;

                    END
                    {
                        -e && unlink
                        for @tmp_filz;
                    }

                    $path
                }
                else
                {
                    die "Failed 'tempfile', $!\n";
                }
            }
            or skip $@, 1;

            note "Version file: '$v_file'";

            eval
            {
                $madness->import( version_from => $v_file );

                fail "Did not reject '$use'";

                1
            }
            and next;

            $@ =~  m{Botched version_from: no .+? must be > 5.0' }
            ? fail "Mis-handled 5.0.0, '$@' ($use)"
            : pass "Rejected 5.0.0 ($use)"
            ;
        }
    }
}

done_testing;
__END__
