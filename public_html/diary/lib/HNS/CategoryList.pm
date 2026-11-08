package HNS::CategoryList;
# $Id: CategoryList.pm,v 1.9 2001/04/14 23:32:00 kenji Exp $
################################################################

=head1 NAME

HNS::CategoryList - カテゴリリストクラス


=cut

################################################################
use strict;
use HNS::DateSelect;
@HNS::CategoryList::ISA = qw(HNS::DateSelect);

use Image::Size;
use HNS::System;
use HNS::Template;
use HNS::Diary::Template;

__PACKAGE__->attributes(qw(year month day));

use vars qw(%DB $CatDir $TitleLabel $SubmitLabel 
		$Template $Template_no_img $Categorize);
use vars qw(%Template %Template_no_img);

=head1 STATIC VARIABLES

 $CatDir       カテゴリファイルディレクトリ
 $TitleLabel   タイトルラベル
 $SubmitLabel  サブミットラベル
 $Template
 $Template_no_img
 $Categorize

=cut

$CatDir = "cat";
$TitleLabel = "Title List";
$SubmitLabel = "Show!";
$Template = qq(<img src="%src" width="%width" height="%height" alt="">%value<br>\n);
$Template_no_img = qq(%value<br>\n);
$Categorize = "Categorize";

################################################################
sub initialize($)
{
    my $self = shift;
    $self->SUPER::initialize;
    $self->month_all(1);
    tie %DB, 'SimpleDB::Hash', "$CatDir/cat.txt";
#    print $DB{anime};
}

=head2 $c->AsHTML;

HTML 変換する

=cut


sub AsHTML($)
{
    my $self = shift;

    my $html = "$TitleLabel<br>\n" .
	qq(<form action="title_wrapper.cgi" method="get">\n);
    $html .= qq(<input name="CAT" type="checkbox" value="ALL">$Categorize<br>\n);

    my $templ = "HNS::Template"->new();
    for my $cat (sort keys %DB){
	next unless $cat;
	my $img = "$CatDir/$DB{$cat}";
	my ($w, $h) = imgsize($img);
	
	$html .= qq(<input name="CAT" type="checkbox" value="$cat">\n);
        if ($w eq undef) {
          $html .= $templ->Expand(SelectTemplate($Template_no_img,
						 %Template_no_img),
                                  {value=>$cat});
        }
        else {
	  $html .= $templ->Expand(SelectTemplate($Template, %Template),
		  		  {src=>$img,
				   width=>$w, height=>$h,
				   value=>$cat});
	}				 
    }
    $html .= $self->SUPER::AsHTML($self->year, $self->month, $self->day, $SubmitLabel);
    $html .= "</form>\n";
    return $html;
}


1;
