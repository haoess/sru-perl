package SRU::Utils::XML;
#ABSTRACT: XML utility functions for SRU

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT_OK = qw( element elementNoEscape escape stylesheet );

=head1 SYNOPSIS

    use SRU::Utils::XML qw( escape );
    return escape( $text );

=head1 DESCRIPTION

This is a set of utility functions for use with XML data.

=head1 METHODS

=head2 element( $tag, $text )

Creates an xml element named C<$tag> containing escaped data (C<$text>).

=cut

sub element {
    my ($ns, $tag, $text) = @_;
    return '' if ! defined $text;
    return "<$ns:$tag>" . escape($text) . "</$ns:$tag>";
}

=head2 elementNoEscape( $tag, $text )

Similar to C<element>, except that C<$text> is not escaped.

=cut

sub elementNoEscape {
    my ($ns, $tag, $text) = @_;
    return '' if ! defined $text;
    return "<$ns:$tag>$text</$ns:$tag>";
}

=head2 escape( $text )

Does minimal escaping on C<$text>.

=cut

sub escape {
    my $text = shift || '';
    $text =~ s/</&lt;/g;
    $text =~ s/>/&gt;/g;
    $text =~ s/&/&amp;/g;
    return $text;
}

=head2 stylesheet( $uri )

A shortcut method to create an xml-stylesheet declaration.

=cut

sub stylesheet {
    my $uri = shift;
    return qq(<?xml-stylesheet type='text/xsl' href="$uri" ?>);
}

1;
