########################################################################
# housekeeping
########################################################################

package Module::FromPerlVer::Dir;
use 5.006;
use strict;
use version;
use parent  qw( Module::FromPerlVer::Extract );

use Carp                    qw( croak               );
use Cwd                     qw( cwd                 );
use File::Basename          qw( basename dirname    );
use File::Copy::Recursive   qw( dircopy             );
use File::Find              qw( find                );
use FindBin                 qw( $Bin                );
use List::Util              qw( first               );

use File::Spec::Functions
qw
(
    &splitpath
    &splitdir
    &catpath
    &catdir
);

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = version->parse( 'v0.1.0' )->numify;

our @CARP_NOT   = ( __PACKAGE__ );

########################################################################
# utility subs
########################################################################

my $search_bin
= sub
{
    my $base    = shift;

    my( $vol, $dir ) = splitpath $Bin, 1;

    for
    (
        my @dirz    = splitdir $dir
        ;
        @dirz > 1
        ;
        pop @dirz
    )
    {
        my $path    = catpath $vol, ( catdir @dirz ), $base;

        -e $path
        and return $path;
    }

    croak "Bogus source_prefix: no '$base' in or above '$Bin'";
};

########################################################################
# methods
########################################################################

sub source_prefix
{
    my $extract = shift;
    my $dir     = $extract->{ version_dir }
    or die "Bogus source_prefix: false 'version_dir'";

    # order of paths will prefer "./t/version" to 
    # "./version" during testing.

    my $path
    = -e $dir
    ? $dir
    : $search_bin->( $dir )
    or
    die "Botched source_prefix: non-existent '$dir' ($Bin).\n";

    # in any case, if we get this far the last stat was $path.
    # report any errors using the absolute path.

    -d _        or die "Bogus version_prefix: non-dir      '$path'\n";
    -r _        or die "Bogus version_prefix: non-readable '$path'\n";
    -x _        or die "Bogus version_prefix: non-execable '$path'\n";

    for my $cwd ( cwd )
    {
        # convert $path to relative for easier viewing.

        index $path, $cwd
        or 
        substr $path, 0, length( $cwd ), '.'
    }

    # belt and suspenders.

    -e $path
    or croak "Bogus source_prefix: mis-handled '$path' ($dir).";

    my @found   = glob "$path/*"
    or die "Bogus version_prefix: '$path' is empty directory.\n";

    # caller gets back the relpath to the version dir.
    # cache it for later use in this module.

    $extract->value( source_dir => $path )
}

sub module_sources 
{
    my $extract     = shift;
    my $version_d   = $extract->value( 'source_dir' );

    grep
    {
        -d 
    }
    glob "$version_d/*"
}

sub source_files
{
    my $extract     = shift;
    my $source_d    = $extract->value( 'module_source' );
    my $n           = length $source_d;
    my @pathz       = ( [], [] );

    find
    sub
    {
        my $path    = $File::Find::name;

        $path ne $source_d
        or return;

        my $rel     = '.' . substr $path, $n;

        my $i
        = -d $_
        ? 1
        : 0
        ;

        push @{ $pathz[ $i ] }, $rel;
    },
    $source_d;

    $extract->value( source_files => \@pathz );

    # deal with a set of empty dirs.

    @{ $pathz[0] }
    or warn "No input files found: '$source_d'";

    @pathz
}

sub get_files
{
    local $\    = "\n";
    my $extract = shift;

    my ( $filz, $dirz ) = @{ $extract->value( 'source_files' ) };
    my $path            = $extract->value( 'module_source' ); 
    my $found           = dircopy $path, '.';
    
    print "# Processed: $found files/dirs from '$path'";

    my $expect          = @$filz + @$dirz + 1;

    $found != $expect
    and
    print "# Oddity: mismatched count $found != $expect.";

    $found
}

# keep require happy
1
__END__
