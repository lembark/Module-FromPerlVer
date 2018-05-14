########################################################################
# housekeeping
########################################################################

package Test::KwikHaks;
use v5.008;
use strict;
use version;

use Archive::Tar;

use Cwd                 qw( getcwd              );
use File::Basename      qw( basename            );
use File::Find          qw( finddepth           );
use File::Temp          qw( tempfile tempdir    );
use FindBin             qw( $Bin                );
use List::Util          qw( pairmap uniq        );
use List::MoreUtils     qw( zip                 );
use Symbol              qw( qualify_to_ref      );

use File::Spec::Functions
qw
(
    &splitpath
    &splitdir
    &catpath
    &catdir
    &abs2rel
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

my $err_fh  = *STDERR{ IO };
my $out_fh  = *STDOUT{ IO };

my $output_fh
= $verbose
? $err_fh
: $out_fh
;

#mkdir_if( search_bin( 't' ),  'sandbox' );

########################################################################
# exported utilities
########################################################################

sub format
{
    if( @_ > 1 )
    {
        my $head    = shift;

        join "\n#  " => '', "$head:", @_
    }
    elsif( @_ )
    {
        "\n# $_[0]";
    }
    else
    {
        '';
    }
}

sub output
{
    my $output  = &format;

    print $output_fh $output;
    print "\n";

    return
}

sub blank_line
{
    print $err_fh "\n";
}

sub error
{
    local $\    = "\n";

    my $output  = &format;

    print STDERR $output;

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

        output( "Search: '$base' ($path)" );

        return $path
    }
    continue
    {
        pop @dirz;
    }

    return
}

for
(
    [ sandbox_path  => 'sandbox'            ],
    [ version_path  => 'version'            ],
)
{
    my ( $name, $rel_path ) = @$_;

    *{ qualify_to_ref $name }
    = sub
    {
        search_bin  $rel_path
        or die "Failed search_bin: '$rel_path' ($Bin)"
    };
}

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
            = tempfile 
            (
                'perl_version.XXXX' =>
                DIR     => sandbox_path(),
                UNLINK  => 1,
            )
        )
        {
            print $fh "$use $perl_v;\n"
            or die "Failed print: '$path', $!\n";

            close $fh
            or die "Failed close: '$path', $!\n";

            abs2rel $path, getcwd
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

#    output( "mkdir_if: '$path'" );

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

    # cartesian product of formats and versions

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

sub work_dir
{
    # put all of the scratch dir's under a single sandbox
    # filesystem to simplify cleanup.

    my $t_d     = search_bin 't';
    my $sand_d  = mkdir_if $t_d, 'sandbox';
    my $tmpl    = basename $0 . '-XXXX';
    my $cwd     = getcwd;

    my $work_tmp
    = tempdir
    (
        $tmpl =>
        DIR     => $sand_d,
        CLEANUP => 1,
    )
    or die "Failed create tmpdir: $!.\n";

    index $work_tmp, $cwd
    or
    $work_tmp   = abs2rel $work_tmp, $cwd;

    # alive at this point => paths are usable.

    output "Work dir: '$work_tmp'";

    $work_tmp
}

1
__END__
