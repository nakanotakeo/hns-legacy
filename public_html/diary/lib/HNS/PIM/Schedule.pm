package HNS::PIM::Schedule;
# $Id: Schedule.pm,v 1.31 2003/10/27 16:40:11 togawa Exp $
################################################################

=head1 NAME

HNS::PIM::Schedule - スケジュールクラス

=head1 SYNOPSIS

 my $sch = HNS::PIM::Schedule->new(dir=>'diary');
 $sch->Read;
 print $sch->AsHTML;


=cut

################################################################
use strict;
#require 'jcode.pl';
use ObjectTemplate;
use CodeConv;
@HNS::PIM::Schedule::ISA = qw(ObjectTemplate);

use HNS;
use HNS::System;
use HNS::Template;
use HNS::Diary::Template;

__PACKAGE__->attributes(qw(contents error));

################################################################
use vars qw($MaxNum $ContentTemplate $PastContentTemplate $TodayContentTemplate $BeginTemplate $EndTemplate @WeekString @ABCString $Unfixed $Range $RRange $GraceDays $PrintOverMaxNum);
use vars qw(%ContentTemplate %PastContentTemplate %TodayContentTemplate
            %BeginTemplate %EndTemplate);

$MaxNum = 8;                # max number of showing
@WeekString = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');

@ABCString = ('Early', 'Middle', 'Later');
$Unfixed = "??";
$Range = 1;
$RRange = $Range;
$GraceDays = 0;
$PrintOverMaxNum = 0;

# template
$ContentTemplate = qq(<li><strong>%month/%day%week</strong> %content</li>\n);
$TodayContentTemplate = '';
$PastContentTemplate = qq(<li>%month/%day%week %content</li>\n);
$BeginTemplate = "<ul>";
$EndTemplate = "</ul>";

my %dowNum = ('sun', 0, 'mon', 1, 'tue', 2, 'wed', 3,
          'thu', 4, 'fri', 5, 'sat', 6,
          'su',  0, 'mo',  1, 'tu',  2, 'we',  3,
          'th',  4, 'fr',  5, 'sa',  6,
          '日',  0, '月',  1, '火',  2, '水',  3,
          '木',  4, '金',  5, '土',  6);

 
sub initialize($)
{
    my $self = shift;
    $self->contents([]);
}
################################################################

=head2 $t->Read;

データファイルを読み込む

=cut

sub Read ($)
{
    my $self = shift;
    use DateTime::Date;
    my $date = DateTime::Date->new();
    $date->year($HNS::Status->start_time->year);
    $date->month($HNS::Status->start_time->month);
    $date->day($HNS::Status->start_time->day);
    my $id = $HNS::Status->id;
    $id = "XXXXXXXXXXXXXXXXX" if length($id) < 17;
    my %GRP_DB;
    tie (%GRP_DB, 'SimpleDB::Hash',
         "$HNS::System::DiaryDir/conf/group.txt",1);

    my %abc = (A => 10.5, B => 20.5, C => 31.5,
               a => 10.5, b => 20.5, c => 31.5);

    # collect reading file
    my @files;

    my $readMonths = $Range;
    if ($GraceDays > 0) {
        $date-='1M';
        $readMonths++;
    }
    for (0 .. $readMonths) {
        push(@files, $self->get_files($date));
        $date+='1M';
    }

#    print "content-type: text/html\n\n";

    # read yotei files
    for my $file (@files){
        # read file
        open(F, $file) || next;
#   print "$file, ";
        # set default year, month
        my ($y, $m) = $file =~ /y(\d{4})(\d{2})$/;
    
        # read content
        my $isGrouped = 0;
        my $isMyGroup = 0;
        while (<F>){
            next if /^$/;
            CodeConv::toeuc(\$_);
            my ($num, $content) = /^(\S+)\s+(.*)$/;
            if ($num == "GRP") {
                $isGrouped = 1;
                my @grp = split(" ",$content);
                foreach my $grp (@grp) {
                    if ($GRP_DB{$grp} =~ $id) {
                        $isMyGroup = 1;
                    }
                }
                next;
            }
            my $date = DateTime::Date->new(year=>$y, month=>$m);
            if ($num =~ m!^(\d+)/(\d+)$!){     # 03/31 content..
                $date->month($1), $date->day($2);
            } elsif ($num =~ m!^(\d+)$!){      # 31 content..
                $date->day($num);
            } elsif ($num =~ m!^(\d+)/([ABCabc])$!) { # 03/A content ...
                $date->month($1);
                $date->day($abc{$2});
            } elsif ($num =~ m!^[ABCabc]$!) {     # A content ...
                $date->day($abc{$num});
            } else {
                $date->day(32);
            }
            if ($isGrouped != 0) {
                if ($isMyGroup == 0) { 
                    $isGrouped = 0;
                    next;
                }
                $content  ="<font color=\"red\">".$content."</font>";
            }
            push(@{$self->contents}, {date=>$date, content=>$content});
            $isGrouped = 0;
            $isMyGroup = 0;
        }
        close F;
    }
    closedir(DIR);

    # add repeat plan
    my $filename = "$HNS::System::DiaryDir/repeat";
    my @repeats;

    my $isGrouped = 0;
    my $isMyGroup = 0;

    open(F, $filename);
    while(<F>){
        next if /^\s*#/;
        next if /^\s*$/;

        if (/^GRP\s+(.*)$/) {
            $isGrouped = 1;
            my $groups = $1;
            my @grp = split(" ", $groups);
            foreach my $grp (@grp) {
                if ($GRP_DB{$grp} =~ /$id/) {
                    $isMyGroup = 1;
                }
                else {
                    $isMyGroup = 0;
                }
                next;
            }
            next;
        }

        if (/^([^\[\s]+)(?:\[([^\]]+)\])?\s+(.*)$/) {
            my @range = parse_range($2);
            if ($isGrouped == 1) {
                $isGrouped = 0;
                if ($isMyGroup == 0) {
                    next;
                }
                push(@repeats, [$1, "<font color='red'>".$3."</font>", @range]);
            }
            else {
                push(@repeats, [$1, $3, @range]); # [num content begin end]
            }
        } elsif (/^\[([^\]]+)\]\s+(.*)$/) {
            my @range = parse_range($1);
            if ($isGrouped == 0) {
                $isGrouped = 0;
                if ($isMyGroup == 0) {
                    next;
                }
                push(@repeats, ['', "<font color='red'>".$2."</font>", @range]);
            }
            else {
                push(@repeats, ['', $2, @range]); # [num content begin end]
            }
        }
    }
    close F;
    $date->year($HNS::Status->start_time->year);
    $date->month($HNS::Status->start_time->month);
    $date->day($HNS::Status->start_time->day);
    $readMonths = $RRange;
    if ($GraceDays > 0) {
    $date-='1M';
        $readMonths++;
    }
    for (0 .. $readMonths) {
    my ($y, $m) = ($date->year, $date->month);
    $date+='1M';
    foreach my $rplan (@repeats) {
        my ($num, $content, $brng, $erng) = @$rplan;
        my $tmpd = DateTime::Date->new(year=>$y, month=>$m, day=>1);
        my $dmonth = $tmpd->DaysMonth();
        if (@$rplan == 4 && $num ne ''
         && ((sprintf("%04d%02d%02d", $y, $m, $dmonth) < $brng)
          || (sprintf("%04d%02d%02d", $y, $m, 1) > $erng))) {
            next;
        }
        my $d;
        my $m2 = $m;
        if ($num =~ m!^(\d+)/(\d+)$!){        # yearly 1/31 content..
        $m2 = $1;
        $d = $2;
        } elsif ($num =~ m!^(\d+)/([ABCabc])$!) { # yearly 1/A content ...
        $m2 = $1;
        $d = $abc{$2};
        } elsif ($num =~ m!^(\d+)/(-?\d+)([^\d].*)$!) {  # yearly 1/nth week
            my $dow = $3;
        $dow =~ tr/A-Z/a-z/;
            if ($dowNum{$dow} eq '') {
            $d = 32;
            $content = "$num? $content";
        } else {
            $m2 = $1;
            $d = get_nth_dow($y, $m2, $2, $dowNum{$dow});
        }
        } elsif ($num =~ m!^(\d+)$!){         # monthly 31 content..
        $d = $num;
        } elsif ($num =~ m!^[ABCabc]$!) {     # monthly A content ...
        $d = $abc{$num};
        } elsif ($num =~ m!^[Ee]?(-\d+)?$! && $num ne '') { # monthly End content ...
        $d = $dmonth + $1;
        } elsif ($num =~ /^(-?\d+)([^\d].*)$/) {  # monthly nth week
            my $dow = $2;
        $dow =~ tr/A-Z/a-z/;
            if ($dowNum{$dow} eq '') {
            $d = 32;
            $content = "$num? $content";
        } else {
            $d = get_nth_dow($y, $m, $1, $dowNum{$dow});
        }
        } else {
            my $dow = $num;
        $dow =~ tr/A-Z/a-z/;
            if ($dowNum{$dow} ne '') {        # weekly
                for (my $i = 1; $i <= 5; $i++) {
            $d = get_nth_dow($y, $m, $i, $dowNum{$dow});
            my $s = sprintf("%04d%02d%02d", $y, $m, $d);
            if ($d >= 1 && $d <= $dmonth
             && (@$rplan == 2
              || ($s >= $brng && $s <= $erng))) {
                my $tmpd2 = DateTime::Date->new(year=>$y, month=>$m, day=>$d);
                push(@{$self->contents}, {date=>$tmpd2, content=>$content});
            }
            }
            $d = 0;
                $m2 = 0;
        } elsif (@$rplan == 4 && $num eq '') {  # every day with range
            for (my $i = 1; $i <= $dmonth; $i++) {
            my $s = sprintf("%04d%02d%02d", $y, $m, $i);
            if ($s >= $brng && $s <= $erng) {
                my $tmpd2 = DateTime::Date->new(year=>$y, month=>$m, day=>$i);
                push(@{$self->contents}, {date=>$tmpd2, content=>$content});
            }
            }
            $d = 0;
                $m2 = 0;
        } else {
            $content = "$num? $content";
            $d = 32;
        }
        }
        if ($m == $m2 && 1 <= $d && $d <= $dmonth) {
        my $s = sprintf("%04d%02d%02d", $y, $m, $d);
        if ((@$rplan == 2) || ($s >= $brng) && ($s <= $erng)) {
            $tmpd->day($d);
            push(@{$self->contents}, {date=>$tmpd, content=>$content});
        }
        }
    }
    }
}

=head2 $t->AsHTML;

HTML変換して返す

=cut

sub AsHTML($)
{
    my $self = shift;
    my $templ = HNS::Template->new();
    my $cnt;
    my $html;
    my $day;
    my $week;
    my $prev;

    my $now_date = $HNS::Status->start_time;
    my $limit_date = DateTime::Date->new(year=>$now_date->year,
                    month=>$now_date->month,
                    day=>$now_date->day);
    $limit_date -= "${GraceDays}D";
    $html .= SelectTemplate($BeginTemplate, %BeginTemplate);
    
    my $until_date = DateTime::Date->new(year=>$now_date->year,
                    month=>$now_date->month,
                    day=>$now_date->day);
    $until_date += $Range . 'M';
    # error check
    if ($self->error){
    $html .= $self->error;
    }
    for (sort { $a->{date} <=> $b->{date} ||
                $a->{content} cmp $b->{content} } @{$self->contents}){
    next unless $limit_date <= $_->{date} &&   # now and future
        $until_date > $_->{date};              # until next month
    last if (++$cnt > $MaxNum &&               # less than equal $MaxNum
	( $PrintOverMaxNum == 0 || $_->{date} != $prev->{date})); # if this date is different of $Maxnum
    $week = "";
    if ($_->{date}->day == 32) { # Unfixed
        $day = $Unfixed;
    } elsif ($_->{date}->day == 10.5 ) { # early
        $day = $ABCString[0];
    } elsif ($_->{date}->day == 20.5 ) { # middle
        $day = $ABCString[1];
    } elsif ($_->{date}->day == 31.5 ) { # late
        $day = $ABCString[2];
    } else {
        $day = sprintf("%02d", $_->{date}->day);
        $week = '(' . $WeekString[$_->{date}->week] . ')';
    }
    my $template;
    if ($now_date > $_->{date}) {
        $template =  SelectTemplate($PastContentTemplate,
                    %PastContentTemplate);
    } elsif ($now_date == $_->{date}) {
        $template =  SelectTemplate($TodayContentTemplate,
                    %TodayContentTemplate)
          || SelectTemplate($ContentTemplate, %ContentTemplate);
    } else {
        $template =  SelectTemplate($ContentTemplate, %ContentTemplate);
    }
    $html .= $templ->Expand($template,
                {year=>sprintf("%04d", $_->{date}->year),
                 month=>sprintf("%02d", $_->{date}->month),
                 day=>$day,
                 week=>$week,
                 content=>$_->{content}});
    if ( $cnt == $MaxNum && $PrintOverMaxNum != 0) {
	$prev = $_;             # remember this for $PrintOverMaxNum
    }
    }
    $html .= SelectTemplate($EndTemplate, %EndTemplate);
}
################################################################
# private:
sub get_files($$)
{
    my ($self, $date) = @_;
    my @files;
    
    my $file_flat = sprintf("%s/y%04d%02d",
                $HNS::System::DiaryDir,
                $date->year, $date->month);
    my $file_year = sprintf("%s/%04d/y%04d%02d",
                $HNS::System::DiaryDir,
                $date->year, $date->year, $date->month);
    if (-f $file_flat){
    if (-f $file_year){
        $self->set_error("Duplicate: $file_flat, $file_year");
#       die "Dupricate: $file_flat, $file_year";
    }
    push(@files, $file_flat);
    } elsif (-f $file_year){
    push(@files, $file_year);
    }
    return @files;
}

sub set_error($$){
    my ($self, $msg) = @_;
    
    $self->error($msg);
}

#指定年月の第$n$dow曜日($n<0なら月末から数える, $n=-1なら最終)
sub get_nth_dow($$$$) {
    my ($y, $m, $n, $dow) = @_;
    my $dtmp = DateTime::Date->new(year=>$y, month=>$m, day=>1);
    my $days = $dtmp->DaysMonth();
    my $d;
    if ($n > 0) {
#   $dtmp->day(1);
    my $first = $dtmp->week();
    if ($dow >= $first) {
        $d = ($n-1)*7 + $dow - $first + 1;
    } else {
        $d = $n*7 + $dow - $first + 1;
    }
    } elsif($n < 0) {
    $dtmp->day($days);
    my $last = $dtmp->week();
    if ($dow <= $last) {
        $d = $days - ($last - $dow) + ($n+1)*7;
    } else {
        $d = $days - ($last - $dow) + $n*7;
    }
    }
    if ($d < 1 || $d > $days) {
    return 0;
    }
    return $d;
}

# repeatの範囲指定をparseする
# 戻り値: ()                       : 範囲指定なし
#         ('yyyymmdd', 'yyyymmdd') : 範囲の最初と最後の日
sub parse_range($) {
    my ($spec) = @_;
    my @ba = (0, 1, 1);
    my @ea = (9999, 12, 31);
    return () if ($spec eq '');
    if ($spec =~ /^([^-]*)-(.*)$/) {
        my ($b, $e) = ($1, $2);
    if ($b eq '') {
#       @ba = (0, 1, 1);
    } elsif ($b =~ /^\d{4}$/) {
        @ba = ($b, 1, 1);
    } elsif ($b =~ m!^(\d{4})/(\d+)$!) {
        @ba = ($1, $2, 1);
    } elsif ($b =~ m!^(\d{4})/(\d+)/(\d+)$!) {
        @ba = ($1, $2, $3);
    }
    if ($e eq '') {
#       @ea = (9999, 12, 31);
    } elsif ($e =~ /^\d{4}$/) {
        @ea = ($e, 12, 31);
    } elsif ($e =~ m!^(\d{4})/(\d+)$!) {
#       my $tmpd = DateTime::Date->new(year=>$y, month=>$m, day=>1);
#       my $dmonth = $tmpd->DaysMonth();
#       @ea = ($1, $2, $dmonth);
        @ea = ($1, $2, 31);
    } elsif ($e =~ m!^(\d{4})/(\d+)/(\d+)$!) {
        @ea = ($1, $2, $3);
    }
    } else {
        # illegal format
    }
    return (sprintf("%04d%02d%02d", @ba), sprintf("%04d%02d%02d", @ea));
}

################################################################
# return Yotei list of the Day
sub get_yotei($$$$)
{
    my ($self,$year, $month, $day) = @_;
    my $tmpdate = DateTime::Date->new();
    $tmpdate->year($year);
    $tmpdate->month($month);
    $tmpdate->day($day);
    
    my %abc_min = (A => 1, B => 11, C => 21,
           a => 1, b => 11, c => 21);
    my %abc_max = (A => 10, B => 20, C => 31,
           a => 10, b => 20, c => 31);

    my $id = $HNS::Status->id;
    $id = "XXXXXXXXXXXXXXXXX" if length($id) < 17;
    my %GRP_DB;
    tie (%GRP_DB, 'SimpleDB::Hash',
        "$HNS::System::DiaryDir/conf/group.txt",1);

    my @direct;
    my @files = $self->get_files($tmpdate);

    # read yotei files
    for my $file (@files){
        open(F, $file) || next;
        # set default year, month
        my ($y, $m) = $file =~ /y(\d{4})(\d{2})$/;
    
        # read content
        while (<F>){
            next if /^$/;
            CodeConv::toeuc(\$_);
            my ($num, $content) = /^(\S+)\s+(.*)$/;
            my $date = DateTime::Date->new(year=>$y, month=>$m);
            if ($num =~ m!^(\d+)/(\d+)$!){     # 03/31 content..
                $date->month($1), $date->day($2);
                next if ($tmpdate->day != $date->day);
            } elsif ($num =~ m!^(\d+)/([abcABC])$!){     # 03/A content..
                $date->month($1);
                next if ($tmpdate->day < $abc_min{$2} || $tmpdate->day > $abc_max{$2});
            } elsif ($num =~ m!^[abcABC]$!){      # A content..
                next if ($tmpdate->day < $abc_min{$num} || $tmpdate->day > $abc_max{$num});
            } elsif ($num =~ m!^(\d+)$!){      # 31 content..
                $date->day($num);
                next if ($tmpdate->day != $date->day);
            } else {
                next; # ignored
            }
            push(@direct, $content);
        }
        close F;
    }
    closedir(DIR);
 
    # read repeat plan file
    my $filename = "$HNS::System::DiaryDir/repeat";
    my @repeats;

    my $isGrouped = 0;
    my $isMyGroup = 0;

    open(F, $filename);
    while(<F>){
        next if /^\s*#/;
        next if /^\s*$/;

        if (/^GRP\s+(.*)$/) {
print "2GRP $1 ";
            $isGrouped = 1;
            my $groups = $1;
            my @grp = split(" ", $groups);
            foreach my $grp (@grp) {
                if ($GRP_DB{$grp} =~ /$id/) { 
                    $isMyGroup = 1;
                }
                else {
                    $isMyGroup = 0;
                }
                next;
            }
            next;
        }

        CodeConv::toeuc(\$_);
        if (/^([^\[\s]+)(?:\[([^\]]+)\])?\s+(.*)$/) {
            my @range = parse_range($2);
            if ($isGrouped == 1) {
                $isGrouped = 0;
                if ($isMyGroup == 0) {
                    next;
                }
                push(@repeats, [$1, "<font color='red'>".$3."</font>", @range]);
            }
            else {
                push(@repeats, [$1, $3, @range]); # [num content begin end]
            }
        } elsif (/^\[([^\]]+)\]\s+(.*)$/) {
            my @range = parse_range($1);
            if ($isGrouped == 0) {
                $isGrouped = 0;
                if ($isMyGroup == 0) {
                    next;
                }
                push(@repeats, ['', "<font color='red'>".$2."</font>", @range]);
            }
            else {
                push(@repeats, ['', $2, @range]); # [num content begin end]
            }
        }
    }
    close F;
    foreach my $rplan (@repeats) {
    my ($num, $content, $brng, $erng) = @$rplan;
    my $dmonth = $tmpdate->DaysMonth();
    my $datestr = sprintf("%04d%02d%02d", $tmpdate->year, $tmpdate->month, $tmpdate->day);
    next if ($brng ne '' && ($datestr < $brng));
    next if ($erng ne '' && ($datestr > $erng));

    my $d = 0;
    my $m = $tmpdate->month;
    if ($num =~ m!^(\d+)/(\d+)$!){        # yearly 1/31 content..
        $m = $1;
        $d = $2;
    } elsif ($num =~ m!^(\d+)/([ABCabc])$!) { # yearly 1/A content ...
        if ($abc_min{$2} <= $day && $day <= $abc_max{$2}) {
        $m = $1;
        $d = $tmpdate->day;
        }
    } elsif ($num =~ m!^(\d+)/(-?\d+)([^\d].*)$!) {  # yearly 1/nth week
        my $dow = $3;
        $dow =~ tr/A-Z/a-z/;
        if ($dowNum{$dow} eq '') {
        $d = 32;
        $content = "$num? $content";
        } else {
        $m = $1;
        $d = get_nth_dow($tmpdate->year, $m, $2, $dowNum{$dow});
        }
    } elsif ($num =~ m!^(\d+)$!){         # monthly 31 content..
        $d = $num;
    } elsif ($num =~ m!^[ABCabc]$!) {     # monthly A content ...
        if ($abc_min{$num} <= $tmpdate->day && $tmpdate->day <= $abc_max{$num}) {
        $d = $tmpdate->day;
        }
    } elsif ($num =~ m!^[Ee]?(-\d+)?$! && $num ne '') { # monthly End content ...
        $d = $dmonth + $1;
    } elsif ($num =~ /^(-?\d+)([^\d].*)$/) {  # monthly nth week
        my $dow = $2;
        $dow =~ tr/A-Z/a-z/;
        if ($dowNum{$dow} eq '') {
        $d = 32;
        $content = "$num? $content";
        } else {
        $d = get_nth_dow($tmpdate->year, $tmpdate->month, $1, $dowNum{$dow});
        }
    } else {
        my $dow = $num;
        $dow =~ tr/A-Z/a-z/;
        if ($dowNum{$dow} ne '') {        # weekly
        $d = get_nth_dow($tmpdate->year, $tmpdate->month, 1, $dowNum{$dow});
        if (($d - $tmpdate->day) % 7 == 0) {
            $d = $tmpdate->day;
        }
        } elsif (@$rplan == 4 && $num eq '') {  # every day with range
        $d = $tmpdate->day;
        } else {
        $content = "$num? $content";
        $d = 32;
        }
    }
    if ($m == $tmpdate->month && $d == $tmpdate->day) {
        push(@direct, $content);
    }
    }
   
    return @direct;
}

1;
