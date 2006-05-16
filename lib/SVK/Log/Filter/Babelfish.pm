package SVK::Log::Filter::Babelfish;

use strict;
use warnings;

use SVK::Log::Filter;
use WWW::Babelfish;

our $VERSION = '0.0.1';

sub setup {
    my ($self, $stash) = @_[SELF, STASH];

    # create a WWW::Babelfish object
    my $service = $ENV{BABELFISH_SERVICE} || 'Google';
    my $fish = WWW::Babelfish->new( service => $service );
    die "Can't create a babelfish using the '$service' service.\n"
        if !$fish;
    $stash->{babelfish_fish} = $fish;

    # determine the source and destination languages
    my ( $src_lang, $dest_lang ) = split /\s+/, $stash->{argument};
    ( $dest_lang, $src_lang ) = ( $src_lang, $dest_lang ) if !$dest_lang;
    $stash->{babelfish_source}
        = _lang_to_name( $fish, $src_lang ) || 'English';
    $stash->{babelfish_destination}
        = _lang_to_name( $fish, $dest_lang ) || 'English';

    return;
}

sub revision {
    my ($self, $props, $stash) = @_[SELF, PROPS, STASH];

    my $src_name  = $stash->{babelfish_source};
    my $dest_name = $stash->{babelfish_destination};
    my $text      = $props->{'svn:log'};

    my $fish = $stash->{babelfish_fish};
    my $new_svn_log = $fish->translate(
        source      => $src_name,
        destination => $dest_name,
        text        => $text,
    );

    die "Unable to translate from '$src_name' to '$dest_name': $text\n"
        if !$new_svn_log;

    $props->{'svn:log'} = $new_svn_log;

    return;
}

sub _lang_to_name {
    my ($fish, $lang_tag) = @_;

    return if !$lang_tag;
    my $pairs = $fish->languagepairs();

    while ( my ( $src_name, $dests ) = each %$pairs ) {
        while ( my ( $dest_name, $pair_tag ) = each %$dests ) {
            my ( $src_tag, $dest_tag ) = split /[_|]/, $pair_tag;
            return $src_name  if $lang_tag eq $src_tag;
            return $dest_name if $lang_tag eq $dest_tag;
        }
    }


    die "Unknown language tag '$lang_tag'\n";
    return;
}

1;

__END__

=head1 NAME

SVK::Log::Filter::Babelfish - translate log messages using online services

=head2 SYNOPSIS

    > svk log --filter 'babelfish de' //mirror/project/trunk
    ----------------------------------------------------------------------
    r1234 (orig r456):  author | 2006-05-15 09:28:52 -0600

    Dieses ist die Maschinenbordbuchanzeige für die Neuausgabe.
    ----------------------------------------------------------------------

=head1 DESCRIPTION

Uses L<WWW::Babelfish> to translate the log messages into a different
language.  All filters downstream from this one see log messages in the new
language.  Of course, there are no permanent changes to the revision
properties.

This filter takes two arguments indicating the source and destination
languages of the log messages.  The first argument is the two-letter ISO code for
the source language.  The second argument is the two-letter ISO code for the
destination language.  If only one argument is supplied, the source language
is assumed to be English.  Here are some examples

    > svk log --filter 'babelfish de'
    [English to German]
    > svk log --filter 'babelfish fr es'
    [French to Spanish]
    > svk log --filter 'babelfish es | babelfish es en'
    [English to English via Spanish]

=head1 STASH/PROPERTY MODIFICATIONS

Babelfish modifies the stash under the 'babelfish_' namespace.  It also
modifies the 'svn:log' property for each revision, replacing the original text
with the translated version.

=head1 BUGS

There is a problem with non-ASCII characters in the output.  I'm not sure if
this is my problem or something from WWW::Babelfish.

=head1 AUTHORS

Michael Hendricks E<lt>michael@palmcluster.orgE<gt>

=head1 COPYRIGHT

Copyright 2006 by Michael Hendricks E<lt>michael@palmcluster.orgE<gt>

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut
