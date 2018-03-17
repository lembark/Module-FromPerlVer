########################################################################
# housekeping
########################################################################

package Module::FromPerlVer::Util;
use 5.006;
use strict;

use Carp    qw( croak           );
use Cwd     qw( getcwd          );
use FindBin qw( $Bin            );
use Symbol  qw( qualify_to_ref  );

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

our $VERSION    = '0.001000';
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
    # 2 .. N avoids adding root dir's to the list.

    my @found
    = map
    {
        my $path    = catpath( $vol, catdir( @dirz ), $base );

        print "#  Test '$base': '$path'.\n"
        if $verbose;

        pop @dirz;

        -e $path
        ? $path
        : ()
    }
    ( 2 .. @dirz )
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
    search_dir $Bin => @_
}

sub find_libs
{
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
