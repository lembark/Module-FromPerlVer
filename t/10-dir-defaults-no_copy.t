use 5.006;
use version;
use lib qw( lib t/lib );

use Test::More;


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
    (
        @$dirz,
        @$filz
    );

    diag "$heading:\n", explain \@resultz;

    wantarray
    ?  @resultz
    : \@resultz
};

unlink @$filz;

$exists->( 'Unlinked' );

ok ! -e , "No pre-existing: '$_'"
for @$filz;

my $count   = $madness->get_files;

ok 10 == $count, "Get files returns $count (10)";

diag "Processed: $count items";

my @pass1   = $exists->( 'Copied' );

ok $_->[1] , "Installed: '$_->[0]'"
for @pass1;

$madness->cleanup;

$exists->( 'Cleanup' );

# don't check $dirz on way out: there may be
# items not in $filz that keep them alive.

for( @$filz )
{
    if( -e )
    {
        fail "Removed: '$_'";
        diag "Failed cleanup: '$_'";
    }
    else
    {
        pass "Removed: '$_'";
    }
}

done_testing;
__END__
