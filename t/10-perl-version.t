use 5.008;
use lib qw( lib t/lib );

use Test::More;
use Test::Deep;

use FindBin qw( $Bin );
use lib( "$Bin/../lib" );
use Test::KwikHaks;

delete $ENV{ PERL_VERSION };

my $madness = 'Module::FromPerlVer';

my $work_d  = eval { Test::KwikHaks::work_dir() }
or BAIL_OUT "Failed create tmpdir: $@";

use_ok $madness =>  ( no_copy => 1, dest_dir => $work_d )
or BAIL_OUT "$madness is not usable.";

my ( $filz, $dirz ) = $madness->dest_paths;

my $exists
= sub
{
    my $heading = shift || 'Existing';
    my @resultz
    = map
    {
        [ $_ => -e ]
    }
    sort
    {
        $a cmp $b
    }
    (
        @$dirz,
        @$filz
    );

    note "$heading:\n", explain \@resultz
    if $verbose;

    wantarray
    ?  @resultz
    : \@resultz
};

# cleanup prior to running in case prior
# tests left cruft behind.

$madness->cleanup();

my $prior   = $exists->( 'Prior' );

ok ! -e , "No pre-existing: '$_'"
for @$filz;

for my $found ( $madness->copy_source_dir )
{
    my $expect  = 1 + @$filz + @$dirz;

    ok $found == $expect, "Get files returns $found ($expect)";
}

my @copy    = $exists->( 'Copied' );

ok $_->[1] , "Installed: '$_->[0]'"
for @copy;

$madness->cleanup;

my $after   = $exists->( 'After' );

# after the cleanup the filesystem should look
# as it did on the way in. any existing dir's 
# will still be there but files should be gone.

cmp_deeply $after, $prior, 'Cleanup';

done_testing;
__END__
