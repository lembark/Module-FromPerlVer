########################################################################
# housekeeping
########################################################################

package Test::KwikHaks;
use v5.006;
use strict;
use version;

use File::Basename      qw( basename    );
use File::Find          qw( finddepth   );
use File::Temp          qw( tempfile    );
use FindBin             qw( $Bin        );
use List::Util          qw( pairmap     );
use List::MoreUtils     qw( zip uniq    );

use File::Spec::Functions
qw
(
    &splitpath
    &splitdir
    &catpath
    &catdir
);

########################################################################
# package variables
########################################################################

our $VERSION    = version->parse( '0.4.0' )->numify;
my $verbose     = 1; #$ENV{ VERBOSE_FROMPERLVER };

my $wanted
= sub
{
    '.' eq $_
    or
    -d $_
    ? rmdir     || warn "Failed rmdir: '$_', $!"
    : unlink    || warn "Failed unlink: '$_', $!"
    ;
};

my $output_fh
= $verbose
? *STDERR{ IO }
: *STDOUT{ IO }
;

########################################################################
# exported utilities
########################################################################

sub output
{
    local $\    = "\n";

    if( @_ > 1 )
    {
        my $head    = shift;

        print $output_fh join "\n#  " => "# $head:", @_
    }
    elsif( @_ )
    {
        print $output_fh "# $_[0]";
    }
    else
    {
        print $output_fh '';
    }

    return
}

sub perl_v_from_basename
{
    local $\    = "\n";
    my $base    = basename $0, '.t';
    my $i       = rindex $base, '-';

    my $perl_v  = substr $base, ++$i
    or die "Botched test: no perl version in '$base'.\n";

    version->parse( $perl_v )
    or die "Botched test: invalid perl version '$perl_v' ($base).\n";

    output( "Testing perl version: '$perl_v' ($base)." );

    wantarray
    ? ( $base, $perl_v )
    : $perl_v
}

sub test_git_version
{
    local $\    = "\n";
    chomp( my $git = qx( git --version ) );

    die "Non-zero exit from git: '$?'.\n"
    if $?;

    die "Empty return from 'git --version'\n"
    unless $git;

    output( "git version: '$git'." );

    $git
}

sub search_bin
{
    # find only the first basename up the path from $Bin.

    my $base    = shift;

    my( $vol, $dir ) = splitpath $Bin, 1;

    my @dirz    = splitdir $dir;

    while( @dirz > 1 )
    {
        my $path    = catpath( $vol, catdir( @dirz ), $base );

        -e $path
        or next;

        output( "Test $base: '$path'." );

        return $path
    }
    continue
    {
        pop @dirz
    }

    return
}

sub sandbox_path    { search_bin 'sandbox'          }
sub version_path    { search_bin 'version'          }
sub git_path        { search_bin 'sandbox/.git'     }
sub tball_path      { search_bin 'sandbox/.git.tar' }

sub write_version_file
{
    my $perl_v  = shift;
    my $use     = shift || 'use';
    
    # avoid using this with the version file.

    delete $ENV{ PERL_VERSION };

    eval
    {
        if
        (
            my ( $fh, $path ) 
            = tempfile 'perl_version.XXXX'
        )
        {
            print $fh "$use $perl_v;\n"
            or die "Failed print: '$path', $!\n";

            close $fh
            or die "Failed close: '$path', $!\n";

            $path
        }
        else
        {
            die "Failed 'tempfile', $!\n";
        }
    }
    or do
    {
        warn "Failed write version file: $@";

        ''
    }
}

sub mkdir_if
{
    my $path = catdir @_;

    output( "mkdir_if: '$path'" );

    -d $path            ? output( "Existing: '$path'." )
    : mkdir $path, 0777 ? output( "Created:  '$path'." )
    : die "Failed mkdir: '$path', $!.\n"
    ;

    # no telling what umask or other things are doing to
    # the stats. just set it outright here.

    chmod 0770, $path
    or die "Failed chmod: '$path', $!.\n";

    $path
}

sub rm_rf
{
    finddepth $wanted, $_
    for @_;

    -d && rmdir
    for @_;
}

sub generate_versions
{
    my @versionz 
    = qw
    (
        5.0.1
        5.6.0
        5.8.8
        5.888.888
        5.999.999
    );

    my @formatz
    = qw
    (
        %d.%d.%d
        %d.%03d%03d
        %d.%03d.%03d
        %d.%03d_%03d
    );

    # lexical sort works.

    my @v_stringz
    = uniq
    sort
    map
    {
        (
            $_, "v$_"
        )
    }
    pairmap
    {
        sprintf $a => @$b
    }
    map
    {
        my @v   = ( [ split /\W/ ] ) x @formatz;

        zip @formatz, @v
    }
    @versionz;

    wantarray
    ?  @v_stringz
    : \@v_stringz
}

1
__END__
