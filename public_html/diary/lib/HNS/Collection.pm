package HNS::Collection;
# $Id: Collection.pm,v 1.19 2003/11/22 08:58:35 togawa Exp $
###############################################################

=head1 NAME

HNS::Collection   :  diary collection class

=head1 SYNOPSIS

  use HNS::Collection;

  my $col = HNS::Collection->new();
  $col->Read($y);
  $col->Print($y, $m, $d);
  #$col->PrintRecent;   # recent

=cut

################################################################
use strict vars;
use ObjectTemplate;
@HNS::Collection::ISA = qw(ObjectTemplate);

use HNS;
use HNS::Diary;
use DateTime::Date;
use HNS::Template;
use HNS::Diary::Template;

#

=head1 MEMBER VARIABLES

 diarys         日記群
 last_modified  最終更新時刻
 mode           モード
 start_time     開始時刻
 end_time       終了時刻
 year,month,day 年月日
 prev,next	prev month, next month

=cut

__PACKAGE__->attributes(qw(diarys last_modified mode start_time end_time year month day
		prev next));
use vars qw(%FootMessages);


=head1 STATIC VARIABLES

 %FootMessage  フットメッセージ

=cut

%FootMessages = 
    ('HasContent'=>"Diary for %num day(s)\n",
     'NoContent' =>"No Match\n");

################################################################
sub initialize($)
{
    my $self = shift;
    $self->diarys({});
}
################################################################

=head2 $c->Read($year, $month, $day);

$year, $month, $day の日記を読み込む。
$day は日付指定のほかに、一桁目指定、旬指定(a,b,c)ができる。

=cut

sub Read($$$$)
{
    my ($self, $year, $month, $day) = @_;

    # set date
    $self->year($year), $self->month($month), $self->day($day);
    # start time
    $self->start_time(time);

    $day = '(0\d|10)' if $day eq "a";
    $day = '(11|12|13|14|15|16|17|18|19|20)' if $day eq "b";
    $day = '(21|22|23|24|25|26|27|28|29|30|31)' if $day eq "c";

    $self->collect_yearly($year);
    for my $ymd (sort keys %{$self->diarys}){
	my $diary = $self->diarys->{$ymd};
	$diary->filename =~ /d(\d+)\.hnf/;
	next unless ($1 =~ /$year$month$day/);
	$diary->Read;
    }

    $self->seek_prev_next_month($year, $month);
}


=head2 $c->ReadDay($month, $day);

$month, $day の日記を読み込む。

=cut

sub ReadDay($$$)
{
    my ($self, $month, $day) = @_;

    # set date
    $self->month($month), $self->day($day);
    # start time
    $self->start_time(time);
    $self->mode('RECENT');

    my $DiaryDir = $HNS::System::DiaryDir;
    my (@files, @years);

    opendir DIR, $DiaryDir;
    @files = grep /^d\d{4,}$month$day\.hnf$/, readdir DIR;
    closedir DIR;

    foreach my $file (@files) {
        my $diary = HNS::Diary->new(filename=>"$DiaryDir/$file");
        $file =~ /^d(.*)\.hnf$/;
        $self->diarys->{$1} = $diary;
    }

    opendir DIR, $DiaryDir;
    @years = grep /^(\d{4,})$/, readdir DIR;
    closedir DIR;
    foreach my $year (@years) {
        my $ymd = $year . $month . $day;
        if ((-f "$DiaryDir/$year/d$ymd.hnf") && 
	(!$self->diarys->{$ymd})) { 
            my $diary = HNS::Diary->new(filename=>
		"$DiaryDir/$year/d$ymd.hnf"); 
	    $self->diarys->{$ymd} = $diary;
	}
    } 

    # read cache file for only cache mode
    if (($HNS::System::Caching) && ($HNS::System::AllowCacheOnly)) {
        my $CacheDir = $HNS::System::CacheDir;
        opendir DIR, $CacheDir;
        @years = grep /^(\d{4,})$/, readdir DIR;
        closedir DIR;
        foreach my $year (@years) {
            my $ymd = $year . $month . $day;
            if ((-f "$DiaryDir/$year/d$ymd.hnf") &&
            (!$self->diarys->{$ymd})) {
                my $diary = HNS::Diary->new(filename=>
                  "$DiaryDir/$year/d$ymd.hnf");
                $self->diarys->{$ymd} = $diary;
            }
        }
    }

    for my $ymd (reverse sort keys %{$self->diarys}){
        my $diary = $self->diarys->{$ymd};
        $diary->Read;
        # set date
        unless ($self->year){
            $self->year($diary->year);
            $self->month($diary->month);
            $self->day($diary->day);
        }
    }

    # set now date if no diary
    unless ($self->year){
        $self->year(sprintf("%04d", $HNS::Status->start_time->year));
        $self->month(sprintf("%02d", $HNS::Status->start_time->month));
        $self->day(sprintf("%02d", $HNS::Status->start_time->day));
    }

    $self->seek_prev_next_month($self->year, $month);
}


=head2 $c->ReadRecent($max);

最新 $max 分を読み込む。

=cut

sub ReadRecent($;$)
{
    my ($self, $max) = @_;
#    $max ||= 5;
    
    $self->start_time(time);
    $self->mode('RECENT');
    my $year = $HNS::Status->start_time->year;

    my $cnt = 0;
    my $y_cnt;
    # read this year and last year, for acrossing year
    # for exapmle: 1999/01/02, 1999/01/01, 1998/12/31, 1998/12/30...
#print "content-type: text/html\n\n";
    while ($cnt<$max){
	# read file info : first this year, second last year
	$self->collect_yearly($year);
	for my $ymd (reverse sort keys %{$self->diarys}){
#print "$cnt $ymd ";
	    my $diary = $self->diarys->{$ymd};
#print "$diary->year $year ";
	    next unless $diary->year == $year;
#print "read<br>";
	    $diary->Read;
	    if ($diary->read_done == 1) { #"OK" is found
	        # last modified
		if ($diary->last_modified > $self->last_modified){
		    $self->last_modified($diary->last_modified);
		}
		# end of reading
		last if (++$cnt>=$max);
	    }
	    # set date
	    unless ($self->year){
		$self->year($diary->year);
		$self->month($diary->month);
		$self->day($diary->day);
	    }
	}
	last if ++$y_cnt>1;  # read done of this year and last year
	$year--;
    }
    # set now date if no diary
    unless ($self->year){
	$self->year(sprintf("%04d", $HNS::Status->start_time->year));
	$self->month(sprintf("%02d", $HNS::Status->start_time->month));
	$self->day(sprintf("%02d", $HNS::Status->start_time->day));
    }

    $self->seek_prev_next_month($self->year, $self->month);
}
# return year-matched file list (directory containted)
# private:
sub collect_yearly ($$)
{
    my ($self, $year) = @_;
    
    for my $dir ($HNS::System::DiaryDir, "$HNS::System::DiaryDir/$year"){
	opendir(DIR, $dir) || next;
#	for my $file (sort readdir(DIR)){
	my $file;
	while ($file = readdir(DIR)){
	    next unless (-f "$dir/$file" &&	# normal file
			 $file =~ /^d($year\d{4})\.hnf$/ &&
			 !$self->diarys->{$1});
	    my $diary = "HNS::Diary"->new(filename=>"$dir/$file");
	    $self->diarys->{$1} = $diary;
	}
    }

    # read cache file for only cache mode
    if (($HNS::System::Caching) && ($HNS::System::AllowCacheOnly)) {
        my $dir = "$HNS::System::CacheDir/$year";
        opendir(DIR, $dir);
        my $file;
        while ($file = readdir(DIR)){
            next unless (-f "$dir/$file" &&	# normal file
                         $file =~ /^($year\d{4})\.xhnf$/ &&
                         !$self->diarys->{$1});
            my $diary = HNS::Diary->new(filename=>
			"$HNS::System::DiaryDir/$year/d$1.hnf");
            $self->diarys->{$1} = $diary;
        }
    }

    return;
}

sub seek_prev_next_month($$$) {
    my ($self, $year, $month) = @_;
    my $DiaryDir = $HNS::System::DiaryDir;
    my @years;

    my $date_prev = "DateTime::Date"->new(year=>$year, month=>$month, day=>1);
    my $date_next = "DateTime::Date"->new(year=>$year, month=>$month, day=>1);
    $date_prev -= '1M';
    $date_next += '1M';

    unless ($HNS::System::StrictCalendarLink) {
        $self->prev($date_prev);
        $self->next($date_next);
        return;
    }

    # checking hnf of prev month existence
    my @exist;  # exist hnf in the month?
    while (!@exist) {
      my $year = $date_prev->year;
      my $month = $date_prev->month;
      $month = sprintf("%02d", $month);
      last unless (-d "$DiaryDir/$year");
      opendir DIR, "$DiaryDir/$year";
      @exist = grep /^d$year$month\d\d\.hnf$/, readdir DIR;
      closedir DIR;
      $date_prev -= '1M' unless @exist;
    }
    # check more
    unless (@exist) {
      opendir DIR, $DiaryDir;
      @years = grep /^(\d{4,})$/, sort readdir DIR; # less Y1K
      closedir DIR;
      foreach my $year (reverse @years) {
        last if @exist;
        if ($year > $date_prev->year) {
          next;
        }
        $date_prev->year($year);
        $date_prev->month(12);
        for (1..12) {
          my $month = $date_prev->month;
          $month = sprintf("%02d", $month);
          opendir DIR, "$DiaryDir/$year";
          @exist = grep /^d$year$month\d\d\.hnf$/, readdir DIR;
          closedir DIR;
          last if @exist;
          $date_prev -= '1M' unless @exist;
        }
      }
    } 

    if (@exist) {
      $self->prev($date_prev);
    }
    else {
      $self->prev('NONE'); 
    }

    # checking hnf of next month existence
    my @exist = ();  # exist hnf in the month?
    while (!@exist) {
      my $year = $date_next->year;
      my $month = $date_next->month;
      $month = sprintf("%02d", $month);
      last unless (-d "$DiaryDir/$year");
      opendir DIR, "$DiaryDir/$year";
      @exist = grep /^d$year$month\d\d\.hnf$/, readdir DIR;
      closedir DIR;
      $date_next += '1M' unless @exist;
    }
    # check more
    unless (@exist) {
      foreach my $year (@years) {
        last if @exist;
        if ($year < $date_next->year) {
          next;
        }
        $date_next->year($year);
        $date_next->month(1);
        for (1..12) {
          my $month = $date_next->month;
          $month = sprintf("%02d", $month);
          opendir DIR, "$DiaryDir/$year";
          @exist = grep /^d$year$month\d\d\.hnf$/, readdir DIR;
          closedir DIR;
          last if @exist;
          $date_next += '1M' unless @exist;
        }
      }
    }

    if (@exist) {
      $self->next($date_next);
    }
    else {
      $self->next('NONE');
    }
}
################################################################

=head2 $c->Print;

表示する

=cut

sub Print($)
{
    my $self = shift;

    my @ymds = sort keys %{$self->diarys};
    @ymds = reverse @ymds if $HNS::System::AlwaysReverse eq "ON" || 
				$self->mode eq 'RECENT';

    my $num;
    for (@ymds){
	my ($md, $diary) = ($_, $self->diarys->{$_});
#	print "md:$md, ";
	next unless $diary->read_done;
	my $reverse_sec;
	if (($self->mode eq 'RECENT') && ($HNS::System::NewReverse)) {
	    $reverse_sec = 1;
	}
	$diary->Print($reverse_sec);
	$num++;
    }
    # Footer
    my $msg_type = $num ? 'HasContent' : 'NoContent';
    my $templ = "HNS::Template"->new();
    print $templ->Expand(SelectTemplate($FootMessages{$msg_type},
					%{$FootMessages{$msg_type}}),
			 { num => $num});
    $self->end_time(time);
}
################################################################
1;
