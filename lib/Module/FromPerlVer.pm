########################################################################
# housekeeping
########################################################################

# Use the lowest-version of Perl that supports
# File::Copy::Recursive & friends -- yeah, ancient.

package Module::FromPerlVer;
use 5.006;
use strict;
use version;

use Cwd                     qw( getcwd          );
use File::Basename          qw( basename        );
use File::Copy::Recursive   qw( dircopy         );
use File::Find              qw( find            );
use File::Spec::Functions   qw( &catpath        );
use FindBin                 qw( $Bin            );
use List::Util              qw( first reduce    );
use Symbol                  qw( qualify_to_ref  );

use File::Spec::Functions
qw
(
    &abs2rel
    &rel2abs

    &catdir
    &catpath
    &splitpath
);

########################################################################
# package variables & sanity checks
########################################################################

our $VERSION    = '0.0.1';

my $default_d   = 'version';

my $cwd         = getcwd;

########################################################################
# utility subs
########################################################################

my @handlerz = 
(
    sub
    {
        # set running perl version.

        my $argz    = shift;
        my $path    = $argz->{ version_from } || '';
        my $perl_v  = '';

        if( my $value = $ENV{ PERL_VERSION } )
        {
            warn "Overriding '$path' with PERL_VERSION='$value'.\n"
            if $path;

            $perl_v = version->parse( $value )->numify
            or
            die "Botched version_from: invalid '$value' from PERL_VERSION.\n";
        }
        elsif( $path )
        {
            -e $path or die "Bogus version_from: non-existant '$path'\n";
            -f _     or die "Bogus version_from: non-file     '$path'\n";
            -s _     or die "Bogus version_from: zero-size    '$path'\n";
            -r _     or die "Bogus version_from: non-readable '$path'\n";

            # at this point the version file seems minimally usable.

            my $found
            = do
            {
                open my $fh, '<', $path
                or
                die "Botched version_from: open '$path', $!\n";

                first
                {
                    if
                    (
                        my ( $min_v )
                        = m{ \b use \s+ (v?5[.][\d_]*)}x
                    )
                    {
                        $perl_v 
                        = version->parse( $min_v )->numify
                        or 
                        die "Invalid version string: '$_' ($path)"
                    }
                    elsif
                    (
                        my ( $max_v ) 
                        = m{ \b no  \s+ (v?5[.][\d_]*)}x
                    )
                    {
                        $perl_v
                        = version->parse( $max_v )->numify - 0.000001
                        or 
                        die "Invalid version string: no '$_' ($path)"
                    }
                    else
                    {
                        ''
                    }
                }
                grep
                {
                    /\S/
                }
                readline $fh
                or
                die "Bogus version_from: '$path' lacks 'use version'.\n";
            };
        }
        else
        {
            # this *should* to be parseable.

            $perl_v = version->parse( $^V )->numify
            or
            die "Severe weirdness: unparsable \$^V ($^V).\n";

        }

        # belt & suspenders time

        $perl_v
        or die "Broken perl_version: no version extracted.";

        *{ qualify_to_ref 'perl_version' }
        = sub 
        {
            $perl_v
        };

        print "# Perl version: '$perl_v'\n";

        return
    },

    sub
    {
        # exract version parent directory

        my $argz    = shift;
        my $vers_d  = $argz->{ version_dir } || $default_d;

        my ( $vol, $dir )   = splitpath $vers_d, 1;

        # $Bin/$dir simplifies testing by locating './t/version'
        # for anything running in ./t using only the default.

        my $path
        = first
        {
            -d
        }
        map
        {
            my $d   = catdir $_, $dir;

            catpath $vol, $d, ''
        }
        (
            '',
            $cwd,
            $Bin,
        )
        or
        die "Bogus version_dir: Non-existant: '$dir'.\n";

        # first, above, guarantees that this is the last
        # dir examined. make the final sanity checks.

        -r _        or die "Bogus version_dir: non-readable '$path'";
        -w _        or die "Bogus version_dir: non-writeable '$path'";
        -x _        or die "Bogus version_dir: non-execable '$path'";

        index $path, $cwd
        or
        $path   = abs2rel $path, $cwd;

        my @found   = glob "$path/*"
        or die "Botchd version_dir: '$path' is empty directory.\n";

        *{ qualify_to_ref 'version_dir' }
        = sub { $path };

        print "# Version directory: '$path'\n";

        return
    },

    sub
    {
        # locate source dir supporting perl version.

        my $perl_v      = perl_version();
        my $version_d   = version_dir();

        # klutzy as this looks it beats a sort on $_->[0]
        # followed by first.

        my $found
        = reduce
        {
            # i.e., from any dir with version <= perl_v
            # prefer the one with the highest verison.
            # equality handles differences in version 
            # format colliding on a single numified value.

            $perl_v < $b->[0]
            ? $a
            : $a->[0] >= $b->[0]
            ? $a
            : $b
        }
        (
            # sentinel allows evaluating all version dir's
            # for <= $perl_v.

            [ 0, '' ],
            map
            {
                my $dir_v   
                = eval
                {
                    version->parse( basename $_ )->numify
                }
                or warn "Unusable version dir: '$_', not parsable.\n";

                $dir_v
                ? [ $dir_v, $_ ]
                : ()
            }
            glob "$version_d/*"
        );

        $found->[0]
        or 
        die "Failed version dir: all '$version_d' > $perl_v\n";

        my $source_d    = $found->[ -1 ];

        *{ qualify_to_ref 'source_dir' }
        = sub
        {
            $source_d
        };

        print "# Source directory:  '$source_d'\n";

        return
    },

    sub
    {
        # set the destination directory.

        my $argz    = shift;
        my $dest_d  = $argz->{ dest_dir } || $cwd;

        -e $dest_d  or die "Botched dest_dir: non-existant '$dest_d'";
        -d _        or die "Botched dest_dir: non-directory '$dest_d'";
        -r _        or die "Botched dest_dir: non-readable '$dest_d'";
        -w _        or die "Botched dest_dir: non-writeable '$dest_d'";

        index $dest_d, $cwd
        or
        $dest_d     = abs2rel $dest_d, $cwd;

        # looks minimally usable...

        *{ qualify_to_ref 'dest_dir' }
        = sub
        {
            $dest_d
        };

        print "# Dest dir: '$dest_d'.\n";

        return
    },

    sub 
    {
        # locate files to copy
        #
        # pre-assigning the hashref's simplifies dealing
        # with a collection of empty dir's.

        my $source_d    = source_dir();
        my @pathz       = ( [], [] );

        my $n           = length $source_d;

        find
        sub
        {
            my $path    = $File::Find::name;

            $path eq $source_d
            and return;

            my $is_dir  
            = -d 
            ? 1
            : 0
            ;

            my ( $vol, $dir, $base )
            = splitpath $path, $is_dir;

            my $sub_d   = abs2rel $dir, $source_d;

            push @{ $pathz[ $is_dir ] }, catpath $vol, $sub_d, $base;
        },
        $source_d;

        # deal with a set of empty dirs.

        @{ $pathz[0] }
        or warn "No input files found: '$source_d'";

        *{ qualify_to_ref 'source_paths' }
        = sub
        {
            wantarray
            ? @pathz
            : $pathz[0]
        };

        local $,    = "\n#\t";
        print '# Source files:', @{ $pathz[0] }, "\n";

        return
    },

    sub
    {
        my ( $dst_v, $dst_d )   = splitpath dest_dir(), 1;
        my ( $filz, $dirz   )   = source_paths();

        my @dst_filz
        = map
        {
            my ( undef, $src_d, $base ) = splitpath $_;

            catpath $dst_v, catdir( $dst_d, $src_d ), $base;
        }
        @$filz;

        my @dst_dirz
        = map
        {
            my ( undef, $dir, undef ) = splitpath $_, 1;

            catpath $dst_v, catdir( $dst_d, $dir ), '';
        }
        @$dirz;

        for( @dst_filz, @dst_dirz )
        {
            index $_, $cwd
            and
            $_  = abs2rel $_, $cwd
        }

        *{ qualify_to_ref 'dest_paths' }
        = sub
        {

            wantarray
            ? ( \@dst_filz, \@dst_dirz )
            :   \@dst_filz
        };
    },

    sub
    {
        *{ qualify_to_ref 'cleanup' }
        = sub
        {
            my ( $filz, $dirz ) = dest_paths();

            unlink @$filz;

            -e $_ && warn "Failed removal: '$_'"
            for @$filz;

            # i.e., don't clobber dir's which have any
            # files we didn't copy in them. this is most
            # likely for ./t which can have common tests.

            for my $dir ( @$dirz )
            {
                ( my @a = glob "$dir/*" )
                or 
                rmdir $dir;
            }
        };

        return
    },

    sub
    {
        my ( $filz, $dirz ) = source_paths();
        my $dest_d          = dest_dir();
        my $expect  = 1 + @$filz + @$dirz;

        *{ qualify_to_ref 'copy_source_dir' }
        = sub
        {
            my $src     = source_dir();
            my $dst     = dest_dir();
            my $found   = dircopy $src, $dst;
            
            print "# Copied: $found files from '$src'\n";

            $found != $expect
            and
            warn "# Oddity: mismatched count $found != $expect.\n";

            $found
        };

        print "# Expect: $expect files to be copied.\n";

        return
    }
);

########################################################################
# import is where it all happens
########################################################################

sub import
{
    my ( undef, %argz ) = @_;

    for my $sub ( @handlerz )
    {
        $sub->( \%argz );
    }

    # at this point the args are consumed and if we are 
    # still alive the copy function has been installed.
    #
    # caller can use cleanup() to remove files copied or 
    # source_paths() to get a list of them.
    #
    # this returns the count from File::Copy::Recursive,
    # which should be true if anything was found to copy.

    $argz{ no_copy }
    or
    copy_source_dir()
}

# keep require happy
1
__END__

=head1 NAME

Module::FromPerlVer - install modules compatible with the running perl.

=head1 SYNOPSIS

    # Aside: unless anyone can find a glaring omission in 
    # the mechanism or utility sub selection this will
    # become version v1.0.

    # ./version directory has sub-dirs with basenames of 
    # parsable perl version strings.
    # 
    # when this module is used the highest numbered version
    # directory compatile with the running perl is copied 
    # into the execution directory of Makefile.PL.
    #
    # source_paths() is useful for describing what gets
    # copied, cleanup() is handy for iterating tests or
    # prior to making a bundle.

    # Makefile.PL

    use Module::FromPerlVer;

    # relative paths to files copied for this version of 
    # perl -- different versions of perl may have different
    # collections of files copied.

    my $copied_files    = Module::FromPerlVer->source_paths;

    # remove the files copied and any empty direcories they
    # were copied into (dir's with pre-copy files left in
    # them are untouched).

    my $removed_count   = Module::FromPerlVer->cleanup;

    # at this point lib, t, and friends are populated with 
    # modules compatible with the running perl. because 
    # the destination directory is $Bin this can include 
    # README, MANIFEST, or Changes files. note that 
    # overwriting  Makefile.PL will *not* work since it 
    # has already been compiled.

    # override the perl version:

    # this can be useful for regression testing earlier 
    # versions of modules against the running version 
    # (e.g., validating experimental features).

    $ PERL_VERSION='5.024002' perl Makefile.PL;

    # use a file to determine the perl version.
    # this takes the use-ed version from the file
    # to set the expected perl version (e.g., to 
    # validate if other modules are suitable).

    use Module::FromPerlVer   qw( version_from ./lib/foobar.pm );

    # or a one-line datafile.
    # "use vX.Y.Z" will find up to that version, "no vX.Y.Z" will 
    # use up to that version minus '0.000001'.
    #
    # perl versions with use or no support any version
    # string avaiable (see "version" module).
    # 
    # say that v5.24.2 breaks your module:

    echo 'no v5.24.2' > ./perl-version;

    use Module::FromPerlVer   qw( version_from perl-version );

    # override the source directory:

    # maybe you don't like the name 'version', you
    # prefer "history" instead.

    use Module::FromPerlVer   qw( version_dir history );

    # set up everything but skip making the copy.
    #
    # this reqires callig "copy_source_dir" to get the 
    # versioned files in their proper place.
    #
    # none of the utility subs take any arguments and
    # can all be called using module or object notation.

    use Module::FromPerlVer   qw( no_copy 1 );


    my ( $filz, $dirz ) = Module::FromPerlVer::source_paths;

    Module::FromPerlVer->copy_source_dir;

    my $madness = 'Module::FromPerlVer';

    $madness->cleanup;



=head1 DESCRIPTION 

Basic idea: Divide up the source space for a module distro
by supporting Perl version. At that point when you want to 
start using features in a new version of Perl just start a
new directory and work with it. When you release the module
distro the module's version compatible with the running 
perl will be selected at install time. No tests in the module
for $^V are necessary.

=head2 Using the module

Using this module requires two things: The module and a local
filesysem labeled by compatible Perl version.

=over 4

=item Version Directory

The default directory for module versions is "version". This 
has sub-directories that are parseable as Perl versions:

    ./version/5.005_003  
    ./version/5.006001
    ./version/5.16
    ./version/v5.24

in each case the basename of the directory is processed by
version::parse.

The filesystem under each version is whatever dir's and 
files are suitable for that version of perl. Common 
examples are README, MANIFEST, Changes, ./lib, ./t,
./bin.

=item Basic Use

Using the module in setup code (e.g., Makefile.PL):

    use Module::FromPerlVer

will look in the ./version directory, sort the subdir's 
in numerically decreasing order by version (see version)
and finds the highest version directory that is
less than or equal to the running perl's version. The 
contents of this directory are copied to the same directory
as the running code.

Versions derived from "use" will be less than equal to that
version, versions derived from "no" will be less than or 
equal to the version minus 0.000001.

=item Supplying the Perl Version

It may be useful in testing to choose a specific subdirectory
(e.g., regression testing older code with newer perl executables,
or testing the module itself). 

Each of these will be passed to version::parse for final 
validation. If version cannot parse the value then the code
will die with a "Bogus perl_version:..." error showing the 
version string being parsed.

In order of priority the Perl version used to select the 
module's compatible directory are:

=over 4

=item $ENV{ PERL_VERSION }

Any true value of  will be used. If this is supplied with
the "version_from" argument a warning will be issued and
the environment variable will be used. Note that "Cat"
"Dog" and "I don't know" are all true, but useless and 
will cause the code to croak.

One use of this is testing the current module with multple
versions of perl:

    #!/bin/bash

    for perl in /opt/perl5/5*/bin/perl
    do
        for i in version/*
        do
            # pick the appropriate module 
            # version from whatever is running.

            perl Makefile.PL    && 
            make all test       ;
        done
    done

or testing all the available module versions with a 
specific version of perl:
    
    #!/bin/bash

    perl='/opt/bin/perl-5.24.1';

    for i in ./version/*
    do
        PERL_VERSION="$(basename $i)"   \
        $perl Makefile.PL               &&
        make all test                   ;
    done

=item use Module::FromPerlVer ( version_from => $path );

The path will be scanned for "use <version string>" and the first
one located will be processed. The file can be a module, executable,
or flat file with one line in it, so long as "use" followed by a
parsable version string is found Life is Good.

The main use of this is validating multiple versions of perl 
with a specific release of the module.

=item Overriding "version".

Say you hate the name version:

    use Module::FromPerlVer qw( version_dir history );

=item Skipping the Copy

If you prefer to call copy_source_dir yourself (e.g., after
cleanup or pre-configuring some other part of the 
environment) use:

    use Module::FromPerlVer qw( no_copy 1 );

This will install all of the utility subs (see "Utility Subs"
below) but will not execute copy_source_dir().

=back

=back

=head2 Utility Subs

A few utility sub's are installed into Module::FromPerlVer 
when it is used. These are used internally to drive the 
file copy process and can be used to supply the values used
to build the module filesytem.

None of these take any arguments: they cannot be used to 
re-set the values determined at import time.

None of them are exported, they can be called usig either 
package or object notation:

    Module::FromPerlVer::copy_source_dir;   # package::subname

    Module::FromPerlVer->cleanup;           # class->method
    $module_name->cleanup;

None of them exist until import() is called: requiring 
Module::FromPerlVer will not install any of them.

The only one that is likely useful outside of the module 
itself are copy_files() and cleanup() which can be called
from Perl code for repeated testing (e.g., bash that iterates
perl versions).

=over 4

=item Calling convention.

All of these ignore any arguments, they can be 
called as class methods or via fully-qualified 
paths with the identical effect:

    Module::FromPerlVer::foobar();
    Module::FromPerlVer->foobar();

=item perl_version()

Returns the parsed, numified Perl version value (see 
version module).

=item version_dir()

Returns the basename of the version directory
(i.e., default 'version').

=item source_dir()

The subdir from which the files are sourced. This will be a
relative path from $FindBin::Bin, including the version 
directory:

    ./version/5.006001
    ./version/v5.24.2

=item source_paths()

Used in a scalar context this returns an arrayref of relative
paths to files copied from the source_dir into the working 
directory by copy_files().

Used in a list context it returns two arrayrefs: one of the 
files one of the directories. The former is used with unlink
in cleanup to remove only the files that were copied; the 
latter is used to rmdir empty directories.

=item dest_dir()

Note: Used mainly for testing.

Returns the dest_dir used to copy source_paths.

It mainly allows parallel testing without the tests overwriting one 
another's output. Might also be useful to install files in a blib 
directory during testing.

=item dest_paths()

Note: Used mainly for testing.

Returns the source_paths() with the destination directory
prefixed. In the default case this will map "./version/X/lib/foo.pm"
to "./lib/foo.pm". If the dest_dir is, say, a tempdir then the
dest paths will look like "./sandbox/10-frobnicate-asdf/lib/foo.pm".

=item copy_source_dir()

This executes the copy of all source files into '.'.

Note: If import is called with "no_copy" and a true
value then this will have to be called, see examples
for calling convention, above.

=item cleanup()

This first executes an unlink the files, then walks the 
dir's executing rmdir on the empty ones.

This approach allows for some files to be re-used across 
multiple releases without getting clobbered by cleanup.
Likely examples are common tests (i.e., t/*.t) or a MANIFEST
for modules which have all of the same files in each version.

=back

=back

=head1 SEE ALSO

=over 4

=item version

This does the parsing of version numbers from code and 
dirs. The POD incudes examples of both parsing and sorting
Perl versions.

=item File::Copy::Recursive

Describes how the files are copied.

=back

=head1 LICENSE

This code is licensed under the same terms as Perl-5.26 or any
later released version of Perl the user preferrs.

=head1 COPYRIGHT

Copyright 2018, Steven Lembark, all rights reserved.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

