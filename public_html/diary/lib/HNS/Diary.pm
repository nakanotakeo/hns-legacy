package HNS::Diary;
# $Id: Diary.pm,v 1.35 2005/01/05 22:44:59 kenji Exp $
################################################################

=head1 NAME

HNS::Diary - diary class

=head1 SYNOPSIS

  use HNS::Diary;

  my $diary = new HNS::Diary(filename=>'d19990331.hnf');
  $diary->Read;
  $diary->Print($reverse_sec);


=head1 DESCRIPTION

 filename attributes must be set in new() or SetFilename()

=cut

################################################################

use strict vars;
use ObjectTemplate;
use DateTime::Date;
use DateTime::Qreki;
use CodeConv;
use HNS::Hnf::TreeBuilder;
use HNS::Hnf::UserVar;
use HNS::Hnf::Warning;
use HNS::Template;
use HNS::Status;
use HNS::Diary::Template;
use HNS::PIM::Schedule;
use Board;
use CGI::QueryString;

#require 'jcode.pl';

use vars qw(@ISA $Head $UserVar $Foot @WeekString);
use vars qw(%Head %Foot);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template
use vars qw($RTMode @RTBuf);		
use vars qw($YoteiHead $YoteiVal $YoteiFoot);
@ISA = qw(ObjectTemplate HNS::Diary::Template);


=head1 MEMBER VARIABLES

 filename
 year,month,day
 tree
 user_var
 last_modified
 read_done

=cut

attributes qw(filename year month day tree user_var last_modified 
	read_done has_user_var);
	      

# template

=head1 STATIC VARIABLES

 $Head
 $Foot
 $UserVar
 @WeekString
 $YoteiHead
 $YoteiVal
 $YoteiFoot

=cut


$Head = qq(<font size="+1">
	   <a href="?%year%month%high&to=%year%month%{day}0#%year%month%{day}0"
	   name="%year%month%{day}0">
	   %year/%month/%day (%week) </a>%user{TENKI}</font><dl>\n);

$UserVar = qq(<div class="uservar">
 %user{TENKI}%user{BASHO}%user{TAIJU}%user{TAION}%user{SUIMIN}%user{BGM}
 %user{HOSU}
</div>);

$Foot = qq(</dd></dl><hr>\n);

#
@WeekString = ('Sun', 'Mon', 'Tue', 'Wed', 'Thr', 'Fri', 'Sat');

$RTMode = 0;	# [0:Normal 1:Push 2:Convert]
@RTBuf  = ();


$YoteiVal = "<li>%value</li>";
$YoteiHead = "Schedule\n<ul>";
$YoteiFoot = "</ul>";

################################################################
sub initialize($)
{
    my $self = shift;

    $self->tree(new HNS::Hnf::TreeBuilder);
    $self->user_var(new HNS::Hnf::UserVar);

    $self->SetFilename($self->filename)
	if ($self->filename);

    $self->has_user_var(0);
}

=head2 $d->SetFilename($filename);

ファイル名をセットする

=cut

sub SetFilename($$)
{
    my ($self, $filename) = @_;
    my ($y, $m, $d) = $self->filename =~ /d(\d{4})(\d{2})(\d{2})\.hnf$/;
    unless ($y && $m && $d){
	die "not hnf file: " . $self->filename;
    }
    $self->year($y), $self->month($m), $self->day($d);
    # set last_modified
    $self->last_modified((stat($self->filename))[9]);

}
################################################################

=head2 $d->Read;

読み込む

=cut

sub Read($)
{
    my $self = shift;
    my $ok;
    my $warning_message;

    my ($year, $month, $day) = ($self->year, $self->month, $self->day);
    my $xhnf = "$HNS::System::CacheDir/$year/$year$month$day.xhnf";

    # xhnf checking
    if ($HNS::System::Caching) {
	# caching on
	if (-f $xhnf) {
	    my $xhnf_lm = (stat($xhnf))[9];
	    if (($self->last_modified == $xhnf_lm)
		|| ($HNS::System::AllowCacheOnly && ! -e $self->filename)) {
		$self->read_done(1);
		return;
	    }
	}
    }

	# UseYoteiView 
    my $YoteiStr = "";
    if ($HNS::System::UseYoteiView) {
        my $sch = new HNS::PIM::Schedule();
        my @yoteis = $sch->get_yotei($year, $month, $day);
        my $val = "";
        my $templ = new HNS::Template;
        for my $y (@yoteis) {
            $templ->SetParamValues(value=>$y);
            $templ->SetTemplate($YoteiVal);
            $val = $val . $templ->Expand;
        }
        if ($val ne "") {
            $YoteiStr = $YoteiHead . $val . $YoteiFoot;			
			unless ($self->user_var->Account("YOTEI", $YoteiStr)){
				$warning_message .=
					&HNS::Hnf::Warning::Message('UndefinedUserVar', "YOTEI");
			}
			else {
				$self->has_user_var(1);
			}
	    }
    }

    # read board data
    Board::read_boarddata();

    # open the file and read
    open (F, $self->filename) || die $self->filename;
    while (<F>){
	# convert kanji charactor code to euc
	CodeConv::toeuc(\$_);
	# convert to entity reference
	s/&/&amp;/g;
	s/>/&gt;/g;
	s/</&lt;/g;

	# CR+LF to LF 
	s/\r$//;

	# parse
	if ($ok){                # body part
	    $self->tree->Parse($_);
	} else {                      # head part
	    if (/^OK$/){                    # line 'OK'
		$ok = 1;
	    } elsif (/^([A-Z]+)\s(.*)$/){   # User Variable
		unless ($self->user_var->Account($1, $2)){
		    $warning_message .=
			&HNS::Hnf::Warning::Message('UndefinedUserVar', $1);
		}
		else {
		    $self->has_user_var(1);
		}
	    } else {                        # illegal line in head part
		$warning_message .= HNS::Hnf::Warning::Message('IllegalHeader');
	    }
	}
    }
    close F;
    $self->read_done(1) if $ok;
    if ($ok && $warning_message){ # OK and warning exist
	$self->tree->{top}->UnshiftContent($warning_message);
    }
}
################################################################

=head2 $d->Print($revserse_sec);

表示する
$revserse_secがTRUEならセクションを逆順に表示する

=cut

sub Print($$)
{
    my $self = shift;
    my $reverse_sec = shift;

    return unless $self->read_done;

    my ($year, $month, $day) = ($self->year, $self->month, $self->day);
    my $dateDayHi = int($day/10);
    my $xhnf = "$HNS::System::CacheDir/$year/$year$month$day.xhnf";

    my $date = new DateTime::Date(year=>$year, month=>$month, day=>$day);

    my $templ = new HNS::Template;
    my $abc;
    if ($day < 11) {
        $abc = "a";
    }
    elsif ($day < 21) {
        $abc = "b";
    }
    else {
        $abc = "c";
    }

    $templ->SetParamValues(year=>$year, month=>$month, day=>$day,
			   high=>int($day/10), abc=>$abc,
			   qreki=>DateTime::Qreki->GetQreki($year, $month, $day),
			   week=>$WeekString[$date->week]);

    # xhnf checking
    if ($HNS::System::Caching) {
	# caching on
	my $date_time = sprintf(qq(%s), $HNS::Status->date_time);
	my $cache_file = "$HNS::System::DiaryDir/log/cache_log";
	if (-f $xhnf) {
	    my $xhnf_lm = (stat($xhnf))[9];
	    # hit
	    if (($self->last_modified == $xhnf_lm)
		|| ($HNS::System::AllowCacheOnly && ! -e $self->filename)) {
		Display ($xhnf, $reverse_sec);
		# hit logging
		if ($HNS::System::CacheLog eq 'ON') {
		    my $cache_log = new SimpleDB::Append("$cache_file"); 
		    $cache_log->Append("$date_time $year$month$day hit\n");
		}

		#unlink $xhnf unless $HNS::System::Caching;
	return;
    }
	}
	else {
	    my $xhnf_dir = "$HNS::System::CacheDir/$year";
	    unless(-d $xhnf_dir) {
		mkdir $xhnf_dir, 0755;
	    }
	}

	# miss logging
	if ($HNS::System::CacheLog eq 'ON') {
	    my $cache_log = new SimpleDB::Append("$cache_file");
	    $cache_log->Append("$date_time $year$month$day miss\n");
	}
    }
    else {
	# caching off
	$HNS::Diary::Hnf = "";
    }

    # head
    my $head = SelectTemplate($HNS::Diary::Head, %HNS::Diary::Head);
    $head =~ s/%user{([A-Z]+)}/$self->user_var->Eval($1)/ge; # user var
    $templ->SetTemplate($head);
    $self->ExpandTempl($templ);

    if ($HNS::System::Caching) {
	open (X, ">$xhnf") || die "can't write cache file, $xhnf";
	eval 'flock(X, LOCK_EX)';
    }

    HnfPrint ($templ->Expand);
    if ($self->has_user_var) {
	my $user_var = $HNS::Diary::UserVar;
	$user_var =~ s/%user{([A-Z]+)}/$self->user_var->Eval($1)/ge; # user var
	$templ->SetTemplate($user_var);
	HnfPrint ($templ->Expand);
    }

    # diarys
    $self->tree->Print($self->year, $self->month, $self->day, 
	$HNS::Diary::section);

    # foot
    # xhnf control code
    HnfPrint ("\n<!-- xhnf_break -->\n");
    $templ->SetTemplate(SelectTemplate($HNS::Diary::Foot, %HNS::Diary::Foot));
    HnfPrint ($templ->Expand);

    if ($HNS::System::Caching) {
	close X;
    }

    utime($self->last_modified, $self->last_modified, $xhnf);

    Display ($xhnf, $reverse_sec);
    #unlink $xhnf unless $HNS::System::Caching;
}


# real display of diary
sub Display ($$) {
    my $xhnf = shift;
    my $reverse_sec = shift;
#print "xhnf: $xhnf<br>\n";

    my @Selected;
    my %Selected;
    my %cat_selected;
   
    my $arg;
    my $QueryString;
    $QueryString = query_string();
    foreach (split('&', $QueryString)) {
	my ($key, $value) = split("=");
	if (defined($value)) {
	    if ($value eq "ALL") {
		$Selected{$key}->[0] = "ALL";
	    } else {
		push(@{$Selected{$key}}, $value);
	    }
	    $arg .= "$_&" if ($key ne "CAT");
	}
    }
    if (length(@{$Selected{CAT}}) == 0) {
	foreach my $cat (split(" ",$HNS::System::CategorySelect)) {
	    $cat_selected{$cat}=1;
	}
    } else {
	foreach my $cat (@{$Selected{CAT}}) {
	    $cat =~ s/%([0-9a-f]{2})/pack('c',hex($1))/gie;
	    CodeConv::toeuc(\$cat);
	    $cat_selected{$cat}=1;
	}
    }

    my %GRP_DB;
    my ($tmp, $tmp2);	# $tmp2 is not for writing to xhnf
    if ($HNS::System::Caching) {
	tie $tmp2, 'SimpleDB::Scalar', "$xhnf", 1;
	$tmp = $tmp2; 
    }
    else {
	$tmp = $HNS::Diary::Hnf;
    }

    if ($HNS::Diary::section) {	# one section display
        my @section = split(/<!-- xhnf_break -->/, $tmp);
        my $last = @section - 1;
	my $count = 1;
	if ($HNS::Diary::section =~ /^G(\d+)/) {	# is GRP section?
	    $HNS::Diary::section = $1;

            while ($count <= $HNS::Diary::section) {
                unless ($section[$count] =~ /^<!-- xhnf_grp (.*) -->$/m) {
                    $HNS::Diary::section++;
                }
                $count++;
            }
 
            $section[$HNS::Diary::section] =~ 
		s/^<!-- xhnf_grp (.*) -->$/<!-- xhnf_grp_p -->/m;
            my @grp = split (" ", $1);
            unless (defined %GRP_DB){
                tie %GRP_DB, 'SimpleDB::Hash',
                "$HNS::System::DiaryDir/conf/group.txt", 1;
            }
            my $id = $HNS::Status->id;
	    $id = "XXXXXXXXXXXXXXXXX" if length($id) < 17;
            foreach my $grp (@grp) {
		if ($grp =~ s/^!//) {	# reversed GRP
		    if ($GRP_DB{$grp} =~ /$id/) {
			$section[$HNS::Diary::section] = "";
		    } 
		}
		else {	# normal GRP
                    unless ($GRP_DB{$grp} =~ /$id/) {
                	$section[$HNS::Diary::section] = "";
                    }
		}
            }
	}
	else {	# normal section
	    while ($count <= $HNS::Diary::section) {
		if ($section[$count] =~ /^<!-- xhnf_grp (.*) -->$/m) {
		    $HNS::Diary::section++;
		}
		$count++;
	    } 
	}
        print $section[0];  # day head
        print $section[$HNS::Diary::section];
        print $section[$last];      # day foot
    }
    else {	# normal, not one section
	my @grp_display;
	while ($tmp =~ /^<!-- xhnf_grp (.*) -->$/m) {
	    $tmp =~ s/^<!-- xhnf_grp (.*) -->$/<!-- xhnf_grp_p -->/m;
	    my @grp = split (" ", $1);
#print "grp: @grp<br>\n";
	    unless (defined %GRP_DB){
		tie %GRP_DB, 'SimpleDB::Hash',
		    "$HNS::System::DiaryDir/conf/group.txt", 1;
	    }
	    my $id = $HNS::Status->id;
	    $id = "XXXXXXXXXXXXXXXXX" if length($id) < 17;
	    my $display = 0;
            foreach my $grp (@grp) {
                if ($grp =~ s/^!//) {	# reversed GRP
		    if ($GRP_DB{$grp} =~ /$id/) {
                        $display = 0;
                    }
		    else {
			$display = 1;
		    }
                }
                else {	# normal GRP
		    if ($GRP_DB{$grp} =~ /$id/) {
		        $display = 1;
		    }
		}
	    }
	    push (@grp_display, $display);
	}
#print "grp_display: @grp_display<br>\n";
	foreach my $flg (@grp_display) {
	    if ($flg) {
		$tmp =~ s/<!-- xhnf_grp_p -->/<!-- xhnf_grp -->/s;
	    }
	    else {
		$tmp =~ s/<!-- xhnf_grp_p -->.*?<!-- xhnf_break -->//s;
	    }
	}


	my @cat_display;
	while ($tmp =~ /^<!-- xhnf_cat (.*) -->$/m) {
	    $tmp =~ s/^<!-- xhnf_cat (.*) -->$/<!-- xhnf_cat_p -->/m;
	    my @cat = split (" ", $1);
#  print "cat: @cat<br>\n";
	    my $display = 0;

	    if (defined($cat_selected{"ALL"})) {
		$display = 1;
	    } else {
		foreach my $cat (@cat) {
  		    if (defined($cat_selected{$cat})) {
			$display = 1;
		    }
		}
	    }	
	    push (@cat_display, $display);
	}
#  print "cat_display: @cat_display<br>\n";
	my $flg_display = 0;
	foreach my $flg (@cat_display) {
	    if ($flg) {
		$tmp =~ s/<!-- xhnf_cat_p -->/<!-- xhnf_cat -->/s;
		$flg_display = 1;
	    }
	    else {
		$tmp =~ s/<!-- xhnf_cat_p -->.*?<!-- xhnf_break -->//s;
	    }
	}

	if ($flg_display || defined($cat_selected{"ALL"})) {
	    if ($reverse_sec) {
		my @out = split(/\<!-- xhnf_break --\>/, $tmp);
		my $dayhead = shift(@out);
		my $dayfoot = pop(@out);
		print join('', $dayhead, reverse(@out), $dayfoot);
	    } else {
		$tmp =~ s/\<!-- xhnf_break --\>//g;
		print $tmp;
	    }
	}
    }
}

sub HnfPrint ($){
	my $hnf_ = shift;

	### RT
	if( $hnf_ =~ /^<\!--RT START-->/ ) { $RTMode = 1; @RTBuf=(); return; }
	if( $hnf_ =~ /^<\!--RT END-->/ ) { $RTMode = 2; }
	if( $RTMode == 1 ) {
		push(@RTBuf, $hnf_);
		return;
	} elsif( $RTMode == 2 ){
		if($HNS::Status->style_type =~ /NoTable/i){
			$hnf_  = "<pre>\n";
			$hnf_ .= join("",@RTBuf);
			$hnf_ .= "</pre>\n";
		} else {
			$hnf_ = HNS::Hnf::Command::RT::rt2html(@RTBuf);
		}
		$RTMode = 0;
	}

	if ($HNS::System::Caching) {
		print X $hnf_;
	}
	else {
		$HNS::Diary::Hnf .= $hnf_;
	}
}

1;

