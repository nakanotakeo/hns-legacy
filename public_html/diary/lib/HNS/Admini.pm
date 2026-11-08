package HNS::Admini;
################################################################
# HNS::Admini  : Administration
# $Id: Admini.pm,v 1.13 2001/09/30 03:41:56 kenji Exp $
################################################################

=head1 NAME

HNS::Admini - 管理クラス

=cut

use ObjectTemplate;
@HNS::Admini::ISA = qw(ObjectTemplate);

use strict;
use CGI::Cookie;
use HNS::Status;
use HNS::System;


=head1 MEMBER VARIABLES

 message_file   メッセージファイル
 ruri_map_file  ルリマップファイル
 status         HNS::Status オブジェクト
 auths

=cut

__PACKAGE__->attributes(qw(message_file ruri_map_file status auths));

################################################################

sub initialize($)
{
    my $self = shift;
    $self->status(new HNS::Status);
    $self->message_file("$HNS::System::DiaryDir/log/message-by-user.txt");
    $self->ruri_map_file("$HNS::System::DiaryDir/log/ruri-map-by-user.txt");

    # auth
    my $auth_file = "$HNS::System::DiaryDir/conf/auth_ruri.txt";
    $self->auths([]);
    open(AUTH, $auth_file) || die "Can't Open File: $auth_file";
    while (<AUTH>){
	chomp;
	if (/(RURI.............)(.*)/) {
	    push (@{$self->auths}, $1);
	}
    }
    close (AUTH);
}

################################################################

=head2 $a->CheckAuthrized($be_print_header);

authorized なユーザかどうか調べる。
違ったらエラー表示

=cut


sub CheckAuthorized($;$)
{
    my ($self, $be_print_header) = @_;

    my $id = $self->status->id;
    my $authed = 0;
    for (@{$self->auths}){
	if ($id =~ /$_/){
	    $authed = 1;
	}
    }
    unless ($authed){
	if ($be_print_header){
	    $self->PrintHeader('web2nikki: authorization error');
	}
	print "アクセスは許可されていません．<br>\n";
	print "あなたの RURIコード: $id<br>\n";
	print "RURIコードを $HNS::System::DiaryDir/conf/auth_ruri.txt に記述してください．";
	$self->PrintFooter();
	exit 1;
    }
}
################################################################
sub PrintHeader($$;$)
{
    my ($self, $title, $h1) = @_;
    
    print "Content-Type: text/html; charset=EUC-JP\r\n";
    $self->status->PrintCookieHeader 
	if ($HNS::System::AdminCookieFlag eq 'ON' && !$self->status->is_robot);
    print "\r\n";

    print qq(<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN"
	"http://www.w3.org/TR/REC-html40/loose.dtd">
	<html>
	<head>
	<meta name="ROBOTS" content="NONE">
	<title>$title</title>
	</head>

	<body bgcolor="#e0e0ff" text="#000000" link="#0000FF" vlink="#663399" alink="#FF0000">\n);

    if ($h1){
	print qq(<h1>$h1</h1><hr>);
    }
}
sub PrintFooter($;$$)
{
    my ($self,  $pre_message, $uri, $statement) = @_;
    $uri ||= "admini.cgi";
    $statement ||= "admini";
    
    print "\n<hr>\n";
    print "Your RURI code: " . $self->status->id . "<br>";
    print qq(${pre_message}Copyright (c) by <a href="http://www.h14m.org/">HyperNikkiSystem Project</a> 1998-2001\n);
    print qq(<hr><a href="$uri">$statement</a><br>\n);
    print "</body></html>\n";
}
sub RedirectDiary
{
    my $path = $ENV{'SCRIPT_NAME'};
    $path =~ s![^/]*$!!;
    print "Location: http://$ENV{'SERVER_NAME'}$path\r\n\r\n";
}


1;
