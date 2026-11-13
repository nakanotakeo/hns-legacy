package HNS::Calendar::Table;
# $Id: Table.pm,v 1.20 2002/11/03 05:09:58 kenji Exp $
################################################################

=head1 NAME

HNS::Calendar::Table - class of calender with html table tag

=head1 SYNOPSIS

  my $cal = HNS::Calendar::Table->new(year=>$y, month=>$m, col=>$col);
  print $cal->AsHTML;

=cut

################################################################

use strict;
use ObjectTemplate;
use vars qw(@ISA $TableBorder @WeekString $NextTemplate $PrevTemplate
	    $ThisTemplate $DayCurrentTemplate $DayNonCurrentTemplate);
use vars qw(%NextTemplate %PrevTemplate %ThisTemplate
	    %DayCurrentTemplate %DayNonCurrentTemplate);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template
@ISA = qw(ObjectTemplate HNS::Diary::Template);

__PACKAGE__->attributes(qw());

use Time::Local;
use DateTime::Date;
use HNS::Collection;
use HNS::Template;
use HNS::System;
use HNS::Diary::Template;
use CGI::Tools;

################################################################
$TableBorder = 0;
@WeekString = ('<font color="red">Sun</font>', 'Mon', 'Tue', 'Wed', 'Thu',
        'Fri', '<font color="blue">Sat</font>');
$TableBorder = 0;
$NextTemplate = qq(<a href="$HNS::System::MyDiaryURI?%year%month">Next</a>);
$PrevTemplate = qq(<a href="$HNS::System::MyDiaryURI?%year%month">Prev</a>);
$ThisTemplate = qq(<a href="$HNS::System::MyDiaryURI?%year%month">%year/%month</a>);
$DayCurrentTemplate = qq(<a href="%ruri#%{ymd}0">%calendar_day</a>);
$DayNonCurrentTemplate = qq(<a href="%href">%calendar_day</a>);
$HrefTemplate = "%base#%name";
$NameTemplate = "%{ymd}0";

################################################################
sub AsHTML ($$$$)
{
    my ($self, $year, $month, $col, $cat_arg) = @_;
    ($year, $month) = (sprintf("%04d", $year), sprintf("%02d", $month));
    my $html;
    my $templ = "HNS::Template"->new();
    
    # table start
    $html .= qq(<table border="$TableBorder" summary="calendar">\n);
    # month
    my $date = "DateTime::Date"->new(year=>$year, month=>$month, day=>1);
    $html .= "<tr>\n";
    # prev
    $html .= qq( <th colspan="2" align="left">);
    if ($HNS::System::StrictCalendarLink) {
      my $prev = ref $col->prev;
      if ($prev) {
        $html .= $templ->Expand(SelectTemplate($PrevTemplate, %PrevTemplate),
			    {year=>$col->prev->year,
			     month=>sprintf("%02d", $col->prev->month), cat=>$cat_arg});
      }
    }
    else {
	$date -= '1M';
	$html .= $templ->Expand(SelectTemplate($PrevTemplate, %PrevTemplate),
			    {year=>$date->year,
			     month=>sprintf("%02d", $date->month), cat=>$cat_arg});
	$date += '1M';
    }
    $html .= "</th>\n";
    # this month
    $html .= qq( <th colspan="3" align="center">);
    $html .= $templ->Expand(SelectTemplate($ThisTemplate, %ThisTemplate),
			    {year=>$date->year,
			     month=>sprintf("%02d", $date->month), cat=>$cat_arg});
    $html .= "</th>\n";
    # next
    $html .= qq( <th colspan="2" align="right">);
    if ($HNS::System::StrictCalendarLink) {
      my $next = ref $col->next;
      if ($next) {
        $html .= $templ->Expand(SelectTemplate($NextTemplate, %NextTemplate),
			    {year=>$col->next->year,
			     month=>sprintf("%02d", $col->next->month), cat=>$cat_arg});
      }
    }
    else {
	$date += '1M';
	$html .= $templ->Expand(SelectTemplate($NextTemplate, %NextTemplate),
			    {year=>$date->year,
			     month=>sprintf("%02d", $date->month), cat=>$cat_arg});
	$date -= '1M';
    }
    $html .= "</th>\n";
    # week
    $html .= "</tr>\n<tr>\n";
    for (0..6){
	$html .= " <th align=\"center\">" .
#	    $DateTime::Date::WeekString{uc($WeekStringType)}->[$_] .
	    $WeekString[$_] .
		"</th>\n";
    }
    # day
    # null space
    my $start_week = $date->week;
    if ($start_week){
        $html .= "</tr>\n<tr>\n";
    }
    my $day = 1;
    for my $i (1..$start_week){
	$html .= " <td></td>";
    }
    $html .= "\n";
    # 1..31
    for my $calendar_day (1..$date->DaysMonth){
	my $day = sprintf("%02d", $calendar_day);
	if (($calendar_day+$start_week)%7-1 == 0){
           $html .= qq(</tr>\n<tr>\n);
	}
	$html .= qq( <td align="right">);
	my $ymd = sprintf("%04d%02d%02d", $year, $month, $calendar_day);
	if ($col->diarys->{$ymd}){
	    my $high = int($calendar_day/10);
	    my $abc;
	    if ($calendar_day < 11) {
		$abc = "a";
	    }
	    elsif ($calendar_day < 21) {
		$abc = "b";
	    }
	    else {
		$abc = "c";
	    }
	    if ($col->diarys->{$ymd}->read_done){
#		$html .= sprintf($DayCurrentTemplate,
#				 $ENV{'REQUEST_URI'}, 
#				 $year, $month, $day, $day);
		# fix Cross Site Scripting bug	
		my $ruri = CGI::Tools::Escape($ENV{'REQUEST_URI'});
		$html .= $templ->Expand(SelectTemplate($DayCurrentTemplate,
						       %DayCurrentTemplate),
				{ruri=>$ruri, year=>$year,
				 month=>$month, day=>$day, ymd=>$ymd,
				 calendar_day=>$calendar_day});
	    } else {
#		$html .= sprintf($DayNonCurrentTemplate,
#				 $year, $month, $high,
#				 $year, $month, $day, $day);
		my $params = {year=>$year, month=>$month, high=>$high,
			      abc=>$abc, day=>$day, ymd=>$ymd, calendar_day=>$calendar_day};
		$self->ExpandTempl($templ, $params);
		$html .= $templ->Expand($DayNonCurrentTemplate, $params);
	    }
	} else {
	    $html .= qq($calendar_day);
	}
	$html .= qq(</td>\n);
    }
    $html .= qq(</tr>\n</table>);
}
1;

