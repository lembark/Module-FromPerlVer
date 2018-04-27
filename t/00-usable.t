use 5.006;
use strict;

use Test::More;

my $madness = 'Module::FromPerlVer';

require_ok $madness
or BAIL_OUT "$madness is not usable.";

use_ok $madness;

ok $madness->can( 'VERSION' ),  "$madness can 'VERSION'";
ok $madness->VERSION,           "$madness has a VERSION";

done_testing;
__END__
