################################################################
# japanese theme
# $Id: theme.ph,v 1.84 2006/02/28 10:21:48 kenji Exp $

################################################################
# User variable
#  parameter %value is expanded to value of the user variable.
#  you can use other value of user variable by noting as "%user{BASHO}".
package HNS::Hnf::UserVar;
$Templates{'TENKI'}  = "[天気:%value]";
$Templates{'BASHO'}  = "(%value)";
$Templates{'TAION'}  = " 体温:%value度";
$Templates{'TAIJU'}  = " 体重:%value" . "Kg";
$Templates{'SUIMIN'} = " 睡眠:%value時間";
$Templates{'BGM'}    = " BGM:%value";
$Templates{'HOSU'}   = " %value歩";
$Templates{'HON'}    = " 読書:%value";
$Templates{'KITAKU'} = " 帰宅時間:%value";
$Templates{'WALK'}   = " 散歩:%value";
$Templates{'RUN'}    = " ジョギング:%value";
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
$List{"(笑)"}    = "icons/usasho.png";
$List{":-)"}     = "icons/usasmile2.png";
$List{":-("}     = "icons/usaheno2.png";
$List{":-P"}     = "icons/usabe2.png";
$List{"φ(._.)"} = "icons/usamemo.png";

################################################################
# Language
package HNS::System;
$Lang = "ja";

################################################################
# CategoryList
package HNS::CategoryList;
$CatDir = "cat";

$TitleLabel = "タイトル一覧";
$SubmitLabel = "表示!";
$Template = qq(<img src="%src" width="%width" height="%height" alt="">%value<br>\n);
$Categorize = "カテゴリ分類";

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
 h4.comment { margin-left: 1em }
 div.uservar { font-weight: bold; }
 div.section { margin-left: 2em; margin-top: 0 }
 div.sub { margin-left: 1em; margin-top: 0 }
 div.list { margin-left: 1em }
 div.fn { margin-left: 1em; margin-top: 0 }
 div.url { margin-bottom: 0 }
 dl.comments, ul.comments { margin-left: 2em }
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
 div.bold-red { color: red; font-weight: bold }
 span.newmark { color: red; font-size: smaller }
 span.date { font-size: smaller }
 span.saturday { color: blue }
 span.sunday { color: red }
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
$FootMessages{'HasContent'} = "以上、%num 日分です。\n";
$FootMessages{'NoContent'} = "該当するものはありません。\n";


################################################################
# PIM
# Schedule
package HNS::PIM::Schedule;
@WeekString = ('<span class="sunday">日</span>', '月', '火', '水', '木', '金', '<span class="saturday">土</span>');
@ABCString = ('上', '中', '下');
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
@WeekString = ('<span class="sunday">日</span>', '月', '火', '水', '木', '金', '<span class="saturday">土</span>');
$TableBorder = 0;
$NextTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">来月</a>);
$PrevTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">先月</a>);
$ThisTemplate{dynamic} = qq(<a href="$HNS::System::MyDiaryURI?%year%month%cat">%year年%month月</a>);
$NextTemplate{static} = qq(<a href="./%year%month.html">来月</a>);
$PrevTemplate{static} = qq(<a href="./%year%month.html">先月</a>);
$ThisTemplate{static} = qq(<a href="./%year%month.html">%year年%month月</a>);
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
$YearTemplate = "%year年";
$MonthTemplate = "%month月";
$DayTemplate = "%start_day～%end_day日";
$AllLabel = "全て";

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
 <th align="left">予定</th>
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
<a href="%namazu_url">Namazu</a> for hns による簡易全文検索<br>
詳しくは <a href="%unagi_url">詳細指定/ヘルプ</a>を参照して下さい
<form method="GET" action="%unagi_url">
<strong>検索式:</strong>
<input type="TEXT" name="key" size="30" value="%keyword">
<input type="SUBMIT" name="submit" value="Search!">
<input type="HIDDEN" name="whence" value="0">
</form>
);

$NoUnagiTemplate = qq(
<a href="https://web.archive.org/web/20230801153506/http://www.h14m.org/"><img src="./icons/hns-logo.png" width="200" height="40" align="right" alt="HNS logo"></a>
);



################################################################
# Warning
package HNS::Hnf::Warning;
$Head = "<br><span class=\"warning\">\[- 日記システム警告：";
$Foot = "-\]</span><br>\n";

# parameters:
#  %c : the command name
#  %p : command name of inserted position
#
$Messages{'IllegalHeader'} = "ヘッダ部が不正です";
$Messages{'UndefinedUserVar'} = "定義されていないユーザ変数が使われています";
$Messages{'Reserved'} = "コマンド %c は予約されています。";
$Messages{'NoMatch'} = "コマンド %p の中にコマンド %c を含めることはできません。コマンド /%p が抜けている可能性があります。";
$Messages{'NotDefined'} = "コマンド %c の引数として %t は定義されていません。";

################################################################
# Version Message
# paramter:
#  %homepage
#  %public_version
#  %current_version

package HNS;
$VersionMessages{'Public'} = q(<hr>
<div>hns - 日記自動生成システム - Version %public</div>);

$VersionMessages{'NonPublic'}->{dynamic} = qq(<hr>
<div>
<span class="warning">注意：</span> 
今現在使用されているこの日記自動生成システムは 
Version %current です。<br>
公開されている日記自動生成システムは 
Version %public です。
</div>
);

$VersionMessages{'NonPublic'}->{static} = qq(<hr>
<div>
<span class="warning">注意：</span> 
この日記は日記自動生成システム Version %current で生成されました。<br>
公開されている日記自動生成システムは Version %public です。
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
#$BaseTemplate{dynamic} = "$HNS::System::MyDiaryURI?%year%month%day"; # 1日分のみ
$BaseTemplate{static} = "./%year%month.html";		# 静的生成
$HrefTemplate{dynamic} = "%base&amp;to=%name#%name";
#$HrefTemplate{dynamic} = "%base#%name";		# to= を付けない
$HrefTemplate{static} = "%base?to=%name#%name";		# 静的生成

package HNS::Diary;
################
# diary limited parameter:
#   %week		: week string
#
#  user-variable
#   %user{VARNAME}	: string as which user-var-format is expanded using
#			  value of user-variable VARNAME.
@WeekString = ('<span class="sunday">日</span>', '月', '火', '水', '木', '金', '<span class="saturday">土</span>');

$Head{dynamic} = qq(
<h2><a class="hide" href="%href" name="%name">%year年%month月%day日(%week)</a>
[<a href="$HNS::System::MyDiaryURI?%month%day">n年日記</a>]</h2>
);
$Head{static} = qq(
<h2><a class="hide" href="%href" name="%name">%year年%month月%day日(%week)</a></h2>
);

$UserVar = qq(<div class="uservar">
 %user{TENKI}%user{BASHO}%user{TAIJU}%user{TAION}%user{SUIMIN}%user{BGM}
 %user{HOSU}%user{HON}%user{KITAKU}%user{WALK}%user{RUN}%user{YOTEI}
</div>);

# Schedule as User Val
$YoteiVal = "<li>%value</li>";
$YoteiHead = "予定\n<ul>";
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
$EndTemplate = "</div>%boarddata %boardlink<!-- end of NEW -->\n";

package HNS::Hnf::Command::LNEW;
$Template = qq(
<h3 class="new"><a class="hide" name="%name" title="%name" 
href="%href">#%mark</a>
%cat <a href="%1">%content</a></h3>
<div class="section">\n);
$EndTemplate = "</div>%boarddata %boardlink<!-- end of LNEW -->\n";

package HNS::Hnf::Command::RLNEW;
$Template = qq(
<h3 class="new"><a class="hide" name="%name" title="%name" href="%href">#%mark</a>
%cat <a href="%url%2">%content</a></h3>
<div class="section">\n);
$EndTemplate = "</div>%boarddata %boardlink<!-- end of RLNEW -->\n";

package HNS::Hnf::Command::SUB;
$Template = qq(
<h4><a class="hide" name="%name" title="%name" href="%href">＠</a>
%content:</h4> 
<div class="sub">
);
$EndTemplate = "</div><!-- end of SUB -->\n";

package HNS::Hnf::Command::LSUB;
$Template = qq(
<h4><a class="hide" name="%name" title="%name" href="%href">＠</a>
<a href="%1">%content</a>:</h4> 
<div class="sub">
);
$EndTemplate = "</div><!-- end of LSUB -->\n";
$NumAttr = 1;

package HNS::Hnf::Command::RLSUB;
$Template = qq(
<h4><a class="hide" name="%name" title="%name" href="%href">＠</a>
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
$DayTemplate = qq(<a href="%href" class="hide">%year年%month月%day日</a>);

package HNS::Tools::HeadLine::New;
$Template = qq(<b>・</b><a href="%href" title="%para">%content</a>);

################################################################
# Link to board.cgi

package Board;
$ReadStr = 'コメントを読む(%num)';
$SepStr = '|';
$WriteStr = 'コメントする';
$LinkStr = '<div class="boardlink" align="right">[ %readstr %sepstr %writestr ]</div>';
$HeadStr = '<h4 class="comment">この記事へのコメント</h4>';

################################################################
1;
