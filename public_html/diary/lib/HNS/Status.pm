package HNS::Status;
# $Id: Status.pm,v 1.22 2001/09/15 01:56:07 kenji Exp $
################################################################

=head1 NAME

HNS::Status - 状況クラス

=cut

use strict;
use ObjectTemplate;
@HNS::Status::ISA = qw(ObjectTemplate);

use DateTime::Time;
use CGI::Cookie;
use HNS::System;

__PACKAGE__->attributes(qw(id count date_time uri user_agent remote_host referer
	script_name accept jphone is_robot is_mobile style_type 
	calendar_type start_time is mode));
################################################################
sub initialize($)
{
    my $self = shift;

    # environment variable
    $self->uri($ENV{'REQUEST_URI'});
    $self->user_agent($ENV{'HTTP_USER_AGENT'});
    $self->remote_host($ENV{'REMOTE_HOST'} || $ENV{'REMOTE_ADDR'});
    $self->referer($ENV{'HTTP_REFERER'});
    $self->script_name($ENV{'SCRIPT_NAME'});
    $self->accept($ENV{'HTTP_ACCEPT'});
    $self->jphone($ENV{'HTTP_X_JPHONE_MSNAME'});

    # start time
    $self->start_time("DateTime::Time"->new());
    $self->start_time->SetTime(time() + $HNS::System::TZ*3600);
    
    # robot check
    my $ua = $self->user_agent;
    $self->is_robot(1);
    open(F, "$HNS::System::DiaryDir/conf/browser_list.txt") ||
	die "no browser_list.txt";
    while (<F>){
	next if /^$/;
	chomp;
	my $tmp = quotemeta($_);
	if ($ua =~ /^$tmp/){
	    $self->is_robot(0);
	    last;
	}
    }
    close F;
    open(F, "$HNS::System::DiaryDir/conf/robotlist.txt") ||
	die "no robotlist.txt";
    while (<F>){
	next if /^$/;
	chomp;
	my $tmp = quotemeta($_);
	if ($ua =~ /$tmp/) {
	    $self->is_robot(1);
	    last;
	}
    }
    close F;

    # mobile phone check for i system switching
    if ($self->accept =~ /wml/) {	# EZweb/DDI, EZaccess/IDO
	$self->is_mobile(1);
	$self->is_robot(1);
    }
    elsif ($self->jphone =~ /J/) {	# J-SkyWeb/J-PHONE
	$self->is_mobile(1);
	$self->is_robot(1);
    }
    elsif ($ua =~ /^DoCoMo/) {		# iMode/DoCoMo
	$self->is_mobile(1);
	$self->is_robot(1);
    }
    elsif ($ua =~ /^PDXGW/) {		# H",PmailDX/DDI Pocket
	$self->is_mobile(1);
	$self->is_robot(1);
    }
    else {
	open(F, "$HNS::System::DiaryDir/conf/i_browser.txt") ||
	    die "no i_browser.txt";
	while (<F>){
	    next if /^$/;
	    chomp;
	    if ($ua =~ /$_/){
		$self->is_mobile(1);
		$self->is_robot(1);
	    }
	}
	close F;
    }

    # user_agent style
    $self->style_type('Table');
    $self->calendar_type('Table');
    if ($ua){
	open(F, "$HNS::System::DiaryDir/conf/browser_style.txt") ||
	    die "no browser_style.txt";
	while (<F>){
	    next if /^$/ || /^\#/;
	    chomp;
	    my ($the_ua, $style, $calendar) = split(/\s/);
	    if ($ua =~ /$the_ua/){
		$self->style_type($style);
		$self->calendar_type($calendar);
		last;
	    }
	}
	
	close F;
    }
	    
    # cookie
    if ($self->script_name =~ /index.cgi$/) {
	# access to diary
        if ($HNS::System::CookieFlag eq 'ON') { 
	    $self->id(GetCookie('HnsClientID'));
	    $self->count(GetCookie('HnsClientCount'));
	    
	    unless ($self->is_robot){		# normal user agent
	        unless ($self->id) {		# if first visit or lost ID
		    $self->id(uniqID("RURI"));	# then account new ID
	        }
	        $self->count($self->count+1) 
			if $self->script_name =~ /index.cgi$/;
	    		# count up if access to diary
  	    }
	    else {	# robot
	        $self->id('BATTA');
	        $self->count(1);
	    }
        }
	else {
	    $self->id('NONE');
	    $self->count(0);
        }
    }
    else {
	# access to admin pages
	if ($HNS::System::AdminCookieFlag eq 'ON') {
            $self->id(GetCookie('HnsClientID'));
            $self->count(GetCookie('HnsClientCount'));

            unless ($self->is_robot){		# normal user agent
                unless ($self->id) {		# if first visit or lost ID
                    $self->id(uniqID("RURI"));	# then account new ID
                }
            }
	    else {	# robot
                $self->id('BATTA');
                $self->count(1);
            }
        }
	else {
            $self->id('NONE');
            $self->count(0);
	}
    }

    # date, time
    my $time = $self->start_time;
    my $date_time = sprintf("[%04d/%02d/%02d:%02d:%02d:%02d %+2.2d00]",
			    $time->year, $time->month, $time->day,
			    $time->hour, $time->min, $time->sec,
			    $HNS::System::TZ);
    $self->date_time($date_time);

    # intelle search
    if ($HNS::Style::UnagiUse eq "ON") {
	    use HNS::IntelliSearch;
	    $self->is(HNS::IntelliSearch->new(referer => $self->referer));
	    $self->is->GetKeyword();
    }

    # mode 
    if ($HNS::System::Mode eq 'auto') {
	$self->mode($self->script_name ? 'dynamic' : 'static');
    } else {
	$self->mode($HNS::System::Mode);
    }
}

################################################################
sub AsRefererLog ($)
{
    my $self = shift;
    
    return sprintf(qq(%s %s %s %s "%s" "%s" "%s"\n),
		   $self->date_time, $self->remote_host,
		   $self->id, $self->count,
		   $self->uri, $self->referer, $self->user_agent);
}
sub AsDenialLog ($)
{
    my $self = shift;

    if ($self->count == 1) {
	$self->id('NONE') unless $self->id eq "BATTA";
    }

    return sprintf(qq(%s %s %s %s "%s" "%s" "%s"\n),
                   $self->date_time, $self->remote_host,
                   $self->id, $self->count,
                   $self->uri, $self->referer, $self->user_agent);
}
sub AsCookieLog ($)
{
    my $self = shift;

    sprintf("%s:%s:%s:%s\r\n",
	    $self->date_time, $self->id, 
	    $self->remote_host, $self->user_agent);
}

sub PrintCookieHeader($)
{
    my $self = shift;

    my $expires = $HNS::System::CookieExpires;
    print AsCookieHeader('HnsClientID', $self->id, $expires);
    print AsCookieHeader('HnsClientCount', $self->count, $expires);
}
################################################################
sub uniqID($)                # static function
{
    my $prefix = shift;
    # msg00917.html

    my $sec = time;
    my $pid = $$ % 0x10000;
    my $rand = rand(16);
    return sprintf("%s%08x%04x%01x", $prefix, $sec, $pid ,$rand)
}
    
1;
