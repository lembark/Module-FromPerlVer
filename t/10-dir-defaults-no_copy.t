use 5.006;
use version;

use Test::More;

my $madness = 'Module::FromPerlVer';

use_ok $madness => qw( no_copy 1 )
or BAIL_OUT "$madness is not usable.";

my $filz    = $madness->source_files;

unlink @$filz;

ok ! -e , "No pre-existing: '$_'"
for @$filz;

my $count   = $madness->get_files;

diag "Processed: $count items";

ok 10 == $count, "Get files returns $count (10)";

my @found
= map
{
    [ $_ => -e ]
}
@$filz;

diag "Found:\n",   explain \@found;

ok $_->[1] , "Installed: '$_'"
for @found;

$madness->cleanup;

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
