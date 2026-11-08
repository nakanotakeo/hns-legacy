package HNS::PIM::Link;
# $Id: Link.pm,v 1.3 2003/05/28 04:52:55 togawa Exp $
################################################################
####仕様####
#diary/linkに
#優先順位 URL ページ名
#と記述する。
#これによりTodoと似たようにする。
#出力は
#<ul>
#<li><a href="URL">ページ名</a>
#<li><a href="http://www.yahoo.co.jp/">yahoo!JAPAN</a>
#…
#</ul>
################################################################
=head1 NAME

HNS::PIM::Link - Link集定義

=head1 SYNOPSIS

 my $link = new HNS::PIM::Link(filename=>'diary/link');
 $link->Read;
 print $link->AsHTML;


=cut

################################################################
use strict;
use ObjectTemplate;
use CodeConv;
@HNS::PIM::Link::ISA = qw(ObjectTemplate);

use HNS::System;
use HNS::Template;
use HNS::Diary::Template;

attributes qw(contents);

use vars qw($MaxNum $ContentTemplate $BeginTemplate $EndTemplate);
use vars qw(%ContentTemplate %BeginTemplate %EndTemplate);

#元は
#$MaxNum = 8:
$MaxNum = 8;

# template
#$ContentTemplate = "<li><strong>%priority</strong> %content</li>\n";
$ContentTemplate = "<li><a href=\"%e_url\">%content</a></li>\n";
$BeginTemplate = "<ul>";
$EndTemplate = "</ul>";

sub initialize($)
{
    my $self = shift;
    $self->contents([]);
}
################################################################

=head2 $t->Read;

データファイルを読み込む

=cut

sub Read ($)
{
    my $self = shift;
    my $filename = "$HNS::System::DiaryDir/link";
    open(F, $filename) || return;
    while (<F>){
#JISコード対策かも。
	next if /^$/;
	CodeConv::toeuc(\$_);
#先頭に数字が一回以上 空白 なんかの文字 末尾
#	/^(\d+)\s(.*)$/;
#	/^(\d+)\s(.*)\s(.*)$/;
	/^(\d+)\s(\S+)\s(.*)$/;
#	@{$self->contents} = split('/\s/', $self->contents);
	push(@{$self->contents},
	     {priority=>sprintf("%02d",$1), e_url=>$2, content=>$3});
#	     {priority=>sprintf("%02d",$1), content=>$2});
    }
    close F;
}

=head2 $t->AsHTML;

HTML変換して返す

=cut

sub AsHTML ($)
{
    my $self = shift;
    my $templ = new HNS::Template;
    my $html .= SelectTemplate($BeginTemplate, %BeginTemplate);
    my $cnt;    

    for (sort {$b->{priority} <=> $a->{priority}} @{$self->contents}){
	last if ++$cnt > $MaxNum;
	$html .= $templ->Expand(SelectTemplate($ContentTemplate,
					       %ContentTemplate),
				{priority=>$_->{priority},
				 e_url=>$_->{e_url},
				 content=>$_->{content}});
    }
    $html .= SelectTemplate($EndTemplate, %EndTemplate);
}
	
1;
