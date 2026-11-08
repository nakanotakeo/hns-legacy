package HNS::AccessControl;
################################################################
# HNS::AccessControl
# $Id: AccessControl.pm,v 1.15 2001/01/07 13:34:53 kenji Exp $
################################################################
use ObjectTemplate;
@HNS::Admini::ISA = qw(ObjectTemplate);

use strict;
use CGI::Cookie;
use CGI::QueryString;
use HNS::Status;
use HNS::System;

attributes qw(message_file ruri_map_file status);

################################################################
sub initialize($)
{
    my $self = shift;
    $self->status(new HNS::Status);

    my $id = $self->status->id;
    my $count = $self->status->count;
    my $domain = $self->status->remote_host;
    my $agent = $self->status->user_agent;
    my $uri = $self->status->uri;
    my $referer = $self->status->referer;
    my $x_forwarded = $ENV{'HTTP_X_FORWARDED_FOR'};
    my $arg = param('keywords');

    my $tmp;
    my $allow;
    my $deny;

    # access control file
    my $acl_file = "$HNS::System::DiaryDir/conf/access_control.txt";

    if (-f $acl_file) {
      open(ACL, $acl_file) || die "Can't Open File: $acl_file";

      while (<ACL>){
  	chomp;
        $allow = 0;
	$deny = 0;

	if (/^allow: (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*)/) {
	  # ruri_code ip/domain agent referer x_forwarded count arg

          my $acl_id = $1;
          my $acl_domain = $2;
          my $acl_agent = $3;
          my $acl_referer = $4;
          my $acl_x_forwarded = $5;
	  my $acl_count = $6;
	  my $acl_arg = $7;

          if ($acl_id eq "*") {
             $allow++;
          }
          elsif ($id =~ /^$acl_id$/) {
             $allow++;
          }

          if ($acl_domain eq "*") {
             $allow++;
          }          
          else {
            if ($acl_domain =~ /[^\d.]/) {
              if ($domain =~ /$acl_domain$/i) {
                $allow++;
              }
            } else {
              if ($domain =~ /^$acl_domain/){
                $allow++;
              }
            }
          }

          if ($acl_agent eq "*") {
            $allow++;
          }
          elsif ($agent =~ /$acl_agent/) {
            $allow++;
          }

          if ($acl_referer eq "*") {
             $allow++;
          }
          elsif ($referer =~ /^$acl_referer/i) {
            $allow++;
          }

          if ($acl_x_forwarded eq "*") {
            $allow++;
          }
          elsif ($x_forwarded =~ /$acl_x_forwarded/) {
            $allow++;
          }

          if ($acl_count eq "*") {
            $allow++;
          }

          if ($acl_arg eq "*") {
            $allow++;
          }

          if ($allow == 7) {
            return 1;	# access ok
          }
	}
        elsif (/^deny: (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*?) (.*)/) {
	  # ruri_code ip/domain agent referer x_forwarded count arg error_code

          my $acl_id = $1;
          my $acl_domain = $2;
          my $acl_agent = $3;
          my $acl_referer = $4;
          my $acl_x_forwarded = $5;
          my $acl_count = $6;
          my $acl_arg = $7;
          my $acl_error_code = $8;

          if ($acl_id eq "*") {
            $deny++;
          }
          elsif ($id =~ /^$acl_id$/) {
            $deny++;
          }

          if ($acl_domain eq "*") {
            $deny++;
          }
          else {
            if ($acl_domain =~ /[^\d.]/) {
              if ($domain =~ /$acl_domain$/i) {
                $deny++;
              }
            } else {
              if ($domain =~ /^$acl_domain/){
                $deny++;
              }
            }
          }

          if ($acl_agent eq "*") {
            $deny++;
          }
          elsif ($agent =~ /$acl_agent/) {
            $deny++;
          }

          if ($acl_referer eq "*") {
             $deny++;
          }
          elsif ($referer =~ /^$acl_referer/i) {
            $deny++;
          }

          if ($acl_x_forwarded eq "*") {
            $deny++;
          }
          elsif ($x_forwarded =~ /$acl_x_forwarded/) {
            $deny++;
          }

          if ($acl_count eq "*") {
            $deny++;
          }

          if ($acl_arg eq "*") {
            $deny++;
          }

          if ($deny == 7) {
	    if ($HNS::System::Error{$acl_error_code}) {
		print $HNS::System::Error{$acl_error_code};
	    }
	    else {
		print $HNS::System::Error{404};
	    }

            if (-w "$HNS::System::DiaryDir/log/denial_log") {
              my $denial_log = 
		new SimpleDB::Append("$HNS::System::DiaryDir/log/denial_log");
              $denial_log->Append($self->status->AsDenialLog);
            }

            exit 1;
          }
        }
      }

      close (ACL);
    }
}

1;

