package HNS::Tools::RSS;
# $Id: RSS.pm,v 1.7 2005/04/25 12:22:36 kenji Exp $

#HNS用RSSモジュール RSS.pm by ishinao / ishinao@ishinao.net
#
# ライセンスはGPLになるんだっけ？
# たぶん無駄がたくさんあるので、分かる人は無駄を削ってください。
#
#使い方
#
#  use HNS::Tools::RRS;
#  $rss = new HNS::Tools::RSS;
#  $rss->Update(); #現在の情報をキャッシュファイルに保存
#  $rss->Print();  #キャッシュファイルに基づいてRSSを出力
#

use strict vars;
use HNS::Tools::Title;

use vars qw(@ISA);
@ISA = qw(HNS::Tools::Title);

use vars qw(@RssItems);

require './config.ph';

sub xml_header($) {
    my $self = shift;
	print "<?xml version=\"1.0\" encoding=\"euc-jp\" ?>\n";
	print "<rdf:RDF\n";
	print "	xmlns=\"http://purl.org/rss/1.0/\"\n";
	print "	xmlns:rdf=\"http://www.w3.org/1999/02/22-rdf-syntax-ns#\"\n";
	print "	xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n";
	print "	xml:lang=\"ja\">\n";
}

sub xml_footer($) {
    my $self = shift;
    print "</rdf:RDF>\n";
}

sub rdf_channel($) {
	my $self = shift;
	my $items = shift;
	
	print "<channel rdf:about=\"$HNS::System::MyDiaryURI\">\n";
	print "<title>$HNS::System::Title</title>\n";
	print "<link>$HNS::System::MyDiaryURI</link>\n";
	print "<description>$HNS::System::Title Recent</description>\n";
       print "<dc:creator>$HNS::System::Author</dc:creator>\n";
	print "<items>\n";
	print "	<rdf:Seq>\n";
	print $items;
	print "	</rdf:Seq>\n";
	print "</items>\n";
	print "</channel>\n";
}

sub Print($) {
    my $self = shift;

	my @currentItems;

	if (-e "$HNS::System::CacheDir/rss.txt") {
		open(RSS, "$HNS::System::CacheDir/rss.txt") or die;
		flock(RSS, 1);

		while (<RSS>) {
			chomp($_);
			my ($url, $title, $created, $description) = split("\t", $_);
			my $rssitem;
			$rssitem->{url} = $url;
			$rssitem->{title} = $title;
			$rssitem->{created} = $created;
			$rssitem->{description} = $description;
			
			push(@currentItems, $rssitem);
		}
		close(RSS);
	}
	
	my $channels;
	my $items;

	foreach (@currentItems) {
		my $item = $_;
		my ($url, $title, $description, $created);
		$url = $item->{url};
		$title = $item->{title};
		$description = $item->{description};
		$created = $item->{created};

		if ($url) {
			$channels .="\t\t<rdf:li rdf:resource=\"$url\" />\n";
			$items .= "<item rdf:about=\"$url\">\n";
			$items .= "\t<title>$title</title>\n";
			$items .= "\t<link>$url</link>\n";
			$items .= "\t<description>$description</description>\n";
			$items .= "\t<dc:date>$created</dc:date>\n";
			$items .= "</item>\n";
		}
	}

	print "Content-type: text/xml\n";
	print "\n";
    $self->xml_header();
	$self->rdf_channel($channels);
	print $items;
    $self->xml_footer();
}

sub Update($) {
    my $self = shift;

	my $rssfile = "$HNS::System::CacheDir/rss.txt";

	my $hnflastmodified;
	tie $hnflastmodified, 'SimpleDB::Scalar',
		"$HNS::System::DiaryDir/log/LastModified";
	my $rsslastmodified = (stat($rssfile))[9];

	if ($rsslastmodified > $hnflastmodified) {
		return;
	}

	my $Max = $HNS::System::DefaultMax * 2;
	$self->getFileList($Max);
	my @files = reverse sort keys(%{$self->files});

	my %currentItems;
	if (-e $rssfile) {
		open(RSS, $rssfile) or die;
		flock(RSS, 1);

		while (<RSS>) {
			chomp($_);
			my ($url, $title, $created, $description) = split(/\t/, $_);
			$currentItems{$url} = $created;
		}
		close(RSS);
	}

	foreach my $i (1 .. ($#files < $Max ? $#files : $Max)) {
		$self->readHnf($files[$i-1]);
	}

	if (@RssItems > 0) {
		open(RSS, "> $rssfile") or die;
		flock(RSS, 2);

		foreach (@RssItems) {
			my $item = $_;
			my ($url, $title, $description, $created);
			$url = $item->{url};
			$title = $item->{title};
			$description = $item->{description};
			$created = $item->{created};

			if ($currentItems{$url}) {
				$created = $currentItems{$url};
			} else {
				if (%currentItems > 0) {
					my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = gmtime(time);
					$year += 1900;
					$mon++;
					$created = sprintf("%04d-%02d-%02dT%02d:%02d:%02d+00:00",$year, $mon, $mday, $hour, $min, $sec);
				}
			}
			
			print RSS "$url\t$title\t$created\t$description\n";
		}
		close(RSS);
	}
}

sub Parse($$@) {
    my ($self, $params, @hnf) = @_;
    my ($grpCount, $newCount, $subCount);
    my $id;
    my @rssitems;

    foreach my $section (@hnf) {
		my $grp;
		if ($section->{grp}) {
		    $grpCount++;
		    $params->{new} = "G" . $grpCount;
		    $params->{mark} = $HNS::Hnf::Command::GRP::Mark;
		    $grp = "<!-- GRP:" . $section->{grp} . " -->";
		} else {
		    $newCount++;
		    $params->{new} = $newCount;
		    $params->{mark} = $newCount;
		    $grp = "";
		}
		if ($section->{new} =~ /^NEW ?/) {
		    $params->{content} = $';
		} elsif ($section->{new} =~ /^LNEW /) {
		    $params->{content} = (split(' ', $', 2))[1];
		} elsif ($section->{new} =~ /^RLNEW /) {
		    $params->{content} = (split(' ', $', 3))[2];
		}
		$params->{cat_link} = "";
	
		my $para;
		foreach (@{$section->{text}}, map(@{$_}, @{$section->{sub}})) {
                   s/&/&amp;/g;
		    s/"/&quot;/g;
		    s/~$//;
		    s/\t/ /;	# cache/rss.txt tab separator

		    if (/^!/) { # comment
				;
		    } elsif (/^[A-Z]+(\s|$)/) { # hnf command
				my ($cmd, $rest) = split(' ', $_, 2);
				if ($cmd =~ /^(SUB|LSUB|RLSUB|LI|DT|DD|PRE)$/ &&
				    $para && $para !~ /&#10;$/) {
				    $para .= "&#10;";
				}
				if ($cmd =~ /^(SUB|URL|STRIKE|STRONG)/) {
				    $para .= $rest;
				} elsif ($cmd =~ /^(LSUB|LINK|LSTRIKE)/) {
				    $para .= (split(' ', $rest, 2))[1];
				} elsif ($cmd =~ /^(RLSUB|RLINK|FONT)/) {
				    $para .= (split(' ', $rest, 3))[2];
				} elsif ($cmd =~ /^LI$/) {
				    $para .= "・$rest";
				}
		    } elsif (m|^/[A-Z]+|) {	# close command
				;
		    } else {
				$para .= $_;
		    }
		    if (length $para >= 150) {
				$para .= "...";
				last;
		    }
		}
		$params->{para} = $para;

		my %item = %$params;
		my ($day, $abc, $mark, $year, $new ,$para, $month, $content, $high);
		$day = $item{"day"};
		$abc = $item{"abc"};
		$mark = $item{"mark"};
		$year = $item{"year"};
		$new = $item{"new"};
		$para = $item{"para"};
		$month = $item{"month"};
		$content = $item{"content"};
		$high = $item{"high"};

		my $url = $HNS::System::MyDiaryURI."?$year$month$abc#$year$month$day$mark";
		my $rssitem;
		$rssitem->{url} = $url;
		$rssitem->{title} = $content;
		$rssitem->{description} = $para;
		$rssitem->{created} = "$year-$month-$day";

		if ($grp eq '') {push(@rssitems, $rssitem);}
    }
	push(@RssItems, reverse(@rssitems));
}

1;
