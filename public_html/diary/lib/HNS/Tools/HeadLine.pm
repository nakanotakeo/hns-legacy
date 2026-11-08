package HNS::Tools::HeadLine;
# $Id: HeadLine.pm,v 1.3 2001/11/15 12:44:36 kenji Exp $
# HeadLine.pm 2001/5/14 ari@mbf.sphere.ne.jp (Akihiro Arisawa)
#
# Copyright (C) 2001 Akihiro Arisawa, HyperNikkiSystem Project
# All rights reserved.
#
# This is free software with ABSOLUTELY NO WARRANTY.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either versions 2, or (at your option)
# any later version.
######################################################################

use strict vars;
use HNS::Tools::Title;
use HNS::Diary::Template;
use vars qw(@ISA);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template
use vars qw($RecentBaseTemplate $RecentNameTemplate $RecentHrefTemplate
	    %RecentBaseTemplate %RecentNameTemplate %RecentHrefTemplate);
use vars qw($DayTemplate %DayTemplate);
use vars qw($HeadTitle $Header $BacktoDiary
	    %HeadTitle %Header %BacktoDiary);
use vars qw($Max);
use vars qw($Version);
@ISA = qw(HNS::Tools::Title HNS::Diary::Template);

require './config.ph';

$Max = $HNS::System::DefaultMax * 3;
$HrefTemplate = "%base#%name";
$RecentBaseTemplate = "$HNS::System::MyDiaryURI";
$DayTemplate = qq(<a href="%href" class="hide">%year/%month/%day</a>);
$HeadTitle = qq(<title>$HNS::System::Title HeadLine</title>\n);
$Header = "";
$BacktoDiary = "";

sub main($) {
    my $self = shift;
    my ($Base, $Name, $Href, %Base, %Name, %Href);
    my ($NewBase, $NewName, $NewHref, %NewBase, %NewName, %NewHref);

    $self->html_header();
    $self->getFileList($Max);

    my @files = reverse sort keys(%{$self->files});

    foreach ('Base', 'Name', 'Href') {
	${$_} = ${"${_}Template"};
	${"${_}Template"} = ${"HNS::Tools::HeadLine::New::${_}Template"} =
	  ${"Recent${_}Template"} if (${"Recent${_}Template"});
	%{$_} = %{"${_}Template"};
	%{"${_}Template"} = %{"HNS::Tools::HeadLine::New::${_}Template"} =
	  %{"Recent${_}Template"} if (%{"Recent${_}Template"});
    }
    foreach my $i (1 .. (sort {$a <=> $b} ($Max, $HNS::System::DefaultMax, $#files))[0]) {
	$self->readHnf($files[$i-1]);
    }

    foreach ('Base', 'Name', 'Href') {
	${"${_}Template"} = ${"HNS::Tools::HeadLine::New::${_}Template"} =
	  ${$_};
	%{"${_}Template"} = %{"HNS::Tools::HeadLine::New::${_}Template"} =
	  %{$_};
    }
    foreach my $i ($HNS::System::DefaultMax+1 .. ($#files < $Max  ? $#files : $Max)) {
	$self->readHnf($files[$i-1], 'headline');
    }

    $self->html_body();
    $self->html_footer();
}

sub Parse($$@) {
    my ($self, $params, @hnf) = @_;
    my ($grpCount, $newCount, $subCount);
    my $id;
    my @title = @{$self->title};

    my $templ = HNS::Template->new();
    my $newHtml = HNS::Tools::HeadLine::New->new();

    $self->ExpandTempl($templ, $params);
    push(@title,
	 $templ->Expand(SelectTemplate($DayTemplate, %DayTemplate), $params));

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
	    s/"/&quot;/g;
	    s/~$//;

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
		    $para .= "¡¦$rest";
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

	push(@title, $grp . $newHtml->AsHTML($templ, $params));
    }
    $self->title(\@title);
}

sub html_footer($) {
    my $self = shift;
    my $elapse_time = time() - $self->start_time;

    print SelectTemplate($BacktoDiary, %BacktoDiary);

    print qq(
<!-- elapsed time: $elapse_time -->
<hr>
	<div align="right">
	Powered by HNS HeadLine-$Version
<!--	<a href="http://www.h14m.org/">HyperNikkiSystem Project</a> -->
	</div>
</body>
</html>
);
}

package HNS::Tools::HeadLine::New;
use HNS::Diary::Template;
use vars qw(@ISA);
@ISA = qw(HNS::Tools::Title::New HNS::Tools::HeadLine);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template
use vars qw($Template %Template);
$Template = qq(<a href="%href" title="%para">¡¦</a>%content);

1;
