use 5.006;
use version;

use Test::More;

my $madness = 'Module::FromPerlVer';

use_ok $madness => qw( use_dir 1 no_copy 1 )
or BAIL_OUT "$madness is not usable.";

my $filz    = $madness->source_files;

note "Source files:\n", explain $filz;

ok ! -e , "No pre-existing: '$_'"
for @$filz;

my $count   = $madness->get_files;

ok 10 == $count, "Get files returns $count (10)";

ok -e , "Installed: '$_'"
for @$filz;

$madness->cleanup;

ok ! -e , "Removed file: '$_'"
for @$filz;

ok ! -d , "Removed dir: '$_'"
for qw( etc pod );

done_testing;
__END__
