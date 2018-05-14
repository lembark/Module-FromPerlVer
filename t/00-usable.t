use 5.006;
use strict;

use Test::More;

my $madness = 'Module::FromPerlVer';

require_ok $madness
or BAIL_OUT "$madness is not usable.";

use_ok $madness;

ok $madness->can( 'VERSION' ),  "$madness can 'VERSION'";
ok $madness->VERSION,           "$madness has a VERSION";

my @missing
= grep
{
    ! require_ok $_
}
qw
(
    lib
    strict
    version
    Archive::Tar
    File::Basename
    File::Find
    File::Spec::Functions
    File::Temp
    FindBin
    List::MoreUtils
    Symbol
    Test::Deep
    Test::More
    Cwd
    List::Util
    File::Copy::Recursive::Reduced
);

BAIL_OUT 'Missing modules: ' . join ' ' => @missing
if @missing;

done_testing;
__END__
