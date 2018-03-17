########################################################################
# housekeeping
########################################################################

package Test::KwikHaks;
use v5.006;
use strict;
use version;

use File::Basename  qw( basename    );
use File::Temp      qw( tempfile    );
use FindBin         qw( $Bin        );

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

sub perl_v_from_basename
{
    my $base    = basename $0, '.t';
    my $i       = rindex $base, '-';

    my $perl_v  = substr $base, ++$i
    or die "Botched test: no perl version in '$base'.\n";

    version->parse( $perl_v )
    or die "Botched test: invalid perl version '$perl_v' ($base).\n";

    print "# Testing perl version: '$perl_v' ($base).\n";

    wantarray
    ? ( $base, $perl_v )
    : $perl_v
}

sub test_git_version
{
    chomp( my $git = qx( git --version ) );

    die "Non-zero exit from git: '$?'.\n"
    if $?;

    print "# git version: '$git'.\n";

    1
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

        print "# Test $base: '$path'.\n";

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

1
__END__
