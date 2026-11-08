# $Id: Tools.pm,v 1.5 2002/02/02 09:57:03 bonaim Exp $
package CGI::Tools;

=head1 NAME

  CGI::Tools - CGI ツール群

=cut

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(Escape);



=head2 Escape($str);

$str をエスケープする

=cut

sub Escape($)
{
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/\"/&quot;/g;
    $str;
}

=head2 URIEscape($str);

$str をURLエスケープする

=cut

sub URIEscape($)
{
    my $str = shift;
    $str =~ s/(\W)/'%' . unpack('H2', $1)/eg;
    $str;
}

=head2 URIUnEscape($str);

$str をURLアンエスケープする

=cut

sub URIUnEscape($)
{
    my $str = shift;
    $str =~ s/%([0-9A-Fa-f][0-9A-Fa-f])/pack('H2', $1)/eg;
    $str;
}

1;
################################################################
