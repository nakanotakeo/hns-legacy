package HNS::PIM::Todo;
# $Id: Todo.pm,v 1.10 2003/05/28 04:52:56 togawa Exp $
################################################################

=head1 NAME

HNS::PIM::Todo - Todo 管理クラス

=head1 SYNOPSIS

 my $todo = HNS::PIM::Todo->new(filename=>'diary/todo');
 $todo->Read;
 print $todo->AsHTML;


=cut

################################################################
use strict;
use ObjectTemplate;
use CodeConv;
@HNS::PIM::Todo::ISA = qw(ObjectTemplate);

use HNS::System;
use HNS::Template;
use HNS::Diary::Template;

__PACKAGE__->attributes(qw(contents));

use vars qw($MaxNum $ContentTemplate $BeginTemplate $EndTemplate);
use vars qw(%ContentTemplate %BeginTemplate %EndTemplate);

$MaxNum = 8;

# template
$ContentTemplate = "<li><strong>%priority</strong> %content</li>\n";
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
    my $filename = "$HNS::System::DiaryDir/todo";
    open(F, $filename) || return;
    while (<F>){
	next if /^$/;
	CodeConv::toeuc(\$_);
	/^(\d+)\s(.*)$/;
	push(@{$self->contents},
	     {priority=>sprintf("%02d",$1), content=>$2});
    }
    close F;
}

=head2 $t->AsHTML;

HTML変換して返す

=cut

sub AsHTML ($)
{
    my $self = shift;
    my $templ = HNS::Template->new();
    my $html .= SelectTemplate($BeginTemplate, %BeginTemplate);
    my $cnt;    

    for (sort {$b->{priority} <=> $a->{priority}} @{$self->contents}){
	last if ++$cnt > $MaxNum;
	$html .= $templ->Expand(SelectTemplate($ContentTemplate,
					       %ContentTemplate),
				{priority=>$_->{priority},
				 content=>$_->{content}});
    }
    $html .= SelectTemplate($EndTemplate, %EndTemplate);
}
	
1;
