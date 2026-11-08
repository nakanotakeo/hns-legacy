package Board;
################################################################
# Board

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

# $Id: Board.pm,v 1.9 2002/04/05 15:36:39 bonaim Exp $
################################################################

use strict;
use Board::System;
use vars qw($UseBoard $UnDeletableKey $ThreadsPerPage $MaxArticle $BoardData $HnsPath $RecentView $RecentTime $ReadStr $SepStr $WriteStr $LinkStr $HeadStr $Version $FieldMaxLen $URLMaxLen $BodyMaxLen $CSSFile $Title $RecentTime $BoardOnHNS $BodyLenOnHNS $HideReadLinkWhenNoMsg);

$Version = "0.1.1";

$UseBoard = 0;

$UnDeletableKey = 'undeletable';
$HnsPath = './index.cgi';
$BoardData = 'boarddata.txt';

$ThreadsPerPage = 5;
$MaxArticle = 100;
$RecentView = 10;
$FieldMaxLen = 100;
$URLMaxLen = 150;
$BodyMaxLen = 2000;

$RecentTime = 2 * 24 * 60 * 60;

$ReadStr = 'Read More... (%num)';
$SepStr = '|';
$WriteStr = 'Post message...';
$LinkStr = '<div class="boardlink" align="right">( %readstr %sepstr %writestr )</div>';

$HeadStr = '<h4 class="comment">Comments related this article</h4>';

# 0 => disabled
# 10 => non-body part
# 20 => non-body & body(truncated or not)
$BoardOnHNS = 20;
# 0 is unlimited.
# if not 0, <br> will be removed.
# this number contains tags' length.
$BodyLenOnHNS = 80;

# if there is no comment for the article, 
# the option hides %readstr and %sepstr.
$HideReadLinkWhenNoMsg = 1;

$CSSFile = '';
$Title = 'Board';

my %CommentByArticle;
my %ArticleNum;
my $read_done = 0;

sub read_boarddata()
{
  return unless $UseBoard;

  return if $read_done;

  my $board = new Board::System;
  $board->LoadLightly();
  foreach my $article (@{$board->article_list}) {
      my $diary = $article->ref_diary;
      next unless $diary;
      $CommentByArticle{$diary} = [] unless $CommentByArticle{$diary};
      $ArticleNum{$diary}++;
      push(@{$CommentByArticle{$diary}}, $article);
  }

  $read_done = 1;
}

sub truncate_body($)
{
    my $body = shift;
    my $is_continue = 0;

    return $body if ($BodyLenOnHNS == 0);

    $body =~ s/<br>/ /g;

    $body = substr($body, 0, $BodyLenOnHNS);
    $is_continue = 1 if (length($body) == $BodyLenOnHNS);
    # $body should be euc-jp
    # remove splitted kanji
    $body =~ s/\x8F.?$//; # remove JIS X 0212
    $body =~ s/.$// if ($body =~ tr/\x8E\xA1-\xFE// % 2); # remove JIS X 0201 and JIS X 0208

    # remove splitted tags
    $body =~ s/\&\w*$//g;

    $body .= "..." if $is_continue;

    return $body;
}

sub get_commentstr($)
{
    return "" unless $UseBoard;
    return "" unless $BoardOnHNS;
    my $daydata = shift;

    my @list;
    my $str;

    return "" unless ($CommentByArticle{$daydata});

    $str = $HeadStr . "\n";
    @list = @{$CommentByArticle{$daydata}};

    if ($BoardOnHNS == 10) {
	$str .= qq(<ul class="comments">\n);
	foreach my $article (@list) {
	    $str .= q(<li>);
	    $str .= $article->GetSubject(0,0);
	    $str .= qq(</li>\n);
	}
	$str .= qq(</ul>\n);
    } elsif ($BoardOnHNS == 20) {
	$str .= qq(<dl class="comments">\n);
	foreach my $article (@list) {
	    $str .= q(<dt>);
	    $str .= $article->GetSubject(0,0);
	    $str .= qq(</dt>\n<dd>);
	    $str .= truncate_body($article->body);
	    $str .= qq(</dd>\n);
	}
	$str .= qq(</dl>\n);
    }
    return $str;
}
sub get_linkstr($)
{
  return "" unless $UseBoard;

  my ($daydata) = shift;
  my $num = $ArticleNum{$daydata};
#  my $num = $#{$CommentByArticle{$daydata}}+1;
  my $readstr = $ReadStr;
  my $sepstr = $SepStr;
  my $writestr = $WriteStr;
  my $linkstr = $LinkStr;

  # readstr
  $num = 0 if ($num eq '');
  $readstr =~ s/%num/$num/g;
  if ($num != 0) {
    $readstr = qq(<a href="board.cgi?act=diary&amp;diary=${daydata}">) . $readstr . '</a>';
  } elsif ($num == 0 && $HideReadLinkWhenNoMsg) {
      $readstr = '';
      $sepstr = '';
  }
  # writestr
  $writestr = qq(<a href="board.cgi?act=write&amp;diary=${daydata}">) . $writestr . '</a>';

  # linkstr
  $linkstr =~ s/%readstr/$readstr/g;
  $linkstr =~ s/%sepstr/$sepstr/g;
  $linkstr =~ s/%writestr/$writestr/g;

  return $linkstr;
}

1;
