use 5.008;
use lib qw( lib t/lib );

use Test::More;

my $madness = 'Module::FromPerlVer';

my @methodz
= qw
(
    perl_version
    source_prefix
    module_source
    source_files
    cleanup
    get_files
);

require_ok $madness
or BAIL_OUT "$madness is not usable.";

note "Require $madness: VERSION = " . $madness->VERSION;

ok ! $madness->can( $_ ), "No pre-existing '$_'"
for @methodz;

eval
{
    $madness->import( no_copy => 1 );

    pass "Survived import.";

    ok $madness->can( $_ ), "Import installs: '$_'"
    for @methodz;

    1
}
or
fail "Failed import: $@";

my $vers
= ref $^V
? $^V
: sprintf '%vd', $^V
;

$perl_v
= eval
{
    version->parse( $vers )->numify
}
or BAIL_OUT "Failed parse: '$vers', $@";

for
(
    [ perl_version  => $perl_v              ],
    [ source_prefix => 't/version'          ],
    [ module_source => 't/version/5.005003' ],
)
{
    my ( $method, $expect ) = @$_;

    my $found   = $madness->$method;

    ok $found == $expect, "$method: '$found' ($expect)";
}

done_testing;
__END__
