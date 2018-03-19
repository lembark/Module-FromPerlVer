########################################################################
# housekeping
########################################################################

package Module::FromPerlVer::Util;
use 5.006;
use strict;
use version;

use Carp            qw( croak           );
use Cwd             qw( getcwd          );
use File::Basename  qw( dirname         );
use FindBin         qw( $Bin            );
use Symbol          qw( qualify_to_ref  );

use File::Spec::Functions
qw
(
    &splitpath
    &splitdir
    &catpath
    &catdir
);

require lib;

########################################################################
# package variables
########################################################################

our $VERSION    = version->parse( '0.3.0' )->numify;
our @CARP_NOT   = ( __PACKAGE__ );

my  $verbose     = $ENV{ VERBOSE_FROMPERLVER };

my @exportz
= qw
(
    search_dir
    search_bin
    search_cwd
    find_libs
);

########################################################################
# utility subs
########################################################################

########################################################################
# yanked from FindBin::libs.

sub search_dir
{
    my $from    = shift
    or croak "Bogus search_dir: false from dir";
    my $base    = shift
    or croak "Bogus search_dir: false basename";

    my( $vol, @dirz )
    = do
    {
        my ( $v, $d ) = splitpath $from, 1;

        ( $v => splitdir $d )
    };

    # find all of the paths below the root.
    # n-1 avoids adding root dir's to the list.

    my $n
    = '.' eq $dirz[0]
    ? @dirz
    : @dirz - 1
    ;

    my @found
    = map
    {
        my $path    = catpath( $vol, catdir( @dirz ), $base );

        print "#  Test '$base': '$path'."
        if $verbose;

        pop @dirz;

        -e $path
        ? $path
        : ()
    }
    ( 1 .. $n )
    or do
    {
        # normally the caller will warn if missing files.
        # use verbose to show alternates searched.

        warn "Not found: '$base' ($from)"
        if $verbose;

        return
    };

    print join "\n#\t" => "#  Found '$base':", @found
    if $verbose;

    wantarray
    ? @found
    : $found[0]
}

sub search_cwd
{
    search_dir getcwd(), @_
}

sub search_bin
{
    search_dir $Bin,     @_
}

sub search_for
{
    # this is normally used within Makefile.PL, at which point
    # search_bin and search_cwd yield the same result. tesing
    # may yield different results from ./t as $Bin: search it
    # first.

    my $base    = shift;

    # deal with the simplest case first.

    -e $base
    and return $base;

    # if bin is below cwd then only search
    # from bin through cwd.

    my $bin     = $Bin;
    my $cwd     = getcwd;

    my @dirz
    = do
    {
        if( $bin eq $cwd )
        {
            # this will normally be the case, e.g., "perl Makefile.PL"
            # will be using . for both.

            ( $bin )
        }
        elsif( index $bin, $cwd )
        {
            # bin isn't below cwd: search them both

            ( $bin, $cwd )
        }
        else
        {
            substr $bin, 0, length $cwd, '.';

            ( $bin )
        }
    };

    my $path    = '';

    for my $dir ( @dirz )
    {
        $path = search_dir $dir => $base
        and return $path;
    }

    return
}

sub find_libs
{
    # this will normally find ./t/lib & ./lib.

    my @dirz    = search_bin 'lib'
    or die "No libs found: '$Bin'\n";

    libs->import( @dirz );

    return
}

sub import
{
    shift;      # discard this package

    my $caller  = caller;

    for my $name ( @_ ? @_ : @exportz )
    {
        *{ qualify_to_ref $name, $caller }
        = __PACKAGE__->can( $name )
        or croak "Bogus Util: unknown '$name'";
    }
}

# keep require happy
1
__END__
