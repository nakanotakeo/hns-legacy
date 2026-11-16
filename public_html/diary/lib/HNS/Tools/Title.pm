package HNS::Tools::Title;
# $Id: Title.pm,v 1.8 2003/05/28 04:52:58 togawa Exp $
# Title.pm 2001/5/6 ari@mbf.sphere.ne.jp (Akihiro Arisawa)
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
use SimpleDB::Hash;
use DateTime::Date;
use CodeConv;
use HNS::Status;
use HNS::Hnf::Command;
use HNS::Diary::Template;
use ObjectTemplate;
use CGI::Tools;

use vars qw(@ISA);
use vars qw($Range);
use vars qw($CatTemplate $CatLinkTemplate $HeadTitle $Header $BacktoDiary
	    %CatTemplate %CatLinkTemplate %HeadTitle %Header %BacktoDiary);
use vars qw($NKF $NKF_USE);
use vars qw($Version);

@ISA = qw(HNS::Diary::Template ObjectTemplate);
__PACKAGE__->attributes(qw(arg mode files title cat_title start_time));

# customizable variables at config.ph.
$Range = 3;

require './config.ph';

# customizable variables at theme.ph
$CatTemplate = qq(<h3>%img<a href="title.cgi?%{arg}CAT=%enc_var">%var</a></h3>\n);
$CatLinkTemplate = qq([<a href="title.cgi?%{arg}CAT=%enc_var">%var</a>]);

$HeadTitle = qq(<title>$HNS::System::Title Title List</title>\n);
$Header = qq(<h1><a href="$HNS::System::MyDiaryURI">$HNS::System::Title</a> Title List</h1>\n);
$BacktoDiary =
        qq(<div align="right"><a href="$HNS::System::MyDiaryURI">Back to Diary</a></div>\n);

################################################################
# global variables
my @Selected;
my %Selected;
my %GRP_DB;

sub initialize($)
{
    my $self = shift;

    $self->start_time(time());
    $self->files({});
}

sub main ($) {
    my $self = shift;

    $self->getArg();
    $self->html_header();
    $self->getFileList();

    my %files = %{$self->files};
    foreach (($self->mode ne 'recent' && $HNS::System::AlwaysReverse eq "OFF")
	     ? sort keys(%files) : reverse sort keys(%files)) {
	$self->readHnf($_, 'title');
    }

    $self->html_body();
    $self->html_footer();
}

sub getArg () {
    my $self = shift;
    my $method = $ENV{'REQUEST_METHOD'};
    my $query;
    my $arg;

    if ($method eq 'GET' || $method eq 'HEAD') {
	$query = $ENV{'QUERY_STRING'};
    } elsif ($method eq 'POST') {
	read(STDIN, $query, $ENV{'CONTENT_LENGTH'});
    } else {
	$query = join('&', @ARGV);
    }

    foreach (split('&', $query)) {
	my ($key, $value) = split("=");
	if (defined($value)) {
	    if ($value eq "ALL") {
		$Selected{$key}->[0] = "ALL";
	    } else {
		push(@{$Selected{$key}}, $value);
	    }
	    $arg .= "$_&" if ($key ne "CAT");
	} else {
	    if ($key =~ /^(\d{4})/) {
		push(@Selected, $key);
		$arg .= "$key&";
	    }
	}
    }
    $self->arg($arg);
}


sub html_header($) {
    my $self = shift;

    if ($HNS::Status->mode ne 'static') {
	print qq(Content-Type: text/html; charset=EUC-JP\r\n\r\n);
    }

    print $HNS::ExtHTML::DOCTYPE;
    if ($HNS::System::Lang) {
	print qq(<html lang="$HNS::System::Lang">\n<head>\n);
    } else {
	print qq(<html>\n<head>\n);
    }

    print qq(<meta http-equiv="Content-Type" content="text/html; charset=EUC-JP">\n);

    print SelectTemplate($HNS::ExtHTML::Head, %HNS::ExtHTML::Head);
#    print SelectTemplate($HeadTitle, %HeadTitle);
    print $self->get_template_variable('HeadTitle');

    print qq(</head>\n\n);
    print qq(<body $HNS::ExtHTML::BodyVal>\n);

    print $self->get_template_variable('Header');
}


sub html_footer($) {
    my $self = shift;
    my $elapse_time = time() - $self->start_time;

    print $self->get_template_variable('BacktoDiary');

    print qq(
<!-- elapsed time: $elapse_time -->
<hr>
	<div align="right">
	Powered by HNS Title List-$Version,
	<a href="http://www.h14m.org/">HyperNikkiSystem Project</a>
	</div>
</body>
</html>
);
}


sub getFileList($;$) {
    my ($self, $num) = @_;

    $self->mode('recent');

    if (@Selected) { # ?2001, ?200105, ?2001050, ?200105a
	$self->mode(undef);

	foreach my $selected (@Selected) {
	    $self->getFileListByPattern($self->diaryDir(substr($selected, 0, 4)),
					$selected);
	}
    }

    if (defined($Selected{YEAR})) { # YEAR=2001&MONTH=5
	my %pat;

	$self->mode(undef);

	foreach my $year (@{$Selected{YEAR}}) {
	    my $dir = $self->diaryDir($year);
	    $pat{year} = $year;
	    if (defined($Selected{MONTH}) && $Selected{MONTH}->[0] ne "ALL") {
		foreach my $month (@{$Selected{MONTH}}) {
		    $pat{month} = $pat{year} . sprintf("%02d", $month);
		    if (defined($Selected{DAY}) &&
			$Selected{DAY}->[0] ne "ALL") {
			foreach my $day (@{$Selected{DAY}}) {
			    $pat{day} = $pat{month} . $day;
			    $self->getFileListByPattern($dir, $pat{day});
			}
		    } else {
			$self->getFileListByPattern($dir, $pat{month});
		    }
		}
	    } else {
		$self->getFileListByPattern($dir, $pat{year});
	    }
	}
    }

    if ($self->mode eq 'recent') { # Recent
	#	my $date = $HNS::Status->start_time;
	my $date = "DateTime::Date"->new(
	    year  => $HNS::Status->start_time->year,
	    month => $HNS::Status->start_time->month,
	    day   => $HNS::Status->start_time->day
	    );
	if ($num) {
	    while ($date->year >= $HNS::System::StartYear &&
		   keys %{$self->files} < $num) {
		$self->getFileListByPattern($self->diaryDir($date->year),
					    $date->year);
		$date -= '1Y';
	    }
	} else {
	    if ($Range < 0) {
		$Range = $Range * -1 + 1;
		$date += $Range-1 . 'M';
	    }
	    foreach (1 .. $Range) {
		last if ($date->year < $HNS::System::StartYear);
		$self->getFileListByPattern($self->diaryDir($date->year),
					    $date->year . sprintf("%02d", $date->month));
		$date -= '1M';
	    }
	}
    }
}

sub getFileListByPattern($$$) {
    my ($self, $dir, $pat) = @_;
    my @files;
    my %files = %{$self->files};

    $pat =~ s/[abc]$/{'a' => '(0\d|10)',
		      'b' => '(11|12|13|14|15|16|17|18|19|20)',
		      'c' => '(21|22|23|24|25|26|27|28|29|30|31)'}->{$&}/e;
    opendir DIR, $dir or die "can't open directory: $!";
    @files = grep /^d$pat\d{0,4}.hnf$/, readdir DIR;    # Y10K
    closedir DIR;
    foreach (@files) {
	$files{$_} = "$dir/$_";
    }
    $self->files(\%files);
}

sub diaryDir($$) {
    my ($self, $year) = @_;;

    if (-d $HNS::System::DiaryDir . "/" . $year) {
	$HNS::System::DiaryDir . "/" . $year;
    } else {
	$HNS::System::DiaryDir;
    }
}

sub readHnf ($$;$) {
    my ($self, $hnf, $cache_suffix) = @_;

    if ($HNS::System::Caching && $cache_suffix) {
	$hnf =~ /d((\d+)\d{4})\.hnf$/;
	my $cache = "$HNS::System::CacheDir/$2/$1.$cache_suffix";
	my $lm = (stat($self->files->{$hnf}))[9];
	if (-e $cache && $lm == (stat($cache))[9]) { # use cache
	    my @new = @{$self->title};
	    my %cat = %{$self->cat_title};
	    open(CACHE, $cache);
	    while (<CACHE>) {
		if (/^<!-- CAT:(.*?) -->/) {
		    push(@{$cat{$1}}, $');
		} else {
		    push(@new, $_);
		}
	    }
	    close(CACHE);
	    $self->title(\@new);
	    $self->cat_title(\%cat);
	} else { # generate cache
	    mkdir "$HNS::System::CacheDir/$2", 0755
	      unless (-d "$HNS::System::CacheDir/$2");
	    my @new = @{$self->title}; $self->title([]);
	    my %cat = %{$self->cat_title}; $self->cat_title({});
	    $self->readHnf1($hnf);
	    open(CACHE, "> $cache");
	    foreach (@{$self->title}) {
		push(@new, $_);
		print CACHE "$_\n";
	    }
	    foreach my $cat (keys %{$self->cat_title}) {
		foreach (@{$self->cat_title->{$cat}}) {
		    push(@{$cat{$cat}}, $_);
		    print CACHE "<!-- CAT:$cat -->$_\n";
		}
	    }
	    close(CACHE);
	    utime($lm, $lm, $cache);
	    $self->title(\@new);
	    $self->cat_title(\%cat);
	}
    } else {
	$self->readHnf1($hnf);
    }
}

sub readHnf1($$) {
    my ($self, $hnf) = @_;
    my ($ok, $newCount, $subCount);
    my (@hnf, $text);
    $hnf =~ /d(\d+)(\d\d)(\d\d)\.hnf/;
    my $params = { year => $1, month => $2, day => $3, high => int($3/10),
		   abc => ($3 <= 10 ? 'a' : $3 <= 20 ? 'b' : 'c'),
		   arg => $self->arg};

    if ($NKF_USE) {
	open (HNF, "$NKF -emXZ1 $self->files->{$hnf} |") || die "can't open hnf: $!";
    } else {
	open (HNF, $self->files->{$hnf}) || die "can't open hnf: $!";
    }
    while (<HNF>) {
	s/\r?\n?$//;

	if (! $ok) { # hnf header
	    if (/^OK$/) {  # line 'OK'
		$ok = 1;
	    } elsif (/^([A-Z]+)\s/) {  # User Variable
		;
	    } else {  # illegal hnf header
		last;
	    }
	} else { # hnf body
	    CodeConv::toeuc(\$_) unless ($NKF_USE);

	    # convert to entity reference
	    s/&/&amp;/g;
	    s/>/&gt;/g;
	    s/</&lt;/g;

	    if (/^(GRP|CAT|NEW|LNEW|RLNEW) ?/) {
		if ($1 eq "GRP") {
		    $hnf[$newCount]->{grp} = $';
		} elsif ($1 eq "CAT") {
		    $hnf[$newCount]->{cat} = $';
		} else {
		    $hnf[$newCount]->{new} = $_;
		    $text = \@{$hnf[$newCount]->{text}};
		    $newCount++;
		    $subCount = 0;
		}
	    } elsif (/^(SUB|LSUB|RLSUB)/) {
		$hnf[$newCount-1]->{sub}->[$subCount]->[0] = $_;
		$text = \@{$hnf[$newCount-1]->{sub}->[$subCount]};
		$subCount++;
	    } else {
		push(@{$text}, $_);
	    }
	}
    }
    close(HNF);

    $self->Parse($params, @hnf);
}

sub Parse($$@) {
    my ($self, $params, @hnf) = @_;
    my ($grpCount, $newCount, $subCount);
    my $templ = HNS::Template->new();
    my $id;

    my $newHtml = HNS::Tools::Title::New->new();
    my $subHtml = HNS::Tools::Title::Sub->new();

    my @new = @{$self->title};
    my %cat = %{$self->cat_title};

    foreach my $new (@hnf) {
	my $cat_link;
	my $grp;
	if ($new->{grp}) {
	    $grpCount++;
	    $params->{new} = "G" . $grpCount;
	    $params->{mark} = $HNS::Hnf::Command::GRP::Mark;
	    $grp = "<!-- GRP:" . $new->{grp} . " -->";
	} else {
	    $newCount++;
	    $params->{new} = $newCount;
	    $params->{mark} = $newCount;
	    $grp = "";
	}
	if ($new->{new} =~ /^NEW ?/) {
	    $params->{content} = $';
	} elsif ($new->{new} =~ /^LNEW /) {
	    $params->{content} = $newHtml->ConvUrl($');
	} elsif ($new->{new} =~ /^RLNEW /) {
	    $params->{content} = $newHtml->ConvRlink($');
	}
	$params->{cat_link} = $cat_link;

	if ($new->{cat}) {
	    my $html = $grp . $newHtml->AsHTML($templ, $params);
	    foreach my $cat (split(' ', $new->{cat})) {
		push(@{$cat{$cat}}, $html);

		$params->{var} = $params->{enc_var} = $cat;
		$params->{enc_var} =~ s/([^a-zA-Z0-9~\-\_\.\/\:\%])/
		  sprintf("%%%02X",ord($1))/ge;
		# fix Cross Site Scripting bug
		$params->{enc_var} = CGI::Tools::Escape($params->{enc_var});
		$cat_link .=
		  $templ->Expand(SelectTemplate($CatLinkTemplate,
						%CatLinkTemplate),
				 $params);
	    }
	}
	$params->{cat_link} = $cat_link;
	push(@new, $grp . $newHtml->AsHTML($templ, $params));

	my $subCount;
	foreach my $sub (@{$new->{sub}}) {
	    $params->{sub} = ++$subCount;
	    if ($sub->[0] =~ /^SUB ?/) {
		$params->{content} = $';
	    } elsif ($sub->[0] =~ /^LSUB /) {
		$params->{content} = $subHtml->ConvUrl($');
	    } elsif ($sub->[0] =~ /^RLSUB /) {
		$params->{content} = $subHtml->ConvRlink($');
	    }

	    my $html = $grp . $subHtml->AsHTML($templ, $params);
	    if ($new->{cat}) {
		foreach my $cat (split(' ', $new->{cat})) {
		    push(@{$cat{$cat}}, $html);
		}
	    }
	    push(@new, $html);
	}
    }

    $self->title(\@new);
    $self->cat_title(\%cat);
}

sub html_body($) {
    my $self = shift;
    my $templ = HNS::Template->new();
    my %CAT_DB;
    my %selected_cat;
    my %cat = %{$self->cat_title};
    my @new = @{$self->title};

    if ($Selected{CAT}->[0] eq "ALL") {
	foreach (keys %cat) {
	    my $enc_cat = $_;
	    $enc_cat =~ s/([^a-zA-Z0-9~\-\_\.\/\:\%])/sprintf("%%%02X",ord($1))/ge;
	    # fix Cross Site Scripting bug
	    $enc_cat = CGI::Tools::Escape($enc_cat);
	    $selected_cat{$_} = $enc_cat;
	}
    } else {
	foreach (@{$Selected{CAT}}) {
	    my $cat = $_;
	    $cat =~ s/%([\dA-Fa-f][\dA-Fa-f])/pack("C", hex($1))/ge;
	    $cat = CGI::Tools::Escape($cat);	# fix Cross Site Scripting bug
	    $selected_cat{$cat} = $_;
	}
    }

    if (%selected_cat) {
	tie %CAT_DB, 'SimpleDB::Hash', "$HNS::CategoryList::CatDir/cat.txt";
	foreach my $cat (keys(%selected_cat)) {
	    # fix Cross Site Scripting bug
	    $cat = CGI::Tools::Escape($cat);
	    $self->arg(CGI::Tools::Escape($self->arg));

	    $templ->SetParamValues('var' => $cat);
	    $templ->SetParamValues('enc_var' => $selected_cat{$cat});
	    $templ->SetParamValues('arg' => $self->arg);
	    my $img = "$HNS::CategoryList::CatDir/$CAT_DB{$cat}";
	    $templ->SetParamValues('img' => -f $img ?
				   qq(<img src="$img" alt="$cat">) : "");
	    print $templ->Expand(SelectTemplate($CatTemplate, %CatTemplate));

	    foreach my $title (@{$cat{$cat}}) {
		next unless ($self->check_grp($title));
		print "$title<br>\n";
	    }
	}
    } else {
	foreach my $title (@new) {
	    next unless ($self->check_grp($title));
	    print "$title<br>\n";
	}
    }
}

sub check_grp($$) {
    my ($self, $content) = @_;

    if ($content =~ /^<!-- GRP:(.*) -->/) {
	unless (tied %GRP_DB) {
	    tie %GRP_DB, 'SimpleDB::Hash',
	      "$HNS::System::DiaryDir/conf/group.txt", 1;
	}
	my $id = $HNS::Status->id;
	$id = "XXXXXXXXXXXXXXXXX" if length($id) < 17;

	foreach my $grp (split(' ', $1)) {
	    if ($grp =~ s/^!//) {   # reversed GRP
                unless ($GRP_DB{$grp} =~ /$id/) {
                    return 1;
		}
	    }
            else {	# normal GRP 
	        if ($GRP_DB{$grp} =~ /$id/) {
		    return 1;
	        }
	    }
	}
	return 0;
    } else {
	return 1;
    }
}

package HNS::Tools::Title::Hnf;
require HNS::Diary::Template;
use vars qw(@ISA);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template
use vars qw($Template %Template);
@ISA = qw(HNS::Diary::Template);

$BaseTemplate = "$HNS::System::MyDiaryURI?%year%month%abc";
$HrefTemplate = "%base#%name";
my %RLINK_DB;

sub new($)
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub DESTROY($)
{
}

sub ConvUrl($$)
{
    my $self = shift;
    my ($tmp, $cmd_arg) = split(' ', shift, 2);
    my $ConvUrl = HNS::Hnf::Command::ConvUrl->new();

    $ConvUrl->ConvUrl(\$tmp);
    qq(<a href="$tmp">$cmd_arg</a>);
}

sub ConvRlink($$)
{
    my $self = shift;
    my ($rlink, $add, $cmd_arg) = split(' ', shift, 3);

    unless (tied %RLINK_DB){
	tie %RLINK_DB, 'SimpleDB::Hash',
	  "$HNS::System::DiaryDir/conf/rlink.txt", 1;
    }
    qq(<a href="$RLINK_DB{$rlink}$add">$cmd_arg</a>);
}

sub AsHTML ($$$)
{
	my ($self, $templ, $params) = @_;
	$self->ExpandTempl($templ, $params);
	$templ->Expand($self->get_template_variable('Template'), $params);
}

package HNS::Tools::Title::New;
use HNS::Diary::Template;
use vars qw(@ISA);
@ISA = qw(HNS::Tools::Title::Hnf);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template
use vars qw($Template %Template);
$NameTemplate = "%year%month%day%new";
$Template = qq(<a href="%href">%year/%month/%day#%mark</a>: %cat_link %content);

package HNS::Tools::Title::Sub;
use HNS::Diary::Template;
use vars qw(@ISA);
@ISA = qw(HNS::Tools::Title::Hnf);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template
use vars qw($Template %Template);
$NameTemplate = "%year%month%day%{new}S%sub";
$Template = qq(... <a href="%href">¡÷</a> %content);

1;
