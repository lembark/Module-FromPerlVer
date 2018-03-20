########################################################################
# housekeeping
########################################################################

package Module::FromPerlVer::Extract;
use 5.006;
use version;

use NEXT;

use Carp            qw( croak   );
use Scalar::Util    qw( blessed );

########################################################################
# package variables
########################################################################

our $VERSION    = version->parse( '0.1' )->numify;

########################################################################
# methods
########################################################################

sub value
{
    my ( $extract, $k, ) = splice @_, 0, 2;

    $k
    or croak "Bogus value: false key";

    if( @_ )
    {
        my $v   = shift;

        defined $v
        ? $extract->{ $k } = $v
        : delete $extract->{ $k }
    }
    else
    {
        $extract->{ $k }
    }
}

sub init
{
    my $extract = shift;

    if
    (
        my $argz
        = @_ > 1 ? { @_ }   # flat list -> hash
        : @_ > 0 ? shift    # hashref
        : ''                # nada
    )
    {
        while( my($k,$v) = each %$argz )
        {
            $extract->value( $k => $v )
        }
    }

    return
}

sub construct
{
    my $proto   = shift;

    bless +{}, blessed $proto || $proto
}

sub new
{
    my $extract = &construct;

    $extract->EVERY::LAST::init( @_ );
    $extract
}

# keep require happy
1
__END__

=head1 NAME

Module::FromPerlVer::Extract - common methods for extractors.

=head1 SYNOPSIS

    # see also Module::FromPerlVer::Extract for 
    # valid arguments.
    #
    # the purpose of this module is keeping new
    # and friends out of M::PFV.

    my $type    = 'Dir';    # or 'Git'

    my $class   = qualify $type, 'Module::FromPerlVer';

    # call construct then dispatch EVERY::LAST::init.

    my $extract = $class->new( $argz );

    # acquire, store, delete a value stored in
    # the extractor.

    my $value   = $extract->value( 'foobar' );

    my $new_val = $extract->value( foobar => $value );
    my $old_val = $extract->value( foobar => undef  );

=head1 LICENSE

This code is licensed under the same terms as Perl-5.26 or any
later released version of Perl.

=head1 COPYRIGHT

Copyright 2018, Steven Lembark, all rights reserved.

=head1 AUTHOR

Steven Lembark <lembark@wrkhors.com>

