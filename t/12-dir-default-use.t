use 5.006;
use version;
use lib qw( lib t/lib );

use Test::More;

my $madness = 'Module::FromPerlVer';

use_ok $madness => qw( use_dir 1 )
or BAIL_OUT "$madness is not usable.";

my $filz    = $madness->source_files;

ok -e , "Installed: '$_'"
for @$filz;

$madness->cleanup;

ok ! -e , "Removed file: '$_'"
for @$filz;

done_testing;
__END__
