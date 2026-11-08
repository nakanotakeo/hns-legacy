package HNS;
# $Id: HNS.pm,v 1.74 2006/11/05 01:04:32 kenji Exp $
################################################################

=head1 NAME

HNS - total management of HNS

=head1 SYNOPSIS

 my $hns = HNS->new();
 $hns->Read($y, $m, $d);
 #$hns->Read;                # recent
 $hns->Print;

=head1 DESCRIPTION

hns 全体を管理するクラス。
$HNS::Status は他のクラスから参照される。

=cut

################################################################

use strict vars;
use ObjectTemplate;
@HNS::ISA = qw(ObjectTemplate);

use SimpleDB::Scalar;                # for lastModified, head.txt, foot.txt
use SimpleDB::Append;                # for Append Log
use DateTime::Format;                # for LastModified
use HNS::Calendar::Table;            # must be 'use' not 'require'
use HNS::Calendar::NoTable;          # 'cause static variable may be change
use HNS::Template;
use HNS::System;
use HNS::Collection;
use HNS::Status;
use HNS::ExtHTML;
use HNS::Style;
use HNS::Diary::Template;
################################################################
__PACKAGE__->attributes(qw()); # status);

=head1 STATIC VARIABLES

 $VERSION           このソースのヴァージョン
 $PUBLIC_VERSION    正式公開されているヴァージョン
 %VersionMessages   ヴァージョンメッセージ
 $HnsHomePage       hns のホームページ URI
 $Status            広域的状況オブジェクト

=cut

use vars qw($VERSION $PUBLIC_VERSION %VersionMessages $HnsHomePage $Status);
$VERSION = "2.19.9";
$PUBLIC_VERSION = "2.19.9";

$HnsHomePage = "http://www.h14m.org/";

%VersionMessages =
    ('Public' => q(hns - Hyper NIKKI System - Version %public),
     'NonPublic' => qq(<font color=red>Attention:</font>
		       current version is %current,
		       public released version is %public.));

################################################################
sub initialize($)
{
    my $self = shift;
#    $self->status(new HNS::Status);
    $HNS::Status = "HNS::Status"->new();
}
################################################################
# public:

=head2 $hns->Print($col);

渡された日記コレクション($col) に従い表示する

=cut

sub Print($$) #($$$$$)
{
#    my ($self, $col, $year, $month, $day) = @_;
    my ($self, $col) = @_;
    my %GRP_DB;
    my $no_cache;

    ################################################################
    # last modified
    my $last_modified;
    tie $last_modified, 'SimpleDB::Scalar', "$HNS::System::DiaryDir/log/LastModified";

    if ($last_modified < $col->last_modified){
		$last_modified = $col->last_modified;

		# Push Antenna
		if ($ENV{'SCRIPT_NAME'} && $#HNS::System::antenna >= 0) {
			use LIRS;
			use HTTP;

			my $lirs = LIRS->new();
			my $r = $lirs->getLirs($last_modified, time,
				       $HNS::System::TZ * 60 * 60, 0,
				       $HNS::System::MyDiaryURI,
				       $HNS::System::Title,
				       $HNS::System::Author,
				       $HNS::System::MyDiaryURI,
				       undef);
			$r =~ s/([^\x21-\x7e])/sprintf("%%%02x", unpack("C", $1))/eg;
			my $content = "lirs=$r";

			foreach my $antenna (@HNS::System::antenna) {
				my $h = HTTP->new(agent => "HNS update reporter/$VERSION",
					 referer => $HNS::System::MyDiaryURI);
				$h->POST($antenna, 
					{'Content-Type' => 'application/x-www-form-urlencoded'},
					$content);
			}
		}

		# RSS update
		use HNS::Tools::RSS;
		my $rss = HNS::Tools::RSS->new();
		$rss->Update();
    }
    ################################################################
    # if group member comes, set no-cache header
    unless (tied %GRP_DB) {
        tie %GRP_DB, 'SimpleDB::Hash',
        "$HNS::System::DiaryDir/conf/group.txt", 1;
    }
    my $id = $HNS::Status->id;
    $no_cache = 0;
    $id = "XXXXXXXXXXXXXXXXX" if length($id) < 17;
    foreach my $idg (keys %GRP_DB) {
        if ($GRP_DB{$idg} =~ /$id/) {
            $no_cache = 1;
            last;
        }
    }

    ################################################################
    # Header
    # HTTP header;
    if ($ENV{'SCRIPT_NAME'}){
	my $echo_lm = strftime("%a, %d %b %Y %H:%M:%S %Z",
			       gmtime($last_modified));
	
	print "Content-Type: text/html; charset=EUC-JP\r\n";
        if ($no_cache) {
            print "Pragma: no-cache\r\n";
            print "Cache-Control: no-cache\r\n";
        }
	print "Last-Modified: $echo_lm\r\n";
	$HNS::Status->PrintCookieHeader
	    if ($HNS::System::RefererLog eq 'ON' &&
		$HNS::System::CookieFlag eq 'ON' &&
		!$HNS::Status->is_robot);
	print "\r\n";
    }
    # <header>
    print $HNS::ExtHTML::DOCTYPE;
    if ($HNS::System::Lang) {
        print qq(<html lang="$HNS::System::Lang">\n<head>\n);
    }
    else {
        print qq(<html>\n<head>\n);
    }
    print qq(<meta http-equiv="content-type" content="text/html; charset=EUC-JP">\n)
	if !($HNS::System::LessOutput);
    print qq(<base href="$HNS::System::MyDiaryURI">\n)
	if !($HNS::System::LessOutput);
    print qq(<link rev="made" href="mailto:$HNS::System::UserMail">\n)
	if !($HNS::System::LessOutput);
    if ($HNS::System::Author) {
	print qq(<meta name="author" content="$HNS::System::Author">\n);
    }
    print qq(<!-- HOSHINO_ANTENNA_REGIST $HNS::System::HoshinoAntenna -->\n)
	if !($HNS::System::LessOutput);
    print qq(<!-- THEME $HNS::System::Theme -->\n);

    if ($col->mode eq 'RECENT' &&
	(my $tmp = SelectTemplate($HNS::ExtHTML::Head_recent,
				  %HNS::ExtHTML::Head_recent))) {
	print $tmp;
    } else {
	print SelectTemplate($HNS::ExtHTML::Head, %HNS::ExtHTML::Head);
    }
    print qq(<title>$HNS::System::Title</title>\n);
    print qq(</head>\n\n);
    
    ################################################################
    # Content
    # <body> start
    print qq(<body $HNS::ExtHTML::BodyVal>\n);
    print "<!-- START TIME " . $col->start_time . "-->\n"
	if !($HNS::System::LessOutput);
    my $head_txt;
    if (-f "$HNS::System::Theme/head.txt") {
      tie $head_txt, 'SimpleDB::Scalar', "$HNS::System::Theme/head.txt", 1;
    }
    else {
      tie $head_txt, 'SimpleDB::Scalar', "$HNS::System::DiaryDir/conf/head.txt", 1;
    }
    print $head_txt;
    my $func = $HNS::ExtHTML::DynamicPrintFunc;
    &$func($col) if ref $func;
    
    # print version
    {
	   
	my $version_message_type = $VERSION eq $PUBLIC_VERSION ? 'Public' : 'NonPublic';
	my $templ = "HNS::Template"->new();
	print $templ->Expand(SelectTemplate($VersionMessages{$version_message_type},
					    %{$VersionMessages{$version_message_type}}),
			     {public=>$PUBLIC_VERSION,
			      current=>$VERSION,
			      homepage=>$HnsHomePage})
		if !($HNS::System::LessOutput);
    }
    # print head style
    my $style = "HNS::Style"->new(col=>$col);
    $style->PrintHead if !($HNS::System::LessOutput);
    # diary content
    $col->Print;
    # elasp time
    print "<!-- END TIME " . $col->end_time . "-->\n"
	if !($HNS::System::LessOutput);
    my $elapse_time = $col->end_time - $col->start_time;
    print "<!-- ELAPSE TIME $elapse_time -->\n"
	if !($HNS::System::LessOutput);

    ################################################################
    # Foot
    $style->PrintFoot if !($HNS::System::LessOutput);
    
    # HNS version info
    printf(qq(
	<div align="right">Powered by <a href="%s">hns-%s</a>, 
	<a href="%s">HyperNikkiSystem Project</a>
	</div>
	<hr>),
	$HnsHomePage, $VERSION, $HnsHomePage)
	if !($HNS::System::LessOutput);

    # foot message
    my $foot;
    if (-f "$HNS::System::Theme/foot.txt") {
      tie $foot, 'SimpleDB::Scalar', "$HNS::System::Theme/foot.txt", 1;
    }
    else {
      tie $foot, 'SimpleDB::Scalar', "$HNS::System::DiaryDir/conf/foot.txt";
    }
    print $foot;
    print qq(</body>\n</html>\n);
}    
################################################################

=head2 $hns->RecordLog($ref, $to);

各ログを記録する

=cut

sub RecordLog ($;$$)
{
    my ($self,  $ref, $to) = @_;
    my $LogDir = "$HNS::System::DiaryDir/log";
    my $referer_log;

    # referer log
    if ($HNS::System::RefererLog eq 'ON') {
	if (($HNS::Status->id eq 'BATTA') && ($HNS::System::RefererBATTALog)) {
	    # separete BATTA access from referer_log
	    $referer_log =
		new SimpleDB::Append("$LogDir/referer_batta_log");
	}
	else {
	    $referer_log = 
		new SimpleDB::Append("$LogDir/referer_log");
	}
	$referer_log->Append($HNS::Status->AsRefererLog);
    }
    # link log
    if ($HNS::System::LinkLog eq 'ON' && ($ref && $to)){
	my $link_log = 
	    SimpleDB::Append->new("$LogDir/link_log");
	$link_log->Append("$to $ref\n");
    }
}

1;
# end of HNS.pm
################################################################
