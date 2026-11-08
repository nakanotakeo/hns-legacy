#!/usr/local/bin/perl
#
# list maker for i system and piloweb
# 
# 2000/05/26 0.2 yar-3 caption
# 2000/05/26 0.1 yar-3 work with i system 0.7.3

$ver = "0.2 00/5/24 by yar-3";

require './config.ph';

if ($ENV{'REQUEST_METHOD'} eq "POST") {
	read(STDIN, $query_string, $ENV{'CONTENT_LENGTH'});
} else {
	$query_string = $ENV{'QUERY_STRING'};
}
@a = split(/&/, $query_string);
foreach $a (@a) {
	($name, $value) = split(/=/, $a);
	$value =~ tr/+/ /;
	$value =~ s/%([0-9a-fA-F][0-9a-fA-F])/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
}

$tt = time;
($sec, $min, $hour, $mday, $mon, $year,
	$wday, $yday, $isdst) = localtime($tt);
$year += 1900;
$mon++;
if ($mon < 10 ) { $mon = "0$mon"; } #0suppress
if ($mday < 10 ) { $mday = "0$mday"; }
$today = "$year$mon$mday"; #19991231 format



# 引数
# startday 表示開始日
# endday 表示終了日
# direc 方向(0:昇順 1:降順)
# days 表示日数
$startday = $FORM{'startday'};
$endday = $FORM{'endday'};
$direc = $FORM{'direc'};
$days = $FORM{'days'};

if ($query_string eq "") { #引数なし
	&print_form; #設定用のformを表示
	exit 1;
}
if ($startday eq "" and $endday eq "" and $days ne "") { #最新を表示
	&print_list1;
	exit 1;
}


#
# sub routines
#
sub print_form {
	&html_header("i system list maker form"); #html header
print <<EOF;
<body>
<h1>i system list maker</h1>
<hr>
<ul>
<li>
最新n日分<br>
<form action="./list.cgi" method="get">
<input name="days" size=5 value="30">
日分
<select name="direc">
<option value="0">昇順
<option value="1">降順
</select>
<input type="submit" value="GO">
</form>
</ul>
EOF

	&html_footer;
}

sub print_list1 { #最新りすと
	my $d, $dd, $i, $j, @daylist;

        &html_header("[latest] i system list maker"); #html header
print <<EOF;
<body>
<h1>i system list maker</h1>
Latest $days days
<hr>
<ul>
EOF

	@daylist = reverse(&make_hnf_list);
	for ($i = 0 ; $i < $ days; $i++) {
		if ($direc == 1) {
			$j = $i;
		} else {
			$j = $days - $i - 1;
		}
		$daylist[$j] =~ /(\d{4})(\d{2})(\d{2})/;
		$d = "$1/$2/$3";
print <<EOF;
<li>
<a href="./?$daylist[$j]SALL">
$d
</a>
EOF
	}
print <<EOF;
<p>
<li>
<a href="./?$daylist[0]P">Plan</a>
<li>
<a href="./?$daylist[0]T">ToDo</a>
</ul>
EOF
	&html_footer;

}

sub html_header {
print <<EOF;
content-type: text/html

<html>
<head>
<title>
$_[0]
</title>
</head>
EOF
}


sub html_footer {
print <<EOF;
<hr>
i system
list maker for PiloWeb ver $ver
</body>
</html>
EOF
}

sub make_hnf_list {
#去年から来年までのhnfファイルのリストを作成する
foreach my $y ($year-1..$year+1) {
	opendir DIR, "$diarydir$y" || next;
	push(@ddays, (sort grep s/^d(\d+)\.hnf$/$1/, readdir DIR));
	closedir DIR;
}
return @ddays;
}

