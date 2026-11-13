package HNS::Style;
# $Id: Style.pm,v 1.18 2002/11/03 05:09:57 kenji Exp $
################################################################


=head1 NAME

HNS::Style

=head1 SYNOPSIS

 my $style = HNS::Style->new();
 $style->Print($col, $is_no_table_browser); # $mode : 'RECENT' or not

=cut

################################################################
use strict vars;
use ObjectTemplate;
use vars qw(@ISA $UnagiTemplate $NoUnagiTemplate
	    %Templates $UnagiUse $UnagiURL $NamazuURL
	    $CalendarUse $DirectCalendarUse $PIMUse $TitleListUse);
use vars qw(%UnagiTemplate %NoUnagiTemplate);
@ISA = qw(ObjectTemplate);

use HNS::System;
use HNS::Calendar::Direct;
use HNS::PIM::Schedule;
use HNS::PIM::Todo;
use HNS::PIM::Link;
use HNS::Template;
use HNS::CategoryList;
use HNS::Diary::Template;
use CGI::QueryString;

__PACKAGE__->attributes(qw(col
	      pim_html calendar_html unagi_html direct_html category_html));

################################################################
# unagi
$UnagiUse = "ON";
$UnagiURL = "namazu.cgi";
$NamazuURL = "http://www.namazu.org/";

# flag
$CalendarUse = "ON";
$DirectCalendarUse = "ON";
$PIMUse = "ON";
$TitleListUse = "ON";

# template
$Templates{Table}->{pim} = qq(
<hr>
<table summary="pim" width="100%">
<tr>
 <th align="left">Í½Äê</th>
 <th align="left">TODO</th>
 <th align="left">Link</th>
</tr>
<tr>
 <td valign="top">
 %schedule
 </td>
 <td valign="top">
 %todo
 </td>
 <td valign="top">
 %link
 </td>
</tr>
</table>
);

$Templates{Table}->{head_style} = qq(
%pim
<hr>
<table summary="calendar">
<tr>
<td rowspan="2" valign="top">
%calendar
</td>
<td valign="top">
%unagi
</td>
</tr>
<tr>
<td valign="bottom">
%direct_calendar
</td>
</tr>
</table>
<hr>
);

$Templates{Table}->{foot_style} = "\n<hr>\n%category_list";

$Templates{Table}->{head_recent_style} = $Templates{Table}->{head_style};
$Templates{Table}->{foot_recent_style} = $Templates{Table}->{foot_style};


# template for no table browser
$Templates{NoTable} = {
    pim => qq(<hr>\n%schedule %todo),
    head_style => qq(%pim\n<hr>\n%unagi\n<hr>\n%calendar
                      %direct_calendar\n<hr>\n),
    foot_style=> "<hr>\n%category_list"
    };

$Templates{NoTable}->{head_recent_style} = $Templates{NoTable}->{head_style};
$Templates{NoTable}->{foot_recent_style} = $Templates{NoTable}->{foot_style};


# example for customize
$Templates{Mozilla} = {
    pim=> qq(Mozila %schedule %todo),
    style=> qq(Mozilla %pim %unagi %calendar %direct_calendar)
    };

# unagi template
$UnagiTemplate = qq( 
<a href="%namazu_url">Namazu</a> for hns: Search Engine<br>
for detail see <a href="%unagi_url">Help Document</a>.
<form method="GET" action="%unagi_url">
<strong>keyword:</strong>
<input type="TEXT" name="key" size="30" value="%keyword">
<input type="SUBMIT" name="submit" value="Search!">
<input type="HIDDEN" name="whence" value="0">
</form>
);

$NoUnagiTemplate = qq(
<a href="http://www.h14m.org/"><img src="./icons/hns-logo.gif" width="200" height="40" align="right" alt="HNS logo"></a>
);


################################################################
sub initialize($)
{
    my $self = shift;
    my $html;
    my $templ = "HNS::Template"->new();

    my $template = $Templates{$HNS::Status->style_type};
    if (!defined $template){
	Warning("no such style type: " . $HNS::Status->style_type);
    }

    ## PIM ##
    if ($self->col->mode eq 'RECENT' && $PIMUse eq "ON"){
	# Schedule
	my $schedule = "HNS::PIM::Schedule"->new();
	$schedule->Read;
	
	# TODO
	my $todo = "HNS::PIM::Todo"->new();
	$todo->Read;

	# Link
	my $link = "HNS::PIM::Link"->new();
	$link->Read;
	# PIM
	$self->pim_html($templ->Expand(SelectTemplate($template->{pim},
						      %{$template->{pim}}),
				       {schedule=>$schedule->AsHTML,
					todo=>$todo->AsHTML,
					link=>$link->AsHTML
				       }));
    }
    ## calendar and unagi ##
    # calendar
    if ($CalendarUse eq 'ON'){
#	my %param = (year=>$self->col->year, month=>$self->col->month,
#		     col=>$self->col);
	my $calendar;

        my $cat_arg;
        my $QueryString;
        $QueryString = query_string();
        foreach (split('&', $QueryString)) {
            my ($key, $value) = split("=");
            if ($key eq "CAT") {
		$cat_arg = $cat_arg . "&CAT=$value";
            }
        }

	my $calendar_type = $HNS::Status->calendar_type;
	my $class = "HNS::Calendar::$calendar_type";
	eval {
	    $calendar = $class->new();
	};
	if ($@){
	    Warning("illegal calendar type : $calendar_type($@)");
	} else {
	    my ($y, $m) = ($self->col->mode eq 'RECENT') ?
		($HNS::Status->start_time->year,
		 $HNS::Status->start_time->month) :
		     ($self->col->year, $self->col->month);
	    $self->calendar_html($calendar->AsHTML($y, $m, $self->col, $cat_arg));
	}
    }
    # Unagi
    $self->unagi_html(($UnagiUse eq 'ON') ?
		      $templ->Expand(SelectTemplate($UnagiTemplate,
						    %UnagiTemplate),
				     {namazu_url=>$NamazuURL,
				      unagi_url=>$UnagiURL,
				      keyword=>$HNS::Status->is->keyword})
		      : SelectTemplate($NoUnagiTemplate, %NoUnagiTemplate));
    # direct calendar
    if ($DirectCalendarUse eq 'ON'){
	my $direct = "HNS::Calendar::Direct"->new(year=>$self->col->year,
					       month=>$self->col->month,
					       day=>$self->col->day);
	$self->direct_html($direct->AsHTML);
    }
    # Title List
    if ($TitleListUse eq 'ON'){
        my $category_list = "HNS::CategoryList"->new(year=>$self->col->year,
                                               month=>$self->col->month,
                                               day=>$self->col->day);;
	$self->category_html($category_list->AsHTML);
    }
}
################################################################
sub PrintHead($)
{
    shift->print('head');
}
sub PrintFoot($)
{
    shift->print('foot');
}
    
sub print($$)
{
    my ($self, $head_or_foot) = @_;
    my $templ = "HNS::Template"->new();
    my $recent;
    $recent = "_recent" if ($self->col->mode eq 'RECENT');
 
    # expand and print
    print $templ->Expand(SelectTemplate($Templates{$HNS::Status->style_type}->{"${head_or_foot}${recent}_style"},
					%{$Templates{$HNS::Status->style_type}->{"${head_or_foot}${recent}_style"}}),
			 {pim=>$self->pim_html,
			  calendar=>$self->calendar_html,
			  unagi=>$self->unagi_html,
			  direct_calendar=>$self->direct_html,
			  category_list=>$self->category_html
		      });
}
################################################################
sub Warning ($)
{
    my $msg = shift;
    print "<br><font size='+1' color=red>$msg</font><br>";
}

1;
