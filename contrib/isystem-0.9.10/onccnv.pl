#
#	onccnv.pl --- HTML to ONCコンバータ
#
#	改造、再配布など煮るなり焼くなり好きにしてください。
#	by M.Kawakami <masato@orange.co.jp>
#
#	$Id: onccnv.pl,v 1.1 2000/07/02 07:58:33 yar-3 Exp $
#
#	ChangeLog:
#	  2.0β  HTML Parseを使わないで自前でどうにかする
#	  2.0.1  自分自身($gwurl)へのリンクをG/W機能を経由せずに処理する
#		ようにSELのリンクを修正

use Socket;

package ONCConv;
require Exporter;
@ISA	= qw(Exporter);
@EXPORT	= qw(paser);
@EXPORT_OK	= qw(to_url);

$knjconv_unchecked = 1;
$use_nkf = 0;		# 1ならNKF.pm、0ならjcode.plを使用する

sub new {
	my $self = {};
	my $class = shift;
	bless $self;
	$self->{gwurl} = shift;
	$self->{baseuri} = shift;
	$self->{ref_max} = shift || 40;	# 最大リンク数
	$self->{use_maru} = shift;		# 丸数字使用
	$self->{ref_count} = 0;			# LINKカウント
	$self->{strings} = '';
	$self->{links} = [];
	return $self;
}


# 漢字変換パッケージ自動判別
sub chk_knj_conv {
	if ($knjconv_unchecked) {
		if (defined &main::nkf) {
			$use_nkf = 1;
		} else {
			$use_nkf = 0;
		}
#print "** use_nkf = $use_nkf **\n";
		$knjconv_unchecked = 0;
	}
}

# HTMLテキストを解析してリンクを取り出す
sub parse {
	my $self = shift;
	my $intext = shift;
#print "**intext=[$intext]\n";
	$self->{strings} = '';
	my $links = $self->{links};
	while ($intext =~ /<(.*?)>/) {
		my $tag = $1;
		my $post_tag = $';
		$self->{strings} .= $`;
		if ($tag =~ /a.+?href="(.*?)"/i) {
			my $maru;
			my $link = $self->to_url($1);
			push(@$links, $link);
			$self->{ref_count}++;
			if ($self->{use_maru} && $self->{ref_count} <= 20) {
				$maru = pack("CC", 0xad, 0xa0 + $self->{ref_count});
			} else {
				$maru = sprintf("[%d]", $self->{ref_count});
			}
			$self->{strings} .= $maru;
		}
		if ($tag =~ /^(br|p|li|h\d+|address)$/i) {
			$self->{strings} .= "\n";
		}
		if ($tag =~ /^hr$/i) {
			$self->{strings} .= "\n_____________\n";
		}
		$intext = $post_tag;
	}
	$self->{strings} .= $intext;
	if ($self->{ref_count} >= $self->{ref_max}) {
		$self->{strings} .= "[リンクが多すぎます(>" . $self->{ref_max} . ")]\n";
	}
	$self->{links} = $links;
}

# 
sub to_url {
	my $self = shift;
	my $link = shift;
	my $url;
	if ($link =~ /http:\/\/.*?\/.*?\/?[^\/]*/) {
		$url = $link;
	} elsif ($link =~/^\/.*?\/?[^\/]*/) {
		$self->{baseuri} =~/http:\/\/([^\/]*?)(\/.*?\/?)([^\/]*)$/;
		$url = "http://" . $1 . $link;
	} else {
#		$url = "http://" . $self->{baseuri} . $link;
		$url = $self->{baseuri} . $link;
	}
	return $url;
}


# HTMLをONCに変換
sub main::conv_html2onc($$$;$$) {
	my ($intext, $gwurl, $baseuri, $refmax, $usemaru) = @_;
	my $out, $sels, $url, $link, $i;

	&ONCConv::chk_knj_conv;
	$refmax = 40 if (!$refmax);
	my $onccnv = new ONCConv($gwurl, $baseuri, $refmax, $usemaru);
	$intext =~ s/\n\s+/\n/g;
	$intext =~ s/\s+\n/\n/g;
	$intext =~ s/\n/ /g;
	$onccnv->parse($intext);

	$out = $onccnv->{strings};
#	$out =~ s/[ \t]+\n/\n/g;	# 行末空白除去
#	$out =~ s/\n\n+/\n/g;	# 複数改行は１つに
#	$out =~ s/(\S)[ \t]+/$1 /g;	# 行中の複数空白は１つに
#	$out =~ s/^\n//;		# Contents先頭の空行を除去

	{
		my $u = $gwurl;
		$u =~ s/^http://;
		$sels = "<SEL=0;$u>\n";
		$i = 0;
	}
	$links = $onccnv->{links};
	for $link (@$links) {
		my $u = $link;
		$u =~ s/([:?=&\/\.~])/sprintf("%%%2X",ord($1))/egi ;
		$i++;
		if (index($link, "$gwurl?") == 0) {
			# 自分自身($gwurl)へのリンク
			$u = $link;
			$u =~ s/[?]/?d=/; 	# i-system special feature
						# http://hoge/hoge.cgi?20000101  --> http://hoge/hoge.cgi?d=20000101
		} else {
			$u = "$gwurl?U=$u";
		}
		$u =~ s/^http://;
		$sels .= "<SEL=$i;$u>\n";
	}

	$out = "Content-type: text/plain\n\n"
		 . "From: $baseuri\n"
		 .  "Subject: $baseuri\n"
		 .  "Content-Type: Text/X-PmailDX\n\n"
		 .  "$sels$out";
	$out;
}

package main;

# オープンネットコンテンツ GW動作
sub onc_gateway ($$;$$) {
	my ($url, $gwurl, $ref_max, $flag_maru) = @_;

	&ONCConv::chk_knj_conv;

	# 表題or本文で URL を指定した場合、全角で送って来る端末もある。
	if ($ONCConv::use_nkf) {
		$url = nkf('-e', $url) ;
	} else {
		jcode::convert( \$url , 'euc' ) ;
	}
	$url =~ s/\s+$// ;
	$url =~ s/^\s+// ;
	if ($ONCConv::use_nkf) {
		$url = nkf('-Z', $url) ;
	} else {
		jcode::tr( \$url , "〜￣―ー−" , "~~---" ) ;
		jcode::tr( \$url ,
				   "０-９Ａ-Ｚａ-ｚ　" , "0-9A-Za-z " ) ;
		jcode::tr( \$url ,
				   "＃♯＄％＆（）＊＋，．／：；＜＝＞？＠［］＾＿" ,
				   "##\$%&()*+,./:;<=>?\@[]^_" ) ;
	}

	# オープンネットコンテンツの処理
	if ( $url =~ /^\.(.+)/ ) {	# '.' による省略の補完(masato)
		$url = $abbrev . $1 ;
	}
	if ( $url !~ /^[a-z]+:/ ) {	# proto:が無い場合は http://を付加する
		$url = 'http://' . $url;
	}
	if ( $url =~ /^http:\/\/[^\"\\]+$/i ) {		#"

		my $baseurl = $url;
		$baseurl =~ s/[?](.+)$//;

		my $intext = &get_html_text($url);
		if ($ONCConv::use_nkf) {
			$intext = nkf('-e', $intext) ;
		} else {
			jcode::convert( \$intext , 'euc' ) ;
		}
		my $text = &main::conv_html2onc($intext, $gwurl, $baseurl, $ref_max, $flag_maru);

		$text .= "\n0:終了\n" ;
		if ($ONCConv::use_nkf) {
			$text = nkf('-s', $text) ;
		} else {
			jcode::convert( \$text , 'sjis' ) ;
		}
		print $text ;

	} else {

		# http以外のプロトコルは、禁止。
		#	ftp,telnet,file://... などは危険＆無駄。
		my $ans = <<"EOF" ;
Content-type: text/plain

X-PmailDX-CTRL: LineDisconnect
From: $baseuri
Subject: プロトコルには http しか使えません。
Content-Type: Text/X-PmailDX

$url
切断します。
EOF
		if ($ONCConv::use_nkf) {
			$intext = nkf('-s', $intext) ;
		} else {
			jcode::convert( \$ans , 'sjis' ) ;
		}
		print $ans ;
	}

}


# 自前でHTMLテキストを得る
sub get_html_text ($) {
	my ($url) = @_;
	my $intext = '';
	local (*IN);

	return '' if ($url eq '');

	my ($h, $d, $server, $file) = split(/\//, $url, 4);
	my ($server, $port)= split(/\:/, $server);
	$port = 80 if ($port eq '');

	$remote_address = sockaddr_in($port, inet_aton($server));
	$proto = getprotobyname('tcp');
	socket(IN,PF_INET,SOCK_STREAM,$proto)
		|| die "Socket: $!";
	my $c = 0;
	do {
		$result = connect(IN, $remote_address);
		if ($c++ >= 10) {
			return <<EOF;
<html><head>
<META HTTP-EQUIV=\"Content-Type\" CONTENT=\"text/html\">
<title>CONNECT ERROR</title>
</head>
<body>
Connect Error!
</body>
</html>
EOF
		}
		if ($result != 1) { sleep(1); }
	} while ($result != 1);

	select((select(IN), $| = 1)[0]);

	print IN "GET /$file HTTP/1.0\r\n";
	print IN "Referer: $h\r\n";
	print IN "Host: $server\r\n";
	print IN "Accept: */*\r\n";
	print IN "User-Agent: ONCGW\r\n";
	print IN "Connection: close\n";
	print IN "\r\n";

	#header 非表示
	while (<IN>) {
		m/^\r\n$/ && last;
	}
	$intext .= $_ while (<IN>);

	close(IN);

	$intext;
}

1;


