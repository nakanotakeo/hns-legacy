package HNS::Calendar::NoTable;
# $Id: NoTable.pm,v 1.18 2002/11/03 05:09:57 kenji Exp $
################################################################


=head1 NAME

HNS::Calendar::NoTable;

=head1 SYNOPSIS

  my $cal = HNS::Calendar::NoTable->new(year=>$y, month=>$m, col=>$col);
  print $cal->AsHTML;


=cut

use strict;
use ObjectTemplate;
@HNS::Calendar::NoTable::ISA = qw(ObjectTemplate HNS::Diary::Template);

__PACKAGE__->attributes(qw());

use Time::Local;
use DateTime::Date;
use HNS::Collection;
use HNS::Template;
use HNS::Diary::Template;
use CGI::Tools;

# template
use vars qw($NextTemplate $PrevTemplate $ThisTemplate 
		$DayCurrentTemplate $DayNonCurrentTemplate);
use vars qw(%NextTemplate %PrevTemplate %ThisTemplate
	    %DayCurrentTemplate %DayNonCurrentTemplate);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template

$NextTemplate = qq(<a href="?%year%month">Next</a>);
$PrevTemplate = qq(<a href="?%year%month">Prev</a>);
$ThisTemplate = qq(<a href="?%year%month">%year/%month</a>);
$DayCurrentTemplate = qq(<a href="%ruri#%{ymd}0">%calendar_day</a>);
$DayNonCurrentTemplate = qq(<a href="./?%year%month%high#%{ymd}0">%calendar_day</a>);
$HrefTemplate = "%base#%name";
$NameTemplate = "%{ymd}0";

################################################################
sub AsHTML ($)
{
    my ($self, $year, $month, $col, $cat_arg) = @_;
    ($year, $month) = (sprintf("%04d", $year), sprintf("%02d", $month));

    my $html;
    my $templ = HNS::Template->new();
    
    # month
    my $date = DateTime::Date->new(year=>$year, month=>$month, day=>1);
    $html .= "\n";
    $html .= $templ->Expand(SelectTemplate($ThisTemplate, %ThisTemplate),
			    {year=>$date->year,
			     month=>sprintf("%02d", $date->month), cat=>$cat_arg});
    $html .= "\n";
    # day
    my $start_week = $date->week;
    # 1..31
    for my $calendar_day (1..$date->DaysMonth){
	my $day = sprintf("%02d", $calendar_day);
	my $w = ($day+$start_week-1)%7;

	my $ymd = sprintf("%04d%02d%02d", $year, $month, $calendar_day);
	if ($w == 0){
	    $html .= " | \n";
	}
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
		# fix Cross Site Scripting bug
		my $ruri = CGI::Tools::Escape($ENV{'REQUEST_URI'});
                $html .= $templ->Expand(SelectTemplate($DayCurrentTemplate,
						       %DayCurrentTemplate),
                                {ruri=>$ruri, year=>$year,
                                 month=>$month, day=>$day, ymd=>$ymd,
				 calendar_day=>$calendar_day});
            } else {
		my $params = {year=>$year, month=>$month, high=>$high,
			      abc=>$abc, day=>$day, ymd=>$ymd, calendar_day=>$calendar_day};
		$self->ExpandTempl($templ, $params);
		$html .= $templ->Expand($DayNonCurrentTemplate, $params);
            }
	    $html .= " ";
	} else {
	    $html .= " $calendar_day ";
	}
    }
    $html .= " | \n";
    # prev
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
        $html .= $templ->Expand(SelectTemplate($PrevTemplate, %PrevTemplate),                            {year=>$date->year,
                             month=>sprintf("%02d", $date->month), cat=>$cat_arg});
        $date += '1M';
    }
    # next
    $html .= " ";
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
        $html .= $templ->Expand(SelectTemplate($NextTemplate, %NextTemplate),                            {year=>$date->year,
                             month=>sprintf("%02d", $date->month), cat=>$cat_arg});
        $date -= '1M';
    } 
    $html .= "<br>";
    return $html;
}
1;

