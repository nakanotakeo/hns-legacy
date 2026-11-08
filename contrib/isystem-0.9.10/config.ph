#/usr/loca/bin/perl
# MIOMIO nikki system for iMODE
# yar-3 nikki system config
# 2000/02/17 by yar-3
# 1999/10/6 yar-3

#0.8.5 追加
#$theme テーマ名 
#$theme = "default"; #とすると
#confdirの default.ph が読み込まれる。

#0.7.0 追加
#$titlereverse たいとるの正逆
#$reverse 全部、pilowebでの正逆
$titlereverse = 0;
$reverse = 0;

#piloweb_2days pilowebでアクセスしたときに2日分表示する
$piloweb_2days = 0;

#0.6.3 追加
#catprint カテゴリ表示 on/off
$catprint =0;



#0.6.3 追加
#catprint カテゴリ表示 on/off
$catprint =0;

#0.5.3 追加
# color iMODE対応
$headcolor = "BLUE"; #日記のタイトルの色
$newcolor = "GREEN";  #NEW,LNEWコマンドの着色
$subcolor = "#800000"; #SUB,LSUBコマンドの着色
#16進での指定もOK
$strongcolor = "RED";  #STRONGコマンドの着色
$strikecolor = "Fuchsia"; #STRONGコマンドの着色


#0.4.3追加
# t-saitoh先生のopennet CGIを利用する場合に使う
$ongw = "http://yar-3.net/gw/";
#この機能を使う場合はbaseuriが必須になります
#
#$maxresult 検索の表示数
$maxresult = 10;

#0.4.2追加
#hnfconv=1で文字コード変換
$hnfconv = 0;


# 0.3.3 より追加
# 検索日数
$maxday = 100;


# 0.3.1より追加
# nkfを使う場合は1
# jcode.pl は 2
$nkf =2;

# 0.3.0より追加
# $log 1 で log採取
$log = 1;
#
# レポート機能を使う場合は「$mailto = 'abc@xxx.yyy.zzz';」のように自分の
# メールアドレスを設定する。また、/usr/lib/sendmailが存在することを確認
# しておく。別の場所にある場合は、$sendmail も適切に変更する。詳細メール
# の場合は「$account_detail = 1;」とし、アクセス件数のみをメールする場合
# は「$account_detail = 0;」とする。
#
$mailto   = 'ore@yar-3.net';
$sendmail = '/usr/lib/sendmail';
$account_detail = 1;



# 0.2.9より追加
# baseuri
$baseuri = "http://yar-3.net/imode/";

# *.hnfのあるディレクトリ
$diarydir = "/home/yar-3/diary/";

# confのあるディレクトリ
$confdir = "/home/yar-3/public_html/imode/";

# hnsへのリンク関係
$index = "index.cgi";


# NEW関係の設定
$newline = "<hr>";
$newmark = "\$";
$new1 = '<B>';
$new2 = '</B>';

# SUB関係の設定
$subline = "<br>";
$submark = "\@";
$sub1 = '';
$sub2 = ':';

# タイトル
$title = "yar-3 walking memo";
$head = "やあ3歩記";

# header,footerのファイル名を指定
$headfile = "head.txt";
$titleheadfile = "titlehead.txt";
$footfile = "";

# address要素の入力
$address = 'ore@yar-3.net';

	
#0.8.5 追加
$themefile = "$confdir$theme.ph";
require $themefile if (-e $themefile);
1;
