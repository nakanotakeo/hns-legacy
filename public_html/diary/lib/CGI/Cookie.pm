package CGI::Cookie;
# $Id: Cookie.pm,v 1.6 1999/11/23 15:56:24 tom Exp $
################################################################

=head1 NAME

  CGI::Cookie - クッキーの処理

=head1 SYNOPSIS

 use CGI::Cookie;

 $times = GetCookie("times");

=cut

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(Exporter);
@EXPORT = qw(GetCookie AsCookieHeader);

use DateTime::Time;

BEGIN{
    my $raw_cookie = $ENV{'HTTP_COOKIE'} || $ENV{'COOKIE'};
    for (split("; ", $raw_cookie)){
	my ($key, $value) = split("=");
	$Cookie::Cookies{$key} = $value;
    }
}
################################################################

=head2 GetCookie($name);

クッキー $name の値を返す

=cut

sub GetCookie($)
{
    my $name = shift;
    return $Cookie::Cookies{$name};
}

=head2 AsCookieHeader($name, $value, $expire);

クッキー $name を$value, $expire としてセットする HTTP header を返す

=cut

sub AsCookieHeader($$;$)
{
    my ($name, $value, $expires) = @_;
    my $path = $ENV{'SCRIPT_NAME'};
    $path =~s!/?[^/]+$!!;
#    $path =~s!/[^/]+$!!; $path='/' unless ($path);

    use DateTime::Format;
    if ($expires){
	$expires = sprintf("expires=%s",
			   strftime("%a, %d-%b-%Y %H:%M:%S %Z",
				    gmtime(expire_calc($expires))));
    }
    if ($path) {
      return sprintf("Set-Cookie: %s=%s; path=%s; %s\n",
		 $name, $value, $path,
		 $expires);
    }
    else {
      return sprintf("Set-Cookie: %s=%s; %s\n",
		$name, $value, $expires);
    }
}
################################################################
# thanks to CGI.pm :-)
sub expire_calc {
    my($time) = @_;
    my(%mult) = ('s'=>1,
                 'm'=>60,
                 'h'=>60*60,
                 'd'=>60*60*24,
                 'M'=>60*60*24*30,
                 'y'=>60*60*24*365);
    # format for time can be in any of the forms...
    # "now" -- expire immediately
    # "+180s" -- in 180 seconds
    # "+2m" -- in 2 minutes
    # "+12h" -- in 12 hours
    # "+1d"  -- in 1 day
    # "+3M"  -- in 3 months
    # "+2y"  -- in 2 years
    # "-3m"  -- 3 minutes ago(!)
    # If you don't supply one of these forms, we assume you are
    # specifying the date yourself
    my($offset);
    if (!$time || ($time eq 'now')) {
        $offset = 0;
    } elsif ($time=~/^([+-]?\d+)([mhdMy]?)/) {
        $offset = ($mult{$2} || 1)*$1;
    } else {
        return $time;
    }
    return (time+$offset);
}

1;


