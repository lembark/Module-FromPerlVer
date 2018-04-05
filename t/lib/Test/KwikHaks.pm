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
use List::Util          qw( pairmap             );
use List::MoreUtils     qw( zip uniq            );
use Symbol              qw( qualify_to_ref      );

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

my $err_fh  = *STDERR{ IO };
my $out_fh  = *STDOUT{ IO };

my $output_fh
= $verbose
? $err_fh
: $out_fh
;

########################################################################
# exported utilities
########################################################################

sub format
{
    if( @_ > 1 )
    {
        my $head    = shift;

        join "\n#  " => "# $head:", @_
    }
    elsif( @_ )
    {
        "# $_[0]";
    }
    else
    {
        '';
    }
}

sub output
{
    local $\    = "\n";

    my $output  = &format;

    print $output_fh $output;

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

        output( "Test $base: '$path'." );

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
    [ tball_path    => 'sandbox/git.tar'    ],
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

sub sandbox_tmpdir
{
    my $tball   = tball_path();
    my $sand_d  = sandbox_path();
    my $tmpl    = basename $0 . '-XXXX';

    # alive at this point => paths are usable.

    my $sand_tmp
    = tempdir
    (
        $tmpl =>
        DIR     => $sand_d,
        CLEANUP => 1,
    )
    or die "Failed create tmpdir: $!.\n";


    output 'Workdir: ' . basename $sand_tmp;
    output "Extract: '$tball'";

    chdir $sand_tmp
    or die "Failed chdir: '$sand_tmp', $!";

    Archive::Tar->extract_archive( $tball );

    $sand_tmp
}

sub lib_tmpdir
{
    my $sand_d  = sandbox_path();
    my $tmpl    = basename $0 . '-XXXX';

    # alive at this point => paths are usable.

    my $work_tmp
    = tempdir
    (
        $tmpl =>
        DIR     => $sand_d,
        CLEANUP => 1,
    )
    or die "Failed create tmpdir: $!.\n";

    output "Work dir: '$work_tmp'";

    $work_tmp
}

sub git_sanity
{
    my $cmd = join ' ' => 'git', @_;

    chomp( my @output = qx{ $cmd 2>&1 } );

    if( $? )
    {
        error "Non-zero exit: '$cmd'", @output;
        die "$cmd, $?\n";
    }
    elsif( @output )
    {
        output "$cmd", @output;
    }
    else
    {
        output "Zero exit, empty output from '$cmd'.";
        return
    }

    scalar @output
}

sub verify_git_env
{
    eval
    {
        test_git_version
    }
    or die "Git not available ($@)\n";

    my $sandbox 
    = eval
    {
        sandbox_tmpdir
    }
    or do
    {
        error "No tempdir: $@";
        return
    };

    eval
    {
        # checkout can reasonably get no output;
        # tag and status must return something.

        git_sanity qw( tag -l           ) or die "No tags.\n";
        git_sanity qw( checkout HEAD    );
        git_sanity qw( status .         ) or die "No status.\n";
    }
    or do
    {
        error $@;
        return
    };

    # survival idicates success.
    # caller gets back the test-specific sandbox dir.

    $sandbox
}

sub verify_git_branch
{
$DB::single = 1;

    my ( $prefix, $perl_v )  = @_;

    chomp( my $found = ( qx{ git branch } )[0] );

    0 <= index( $found, $prefix ),
    or
    die "No prefix: '$prefix' in '$found'.\n";

    my $v_rx    = qr{ $prefix (v?[\d._]+) \b }x;

    my ( $tag_v ) = $found =~ $v_rx
    or die "No verion: '$found'\n";

    my $i   = version->parse( $tag_v  )->numify;
    my $j   = version->parse( $perl_v )->numify;

    output "Tag ($i) <=> Perl ($j)";

    $i <= $j
    or die "Invalid tag version: '$i' > '$j'";

    $tag_v
}

1
__END__
