# $Id: DateSelect.pm,v 1.9 1999/11/23 15:56:27 tom Exp $
################################################################
package HNS::DateSelect;

=head1 NAME

HNS::DateSelect - 日付選択クラス


=cut

################################################################
use strict;
use ObjectTemplate;
@HNS::DateSelect::ISA = qw(ObjectTemplate);
@HNS::DateSelect::EXPORT = qw(attributes);

use HNS;
use HNS::Template;
use HNS::System;
use DateTime::Date;


=head1 MEMBER VARIABLES

 month_all
 start_year


=cut


__PACKAGE__->attributes(qw(month_all start_year));
################################################################
# configuration static variabes
#

=head1 MEMBER VARIABLES

 $YearTemplate
 $MonthTemplate
 $DayTemplate
 $AllLabel

=cut

use vars qw($YearTemplate $MonthTemplate $DayTemplate
	    $AllLabel);

$YearTemplate = "%year";
$MonthTemplate = "%month";
$DayTemplate = "%start_day 〜 %end_day";
$AllLabel = "ALL";

################################################################

=head2 $d->AsHTML($year, $month, $day, $SubmitLabel);

HTML 変換する

=cut

sub AsHTML ($;$$$)
{
    my ($self,  $year, $month, $day, $SubmitLabel) = @_;
    my $templ = "HNS::Template"->new();
    my $html;

    # year
    $html .= qq(\n<select name="YEAR">\n);
    for (reverse ($HNS::System::StartYear..$HNS::Status->start_time->year)){
	my $selected = (defined $year && $year == $_)? 'selected' : '';
	$html .= qq(<option value="$_" $selected>);
	$html .= $templ->Expand($YearTemplate, {year=>$_});
	$html .= qq(</option>\n);
    }
    $html .= qq(</select>\n);
    # month
    $html .= qq(<select name="MONTH">\n);
    for (1..12){
	$_ = sprintf("%02d", $_);
	my $selected = (defined $month && $month == $_)? 'selected' : '';
	$html .= qq(<option value="$_" $selected>);
	$html .= $templ->Expand($MonthTemplate, {month=>$_});
	$html .= qq(</option>\n);
    }
    $html .= qq(<option value="ALL">$AllLabel</option>\n)
	if $self->month_all;
    $html .= qq(</select>\n);
    # day
    $html .= qq(<select name="DAY">\n);
    for ('a', 'b', 'c'){
	my $start = {'a'=>1, 'b'=>11, 'c'=>21}->{$_};
	my $end = {'a'=>10, 'b'=>20, 'c'=>''}->{$_};
	my $selected = (defined $day && $day > $start &&
			($end eq '' || $day < $end)) ? 'selected' : '';
        $selected = "" if $self->month_all;
	$html .= qq(<option value="$_" $selected>);
	$html .= $templ->Expand($DayTemplate,
				{start_day=>$start,
				 end_day=>$end});
	$html .= qq(</option>\n);
    }
    my $selected = "selected" if $self->month_all;
    $html .= qq(<option value="ALL" $selected>$AllLabel</option>\n);
    $html .= qq(</select>\n);
    # submit
    $html .= qq(<input type="submit" value="$SubmitLabel">\n);
#    $html .= qq(</form><hr>);
    return $html;
}    

1;

