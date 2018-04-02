use 5.008;
use lib qw( lib t/lib );

use Test::More;
use Test::Deep;

my $verbose     = $ENV{ VERBOSE_FROMPERLVER } || '';

my $madness = 'Module::FromPerlVer';

use_ok $madness => qw( no_copy 1 )
or BAIL_OUT "$madness is not usable.";

my ( $filz, $dirz ) = $madness->source_files;

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

unlink @$filz;

my $prior   = $exists->( 'Prior' );

ok ! -e , "No pre-existing: '$_'"
for @$filz;

for my $found ( $madness->get_files )
{
    my $expect  = 1 + @$filz + @$dirz;

    ok $found == $expect, "Get files returns $found ($expect)";
}

my @copy    = $exists->( 'Copied' );

ok $_->[1] , "Installed: '$_->[0]'"
for @copy;

$madness->cleanup;

my $after   = $exists->( 'After' );

cmp_deeply $after, $prior, 'Cleanup';

done_testing;
__END__
