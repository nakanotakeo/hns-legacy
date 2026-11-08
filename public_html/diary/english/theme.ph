################################################################
# english theme
# $Id: theme.ph,v 1.31 2006/02/28 10:23:28 kenji Exp $

################################################################
# User variable
#  parameter %value is expanded to value of the user variable.
#  you can use other value of user variable by noting as "%user{BASHO}".
package HNS::Hnf::UserVar;
$Templates{'TENKI'}  = "[%value]";
$Templates{'BASHO'}  = "(%value)";
$Templates{'TAION'}  = " Temperature:%value";
$Templates{'TAIJU'}  = " Weight:%value" . "Kg";
$Templates{'SUIMIN'} = " Hours Sleep:%value";
$Templates{'BGM'}    = " BGM:%value";
$Templates{'HOSU'}   = " %value" . " steps";
$Templates{'HON'}    = " Book:%value";
$Templates{'KITAKU'} = " Homecoming:%value";
$Templates{'WALK'}   = " Walking:%value";
$Templates{'RUN'}    = " Running:%value";
$Templates{'YOTEI'}  = "<p>%value</p>";

################################################################
# Mark
package HNS::Hnf::Command::MARK;
# image size is automatically set
$List{"(^^)"}    = "icons/usaniko.png";
$List{"(-_-)"}   = "icons/usamesen.png";
$List{"(^^;"}    = "icons/usaase.png";
$List{"(;_;)"}   = "icons/usauru.png";
$List{"(T_T)"}   = "icons/usauru2.png";
$List{"v(^^)"}   = "icons/usav.png";
$List{"m(__)m"}  = "icons/usapeko.png";
$List{"!!"}      = "icons/usadoki.png";
$List{"??"}      = "icons/usahatena.png";
$List{"!?"}      = "icons/usanaze.png";
$List{":-)"}     = "icons/usasmile2.png";
$List{":-("}     = "icons/usaheno2.png";
$List{":-P"}     = "icons/usabe2.png";

################################################################
# Language
package HNS::System;
$Lang = "en";

################################################################
# CategoryList
package HNS::CategoryList;
$CatDir = "cat";

$TitleLabel = "Title List";
$SubmitLabel = "Show!";
$Template = qq(<img src="%src" width="%width" height="%height" alt="">%value<br>\n);
$Categorize = "Categorize";

################################################################
# Extend HTML
package HNS::ExtHTML;
$DOCTYPE = qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
	"http://www.w3.org/TR/REC-html40/loose.dtd">\n);
#$Head = undef;
$Head{dynamic} = qq(<link rel="alternate" type="application/rss+xml" title="RSS" href="${HNS::System::MyDiaryURI}rss.cgi">
<meta http-equiv="Content-Style-Type" content="text/css">
<style type="text/css"><!--
 body { background: white }
 h3.new { margin-left: 1em }
 div.uservar { font-weight: bold; }
 div.section { margin-left: 2em; margin-top: 0 }
 div.sub { margin-left: 1em; margin-top: 0 }
 div.list { margin-left: 1em }
 div.fn { margin-left: 1em; margin-top: 0 }
 div.url { margin-bottom: 0 }
 pre { 
  white-space:  pre;
  padding:      0.5em;
  border-color: #ffeeb0;
  border-style: outset;
  border-width: 4px
 }
 a.hide:link { color: black; text-decoration: none }
 span.bold-red { color: red; font-weight: bold }
 span.warning { color: red }
 span.saturday { color: blue }
 span.sunday { color: red }
 div.bold-red { color: red; font-weight: bold }
--></style>
);
$Head{static} = qq(<!--#exec cmd="./logging.pl"-->\n) . $Head{dynamic};

#$BodyVal = undef;
##$BodyVal = "bgcolor=#ffffcc";
#$DynamicPrintFunc = undef;
##$DynamicPrintFunc = \&PrintTime;
##sub PrintTime
##{
##    print qq(<div align="center">time is);
##    print join(':', reverse ((localtime)[0..2]));
##    print qq(</div>);
##}
################################################################
package HNS::Collection;
# %num : number of showing diarys
$FootMessages{'HasContent'} = "Diary for %num day(s).\n";
$FootMessages{'NoContent'} = "No match.\n";


################################################################
# PIM
# Schedule
package HNS::PIM::Schedule;
@WeekString = ('<span class="sunday">Sun</span>', 'Mon', 'Tue', 'Wed', 'Thu',
        'Fri', '<span class="saturday">Sat</span>');
@ABCString = ('low', 'mid', 'high');
$Unfixed = '??';
$ContentTemplate = qq(<li><strong>%month/%day%week</strong> %content</li>\n);
$BeginTemplate = "<ul>";
$EndTemplate = "</ul>";

# TODO
package HNS::PIM::Todo;
$ContentTemplate = "<li><strong>%priority</strong> %content</li>\n";
$BeginTemplate = "<ul>";
$EndTemplate = "</ul>";

################################################################
# Calendar
package HNS::Calendar::Table;
@WeekString = ('<span class="sunday">Sun</span>', 'Mon', 'Tue', 'Wed', 'Thu',
        'Fri', '<span class="saturday">Sat</span>');
$TableBorder = 0;
$NextTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">Next</a>);
$PrevTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">Prev</a>);
$ThisTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">%year/%month</a>);
$NextTemplate{static} = qq(<a href="./%year%month.html">Next</a>);
$PrevTemplate{static} = qq(<a href="./%year%month.html">Prev</a>);
$ThisTemplate{static} = qq(<a href="./%year%month.html">%year/%month</a>);
$DayCurrentTemplate = qq(<a href="%ruri#%{ymd}0">%calendar_day</a>);
$DayNonCurrentTemplate = qq(<a href="%href">%calendar_day</a>);

package HNS::Calendar::NoTable;
$NextTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">&gt;&gt;</a>);
$PrevTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">&lt;&lt;</a>);
$ThisTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">%year/%month</a>);
$NextTemplate{static} = qq(<a href="./%year%month.html">&gt;&gt;</a>);
$PrevTemplate{static} = qq(<a href="./%year%month.html">&lt;&lt;</a>);
$ThisTemplate{static} = qq(<a href="./%year%month.html">%year/%month</a>);
$DayCurrentTemplate = qq(<a href="%ruri#%{ymd}0">%calendar_day</a>);
$DayNonCurrentTemplate = qq(<a href="%href">%calendar_day</a>);

################################################################
# DateSelect
package HNS::DateSelect;
$YearTemplate = "%year/";
$MonthTemplate = "%month/";
$DayTemplate = "%start_day - %end_day";
$AllLabel = "All";

################################################################
# Direct Ctalendar
package HNS::Calendar::Direct;
$SubmitLabel = "Go!";

################################################################
# Style
package HNS::Style;
$Templates{Table}->{pim} = qq(
<hr>
<table summary="pim" width="100%">
<tr>
 <th align="left">Schedule</th>
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

$Templates{Table}->{head_style}->{dynamic} = qq(
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

$Templates{Table}->{head_style}->{static} = qq(
%pim
<hr>
%calendar
<hr>
);

$Templates{Table}->{foot_style} = "\n<hr>\n%category_list";

$Templates{Table}->{head_recent_style} = $Templates{Table}->{head_style};
$Templates{Table}->{foot_recent_style} = $Templates{Table}->{foot_style};

# template for no table browser
$Templates{NoTable} = {
    pim => qq(<hr>\n%schedule %todo %link),
    head_style => qq(%pim\n<hr>\n%unagi\n<hr>\n%calendar
		      %direct_calendar\n<hr>\n),
    foot_style=> "<hr>\n%category_list"
    };

$Templates{NoTable}->{head_recent_style} = $Templates{NoTable}->{head_style};
$Templates{NoTable}->{foot_recent_style} = $Templates{NoTable}->{foot_style};

# unagi template
$UnagiTemplate = qq( 
<a href="%namazu_url">Namazu</a> for hns, Search Engine<br>
for detail see <a href="%unagi_url">help</a>
<form method="GET" action="%unagi_url">
<strong>keyword:</strong>
<input type="TEXT" name="key" size="30" value="%keyword">
<input type="SUBMIT" name="submit" value="Search!">
<input type="HIDDEN" name="whence" value="0">
</form>
);

$NoUnagiTemplate = qq(
<a href="http://www.h14m.org/"><img src="./icons/hns-logo.png" width="200" height="40" align="right" alt="HNS logo"></a>
);



################################################################
# Warning
package HNS::Hnf::Warning;
$Head = "<br><span class=\"warning\">\[- Warning:";
$Foot = "-\]</span><br>\n";

# parameters:
#  %c : the command name
#  %p : command name of inserted position
#
$Messages{'IllegalHeader'} = "illegal header.";
$Messages{'UndefinedUserVar'} = "undefined user var %c";
$Messages{'Reserved'} = "command '%c' is reserved. ";
$Messages{'NotDefined'} = "term '%t' is not defined in %c definition file.";
$Messages{'NoMatch'} =
    "command '%c' is not allowed in command '%p'. command '/%p' is missing ?";

################################################################
# Version Message
# paramter:
#  %homepage
#  %public_version
#  %current_version

package HNS;
$VersionMessages{'Public'} = q(<hr>
<div>hns - Hyper NIKKI System - Version %public</div>);

$VersionMessages{'NonPublic'}->{dynamic} = qq(<hr>
<div>
<span class="warning">Caution: </span>
This web diary system is hns %current.<br>
Public released version is hns %public.
</div>
);

$VersionMessages{'NonPublic'}->{static} = qq(<hr>
<div>
<span class="warning">Caution: </span>
This diary was generated by hns %current.<br>
Public released version is hns %public.
</div>
);

################################################################
# Template
# usable parameter (%[A-Za-z0-9_]) is:
#  date:
#   %year, %month, %day	: year, month, day
#   %high		: int(day/10)
#   %abc		: day 1-10 -> a, 11-20 -> b, 21-31 -> c
#  counter:
#   %new, %sub, %fn	: counter of NEW, SUB, FN
#   %mark		: for GRP mark, if not in GRP the same as %new

package HNS::Diary::Template;
$BaseTemplate{dynamic} = "$HNS::System::MyDiaryURI?%year%month%abc";
#$BaseTemplate{dynamic} = "$HNS::System::MyDiaryURI?%year%month%day"; # link to one day
$BaseTemplate{static} = "./%year%month.html";           # static HTML generation
$HrefTemplate{dynamic} = "%base&amp;to=%name#%name";
#$HrefTemplate{dynamic} = "%base#%name";                # no to= 
$HrefTemplate{static} = "%base?to=%name#%name";         # static HTML generation

package HNS::Diary;
################
# diary limited parameter:
#   %week		: week string
#
#  user-variable
#   %user{VARNAME}	: string as which user-var-format is expanded using
#			  value of user-variable VARNAME.
@WeekString = ('<span class="sunday">Sun</span>', 'Mon', 'Tue', 'Wed', 'Thu',
        'Fri', '<span class="saturday">Sat</span>');

$Head{dynamic} = qq(
<h2><a class="hide" href="%href" name="%name">%year/%month/%day(%week)</a>
[<a href="$HNS::System::MyDiaryURI?%month%day">n years ago</a>]</h2>
);
$Head{static} = qq(
<h2><a class="hide" href="%href" name="%name">%year/%month/%day(%week)</a></h2>
);

$UserVar = qq(<div class="uservar">
 %user{TENKI}%user{BASHO}%user{TAIJU}%user{TAION}%user{SUIMIN}%user{BGM}
 %user{HOSU}%user{HON}%user{KITAKU}%user{WALK}%user{RUN}%user{YOTEI}
</div>);

# Schedule as User Val
$YoteiVal = "<li>%value</li>";
$YoteiHead = "Schedule\n<ul>";
$YoteiFoot = "</ul>";

$Foot = qq(<hr>\n);

package HNS::Hnf::Command::ConvUrl;
$HrefTemplate = "%base#%name";
$Template{mydiary} = "%href";

$Template{ISBN} = "http://www.bk1.co.jp/search/search.asp?kywd=%param";
#$Template{ISBN} = "http://www.isize.com/book/cgi-bin/isbn.cgi?isbn=%param";
#$Template{ISBN} = "http://www.eshopping.ne.jp/bks.svl?CID=BKS504&amp;access_method=isbn_cd&amp;input_data=%param";
#$Template{ISBN} = "http://www1.honyasan.co.jp/washo/book.cfm?PRODUCT_CD=%param";
#$Template{ISBN} = sub { $_ = $_[0]; s/-//g; "http://www.amazon.co.jp/exec/obidos/ASIN/$_"; };

$Template{CD} = "http://www.hmv.co.jp/search/title.asp?category=CATALOGUENO&amp;keyword=%param";
#$Template{CD} = "http://www.towerrecords.co.jp/tower/towercdj.nsf/SearchProductID/%param";

$Template{"hns-dev"} = sub { sprintf("http://www.h14m.org/ml/hns-dev/msg%05d.html", $_[0] - 1) };
$Template{"hns-users"} = sub { sprintf("http://www.h14m.org/ml/hns-users/msg%05d.html", $_[0] - 1) };

package HNS::Hnf::Command::CAT;
$Template{dynamic} = qq([<a href="./title.cgi?CAT=%enc_var">%var</a>]);
$ImgTemplate{dynamic} = qq(<a href="./title.cgi?CAT=%enc_var">%img</a>);
$Template{static} = qq([<a href="./tc%year%month.html#%enc_var">%var</a>]);
$ImgTemplate{static} = qq(<a href="./tc%year%month.html#%enc_var">%img</a>);

package HNS::Hnf::Command::NEW;
$Template = qq(
<h3 class="new"><a class="hide" name="%name" title="%name" href="%href">#%mark</a>
%cat %content</h3>
<div class="section">\n);
$EndTemplate = "%boardlink</div><!-- end of NEW -->\n";

package HNS::Hnf::Command::LNEW;
$Template = qq(
<h3 class="new"><a class="hide" name="%name" title="%name"
href="%href">#%mark</a>
%cat <a href="%1">%content</a></h3>
<div class="section">\n);
$EndTemplate = "%boardlink</div><!-- end of LNEW -->\n";

package HNS::Hnf::Command::RLNEW;
$Template = qq(
<h3 class="new"><a class="hide" name="%name" title="%name" href="%href">#%mark</a>
%cat <a href="%url%2">%content</a></h3>
<div class="section">\n);
$EndTemplate = "%boardlink</div><!-- end of RLNEW -->\n";

package HNS::Hnf::Command::SUB;
$Template = qq(
<h4><a class="hide" name="%name" title="%name" href="%href">*</a>
%content:</h4> 
<div class="sub">
);
$EndTemplate = "</div><!-- end of SUB -->\n";

package HNS::Hnf::Command::LSUB;
$Template = qq(
<h4><a class="hide" name="%name" title="%name" href="%href">*</a>
<a href="%1">%content</a>:</h4> 
<div class="sub">
);
$EndTemplate = "</div><!-- end of LSUB -->\n";
$NumAttr = 1;

package HNS::Hnf::Command::RLSUB;
$Template = qq(
<h4><a class="hide" name="%name" title="%name" href="%href">*</a>
<a href="%url%2">%content</a>:</h4> 
<div class="sub">
);
$EndTemplate = "</div><!-- end of RLSUB -->\n";
$NumAttr = 2;

################################################################
# Inline Elements
# these element has no content commands,
# so $EndTemplate, $AllowCommands has no means.

package HNS::Hnf::Command::LINK;
$Template = qq(<a href="%1">%content</a>\n);
$NumAttr = 1;

package HNS::Hnf::Command::RLINK;
$Template = qq(<a href="%url%2">%content</a>\n);
$NumAttr = 2;
# overriden AsHTML

package HNS::Hnf::Command::URL;
$Template = qq(<div class="url">
<img alt="*" src="./icons/mark01.png" width="16" height="16">
<a href="%1">%content (%1)</a>
</div>\n);
$NumAttr = 1;

package HNS::Hnf::Command::STRIKE;
$Template = qq(<strike>%content</strike>\n);

package HNS::Hnf::Command::LSTRIKE;
$Template = qq(<strike><a href="%1">%content</a></strike>\n);
$NumAttr = 1;

package HNS::Hnf::Command::STRONG;
$Template = qq(<strong>%content</strong>\n);

package HNS::Hnf::Command::FONT;
$Template = qq(<font %1="%2">%content</font>\n);
$NumAttr = 2;

package HNS::Hnf::Command::IMG;
$Template = 
    qq(<img %align src="%2" alt="%content" width="%width" height="%height">\n);
$NumAttr = 2;
# overriden AsHTML

package HNS::Hnf::Command::MARK;
$Template = qq(<img src="%src" alt="%1" width="%width" height="%height">\n);
$NumAttr = 1;
# overriden AsHTML

package HNS::Hnf::Command::ALIAS;
$Template = "%term";
# overriden AsHTML

################################################################
# Block Commands
package HNS::Hnf::Command::PRE;
$Template = "<pre>\n";
$EndTemplate = "</pre>\n";

package HNS::Hnf::Command::CITE;
$Template = "<blockquote>\n";
$EndTemplate = "</blockquote>\n";

package HNS::Hnf::Command::UL;
$Template = "<ul>\n";
$EndTemplate = qq(</ul>\n);

package HNS::Hnf::Command::OL;
$Template = "<ol>\n";
$EndTemplate = qq(</ol>\n);

package HNS::Hnf::Command::LI;
$Template = q(<li>%content );
$EndTemplate = "</li>\n";

package HNS::Hnf::Command::HR;
$Template = q(<hr>\n);

package HNS::Hnf::Command::FN;
$Template = 
    qq(<a href="$ENV{'REQUEST_URI'}#%name"><small>*%fn</small></a>\n);

$HeaderTemplate = qq(<hr class="section" width="40%" align="left">
<div class="fn">\n);
$FooterTemplate = qq(</div>\n);

$ContentTemplate = qq(
<a class="hide" name="%name" href="%href"><small>*%fn</small></a>: %content<br>
);

package HNS::Tools::Title;
$CatTemplate{dynamic} =
  qq(<h3>%img<a href="title.cgi?%{arg}CAT=%enc_var">%var</a></h3>\n);
$CatLinkTemplate{dynamic} =
  qq([<a href="title.cgi?%{arg}CAT=%enc_var">%var</a>]);
$CatTemplate{static} =
  qq(<h3>%img<a href="#%enc_var" name="%enc_var">%var</a></h3>\n);
$CatLinkTemplate{static} =
  qq(<a href="tc%year%month.html#%enc_var">%var</a>);
$HeadTitle = qq(<title>$HNS::System::Title Title List</title>\n);
$Header = qq(<h1><a href="$HNS::System::MyDiaryURI">$HNS::System::Title</a> Title List</h1>\n);
$BacktoDiary = qq(<div align="right"><a href="$HNS::System::MyDiaryURI">Back to Diary</a></div>\n);

package HNS::Tools::Title::Hnf;
$BaseTemplate{dynamic} = "$HNS::System::MyDiaryURI?%year%month%abc";
$BaseTemplate{static} = "./%year%month.html";

package HNS::Tools::HeadLine;
$Max = $HNS::System::DefaultMax * 3;
$HeadTitle = qq(<title>$HNS::System::Title HeadLine</title>\n);
$Header = "";
$BacktoDiary = "";
$BaseTemplate{dynamic} = "$HNS::System::MyDiaryURI?%year%month%abc";
$BaseTemplate{static} = "./%year%month.html";
$RecentBaseTemplate{dynamic} = "$HNS::System::MyDiaryURI";
$RecentBaseTemplate{static} = "./recent.html";
$DayTemplate = qq(<a href="%href" class="hide">%year/%month/%day</a>);

package HNS::Tools::HeadLine::New;
$Template = qq(<b>*</b><a href="%href" title="%para">%content</a>);

################################################################
# Link to board.cgi

package Board;
$ReadStr = 'read comments(%num)';
$SepStr = '|';
$WriteStr = 'write comment';
$LinkStr = '<div class="boardlink" align="right">[ %readstr %sepstr %writestr ]</div>';
$HeadStr = '<h4 class="comment">comments for this article</h4>';
 
################################################################
1;
