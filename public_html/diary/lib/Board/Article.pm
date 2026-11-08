package Board::Article;
################################################################
# Board::Article

# 2002/01/27 Yoichi Imai <yoichi@silver-forest.com>

# Copyright (C) 2002 Yoichi Imai <yoichi@silver-forest.com>

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

# $Id: Article.pm,v 1.8 2002/04/05 15:35:41 bonaim Exp $
################################################################

=head1 NAME

Board::Article - Board記事のクラス

=head1 SYNOPSIS

 my $article = new Board::Article($delete_key, $msgid, $refid, $ref_diary, $time, $title, $name, $mail, $site, $addr, $body)
 # or my $article = new Board::Article
 # Perl版ではnewに渡す$timeは数値限定

=head1 DESCRIPTION
Boardの記事1つを示すクラス。

=cut

################################################################

use strict;
use ObjectTemplate;
use Exporter;
use DateTime::Format;
use vars qw(@ISA @EXPORT);
@ISA = qw(ObjectTemplate);
@EXPORT = qw(attributes);

__PACKAGE__->attributes(qw(delete_key msgid refid ref_diary ruri_code time title name mail site addr body));

sub Set
{
    my ($self, $delete_key, $msgid, $refid, $ref_diary, $ruri_code, $time, $title, $name, $mail, $site, $addr, $body) = @_;
    $self->delete_key($delete_key);
    $self->msgid($msgid);
    $self->refid($refid);
    $self->ref_diary($ref_diary);
    $self->ruri_code($ruri_code);
    $self->time($time);
    $self->title($title);
    $self->name($name);
    $self->mail($mail);
    $self->site($site);
    $self->addr($addr);
    $self->body($body);
}
sub GetTimeStr
{
    my ($self) = shift;

    return strftime('%Y/%m/%d %H:%M', localtime($self->time));
}

sub Delete
{
    my ($self) = shift;
    $self->delete_key('');
    $self->body('');
    $self->ruri_code('');
    $self->time('');
    $self->title('');
    $self->name('');
    $self->mail('');
    $self->site('');
    $self->addr('');
    $self->body('');
}

sub IsDeletable
{
    my ($self) = shift;

    return ($self->delete_key ne $Board::UnDeletableKey);
}

sub IsRoot
{
    my ($self) = shift;

    return ($self->refid eq 'root');
}

sub IsFakeRoot
{
    my ($self) = shift;
 
    return ($self->refid eq 'root' && $self->ref_diary ne '');
}
sub IsFresh
{
    my ($self) = shift;

    return 0 unless $Board::RecentTime; # always aged
    return ($self->time > time() - $Board::RecentTime);
}

sub Print($$$)
{
    my ($self, $msgid_hash, $refid_hash) = @_;

    print '<div class="article">', "\n";

    if ($self->delete_key eq '') {
	print "This message was deleted<br>\n";
	print '</div>', "\n";
	return;
    } 

    if($self->IsFakeRoot()) {
	print '<h3>', $self->title, "</h3>\n";
    } else {
	my ($from);

	print '<div>';
	print '<a href="board.cgi?act=write&amp;refid=',
	$self->msgid,
	'">コメントをつける</a>',
	' / <a href="board.cgi?act=delete&amp;msgid=',
	$self->msgid,
	'">削除する</a></div>', "\n";

	print '<div class="header">', "\n";
	print 'Subject: ', $self->title, "<br>\n";
	print 'Date: ', $self->GetTimeStr(), "<br>\n";

	print 'From: ';
	if ($self->mail eq '') {
	    print $self->name;
	} else {
	    print $self->name, ' &lt;', $self->mail, '&gt;';
	}
	print "<br>\n";

	print 'X-URL: <a href="', $self->site, '">', $self->site, "</a><br>\n" if (($self->site) && !($self->site =~ /^http:\/\/$/));

	print "</div>\n";
	print '<p>', $self->body, "</p>\n";
    }
    if (defined($msgid_hash) && defined($refid_hash)) {
	print '<div class="msglinks">', "\n";
	
	if (!($self->IsRoot()) && $msgid_hash->{$self->refid}) {
	    print '<dl><dt>References:</dt>', "\n";
	    print '<dd>';
	    print $msgid_hash->{$self->refid}->GetSubject(0,1);
	    print '</dd></dl>', "\n";
	}
	
	if ($refid_hash->{$self->msgid}) {
	    print '<dl><dt>Follow-Ups:</dt>', "\n";
	    foreach my $article (@{$refid_hash->{$self->msgid}}) {
		print '<dd>';
		print $article->GetSubject(0,1);
		print "</dd>\n";
	    }
	    print "</dl>\n";
	}
	
	print "</div>\n";
    }
    print "</div>\n";
}
sub GetSubject($$)
{
    my ($self, $thr_mode, $show_newmark) = @_;
    my $str = '';
    $str = '<span class="tlink"><a href="board.cgi?act=read&amp;thr=on&amp;msgid=' . $self->msgid . '">[+]</a></span> ' if ($self->IsRoot() && $thr_mode);

    if ($self->IsFakeRoot()) {
	# FIXME: this process should be removed.
	my ($abc) = ('a','b','c','c')[int((substr($self->ref_diary,6,2)-1)/10)]; # FIXME: this should be removed.
	$str .= '<span class="dlink">' .
	        '<a href="' .
		$Board::HnsPath .
		'?' . substr($self->ref_diary,0,6) . $abc . # FIXME
		'&to=' .
		$self->ref_diary . '#' . $self->ref_diary .
		'">' .
		$self->title . '</a></span>';
    } elsif ($self->delete_key eq '') {
	$str .= '[[[Deleted]]]';
    } else {
	$str .= '<span class="subject">' .
	       '<a href="board.cgi?act=read&amp;msgid=' . $self->msgid . '">' .
	       $self->title . '</a>' .
	    '</span>' .
	    '<span class="poster"> by ' . $self->name . '</span>' .
	    '<span class="date">&nbsp;&nbsp;&nbsp;&nbsp;' .
	    $self->GetTimeStr();
	$str .= '<span class="newmark"> [NEW!]</span>' if ($self->IsFresh() && $show_newmark);
	$str .= '</span>';
    }
    return $str;
}

sub GetStr
{
    my $self = shift;
    return join("\t", 
		$self->delete_key,
		$self->msgid,
		$self->refid,
		$self->ref_diary,
		$self->ruri_code,
		$self->time,
		$self->title,
		$self->name,
		$self->mail,
		$self->site,
		$self->addr,
		$self->body) . "\n";
}
1;
