# HyperNikkiSystem 2.19.9-static.1 — Legacy HNF Static Site Generator

This repository contains **HyperNikkiSystem (HNS) 2.19.9-static.1**, a modified fork of HNS 2.19.9, a diary system originally developed by the HyperNikkiSystem Project.

The primary purpose of this fork is to preserve existing HNF (HyperNikki Format) diary archives and make them accessible as static HTML pages without running legacy CGI programs on a public web server.

The original HNS project is no longer actively maintained. Its former website is available through the [Internet Archive](https://web.archive.org/web/20230801153506/http://www.h14m.org/).

## オリジナルのソースアーカイブ

この改修版は、FreeBSD の ports distfiles キャッシュから入手したオリジナルの `hns-2.19.9.tar.gz` を基にしています。

- ファイル名: `hns-2.19.9.tar.gz`
- 入手先: https://distcache.FreeBSD.org/ports-distfiles/hns-2.19.9.tar.gz
- オリジナルのリリース日: 2006年11月5日（同梱の `README.ja` による）

## 主な変更点

オリジナルの HNS 2.19.9 に対して、以下の修正を加えています。

- Perl 5.40 で動作するための互換性修正
- UTF-8 端末で利用できる日本語インストーラ `hns-setup.utf8.ja` の追加
- インストーラで入力された日本語文字列を EUC-JP に変換する処理の追加
- 静的 HTML 生成プログラム `make-diary.pl` の修正
  - CGI をコマンドラインから実行して HTML を生成
  - GRP による非公開エントリの出力を抑制
  - `<base href="...">` および CGI 用 RSS リンクの削除
  - 生成 HTML のパーミッションを `0644` に設定
- 旧 HNS 公式サイトへの一部リンクを Internet Archive に変更

## 想定する用途

過去に HNS を利用していたユーザが、保存済みの `.hnf` ファイルから静的 HTML を生成し、通常の Web サーバで公開することを想定しています。

生成された HTML を公開するサーバには、Perl や HNS の CGI 実行環境は必要ありません。

**このリポジトリは、HNS の動的 CGI 機能を安全に公開できるようにすることを目的としたものではありません。**

## インストール

本リポジトリを取得し、`perl-5.40` ブランチを使用します。

```sh
git clone -b perl-5.40 https://github.com/nakanotakeo/hns-legacy.git
cd hns-legacy
```

Debian などの UTF-8 環境では、次のインストーラを使用できます。

```sh
sh hns-setup.utf8.ja
```

Perl、GNU make、nkf など、HNS が必要とするプログラムをあらかじめ用意してください。

HNS の内部処理と既存の HNF ファイルは、基本的に EUC-JP を前提としています。UTF-8 版インストーラは、入力された日本語のタイトルと著者名を EUC-JP に変換して設定ファイルを生成します。

既存の HNF ファイルは、元の文字コードを維持して配置してください。

## 静的 HTML の生成

インストール後、既存の HNF ファイルを設定した日記ディレクトリに配置します。

静的 HTML の生成には、インストールされた `make-diary.pl` を使用します。

```sh
~/diary/bin/make-diary.pl -f
```

実際のパスは、インストール時に指定した日記ディレクトリに応じて読み替えてください。

`-f` は全ページの強制再生成を指定します。通常の実行では、更新が必要と判定されたページのみ生成します。

生成されるファイルは、原則として以下の形式です。

```text
YYYYMM.html
recent.html
```

月別 HTML と最新日記ページが、インストール時に指定した HTML ディレクトリに作成されます。

### 静的生成時の推奨設定

`config.ph` では、次の設定を推奨します。

```perl
$PIMUse = "OFF";
$TitleListUse = "OFF";
```

これらは、静的 HTML の公開では不要となる動的機能への依存を減らすための設定です。

変更後は HTML を再生成してください。

### 生成された HTML の公開

生成した HTML ファイルと、表示に必要な画像・CSS などの静的ファイルを公開用 Web サーバに配置します。

生成された HTML のパーミッションは `0644` です。

公開サーバでは CGI を実行する必要はありません。セキュリティ上、`.cgi`、`.pl`、`.ph` などのプログラムや設定ファイルは公開対象に含めず、静的ファイルだけを配信することを推奨します。

また、生成ページ内に残る絶対 URL や、動的 CGI を前提とするリンクについては、公開前に確認してください。

## 制限事項・注意事項

- 本リポジトリは、主として既存の日記資産を静的 HTML に変換する用途を想定しています。
- HNS のすべての機能について、Perl 5.40 での動作を保証するものではありません。
- 静的 HTML では、掲示板、検索、投稿などの動的機能は利用できません。
- GRP による非公開エントリの出力抑制処理を追加していますが、非公開情報が出力されないことを公開前に必ず確認してください。
- 古い HNF 資産に含まれる HTML、画像参照、外部リンクなどは、必要に応じて個別に修正してください。
- 日本語テキストの文字コードは原則として EUC-JP です。

## オリジナル版について

HyperNikkiSystem 2.19.9 は、HyperNikkiSystem Project によって開発されたソフトウェアです。

本リポジトリは、そのオリジナルソースに互換性修正と静的 HTML 生成のための変更を加えたものです。

オリジナルのドキュメントについては、`README.ja` などを参照してください。

Original project: [HyperNikkiSystem Project (Internet Archive)](https://web.archive.org/web/20230801153506/http://www.h14m.org/)

## License

The original HyperNikkiSystem is distributed under the terms specified in its original source distribution. Refer to the accompanying license and copyright notices.
