########################################################################
# housekeeping
########################################################################

package Module::FromPerlVer::Git;
use 5.008;
use strict;
use version;
use parent  qw( Module::FromPerlVer::Extract );

use Archive::Tar;

use Cwd                     qw( getcwd          );
use File::Basename          qw( basename        );
use File::Copy::Recursive::Reduced 0.002 qw(dircopy );
use FindBin                 qw( $Bin            );
use List::Util              qw( first           );
use Symbol                  qw( qualify_to_ref  );

use Module::FromPerlVer::Util
qw
(
    search_for
);

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = version->parse( 'v0.4.1' )->numify;
my $verbose     = $ENV{ VERBOSE_FROMPERLVER };

my $nil         = sub{};

# there is no consistent way to determine the location of git
# due to Windows not having a 'which' commnad. solution for
# now is ignoring the issue, letting the path do its work, and
# leaving 'git' without an absolute path.

my @checkout    = qw( git checkout  -f          );
my @clone       = qw( git clone     -n          );
my @restore     = qw( git checkout  --theirs    );

########################################################################
# utility subs
########################################################################

my @handlerz = 
(
    # simplest case first, to more complicated.
    # silently ignore anything that isn't found along the way.

    sub
    {
        search_for '.git'
    },

    sub
    {
        # lacking the tarball is fatal if the tarball is supplied.

        my $extract = shift;
        my $tball   = $extract->value( 'git_tarball' )
        or return;

        my $path    = search_for $tball
        or die "Missing: '$tball'";

        print "# Extract repo from: '$path'";

        for my $tar ( Archive::Tar->new )
        {
            $tar->extract_archive( $path )
            and last;

            my $error   = $tar->error;

            die "Failed extract: '$path'.\n$error\n"
        };

        # at this point the .git tarball should have been
        # extracted.

        -e '.git'
        or die "Botched extract_tarball: no './.git' in '$path'.\n";
    },

    sub
    {
        my $extract = shift;
        my $url     = $extract->value( 'git_repo_url' )
        or return;
        my $cmd     = join ' ' => @clone, $url;

        print STDERR "\n# Cloning from: '$url'\n";

        my $output  = qx{ $cmd };
        if( my $err  = $? )
        {
            die <<END

    Non-zero:   '$err'.
    Executing:  '$cmd'.
    Cloning:    '$url'."
    Output:

    $output

END
        }
        else
        {
            my $base    = basename $url, '.git';
            my $git     = "$base/.git";

            print STDERR "\n# Clone complete: '$base'\n";
            
            -e $git
            or die "Botched clone: missing '$git' ($url).\n";

            dircopy $git, '.';
        }

        # belt-and-suspenders: last chance to catch dircopy
        # failing with a specific message.

        -e '.git'
        or die "Botched clone_url: no './.git'.\n";
    },
);

########################################################################
# methods
########################################################################

sub source_prefix
{
    my $extract = shift;

    $extract->value( 'git_prefix' )
}

sub module_sources
{
    my $extract = shift;

    # whichever one returns indicates that there is a 
    # working .git directory.

    first
    {
        $extract->$_
    }
    @handlerz
    or
    die "Botched module_sources: no tarball, URL, or local .git.\n";

    # at this point expect a ./.git directory.

    my $prefix  = $extract->value( 'git_prefix' )
    or
    die "Botched module_sources: no 'git_prefix' available.\n";

    chomp
    (
        # "git tag --list" fails on some systems, use the
        # short version, see if that solves any of the
        # problems.

        my @tagz = qx{ git tag -l '$prefix*' }
    )
    or
    die "No tags like '$prefix*' found.\n";

    print join "\n#\t" => "#  Git tags: '$prefix*'", @tagz
    if $verbose;

    # at this point git should be able to checkout the
    # tag contents so get_files should work.

    @tagz
}

sub source_files
{
    # avoid returning true in scalar context.

    return
}

sub get_files
{
    my $extract = shift;
    my $tag     = $extract->value( 'module_source' );

    # deal with parsing this iff cleanup is called.

    chomp( my $curr = ( qx{ git branch } )[0] );

    print "# Saving: '$curr' for cleanup.";

    $extract->value( restore_branch => $curr );

    my $cmd
    = do
    {
        # no telling what the tag might look like.
        # quotes protect it from the shell.

        local $"    = ' ';
        
        "@checkout '$tag'"
    };

    my @output = qx{ $cmd 2>&1 };
    if( my $err = $? )
    {
        local $, = "\n#\t";

        chomp @output;

        print STDERR join "\n\t" => "Non-zero: $err ($cmd)", @output;

        die "Non-zero exit: $? from '$cmd'.\n";
    }
    else
    {
        print "# Checkout '$tag' complete.";
    }
}

sub cleanup
{
    my $extract = shift;
    my $branch  = $extract->value( 'restore_branch' );

    system @restore, "'$branch'"
    and
    do
    {
        local $, = ' ';
        warn "Non-zero exit: $? from @restore '$branch'";
    }
}

# keep require happy
1
__END__
