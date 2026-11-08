#!/bin/sh
# HyperNikkiSystem, hns-lite Creating Script for hns-2.10
# 2000/10/21 since 2000/05/04
# ChangeLog
# 2001-02-02     Yoichi Imai <yoichi@silver-forest.com>
#                * added changelog
#                * 0.7 release
#
# Copyright (C) 2000 Yoichi Imai <yoichi@silver-forest.com>
# $Id: hns-lite.sh,v 1.13 2003/01/03 10:26:52 bonaim Exp $

set -e

LITE_VER=`sed -ne 's/^\$VERSION = "\(.*\)";$/\1/p' public_html/diary/lib/HNS.pm`
PATH=$PATH:/usr/sbin
PERL=/usr/local/bin/perl
SENDMAIL=/usr/sbin/sendmail
NKF=/usr/bin/nkf
LITE_DIR="/tmp/hns-lite-root/hns-lite-$LITE_VER"
#LITE_DIR_Q="\\/tmp\\/hns-lite-root\\/hns-lite-$LITE_VER"

mkdir /tmp/hns-lite-setup-$$
cp -pr . /tmp/hns-lite-setup-$$
cd /tmp/hns-lite-setup-$$

rm -rf /tmp/hns-lite-root
mkdir -p $LITE_DIR/hns-lite
mkdir -p $LITE_DIR/diary

make NIKKITITLE="Hoge's Nikki" \
     DIARYDIR="$LITE_DIR/diary" \
     HTMLDIR="$LITE_DIR/hns-lite" \
     PERL_PATH="$PERL" \
     SENDMAIL_PATH="$SENDMAIL" \
     NKF_PATH="$NKF" \
     MYDIARYURI="http://www.example.ne.jp/~hoge/hns-lite/" \
     install

cp -pr docs $LITE_DIR/docs.orig
cp GPL.txt $LITE_DIR/
cp GPL-j.txt $LITE_DIR/
cp README.ja $LITE_DIR/
# tar xvf hns-lite-doc.tar -C $LITE_DIR
cat > $LITE_DIR/INSTALL.txt <<EOF
インストールには,
EUCコードを直接編集できるエディタと
FTPソフトが必要です。

EUCを編集できるエディタとしては
メモ帳++(http://www.vector.co.jp/soft/win95/writing/se120980.html)等があり,
FTPソフトでは,
FFFTP(http://www.vector.co.jp/soft/win95/net/se061839.html)等があります。
なお、メモ帳++, FFFTP共にフリーソフトウェアです。

* インストール方法

1. 設定ファイルの編集
1.1 編集する方法
$設定項目 = "<<<編集する部分>>>";
<<<編集する部分>>>に指定された設定内容を設定します。

$Title : 日記のタイトル
と指定されたら,
$Title = "Hoge's Diary";
というところを
$Title = "ここに日記のタイトルをかきます";
というようにエディタで編集します。
一部使えない文字があるので注意が必要です。

1.2 最低限編集する箇所
hns-lite/config.ph
  $Title :  日記のタイトル
  $UserMail :  メールアドレス
  $Author :  あなたの名前
  $MyDiaryURI :  アップロードしたときにできるであろうhns-liteフォルダのURI
               たとえば, http://www.example.ne.jp/~username/cgi-bin/hns-lite/など。
               実際にアクセスされるのはdiaryフォルダではなくhns-liteフォルダなので
               diary/ ではなく, hns-lite/にアクセスすることになります。
hns-lite/i/config.ph
  $baseuri : $MyDiaryURIと同じものを指定
  $title : 日記タイトル(i-mode用)
  $head : 日記タイトル(i-mode用)
  $address : メールアドレス

2. hns-liteフォルダに直接入っているcgiファイルと,
hns-liteフォルダの中にあるiフォルダのindex.cgiの1行目にある
perlのパスを環境に合わせて変更します。
#!/usr/local/bin/perl
が標準です。同じなら変更する必要はありません。

3. 
 hns-liteフォルダ
 diaryフォルダ
をftpソフトを使って転送します。
両フォルダにある.htaccessというファイルも忘れずにアップロードしてください。
なお, この2つのフォルダは同じ場所に置いてください。

4. パーミッションを変更します。
hns-lite/ *.cgiをすべて : 755
hns-lite/i/index.cgi : 755
diary/   cacheフォルダ : 777
	 logフォルダ,その下のLM,OLD,lockフォルダ : 777
	 logの中のファイルすべて : 666
         data/boarddata.txt      : 666 (board.cgiを使用する場合)

5. 日記へのリンク
日記へのリンクは
http://＜インストールした場所＞/hns-lite/
に行ってください。

おめでとうございます。これで設定は完了です。
あとは, docs.origフォルダの中に入っている説明や,
http://www.h14m.org/にある説明を参考にしてください。
EOF
nkf -s $LITE_DIR/INSTALL.txt > $LITE_DIR/INSTALL.txt.out
mv $LITE_DIR/INSTALL.txt.out $LITE_DIR/INSTALL.txt

cat > $LITE_DIR/README-lite.txt <<EOF
HyperNikkiSystem Lite

HyperNikkiSystem Liteは、
Unixを使うのが難しいユーザや、
Unix環境を用意できないユーザがインストールしやすいように
Hyper NIKKI Systemを再パッケージしたものです。

一部(テーマなど)使えなくなっている機能やファイルがある可能性があります。
その機能を利用したい場合には, Hyper NIKKI Systemから入手するか,
Hyper NIKKI Systemそのものをご利用ください。

HyperNikkiSystem Project
http://www.h14m.org/hns-lite/
EOF
nkf -s $LITE_DIR/README-lite.txt > $LITE_DIR/README-lite.txt.out
mv $LITE_DIR/README-lite.txt.out $LITE_DIR/README-lite.txt

rm -rf /tmp/hns-lite-setup-$$
rm -rf $LITE_DIR/hns-lite/anti-windoze
rm -rf $LITE_DIR/hns-lite/ruribaka

cd $LITE_DIR/hns-lite
sed -e \
 "s|$LITE_DIR/|../|g" \
    config.ph > config.ph.out
sed -e \
 's|\.\./hns-lite|./|g' \
    config.ph.out > config.ph
rm config.ph.out

cd i/
sed -e \
 "s|$LITE_DIR/|../../|g" \
    config.ph > config.ph.out
sed -e \
 's|\.\./\.\./hns-lite/i|./|g' \
    config.ph.out > config.ph

rm config.ph.out
cp ../lib/jcode.pl .
cd ..

cd lib/HNS/
sed -e \
 's|\(print \"RURI[^\$]*\)\$HNS::System::|\1|g' \
    Admini.pm > Admini.pm.out
mv Admini.pm.out Admini.pm

cd $LITE_DIR/diary
cat > .htaccess <<EOF
<Limit GET POST PUT>
 deny from all
</Limit>
EOF

cd $LITE_DIR/hns-lite/lib

sed -e 's/<div align="right">Powered by <a href="%s">hns-%s/&-lite/' \
  HNS.pm > HNS.pm.out
mv HNS.pm.out HNS.pm

cd /tmp/hns-lite-root
tar zcf hns-lite-$LITE_VER.tar.gz hns-lite-$LITE_VER
lha c hns-lite-$LITE_VER.lzh hns-lite-$LITE_VER

