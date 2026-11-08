#!/usr/local/bin/perl
#!%PERL_PATH%
#
# index.cgi as i system and i search system
# 2001/02/28 0.9.10 kei-3, iouri-3 fix CR/LF bug
# 2000/10/24 0.9.9 tokumi-3 piloweb 2days date bug fix
#                  HyperNikkiSystem Project
# 2000/10/20 0.9.8 masato-3 hikisu patch
#                  yar-3 DIV
# 2000/09/19 0.9.7 yar-3 for Palmscape Cruiser (tnx chig-3)
# 2000/08/12 0.9.6 yar-3 today's plan, OK on CR/LF, SPAN
#                  masato-3 user vars
#                  chihalin-3 fix on no hnf day
# 2000/07/17 0.9.5 yar-3 fix month bug
# 2000/07/12 0.9.4 yar-3 fix date bug
# 2000/07/06 0.9.3 tokumi-3 catprint on NEW
# 2000/07/05 0.9.2 masato-3 jump patch
#                  yar-3 fix fileprint charcode bug
#                  yar-3 daystyle
# 2000/07/02 0.9.1 masato-3 to=hoge patch
#                  yar-3 CRLF, STRIKE, JSky
# 2000/06/30 0.9.0 masato-3 rebuild parser
# 2000/06/29 0.8.7 yar-3 LIMG
# 2000/06/29 0.8.6 yar-3 fix cmd match, imodegw
# 2000/06/28 0.8.5 masato-3,yar-3 hns & i system fusion, theme
# 2000/06/22 0.8.4 yar-3 delete <br> about GRP
# 2000/06/14 0.8.3 masato-3 search patch
# 2000/06/12 0.8.2 chihalin-3 PDX bug fixed for ONC browser
# 2000/06/12 0.8.1 masato-3 fixsearch bug
# 2000/06/06 0.8.0 kei-3 fix schedule bug
# see below...
# このcgiは改造自由、再配布自由ですが、無保証です。
# このcgiは GPL です。
# このファイルとconfig.phはEUCコード、改行LFで使用してください。

$out = ""; # いわゆる出力buffer
#$o = ""; # parse buffer

$ver = "0.9.10(Finalβ) 01/02/28 (C)yar-3,masato-3";
#$ver = "0.4.8 with PDX G/W pl7 00/02/29 (C)yar-3,masato";
# 改造したひとは、↑ここらへんを書きかえるとオリジナリティup
$isystem = "http://yar-3.net/isystem/";

$strong = "<strong>";
$strong2 = "</strong>";
$strike = "<strike>";
$strike2 = "</strike>";
$sub_separator = " ";

# ユーザ変数
%UserVarTemplates = (
	TENKI	=> "[天気:%value]",
	BASHO	=> "(%value)",
	TAION	=> " 体温:%value度",
	TAIJU	=> " 体重:%value" . "Kg",
	SUIMIN	=> " 睡眠:%value時間",
	BGM	=> " BGM:%value",
	HOSU	=> " %value歩",
	HON	=> " 読書:%value",
	KITAKU	=> " 帰宅時間:%value",
	WALK    => " 散歩:%value",
	RUN     => " ジョギング:%value"

);
%UserVarAlias = (
	WEATHER     => "TENKI",
	LOCATION    => "BASHO",
	WEIGHT      => "TAIJU",
	TEMPERATURE => "TAION",
	SLEEP       => "SUIMIN",
	STEP        => "HOSU",
	BOOK        => "HON",
	HOMECOMING  => "KITAKU",
);

@color_imode_ua = qw(D502 F502 SH821 P209is D209 F209);

unshift(@INC, ".");
require 'config.ph';
#設定ファイルです。

if ($use_onccnv) {	# HTML to ONCコンバータ使用
	require 'onccnv.pl';
	$ongw = "";
} else {
	# 何もしなくても大丈夫かもしれないが念のため
	eval q{
		sub conv_html2onc { $_[0]; }
		sub onc_gateway {} 
	};
}

if ($nkf == 1) {
	eval q(use NKF);
	if (!defined(&main::nkf)) {
		die "NKF.pm not found";
	}
	# ftp://ftp.ie.u-ryukyu.ac.jp/pub/software/kono/nkf192.shar で入手できます
} elsif ($nkf == 2) {
	require 'jcode.pl'; #jcode.plは最新を推奨
	# ftp://ftp.iij.ad.jp/pub/IIJ/dist/utashiro/perl/ から入手できます
}



@week  = ("日","月","火","水","木","金","土"); #日本語
#@week = ("Su","Mo","Tu","We","Th","Fr","Sa"); #English

#引数の解釈 masato-3
if ($ARGV[0] eq '-t') {
	# デバック用オプション引数を使った実行
	#     使用例 : ./index.cgi -t word=system
	$query_string = $ARGV[1];
	$log = 0;		# ログは取らない
	splice(@ARGV, 0, 2);	# オプション引数を除去
} elsif ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN, $query_string, $ENV{'CONTENT_LENGTH'});
} else {
	$query_string = $ENV{'QUERY_STRING'};
}
$jsky = 1 if $ENV{'HTTP_X_JPHONE_MSNAME'}; # j-skyweb 

@a = split(/&/, $query_string);
foreach $a (@a) {
	($name, $value) = split(/=/, $a);
	if ($name =~ /^word$/i) { # word=hoge だったらURL encodeされたまま保持
		$origword = $value;
	}
	$value =~ tr/+/ /;
	$value =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
}

$ua = $ENV{'HTTP_USER_AGENT'};
#$ua = "PDXGW"; # for testing (PDXGW)
$ua = "PDXGW" if ($FORM{pdxdata} || $FORM{pdxsubj} || $FORM{pdxfrom});
#$day = "SALL" if ($ua =~ /pilo/i); #for piloweb

if ($ua =~ /^DoCoMo/i) { #iMODE端末
	$imode = 1;
#	if ($ua =~ /D502/i or $ua =~ /F502/i or $ua =~ /SH821/i) { # color iMODE?
	if (grep($ua =~ /$_/i, @color_imode_ua)) { # color iMODE?
		$colorimode = 1;
		if ($head){
			$head = "<font color=\"$headcolor\">$head</font>";
		} else {
			$head = "<font color=\"$headcolor\">$title</font>";
		}
		$newmark = "<font color=\"$newcolor\">$newmark";
		$new2 = "$new2</font>";
		$submark = "<font color=\"$subcolor\">$submark";
		$sub2 = "$sub2</font>";
		$strong = "<font color=\"$strongcolor\">$strong";
		$strong2 = "$strong2</font>";
	}
} elsif ($ua =~ /^PDXGW/) { #いわゆるPmailDX
	my $pdxdata = $FORM{pdxdata};
	if ($pdxdata =~ /\s*(\S+)\s*/) {
		$pdxdata = $1;
	} else {
		$pdxdata = $FORM{pdxsubj};
		if ($pdxdata =~ /\s*(\S+)\s*/) {
			$pdxdata = $1;
		} else {
			$pdxdata = '';
		}
	}
	if ($ongw) { # t-saitoh先生のopennet CGIを利用
		my $qbaseuri;

		#print "Location: $ongw" . "?URL=$baseuri\n\n";
		# Locationは使えませんでした>PDX
		print "content-type: text/plain\n\n"; # html header
		print "From: $baseuri\n";
		print "Content-Type: Text/X-PmailDX\n\n";
		if ($pdxdata) {
			$qbaseuri = "$baseuri?word=$pdxdata";
		} else {
			$qbaseuri = $baseuri;
		}
		$qbaseuri =~ s/([:?=&\/\.~])/sprintf("%%%2X",ord($1))/egi ;
		print "<SEL=1;$ongw?URL=$qbaseuri>\n\n";
		print "i system for PmailDX<br>\n";
		if ($pdxdata) {
			print "push 1 for search[$pdxdata].\n";
		} else {
			print "push 1.\n";
		}
		exit 0;
	}
	$pdx = 1;
#	$section = "ALL"; #PmailDXのときは15KBくらい取得できるので1日分を一気に

	# pdxdata(PmailDXの表題or本文)があればそれでいきなり検索
	$FORM{word} = $pdxdata if ($pdxdata ne '');

	$baseuri =~ s/[?](.+)$//;
} elsif ($ua =~ /^UP.Browser/) { # ezweb?
    $ezweb = 1;
}
$use_onccnv = 0 if (!$pdx);

if ($imode or $pdx or $ezweb or $jsky) {
	$strike  = "[S:";
	$strike2 = ":S]";
	if ($colorimode) {
                $strike = "<font color=\"$strikecolor\">$strike";
                $strike2 = "$strike2</font>";
	}
}

#$log = 1;でログ採取。0で採取しない。動かないときは0にして
if ($log) { # logger on
	# print "logging\n";
	&logging;
}

if ($FORM{U} || $FORM{URL}) {		# ONC GW動作
	&onc_gateway($FORM{U} || $FORM{URL}, $baseuri, $ref_max, $flag_maru);
	exit 0;
}


#表示する日記の日付
if ($FORM{to} =~ /^(\d{8})(\d+)/) {
    $day = "$1S$2";
} else {
    $day = $FORM{d} || $ARGV[0]; # ?20001031 という感じ。
}

$tt = time;
($sec, $min, $hour, $mday, $mon, $year,
	$wday, $yday, $isdst) = localtime($tt);
$year += 1900;
$mon++;
if ($mon < 10 ) { $mon = "0$mon"; } #0suppress
if ($mday < 10 ) { $mday = "0$mday"; }
$today = "$year$mon$mday"; #19991231 format
if ($day =~ /^(\d{4})(\d{2})(\d*)/) { # ?09270111
  if ($1 < 1970) {
    $day = ""; # 最新の日記
  }
}
 
if ($day eq 'J') { #日付移動
	&print_jump_form;
	exit 0;
}
if ($day eq 'E') { #検索メニュー
	&print_search_form;
	exit 0;
}
if ($day eq 'PL') { # today's Plan
	$day = $today . "P";
}
if ($day eq 'P' or ($day eq "" and ($ua =~ /pilo/i or $ua =~ /pscruiser/i))) { #Piloweb and PSCruiser
	$piloweb = 1; # piloweb flag
	$section = "ALL";
	$day = "";
}

if (length($day) > 8) { # ?20001031S2 というかんじ
	if ($day =~ /P$/i) { # 末尾がP : planモード
		$day =~ /(\d{8})P/i; #20001031 P に分ける
		$day = $1;
		$plan = 1;
	} elsif ($day =~ /T$/i) { # 末尾がT : todoモード
		$day =~ /(\d{8})T/i; #20001031 P に分ける
		$day = $1;
		$todo = 1;
		$todof = "$diarydir/todo";
	} else {
		$day =~ /(\d{8})s(.+)/i; #20001031 S2 に分ける
		$day = $1;
		$section = $2;
	}
}
if ($day eq "") { # today
#	$day = $today if (-e &make_hnf_fname($today));
	if ($FORM{word}) { # 検索文字列あり
		&search_word($FORM{word});
		exit 0;
	}
 
} else {
	($year, $mon, $mday) = unpack("A4A2A2", $day);
	$hnf = &make_hnf_fname($day);
}

$newcount = 0; #いくつめのNEWか
$subcount = 0; #いくつめのSUBか NEWが変わるとreset

$ok = 0; # header識別 OK までの部分はユーザー変数 i systemでは無視

#去年から来年までのhnfファイルのリストを作成する
foreach my $y ($year-1..$year+1) {
	opendir DIR, "$diarydir$y" || next;
	push(@ddays, (sort grep s/^d(\d+)\.hnf$/$1/, readdir DIR));
	closedir DIR;
}
#$dayがからっぽで当日のhnfがないときは最新のhnfを代用
if ($day eq "") {
	foreach my $d (reverse @ddays) {
		$day = $d;
		($year, $mon, $mday) = unpack("A4A2A2", $day);
		$hnf = &make_hnf_fname($day);
		last if &has_ok($hnf);
	}
}
#前日と翌日の日記ファイルを探す
for ($i = 0; $i <= $#ddays; $i++) {
	last if ($ddays[$i] ge $day);
}
$j = ($ddays[$i] ge $day) ? $i-1 : $i;
while ($j >= 0) {
	my $f = &make_hnf_fname($ddays[$j]);
	if (&has_ok($f)) {
		$prevday = $ddays[$j];
		last;
	}
	$j--;
}
$j = ($ddays[$i] ge $day) ? $i+1 : $i;
while ($j <= $#ddays) {
	my $f = &make_hnf_fname($ddays[$j]);
	if (&has_ok($f)) {
		$nextday = $ddays[$j];
		last;
	}
	$j++;
}

if (!$use_onccnv) {
	$out .= "content-type: text/html\n\n";	# content-typeを出力
}
$out .= "\n<html><head>\n";
$out .= "<!-- や -->\n" if (!$nkf); #nkfやjcode.plが使えないときは「や」テク
#「や」テクとは、iMODE携帯でEUCのサイトを表示する技術(謎)
# tnx 2 masato-3, ari-3
$out .= "<title>$title</title>\n";
$out .= "</head>\n";

&make_body; #<body>部をレンダリングする

$out .= "</html>\n"; #html生成終わり

$out = &conv_html2onc($out, $baseuri, $baseuri, $ref_max, $flag_maru) if $use_onccnv;
$out = &convert2sjis($out) if $nkf; 	#NKF,jcode.pl使用時はsjis変換

print $out; #出力

################################################################
#
# おしまい
#
# あとはsubroutine
#
################################################################


# ファイルを読み出して表示
sub fileprint {
	my $tmpout;
	open(IN, $_[0]);
	while(<IN>) {
		$tmpout .= "$_\n";
	}
	$tmpout = &convert2euc($tmpout) if $nkf;     #NKF,jcode.pl使用時はeuc変換
	return $tmpout;
}

#日付を表示
sub dayprint {
	my $yyyy,$mm,$dd,$m,$d,$w,$tmpday;

	#$daystyle = "<b>%yyyy年%mm月%dd日(%w)</b>" if (!$daystyle) ; #default

        if ($daystyle) {
                $tmpday = $daystyle;
        } else {
                $tmpday = "<b>%yyyy年%mm月%dd日(%w)</b>"; #default
        }

	# %yyyy 4桁西暦
	# %mm   2桁月
	# %dd   2桁日
	# %m    月(0サプレスなし)
	# %d    日(0サプレスなし)
	# %w    曜日

	$day =~ /(\d\d\d\d)(\d\d)(\d\d)/;
	$yyyy = $1;
	$mm = $2;
	$dd = $3;
	$m = $mm; #0.9.5 fix
	$m = sprintf("%1d", $mm) if ($mm < 10);
	$d = $dd; #0.9.5 add
	$d = sprintf("%1d", $dd) if ($dd < 10); 
	$w = getdayoftheweek( "$yyyy/$mm/$dd");

#	$out .= "<br><b>$1年$2月$3日</b>\n";
#	$out .= "<b>$1年$2月$3日</b>\n"; # brを取った
	$tmpday =~ s/%yyyy/$yyyy/;
	$tmpday =~ s/%mm/$mm/;
	$tmpday =~ s/%dd/$dd/;
	$tmpday =~ s/%m/$m/;
	$tmpday =~ s/%d/$d/;
	$tmpday =~ s/%w/$w/;
	$out .= "$tmpday\n";
}

#解析
sub parse {
	$t = $_[0];
	my $o = "";
	$t =~ s/\r$//;
	chomp($t); #これは実はいらない?

	if ( $t =~ /^OK$/ ) { #header識別
		$ok = 1;
		return;
	}

	if ($ok == 0) { #header処理中
		#$o .= $t; #for debugging
		# ユーザー変数の表示
		my ($var, $value) = $t =~ /^(\S+)\s+(\S.*)/;
		if ($UserVarAlias{$var}) {
			$var = $UserVarAlias{$var};
		}
		my $v = $UserVarTemplates{$var};
		if ($var ne '' && $v ne '') {
			$v =~ s/%value/$value/e;
			$o .= $v;
		}
		return;
	}

	if ($t =~ /^RL(NEW|SUB)\s(\S+)\s(\S+)\s(.+)/) { #RLNEW 引数1 2 説明
		$cmd = $1;
		$orig = $2;
		$url = $3;
		$cmt = $4;
		#$t = "cmd=$cmd orig=$orig url=$url $cmt";
		open(RLINK, "$diarydir" . "conf/rlink.txt");
		while($a = <RLINK>) {
			$a =~ /^(\S+)\s(.*)/;
			#$t .= "-$1- -$orig-";
			if ( $1 eq $orig ) { # 一致したら
				$url = $2 . $url;
				$t = "L$cmd $url $cmt"; #LNEW,LSUBに置換してしまう!
			}
		}
		close(RLINK);
	}

        # <,>,&を置換しておく
        if ($t =~ /^((LNEW|LSUB|LSTRIKE|LSTRONG|LINK|URL)\s+(\S+))(\s+.+)?/) {
                $t = &html_escape($1) . &html_escape_zen($4);
        } else {
                $t = &html_escape_zen($t);
        }

        if ($t =~ /~$/) { #末尾の改行を変換
                $t =~ s/~$/<br>/;
        }

        if ($grp > 0) { #GRP機能対応 kenji-3
		if ($t =~ /^(NEW|LNEW|RLNEW|GRP)\s.*/) {
                 # GRPの内部は非表示にする
		}		
		else {
	                return;
		}
        }

	my ($cmd, $p) = ($t =~ /^(\/?[A-Z]+)(?:(?:\s*)|(?:\s+(.*)))$/);
	if ($cmd eq "CAT") { # CAT hoge
		$cat = $cat . $p; #複数行のCATに対応
	} elsif ($cmd eq "GRP") { # GRP機能
		$grp = 1; # grp mode on
	} elsif ($cmd eq "NEW") { # NEW hogehoge
		$newtopic = $2; # searchで使うためにnewの中身を保存
	        if ($grp == 1) {
			# GRPの内部は非表示にする
			$grp = 2;
			return;
		} elsif ($grp == 2) {
			$grp = 0;
		}

		$newcount++;
		#if ( $newcount != 1 and $imode != 1) {
		if ( $imode != 1) { #常時 $newlineで区切ってみる
			$o .= "$newline";
		} else { #iMODEのときは
			$o .= "<br>"; #とりあえず改行
		}
		$subcount = 1;
		$o .= "$newmark$newcount:";
		$o .= "$new1$p";
                if ($cat && $catprint ) { #cat 表示をon/off可能に
                        $o .= "\n[$cat]\n";
                        $cat = "";
                }
		$o .= "$new2";
	} elsif ($cmd eq "LNEW" && $p =~ /(\S+)\s(.+)/) { # LNEW url hogehoge
		#$newtopic = $2; # searchで使うためにnewの中身を保存
                if ($grp == 1) {
                        # GRPの内部は非表示にする
                        $grp = 2;
                        return;
                } elsif ($grp == 2) {
                        $grp = 0;
                }

		$newcount++;
		#if ( $newcount != 1 and $imode != 1) {
		if ( $imode != 1) { #常時 $newlineで区切ってみる
			$o .= $newline;
		} else { #iMODEのときは
			$o .= "<br>"; #とりあえず改行
		}
		$subcount = 1;
		$fncount = 1;
		$fnmode = 0;
		$fn = "";
		$o .= "$newmark$newcount:";
		$o .= $new1;
		$o .= &make_link($1);
		$o .= "$2</a>";
		if ($cat && $catprint ) { #cat 表示をon/off可能に
			#print "[$cat]\n";
			$o .= "\n[$cat]\n";
			$cat = "";
		}
		$o .= $new2;
	} elsif ($cmd eq "SUB") { # SUB hogehoge
		#$subtopic = $p; # searchで使うためにsubの中身を保存
		$o .= "$subline";
		$o .= "$submark$subcount:";		
		$subcount++;
		$o .= "$sub1$p$sub2";
	} elsif ($cmd eq "LSUB" && $p =~ /(\S+)\s(.+)/) { # LSUB url hogehoge
		#$subtopic = $2; # searchで使うためにsubの中身を保存
		$o .= "$subline";
		$o .= "$submark$subcount:";
		$subcount++;
		$o .= &make_link($1);
		$o .= "$sub1$2$sub2</a>";

	} elsif ($cmd eq "LINK" && $p =~ /(\S+)\s(.+)/) { # LINK url hogehoge
		$o .= &make_link($1);
		$o .= "$2</a>";
	} elsif ($cmd eq "URL" && $p =~ /(\S+)(\s(.+))?/) { # URL url hogehoge
		$o .= &make_link($1);
		$o .= "$3 ($1)</a>";
	} elsif ( $cmd eq "UL" or $cmd eq "/UL" or
		  $cmd eq "DL" or $cmd eq "/DL" or
		  $cmd eq "OL" or $cmd eq "/OL") {
		$cmd =~ tr/A-Z/a-z/;
		$o .= "<$cmd>";

	} elsif ( $cmd eq "/PRE") { # /PRE
		$premode = 0;
		$o .= "</pre>";
	} elsif ( $cmd eq "PRE") { # PRE
		if ($premode) {
			$o .= "$1";
		} else {
			$o .= "<pre>";
			$premode = 1;
		}

	} elsif ($cmd eq "CITE") {
		$o .= "<blockquote>\n";
	} elsif ($cmd eq "/CITE") {
		$o .= "</blockquote>\n";
	} elsif ($cmd eq "/BIG") {
		# do nothing
	} elsif ($cmd eq "/DIV") {
		# do nothing
	} elsif ($cmd eq "DIV") {
		#do nothing
	} elsif ($cmd eq "BIG" ) {
		# do nothing
	} elsif ($cmd eq "/SMALL") {
		# do nothing
	} elsif ($cmd eq "SMALL") {
		# do nothing
        } elsif ($cmd eq "LIMG" && $p =~ /(\S+)\s(\S+)\s(\S+)\s(.+)/) {
                # LIMG url {r|l|n} ファイル名 文字列
                $o .= "[LIMG $4]";
	} elsif ($cmd eq "LI") { # LI hoge
		$o .= "<li>$p";
	} elsif ($cmd eq "DT") { #DT hoge
		$o .= "<dt>$p";
        } elsif ($cmd eq "DD") { #DD hoge
	        $o .= "<dd>$p";
	} elsif ($cmd eq "STRIKE") { # STRIKE hoge
		$o .= "$strike$p$strike2";
	} elsif ($cmd eq "LSTRIKE" && $p =~ /(\S+)\s(.*)/) { # LSTRIKE url hoge
		$o .= $strike;
		$o .= &make_link($1);
		$o .= "$2</a>$strike2";
	} elsif ($cmd eq "STRONG") { # STRONG hoge
		$o .= "$strong$p$strong2";
	} elsif ($cmd eq "LSTRONG" && $p =~ /(\S+)\s(.*)/) { #LSTRONG url hoge
		$o .= $strong;
		$o .= &make_link($1);
		$0 .= "$2</a>$strong2";
	} elsif ($cmd eq "SPAN" && $p =~ /(\S+)\s(.*)/) { #SPAN classname hoge
		$o .= $2;
	} elsif ($cmd eq "FONT" && $p =~ /(\S+)\s(\S+)\s(.+)/) { # FONT para value hoge
		$o .= "<font $1=\"$2\">$3</font>";

	} elsif ($cmd eq "IMG" && $p =~ /(\S+)\s(\S+)\s(.+)/) { # IMG para url alt
		if ($1 eq "r") {
			$aln = "align=\"right\"";
		} elsif ($1 eq "l") {
			$aln = "align=\"left\"";
		} elsif ($1 eq "n") {
			$aln = "";
		}
		#$o .= "<img src=\"$2\" $aln ALT=\"$3\"$1=\"$2\">$3</img>\n"; (23:22)
		#iMODEなので基本的に画像は表示しません
		$o .= "[IMG $3]";
	} elsif ( $t =~ /^!(.*)/) { # ! hoge
		#$o .= "<!-- $1 -->\n"; 別に表示しなくてもいいよね
	} elsif ( $t =~ /^!#(.*)/) { # !# hoge
	} elsif ($cmd eq "FN") { # FN
		$fnmode = 1;
		$o .= "<font size=\"-1\" color=GREEN>(";
	} elsif ($cmd eq "/FN") { # /FN
		$fnmode = 0;
		$fncount++;
		$o .= ")</font>\n";
	} elsif ($cmd eq "ALIAS") { # ALIAS 未対応だった!!
		#暫定的にalias文字列を出しておく
		#$o .= "$p";
		$orig = $p;
		open(ALIAS, "$diarydir" ."conf/alias.txt");
		while($a = <ALIAS>) {
			$a =~ /^(\S+)\s(.*)/;
			#print "$a,$1<br>";
			if ( $1 eq $orig ) { # 一致したら
				$o .= "$2";
			}
		}
		close(ALIAS);
	} elsif ($cmd eq "RLINK" && $p =~ /(.+)\s(.+)\s(.+)/ ) { # RLINK 引数1 引数2 説明文章
		$orig = $1;
		$url = $2;
		$cmt = $3;
		open(RLINK, "$diarydir" . "conf/rlink.txt");
		while($a = <RLINK>) {
			$a =~ /^(\S+)\s(.*)/;
			if ( $1 eq $orig ) { # 一致したら
				$url = $2 . $url;
				$o .= &make_link($url);
				$0 .= "$cmt</a>";
			}
		}
		close(RLINK);
	} elsif ($cmd eq "MARK") { #MARKコマンド実装し忘れ
		$o .= $p;
	} elsif ($cmd eq "P") { # P
		$o .= "<p>";
	} elsif ($cmd eq "/P") { # /P
		$o .= "</p>";
	} else {
		    $o .= $t;
	}
	return $o;
}

#タイトル一覧を表示する
sub title {
	#$out .= "<ol>\n";
	my $ok;
	my $uv, @sect;
	while(<IN>) {
		chomp;
		s/\r$//;   #CR+LF to LF
		$_ = convert2euc($_) if ($hnfconv and $nkf);
		if (!$ok) { # header
			if (/^OK$/) { #header識別
				$ok = 1;
				$out .= $uv;
				next;
			}
			if (/^(\S+)\s+(\S.*)/) {
				my $var = $1;
				if ($UserVarAlias{$var}) {
					$var = $UserVarAlias{$var};
				}
				my $v = $UserVarTemplates{$var};
				my $value = $2;
				if ($v ne '' && $catprint) {
					$v =~ s/%value/$value/e;
					$uv .= $v;
				}
			}
			next;
		}
		if (/^GRP/) { # GRP機能 kenji-3
			$grp = 1; # grp mode on
		}

		if (/^NEW()$/ or /^NEW\s(.+)/ or /^LNEW\s\S+\s(.+)/ or /^RLNEW\s\S+\s\S+\s(.+)/){
			if ($grp == 1) {
				# GRPの内部は非表示にする
				$grp = 2;
			} elsif ($grp == 2) {
				$grp = 0;
			}

			$newcount++ unless ($grp);
			#$out .= "<br>\n";
			$sect[$newcount] .= "<br>\n" unless ($grp);
			$uri = $day . "S$newcount";
			my $t = &html_escape($1);
			if ($t eq "") {
				$t = "_";
			}
			#$out .= "$newmark$newcount:$new1" . make_self_link("?$uri") . "$t</a>$new2\n" unless ($grp);
			$sect[$newcount] .= "$newmark$newcount:$new1" . make_self_link("?$uri") . "$t</a>$new2\n" unless ($grp);
			# listingをやめた
		} elsif (/^SUB()$/ or /^SUB\s(.+)/ or /^LSUB\s\S+\s(.+)/  or /^RLSUB\s\S+\s\S+\s(.+)/) {
			my $t = &html_escape($1);
			if ($t eq "") {
				$t = "_";
			}
			#$out .= "$t$sub_separator\n" unless ($grp);
			$sect[$newcount] .=  "$sub_separator$t\n" unless ($grp);
		}
	}

if ($titlereverse) {
	for( $xx = $newcount; $xx >=0; $xx--) {
		$out .= $sect[$xx];
	}
} else {
	for($xx = 0; $xx <= $newcount; $xx++) {
		$out .= $sect[$xx];
	}
}

$out .= "<hr>\n";
	if ($prevday) {
		$out .= make_self_link("?$prevday", "1") . "[前の日]</a>";
	}
	if ($nextday) {
		$out .= make_self_link("?$nextday", "3") . "[次の日]</a>";
	}
	$up = "?$day" . "P";
	$ut = "?$day" . "T";

	$out .= make_self_link("?J", "5") . "[日付移動]</a>\n";

	$out .= make_self_link("$up", "4") . "[予定]</a>\n";
	$out .= make_self_link("$ut", "6") . "[TODO]</a>\n";
	$out .= make_self_link("?E", "8") . "[検索]</a>\n"; #(5)
	$out .= make_self_link("?${day}SALL") . "[全部]</a>\n" unless ($imode);
		#iMODEでは「全部」表示はしない(表示できないから)
	$out .= make_self_link("http://yar-3.net/mi/","0") . "[みお]</a>\n";

	$out .= "<br><a href=$isystem>i system</a> ver $ver<br>\n";
}

# 予定を表示する
sub planprint { 
	my %abc = (A => 10.5, B => 20.5, C => 31.5,
		   a => 10.5, b => 20.5, c => 31.5);
	my %abcString = (A => '上', B => '中', C => '下',
			 a => '上', b => '中', c => '下');
	my %dowNum = ('sun', 0, 'mon', 1, 'tue', 2, 'wed', 3,
		      'thu', 4, 'fri', 5, 'sat', 6,
	              'su',  0, 'mo',  1, 'tu',  2, 'we', 3,
		      'th',  4, 'fr',  5, 'sa',  6,
		      '日', 0, '月', 1, '火', 2, '水', 3,
		      '木', 4, '金', 5, '土', 6);
	my @pp, @p, @repeats;
	local (*PLAN);

	$out .= "[予定]<br>\n";

	# 繰り返し予定を読み込む
	my $planf = $diarydir . "repeat";
	open(PLAN, $planf);
	while(<PLAN>) {
		$_ = convert2euc($_) if ($hnfconv and $nkf);
		s/\r$//;
		chomp;
		next if /^\s*#/;	# コメント行
		next if /^\s*$/;	# 空行も欲しいよね
		if (/^([^\[\s]+)(?:\[([^\]]+)\])?\s+(.*)$/) {
			my @range = parse_range($2);
			push(@repeats, [$1, $3, @range]);	# [dp dsec begin end]
		} elsif (/^\[([^\]]+)\]\s+(.*)$/) {
			my @range = parse_range($1);
			push(@repeats, ['', $2, @range]);	# ['' dsec begin end] 範囲付き毎日予定
		}
	}
	close PLAN;

	# 今月と来月の２か月の予定を処理
	my ($ly, $lm) = ($year, $mon);
	for (1 .. 2) {
		my $me = &month_days($ly, $lm);

		# 各月の予定
		# 予定ファイル名作成 /home/hoge/diary/1999/y199902
		$planf = "$diarydir$ly/y$ly$lm";
		open(PLAN, $planf);
		while(<PLAN>) {
			$_ = convert2euc($_) if ($hnfconv and $nkf);
			s/\r$//;
			chomp;
			my $d, $dd, $m;
			if (/^((\d+)\/)?(\d+)\s/) {
				# 18 デート あるいは 2/18 結婚式 など ari-3
				# 配列に格納する形式は ["19991231" "1999/12/31 ほげ"]
				$m = $2;
				$d = $3;
				#$d = "0" . $d if ($d < 10);
				$d = substr("0" . $d, -2);
				$dd = $d;
			} elsif (/^((\d+)\/)?([abcABC])\s/) {
				# A デート あるいは 2/A 結婚式 など
				# 配列に格納する形式は ["19991210.5" "1999/12/A ほげ"]
				$m = $2;
				$d = $abc{$3};
				$dd = $3;
			}
			$m = $lm if ($m == 0);
			if ($d && $m == $lm) {
				push(@pp, ["$ly$lm$d", "$ly/$lm/$dd $'"]);
			}
		}
		close PLAN;
	
		# 繰り返し予定
		foreach my $rplan (@repeats) {
			my ($dp, $desc, $brng, $erng) = @$rplan;
			my $m = $lm;
			my $dd = '';
			my $d;
			if (@$rplan == 4 && $dp ne ''
			 && ((sprintf("%04d%02d%02d", $ly, $lm, $me) < $brng)
			  || (sprintf("%04d%02d%02d", $ly, $lm, 1) > $erng))) {
				next;
			}
			if ($dp =~ m!^(\d+)/(\d+)$!) {  # 毎年指定月日
				$m = $1;
				$d = $2;
			} elsif ($dp =~ m!^(\d+)/(-?\d+)([^\d].*)$!) { # 毎年指定月第n曜日
				my $dow = $3;
				$dow =~ tr/A-Z/a-z/;
				if ($dowNum{$dow} eq '') {
					$d = 0;
					$dd = $dp . '?'
				} else {
					$m = $1;
					$d = &get_nth_dow($ly, $lm, $2, $dowNum{$dow});
				}
			} elsif ($dp =~ m!^(\d+)/([abcABC])$!) { # 毎年指定月旬
				$m = $1;
				$d = $abc{$2};
				$dd = $2;
			} elsif ($dp=~ /^\d+$/) { # 毎月指定日
				$d = $dp;
			} elsif ($dp =~ /^[Ee]?(-\d+)?$/ && $dp ne '') { # 毎月E(月末) 予定
				$d = $1;
				$d = $me + $1; 
			} elsif ($dp =~ /^(-?\d+)([^\d].+)$/) { # 毎月第n曜日
				my $dow = $2;
				$dow =~ tr/A-Z/a-z/;
				if ($dowNum{$dow} eq '') {
					$d = 0;
					$dd = $dp . '?'
				} else {
					$d = &get_nth_dow($ly, $lm, $1, $dowNum{$dow});
					$d = 0 if ($d < 0 || $d > $me);
				}
			} elsif ($dp =~ /^[abcABC]$/) { # 毎月指定旬
				$d = $abc{$dp};
				$dd = $2;
			} else {
				my $dow = $dp;
				$dow =~ tr/A-Z/a-z/;
				if ($dowNum{$dow} ne '') { # 毎週指定曜日
					# 複数pushする必要があるので自前で処理
					for (my $i = 1; $i <= 5; $i++) {
						$d = &get_nth_dow($ly, $lm, $i, $dowNum{$dp});
						my $s = sprintf("%04d%02d%02d", $ly, $lm, $d);
						if ($d >= 1 && $d <= $me 
						 && (@$rplan == 2 || ($s >= $brng && $s <= $erng))) {
							$d = sprintf("%02d", $d);
							push(@pp, [$s, "$ly/$lm/$d $desc"]);
						}
					}
					# あとは知らん顔:-)
					$d = 0;
				} elsif (@$rplan == 4 && $dp eq '') {	# 範囲付き毎日
					for (my $i = 1; $i <= $me; $i++) {
						my $s = sprintf("%04d%02d%02d", $ly, $lm, $i);
						if ($s >= $brng && $s <= $erng) {
							$d = sprintf("%02d", $i);
							push(@pp, [$s, "$ly/$lm/$d $desc"]);
						}
					}
					# あとは知らん顔:-)
					$d = 0;
				} else { # otherwise
					$d = 32;
					$dd = $dp . '?'
				}
			}
			$m = sprintf("%02d", $m) if ($m ne '');
			if ($d && $m == $lm) {
				my $s = sprintf("%04d%02d%02d", $ly, $m, $d);
				if ((@$rplan == 2) || ($s >= $brng) && ($s <= $erng)) {
					#$d =  "0$d" if ($d < 10);
					$d = substr("0". $d, -2);
					$dd = $d if ($dd eq '');
					push(@pp, [$s, "$ly/$m/$dd $desc"]);
				}
			}
		}

		($ly, $lm) = &next_month($ly, $lm);
	}

#print "** pp start **\n", join("\n", map("$_->[0], $_->[1]", @pp)), "\n** pp end **\n";

	#今月の今日以降のものだけ取り出してソート
	my $today = "$year$mon$mday";
	@p = sort { $a->[0] <=> $b->[0] ||
	    $a->[1] cmp $b->[1] } grep($_->[0] >= $today, @pp);
	#@p = sort { $a->[0] <=> $b->[0] } grep($_->[0] >= $today, @pp);
	if (!$maxplan) {
		$maxplan = 10; # 未定義時の最大数は10こ	
	}
	if ($#p < $maxplan) { # 少ないとき
		$maxplan = $#p + 1;
	}

	for ($i = 0 ; $i < $maxplan ; $i++){
		if ($p[$i]->[1] =~ /^(\d\d\d\d\/\d\d\/\d\d)\s/) {
			$d = $1;
			$d =~ /\d\d\d\d\/(\d\d)\/(\d\d)/;
			$mm = $1; $dd = $2;
			$d = "$mm/$dd(" . &getdayoftheweek($d) . ")";
		} elsif ($p[$i]->[1] =~ /^\d\d\d\d\/(\d\d\/)([abcABC])\s/) {
			$d = $1 . $abcString{$2};
			$d = "$d   ";
		} elsif ($p[$i]->[1] =~ /^\d\d\d\d\/(\d\d)\s/) {
			$d = "$1   ";
		} else {
			$d = "??";
		}
		$a = $';
#print $1;
		$out .= "・$d $a<br>\n"; # ここでplanの見た目を変更可能
	}
	$out .= "<hr>\n";
	#LINK表示
	&ichiran;
}

#曜日を取得!
sub getdayoftheweek {
	my ($y, $m, $d) = ($_[0] =~ /(\d\d\d\d)\/(\d\d)\/(\d\d)/);
#	return "$m/$d(" . $week[&get_dow($y,$m,$d)] . ")";
	return $week[&get_dow($y,$m,$d)];
}

#曜日を取得(0:日, 1:月, ..., 6:土)
sub get_dow {
	# hnsのDate.pmを参考に書き換えました
	# これでtimelocal()を使わずにすみますヨ。
	my ($y, $m, $d) = @_;
	$y = $y + 399 if ($m < 3);
	($y + int($y/4) - int($y/100) + int($y/400) +
	 (0, 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4)[$m] + $d
	) % 7;
}

#指定年月の第$n$dow曜日($n<0なら月末から数える, $n=-1なら最終)
sub get_nth_dow {
	my ($y, $m, $n, $dow) = @_;
#print "get_nth_dow: y=$y, m=$m, n=$n, dow=$dow\n";
	my $days = &month_days($y, $m);
	my $d;
	if ($n > 0) {
		my $first = &get_dow($y, $m, 1);
		if ($dow >= $first) {
			$d = ($n-1)*7 + $dow - $first + 1;
		} else {
			$d = $n*7 + $dow - $first + 1;
		}
	} elsif($n < 0) {
		my $last = &get_dow($y, $m, $days);
		if ($dow <= $last) {
			$d = $days - ($last - $dow) + ($n+1)*7;
		} else {
			$d = $days - ($last - $dow) + $n*7;
		}
	}
	if ($d < 1 || $d > $days) {
		return 0;
	}
	return $d;
}

# repeatの範囲指定をparseする
# 戻り値: ()                       : 範囲指定なし
#         ('yyyymmdd', 'yyyymmdd') : 範囲の最初と最後の日
sub parse_range($) {
	my ($spec) = @_;
	my @ba = (0, 1, 1);
	my @ea = (9999, 12, 31);
	return () if ($spec eq '');
	if ($spec =~ /^([^-]*)-(.*)$/) {
		my ($b, $e) = ($1, $2);
		if ($b eq '') {
#			@ba = (0, 1, 1);
		} elsif ($b =~ /^\d{4}$/) {
			@ba = ($b, 1, 1);
		} elsif ($b =~ m!^(\d{4})/(\d+)$!) {
			@ba = ($1, $2, 1);
		} elsif ($b =~ m!^(\d{4})/(\d+)/(\d+)$!) {
			@ba = ($1, $2, $3);
		}
		if ($e eq '') {
#			@ea = (9999, 12, 31);
		} elsif ($e =~ /^\d{4}$/) {
			@ea = ($e, 12, 31);
		} elsif ($e =~ m!^(\d{4})/(\d+)$!) {
#			my $dmonth = &month_days($1, $2);
#			@ea = ($1, $2, $dmonth);
			@ea = ($1, $2, 31);
		} elsif ($e =~ m!^(\d{4})/(\d+)/(\d+)$!) {
			@ea = ($1, $2, $3);
		}
	} else {
		# illegal format
	}
	return (sprintf("%04d%02d%02d", @ba), sprintf("%04d%02d%02d", @ea));
}

# TODOを表示する
sub todoprint {
	my (@num);
	$out .= "[TODO]<br>\n";
	open(TODO, $todof);
	while(<TODO>) {
		$_ = convert2euc($_) if ($hnfconv and $nkf);
		if (/^(\d+)\s/) { # 99 日記を続ける など
			push(@num, [$1, $']); # 無名配列[得点, 内容]を入れる
		}
	}
	close TODO;

	# 得点をキーにして昇順でソート
	@num =	sort { $b->[0] <=> $a->[0] } @num;
	
	if (!$maxtodo) {
		$maxtodo = 10; # 未定義時の最大数は10こ	
	}
	if ($#num < $maxtodo) { # 少ないとき
		$maxtodo = $#num + 1;
	}

	for ($i = 0 ; $i < $maxtodo ; $i++){
		$out .= "#$num[$i]->[0] $num[$i]->[1]<br>\n"; #ここでTODOの見た目を変更可能
	}
	$out .= "<hr>\n";
	#LINK表示
	&ichiran;
}

#[前][次]ってやつね
sub section_jump {
	if ($section > 1) { # 前のセクションが存在
		$sec = $section - 1;
		$u = "?$day" . "S$sec";
		$out .= make_self_link("$u", "1") . "[前]</a>";
	}
	if ($newcount > $section) { # 後のセクションが存在
		$sec = $section + 1;
		$u = "?$day" . "S$sec"; 
		$out .= make_self_link("$u", "3") . "[次]</a>";
	}
	#一覧
	&ichiran;
}

#日付移動
sub print_jump_form {
if (!$use_onccnv) {
	$out .= "content-type: text/html\n\n";
}
$out .= "<html><head>\n";
$out .= "<!-- や -->\n" if (!$nkf);
$out .= "</head>\n";
$out .= "<title>i system jump</title>\n";
$out .= "<body>\n";
$out .= "<b>i system jump</b><p>\n";
$out .= "任意の日付にジャンプします。<br>\n";
$out .= "3.を押すか、ボタンを押して下さい。<br>\n";

	if ($baseuri && $ezweb) { #ezweb対策 ari-3
		$out .= qq(<form method="GET" action="$baseuri">\n);
	} else {
		$out .= qq(<form method="GET" action="./">\n);
	}

	$out .= qq(<input type="text" name="d" value="$today" size=10 maxsize="8" istyle="4">\n); # istyle is 502 tag
	$out .= qq(<input type="submit" name="g" value="" accesskey="3">\n);
    $out .= "</form>\n";

$out .= "「19990801」のように8桁の数字で指定して下さい。\n";
$out .= "<br>\n";
$out .= "</body></html>\n";


$out = &conv_html2onc($out, $baseuri, $baseuri, $ref_max, $flag_maru) if $use_onccnv;
$out = &convert2sjis($out) if $nkf; 	#NKF,jcode.pl使用時はsjis変換
print $out;
}

#検索フォームを表示
sub print_search_form {
if (!$use_onccnv) {
	$out .= "content-type: text/html\n\n";
}
$out .= "<html><head>\n";
$out .= "<!-- や -->\n" if (!$nkf);
$out .= "</head>\n";
$out .= "<title>i search system</title>\n";
$out .= "<body>\n";
$out .= "<b>i search system</b><br>\n";
$out .= "任意の単語を検索します。<br>\n";

	if ($baseuri) {
		$out .= qq(<form method="GET" action="$baseuri">\n);
	} else {
		$out .= qq(<form method="GET" action="./">\n);
	}

	$out .= qq(<input type="text" name="word" size=16>\n);
	$out .= qq(<input type="submit" name="g" value="" accesskey="3">\n);
    $out .= "</form>\n";

$out .= "単語を入力して\n";
$out .= "3.を押すか、ボタンを押して下さい。<br>\n";

$out .= "<br>\n";
$out .= "正規表現も使えます\n";
$out .= "</body></html>\n";

$out = &conv_html2onc($out, $baseuri, $baseuri, $ref_max, $flag_maru) if $use_onccnv;
$out = &convert2sjis($out) if $nkf; 	#NKF,jcode.pl使用時はsjis変換
print $out;
}

#
# log取得
#
sub logging {
# logging subroutine is based on
# tohoho wwwwcounter
# http://wakusei.cplaza.ne.jp/twn/wwwcount.htm
# thanks 2 tohoho

# server setup
#
# $ mkdir lock
# $ touch isystem.cnt
# $ touch isystem.dat
# $ touch isystem.acc
# $ chmod 777 lock
# $ chmod 666 isystem.*

# from 0.6.8
my $logdir, $count_name, $file_count, $file_date, $file_access, $file_lock;

$logdir = $diarydir . "log/"; #hnsの場合はこれでOKのはず

$count_name = "isystem";
$file_count  = $logdir . "$count_name" . ".cnt";
$file_date   = $logdir . "$count_name" . ".dat";
$file_access = $logdir . "$count_name" . ".acc";
# tnx 2 chihalin-3
$file_lock   = $logdir . "lock/isystem.loc";
 

#
# 環境変数TZを日本時間に設定する
#
$ENV{'TZ'} = "JST-9";

#
# ロック権を得る
#
if ($do_file_lock) {
	foreach $i ( 1, 2, 3, 4, 5, 6 ) {
		if (mkdir("$file_lock", 0755)) {
			# ロック成功。次の処理へ。
			last;
		} elsif ($i == 1) {
			# 10分以上古いロックファイルは削除する。
			($mtime) = (stat($file_lock))[9];
			if ($mtime < time() - 600) {
				rmdir($file_lock);
			}
		} elsif ($i < 6) {
			# ロック失敗。1秒待って再トライ。
			sleep(1);
		} else {
			# 何度やってもロック失敗。あきらめる。
			exit(1);
		}
	}
}

#
# 途中で終了してもロックファイルが残らないようにする
#
$SIG{'PIPE'} = $SIG{'INT'} = $SIG{'HUP'} = $SIG{'QUIT'} = $SIG{'TERM'} = "sigexit";

#
# カウンターファイルからカウンター値を読み出す。
#
if (open(IN, "< $file_count")) {
	$count = <IN>;
	close(IN);
} else {
	$count = -1;
}

#print "count=$count\n";
#
# 日付ファイルから最終アクセス日付を読み出す。
#
if (open(IN, "< $file_date")) {
	$date_log = <IN>;
	close(IN);
} else {
	$date_log = "";
}

#
# 今日の日付を得る
#
($sec, $min, $hour, $mday, $mon, $year) = localtime(time());
$date_now = sprintf("%04d/%02d/%02d", 1900 + $year, $mon + 1, $mday);
$time_now = sprintf("%02d:%02d:%02d", $hour, $min, $sec);
#print "$time_now\n";

#
# 日付が異なる、つまり、今日初めてのアクセスであれば
#
if ($date_log ne $date_now) {
#print "mail log\n";

	#
	# アクセスログをメールで送信する
	#
	if ($mailto ne "") {
		$tmp_count = 0;
		open(IN, "< $file_access");
		while (<IN>) {
			if (/^COUNT/) {
				$tmp_count++;
			}
		}
		close(IN);
		$msg = "";
		$msg .= "To: $mailto\n";
		$msg .= "From: $count_name\n";
		$msg .= "Subject: ACCESS $date_log $tmp_count\n";
		$msg .= "\n";
		if ($account_detail) {
			open(IN, "< $file_access");
			while (<IN>) {
				$msg .= $_;
			}
			close(IN);
		} else {
			$msg .= "Access = $tmp_count\n";
		}
		open(OUT, "| $sendmail $mailto");
		print OUT $msg;
		close(OUT);
	}

	#
	# アクセスログを初期化する
	#
	open(OUT, "> $file_access");
	close(OUT);

	#
	# 今日の日付を日付ログファイルに書き出す
	#
	open(OUT, "> $file_date");
	print(OUT "$date_now");
	close(OUT);
}
#
# カウントアップ処理
#
#print "count up mae\n";
if ($count >= 0) {
#print "count up\n";

	#
	# カウンタをひとつインクリメントする
	#
	$count++;

	#
	# %7E や \~ などを処理する
	#
	$referer = $ENV{'HTTP_REFERER'};
	$referer =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("C", hex($1))/eg;
	$reffile =~ s/\\//g;

	#
	# アクセスログを記録する
	#
	open(OUT, ">> $file_access");
	print(OUT "COUNT = [ $count ]\n");
	print(OUT "TIME  = [ $time_now ]\n");
	#print(OUT "ADDR  = [ $ENV{'REMOTE_ADDR'} ]\n");
	#if ($ENV{'REMOTE_HOST'} ne $ENV{'REMOTE_ADDR'}) {
		print(OUT "HOST  = [ $ENV{'REMOTE_HOST'} ]\n");
	#}
	print(OUT "AGENT = [ $ENV{'HTTP_USER_AGENT'} ]\n");
	# print(OUT "REFER = [ $referer ]\n");
	if ($reffile && (!$my_url || ($reffile !~ /$my_url/))) {
		print(OUT "FROM  = [ $reffile ]\n");
	}
	print(OUT "\n");
	close(OUT);

	#
	# カウンタをカウンタファイルに書き戻す
	#
	if (open(OUT, "> $file_count")) {
		print(OUT "$count");
		close(OUT);
	}
}
#
# ロック権を開放する
#
if ($do_file_lock) {
	rmdir($file_lock);
}



}

# log用 lockfile削除ルーチン
sub sigexit { rmdir($file_lock); exit(0); }


#検索しまくり
sub search_word { # 検索
	my ($word) = @_; #検索語
	my $hitcount = 0; #hit数
	my $bgncount = $FORM{b};	# 今回の表示開始件数
	my $totalhit = $FORM{h};	# 前回検索時に判明した総Hit数
	my $bgnday = $FORM{t};		# 前回検索時の最終日
	my $bgnhit = $FORM{th};		# 前回検索時の最終日までのヒット数

	if (!$use_onccnv) {
		$out .= "content-type: text/html\n\n"; #apache対策? ari-3
	}
	$out .= "<html><head>\n";
	$out .= "<!-- や -->\n" if (!$nkf);
	$out .= "</head>\n";
	$out .= "<title>result</title>\n";
	$out .= "<body>\n";
	$out .= "<b>検索結果</b><br>\n";

	$word = convert2euc($word) if ($nkf); # EUCに変換する
	#あれ？jcode.plを使ってないときはどうするんだろう????

#	print $word;
 
	# ファイルをpick up masato-3
	my @a;
	for my $y ($year-1..$year) {	# 今年と去年の日記が対象
		opendir DIR, "$diarydir$y" || next;
		push(@a, (sort grep s/^(d\d+\.hnf)$/$diarydir$y\/$1/, readdir DIR));
		closedir DIR;
	}
	@a = sort { $b cmp $a } @a;	# 並び替え(降順)
	#これで、最新のhnfから順に並んでいるはず。

	if (!$maxday) {
		$maxday = 60;	  #デフォルトで最大60日を検索
	}
	if ($#a < $maxday) {	  #少ないとき
		$maxday = $#a + 1;
	}
	@a = @a[0 .. $maxday-1];  #検索日数分だけにする
	if (!$maxresult) {	  #デフォルトで10件ずつ表示
		$maxresult = 10;
	}

	if ($bgnday ne '') {	# 前回検索時に既に検索した日は飛ばす
		my $f;
	    while ($f = shift(@a)) {
			if (($f =~ /d(\d{8})\.hnf/) && ($1 le $bgnday)) {
				unshift(@a, $f);
				last;
			}
		}
	    $hitcount = $bgnhit;	# ヒット数を調整(^^)
	}

	my $day;
	my $day2;
	my $lastdday;
	my $lastdhit;
	SEARCH: foreach my $f (@a) {
	  $ok = 0; #ユーザ変数を検索しないように初期化
	  $newcount = 0;
	  $subcount = 0;
	  if ($f =~ /d(\d{8})\.hnf/) {
		$day = $day2 = $1; 
	  } else {
	    next;
	  }
	  $day2 =~ s/(\d\d\d\d)(\d\d)(\d\d)/$1\/$2\/$3/;
	  open(IN, $f); # 最新のファイルから順に開く
	  while(<IN>) {
	    $_ = convert2euc($_) if ($hnfconv and $nkf);
	    s/\r$//;
	    chomp;			 # 改行除去
	    $o = &parse($_); # 解析
	    next if ($o !~ /$word/i); #一致しないので次の行
	    #$out .= $o; # for debug
	    $u = "?$day" . "S" . "$newcount";
	    next if ($u eq $lastu); #先ほどのurl(NEW,SUB)と同じなのでトバス

	    if ($bgncount <= $hitcount && $hitcount < $bgncount+$maxresult) {
	      #$out .= "・<a href=$u>$day2:$newtopic:$subtopic</a> \n";
	      $out .= "・" . make_self_link("$u") . "$day2:$newcount:$subcount</a> \n";
	      s/($word)/<b>$1<\/b>/ig;
	      s/^(LNEW|LSUB|LSTRIKE|LSTRONG|LINK|URL|RLNEW|RLSUB)\s\S+//; 
	      # LNEW, LSUB, LSTRIKE, LSTRONG なんかのuriを削除しまくる
	      s/^[A-Z]+\s//; # hnfコマンドを除去する
	      s/~$//;		 # 改行の'~'を除去
	      $out .= "$_<br>\n";
	      $lastvc = $hitcount;
		  if ($lastdday ne $day) {
		    $lastdhit = $hitcount;
		  }
		  $lastdday = $day;
	    }
	    $lastu = $u;
	    $lastc = $hitcount;
	    $hitcount++;
		if ($totalhit && ($hitcount >= $maxresult+$bgncount)) {
		  # 一度に表示できる件数に達したので総ヒット数を
		  # 前回検索時に得た総ヒット数に置換えてヤメ
		  $hitcount = $totalhit;
	      last SEARCH;
		}
	  }
	  close(IN);
	}

	$out .= sprintf("<hr>$hitcount件中(%d〜%d)<br>\n", $bgncount+1, $lastvc+1);

	# 前の$maxresult件
	if ($bgncount >= $maxresult) {
	  $u = sprintf("?word=%s&b=%d&h=%d", $origword, $bgncount-$maxresult, $hitcount);
	  $out .= make_self_link("$u", "1") . "[前$maxresult件]</a>\n";
	}
	# 一覧
	&ichiran;
	# 次の$maxresult件
	if ($bgncount < $hitcount - $maxresult) {
#	  $u = sprintf("?word=%s&b=%d&h=%d", $origword, $bgncount+$maxresult, $hitcount);
	  $u = sprintf("?word=%s&b=%d&h=%d&t=%s&th=%d", $origword, $bgncount+$maxresult, $hitcount, $lastdday, $lastdhit);
	  # URIとして渡すwordはURL encodeされていなくてはならない!
	  $out .= make_self_link("$u", "3") . "[次$maxresult件]</a>\n";
	}
	$out .= "</body></html>\n";

	$out = &conv_html2onc($out, $baseuri, $baseuri, $ref_max, $flag_maru) if $use_onccnv;
	$out = &convert2sjis($out) if $nkf; 	#NKF,jcode.pl使用時はsjis変換
	print $out;

}

#[一覧]を表示する
sub ichiran {
	$u = "?$day";
	$out .= make_self_link("$u", "2") . "[一覧]</a>\n";
}

# HTML中でエスケープする文字の変換
sub html_escape {
	my ($t) = @_;
	my %cv = ('&' => '&amp;', '"' => '&quot;',
		  '<' => '&lt;',  '>' => '&gt;');
	$t =~ s/([&<>"])/$cv{$1}||$1/ge;
	$t;
}

# HTML中でエスケープする文字を全角文字に変換
sub html_escape_zen {
	my ($t) = @_;
	my %zcv = ('&' => '＆', '"' => '”',
		   '<' => '＜', '>' => '＞');
	$t =~ s/([&<>"])/$zcv{$1}||$1/ge;
	$t;
}

# 漢字コードをEUCに変換
sub convert2euc {
	my ($tmp) = @_;
	if ($nkf == 1) {
		$tmp = nkf('-e', $tmp);
	} elsif ($nkf == 2) {
		jcode::convert(\$tmp, "euc");
	}
	$tmp;
}

# 漢字コードをShift JISに変換
sub convert2sjis {
	my ($tmp) = @_;
	if ($nkf == 1) {
		$tmp = nkf('-s', $tmp);
	} elsif ($nkf == 2) {
		jcode::convert(\$tmp, "sjis");
	}
	$tmp;
}

# 指定年月の日数
sub month_days {
	# hnsのDate.pmを参考に書き直し
	my ($y, $m) = @_;
	my @days = (0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
	if ($m == 2 && (($y%4==0 && $y%100) || ($y==400))) {
		return 29;
	} else {
		return $days[$m];
	}
}

# 翌月
sub next_month {
	my ($y, $m) = @_;
	$m++;
	if ($m > 12) {
		$m = 1;
		$y++;
	}
	$m = sprintf("%02d", $m);
	return ($y, $m);
}

# hnfファイルのフルパス名を作る
sub make_hnf_fname {
	my ($f) = @_;	
    my ($day, $year);
	if ($f =~ /d((\d{4})\d\d\d\d)\.hnf/) {	# 引数は d19991231.hnf とか
		$day = $1;
		$year = $2;
	} elsif ($f =~ /^((\d{4})\d\d\d\d)$/) {	# 引数は 19991231 とか
		$day = $1;
		$year = $2;
	}
	return "$diarydir$year/d$day.hnf";
}

sub make_self_link {
	my ($u, $accesskey) = @_;
	# $accesskey = 0 に対応 (00/7/5 yar-3)
	my @IGraph = ("&#63888;", #0,1,2,3,..とならんでいる
		"&#63879;", "&#63880;", "&#63881;", "&#63882;",
	      "&#63883;", "&#63884;", "&#63885;", "&#63886;", "&#63887;");
	if ($imode) {
		if ($accesskey ne "") {
			qq(<a href="$u" accesskey="$accesskey">$IGraph[$accesskey]);
		} else {
			qq(<a href="$u">$imode_graphic);
		}
	} elsif ($ezweb && $baseuri) {
		qq(<a href="$baseuri$u">);
	} else {
		qq(<a href="$u">);
	}
}
sub make_link {
	my ($u) = @_;
# $imodegw を定義しておくと、それ経由でアクセスするようになる。

	qq(<a href="$imodegw$u">);
}

# hnfファイルにOKがあるかどうかチェック
sub has_ok {
	my ($file) = @_;
	local (*F);
	open (F, $file);
    while (<F>) {
		s/\r$//;
		chomp;
		if (/^OK$/ ) {
			close F;
			return 1;
		}
	}
	close F;
	return 0;
}


#<body>部をレンダリングする
sub make_body {
	$out .= "<body>\n";
	#print "day=$day\n";

	$imark = "";
	if ($imode) { #iMODE携帯でアクセスするとiMODE markがでる
		$imark = "&#63862;"; #iMODE mark
	} #ほかの環境でiMODE絵文字を表示すると文字化けします
	if (!$section) { # titleモードのときだけタイトルを表示
		if ($head eq ""){   # h1に要素を埋め込む
			$out .= "<h1>$imark$title</h1>\n";
		} else {
			$out .= "<h1>$imark$head</h1>\n";
		}
		$out .= "<hr>\n";
	}

	$out .= "$head\n" if ($pdx); #PmailDXの時は$headを表示
	$out .= "$header\n"; #文頭

	if ($section eq "ALL") { #全部系(C)tokumi-3 のとき
		$out .= &fileprint($confdir . $titleheadfile) if ($titleheadfile);
	} elsif ($section) { #セクション表示のときに
		$out .= &fileprint($confdir . $headfile) if ($headfile);
	} else { #タイトルモード
		$out .= &fileprint($confdir . $titleheadfile) if ($titleheadfile);
	}

	&make_diary_body; #日記本体をレンダリングする
	if ($piloweb and $piloweb_2days) { #pilowebでのアクセスでかつ２日表示
		$hnf = make_hnf_fname($prevday); #前の日記ファイルにする
		$day = $prevday;
		&make_diary_body;
	}
	
	if ($footfile ne ""){
		$path = $confdir . $footfile;
		$out .= &fileprint($path); #文末の何か
	}

	if ($address ne "") {
		$out .= "<br>" if $use_onccnv;
		$out .= "<address><a href=mailto:$address>$address</a></address>\n"; #メイルアドレス
	}
	$out .= "</body>\n";
}


sub make_diary_body {
	my $tmp, $i, @sect, $o;
	@sect = ();
	$newcount = 0;

	&dayprint; #日付を表示

	open(IN, $hnf); #当該hnfを開く
	$ok = 0; #ユーザ変数を表示しないように

	if ($section) { #いわゆるtitle表示ではない
		while($tmp = <IN>) {
			$tmp = convert2euc($tmp) if ($hnfconv and $nkf); #hnfがEUC以外で書かれている時
			$tmp =~ s/\r$//;
			chomp($tmp); #改行を落とす
			$o = &parse($tmp); #解釈する
			$sect[$newcount] .= "$o\n" unless ($grp);
		}
		if ($section eq "ALL") { # 全セクション表示
			if ($reverse) { #逆順
				for($i=$newcount; $i >=0; $i--) {
					$out .= "$sect[$i]\n";
				}
			} else { # 通常
				for($i=0; $i <=$newcount; $i++) {
					$out .= "$sect[$i]\n";
				}
			}
		} else { #特定セクションのみ
			$out .= "$sect[$section]\n";
		}
		# 表示終わり
		$out .= "<hr>\n"; #区切り
		&section_jump() if ($section ne "ALL"); #全部表示の時以外はjump先一覧を表示
	} else { # いわゆるtitle表示など
		if ($plan) {
			&planprint(); #予定
		} elsif ($todo) {
			&todoprint(); #TODO
		} else {
			&title(); #タイトル一覧
		}
	}
	close(IN);
}


# i system history
# yns(1999/9) > mns(1999/10) > mns for iMODE(2000/1) > i system(2000/2)
# yns: yar-3 nikki system
# mns: MIOMIO nikki system
#
# version up list
#                     with many users.......
# 2000/05/26 0.7.4 yar-3 fix list.cgi mode
# 2000/05/26 0.7.3 yar-3 fix SALL
# 2000/05/16 0.7.2 yar-3 show titleheadfile when SALL and piloweb
# 2000/05/16 0.7.1 masato-3 repeat plan with range
# 2000/05/15 0.7.0 yar-3 RIS reverse, piloweb_2days
# 2000/05/15 0.6.9 chihalin-3 fix NEW bug, no caption section
# 2000/05/12 0.6.8 yar-3 fix ichiran bug
# 2000/05/12 0.6.7 chihalin-3 maenohi bug fixed
# 2000/05/11 0.6.6 tagoh-3 title, color bug fixed
# 2000/05/10 0.6.5 tagoh-3 RLNEW,RLSUB problem fixed
# 2000/05/10 0.6.4 ari-3 TSUGI problem fixed
# 2000/04/23 0.6.3 yar-3 cat on/off
# 2000/04/10 0.6.2 yar-3 use istyle tag
# 2000/04/10 0.6.1 chihalin-3 patched
# 2000/04/10 0.6.0 masato-3 default day user var
# 2000/04/09 0.5.9 yar-3 fix color imode bug
# 2000/04/06 0.5.8 yar-3,masato-3 pilo ua, fix default day
# 2000/04/06 0.5.7 yar-3 default day, Piloweb(P option)
# 2000/03/31 0.5.6 yar-3 BIG
# 2000/03/30 0.5.5 yar-3,masato-3 small, plan sort
# 2000/03/28 0.5.4 yar-3 title modify
# 2000/03/28 0.5.3 yar-3 color iMODE
# 2000/03/27 0.5.2 yar-3 MARK cmd
# 2000/03/24 0.5.1 masato-3 repeat plan
# 2000/03/15 0.5   masato-3 new generation monthly, yearly
# 2000/03/13 0.4.13 yar-3,masato-3 yearly plan
# 2000/03/10 0.4.12 masato-3 fix monthly plan bug
# 2000/03/08 0.4.11 masato-3 fix monthly plan bug, modify getdayoftheweek
#                   month-end plan support
# 2000/03/06 0.4.10 yar-3 monthly plan
# 2000/03/06 0.4.9 masato-3 NKF.pm
# 2000/03/02 0.4.8 northeye-3,masato-3 quote, counter file, PDXGW
# 2000/03/01 0.4.7 yar-3 RLNEW,RLSUB support, faster search
# 2000/03/01 0.4.6 masato-3 many bugs fixed and add new functions
#                  onccnv.pl plan(ABC), &, glob, capital
# 2000/02/25 0.4.5 yar-3 fix user-var search bug
# 2000/02/24 0.4.4 chihalin-3 lock file fixed(logging)
# 2000/02/24 0.4.3 masato-3 patched(maxresult,fix LI,DT,DD etc)
#                  yar-3 fix <> bug, maxresult bug(url encode)
# 2000/02/23 0.4.2 masato-3 patched(smarten,plan bug,search print)
#                  yar-3 support {jis|sjis} hnf
# 2000/02/22 0.4.1 masato-3 patched(sort,todo,dayoftheweek)
# 2000/02/22 0.4.0 yar-3 brush up
# 2000/02/22 0.3.5 ari-3 patched
# 2000/02/21 0.3.4 yar-3 search bug fix(regexp etc...)
# 2000/02/21 0.3.3 yar-3 i search system
# 2000/02/21 0.3.2 yar-3 with jcode.pl
# 2000/02/18 0.3.1 yar-3 PLAN,TODO
# 2000/02/17 0.3.0 yar-3 ez logger
# 2000/02/17 0.2.9 yar-3 jump refined $baseuri set
# 2000/02/17 0.2.8 yar-3 P fixed
# 2000/02/15 0.2.7 yar-3 ALL sections show 
# 2000/02/15 0.2.6 ari-3 Lynx patched (SUB on title)
# 2000/02/15 0.2.5 yar-3 PDXGW(-H") patched
# 2000/02/15 0.2.4 key-3 iMODE char accesskey patched
# 2000/02/15 0.2.3 yar-3 RLINK
# 2000/02/15 0.2.2 yar-3 ALIAS problem fixed
# 2000/02/14 0.2.1 ari-3 patched (headfile, URL problem, SJIS)
# 2000/02/13 0.2.0 yar-3 (NEW fixed)
# 2000/02/13 0.1.7 key-3 patched (title,author, SUB problem)
# 2000/02/13 0.1.6 kenji-3 patched (GRP)
# 2000/02/13 0.1.5 masato-3 patched (without CGI.pm)
# 2000/02/04 by yar-3
# original 1999/10/06 by yar-3
#
#
# thanks 2 all users.
#                          1999,2000,2001 (C)yar-3 All rights reserved.






