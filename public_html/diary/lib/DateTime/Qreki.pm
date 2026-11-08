package DateTime::Qreki;
# $Id: Qreki.pm,v 1.1 2002/11/03 05:17:13 kenji Exp $
################################################################

use strict;

my $QREKI;

BEGIN {
	if (-f "lib/qreki.pl") {  # qreki.pl installed
		require "qreki.pl";
		$QREKI = 1;
	}
}

sub GetQreki ($$$)
{
  my ($self, $year, $month, $day) = @_;
	if ($QREKI) {
		$month = $month - 1;
		my $julian_day = &qreki'ut2jd(0, 0, 0, $day, $month, $year);
		my ($qday, $qmonth, $qyear, $leap, $moon_age) = qreki::calc_old($julian_day);
		$qmonth = $qmonth + 1;
		sprintf("%s%d·î%dÆü", ($leap ? '±¼' : ''), $qmonth, $qday);
	}
}

1;
