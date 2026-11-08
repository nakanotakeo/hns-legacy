package DateTime::Date;
# $Id: Date.pm,v 1.11 2000/07/21 12:15:50 masato Exp $
################################################################


=head1 NAME

DateTime::Date - 日付クラス


=cut

use strict;
use ObjectTemplate;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(ObjectTemplate);
@EXPORT = qw(attributes);

__PACKAGE__->attributes(qw(year month day zero_padding));

use Time::Local;
use overload
    "++" => "Increment",
    "--" => "Decrement",
    "+=" => "Increment",
    "-=" => "Decrement",
    "<=>"=> "Compare"
    ;


################################################################
# static variable

=head1 STATIC VARIABLES

 @Days_Month  一ヶ月の日数
 %MonthString 文字列

=cut


@DateTime::Date::Days_Month = (0, 31, 28, 31, 30, 31, 30,
			       31, 31, 30, 31, 30, 31);

%DateTime::Date::MonthString =
    ('ABBR' => ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
		'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
     'FULL' => ['', 'January', 'February', 'March', 'April', 'May', 'June',
		'July', 'August', 'September', 'October', 'November',
		'December']);

%DateTime::Date::WeekString =
    ('ABBR' => ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
     'FULL' => ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday',
		'Friday', 'Saturday'],
     'JAPANESE' => ['日', '月', '火', '水', '木', '金', '土']);


################################################################

=head2 $dt->SetTime($time);

time 値をセットする

=cut

sub SetTime ($$)
{
    my ($self, $time) = @_;
    my ($d, $m, $y) = (gmtime($time))[3..5];
    $self->Set($y+1900, $m+1, $d);
}

=head2 $dt->Set($year, $month, $day);

年月日をセットする

=cut

sub Set($$$$)
{
    my ($self, $y, $m, $d) = @_;
    $self->year($y);
    $self->month($m);
    $self->day($d);
    $self;
}
################################################################
# calc week by gregolian
# contributed by KKI <kki-s@geocities.co.jp>
sub week($)
{
    my $self = shift;
    my $y = $self->year;
    my $m = $self->month;
    $y = $y + 399 if ($m < 3);
    ($y + int($y/4) - int($y/100) + int($y/400) +
     (0, 0, 3, 2, 5, 0, 3, 5, 1, 4, 6, 2, 4)[$m] +
     $self->day
    ) % 7;
#    (localtime(timelocal(0,0,0,$self->day,$self->month-1,$self->year)))[6];
}
sub week_string($$)
{
    my ($self, $mode) = @_;

    return $DateTime::Date::WeekString{uc($mode)}[$self->week];
}
sub month_string ($$)
{
    my ($self, $mode) = @_;
    return $DateTime::Date::MonthString{uc($mode)}[$self->month];
}
################################################################
sub convert ($$)
{
    my ($self, $char) = @_;

    if ($char eq 'y'){
	return $self->year-1900;
    } elsif ($char eq 'Y'){
	return $self->year;
    } elsif ($char eq 'm'){
	return sprintf("%02d", $self->month);
    } elsif ($char eq 'b'){
	return $self->month_string('abbr');
    } elsif ($char eq 'B'){
	return $self->month_string('full');
    } elsif ($char eq 'd'){
	return sprintf("%02d", $self->day);
    } elsif ($char eq 'w'){
	return $self->week;
    } elsif ($char eq 'a'){
	return $self->week_string('abbr');
    } elsif ($char eq 'A'){
	return $self->week_string('full');
    } else {
	return undef;
    }
}
	    
################################################################
# Increment year, month or day
#
# $date->Increment('1M');  or  $date += '1M'; ( use overload )

=head2 $dt->Increment($q);

=head2 $dt += $q;

$q だけ値を増やす。
$q は '3Y', '2M', '1D' など。

=cut

sub Increment ($$)
{
    my ($self, $quantity) = @_;
    my ($num, $unit) = $quantity =~ /^(\d+)([YMD])$/;
    $num = 1 if ($num eq '');
    $unit ||= 'D';
    
    if ($unit eq 'D'){
	for (1..$num){
	    if ($self->day < $self->DaysMonth($self->month)){
		$self->day($self->day+1);
	    } else {
		$self->Increment("1M");
		$self->day(1);
	    }
	}
    } elsif ($unit eq 'M'){
	for (1..$num){
	    if ($self->month < 12){
		$self->month($self->month+1);
	    } else{
		$self->month(1);
		$self->year($self->year+1);
	    }
	}
    } elsif ($unit eq 'Y'){
	$self->year($self->year+$num);
    } else {
	return undef;
    }
    $self;
}

=head2 $dt->Decrement($q);

=head2 $dt -= $q;

$q だけ減らす

=cut

sub Decrement ($;$)
{
    my ($self, $quantity) = @_;
    my ($num, $unit) = $quantity =~ /^(\d+)([YMD])$/;
    $num = 1 if ($num eq '');
    $unit ||= 'D';
    
    if ($unit eq 'D'){
	for (1..$num){
	    if ($self->day > 1){
		$self->day($self->day-1);
	    } else {
		$self->Decrement("1M");
		$self->day($self->DaysMonth($self->month));
	    }
	}
    } elsif ($unit eq 'M'){
	for (1..$num){
	if ($self->month > 1){
	    $self->month($self->month-1);
	} else{
	    $self->month(12);
	    $self->year($self->year-1);
	}
    }
    } elsif ($unit eq 'Y'){
	$self->year($self->year - $num);
    } else {
	return undef;
    }
    $self;
}


=head2 $dt->Compare($dt2);

=head2 $dt <=> $dt2;

比較する

=cut

sub Compare ($$)
{
    my ($self, $obj) = @_;

    return ($self->year <=> $obj->year)
	|| ($self->month <=> $obj->month)
	|| ($self->day <=> $obj->day);
}

################################################################

=head2 $dt->DaysMonth;

その年月の日数

=cut

sub DaysMonth ($)
{
    my $self = shift;
    my $y = $self->year;
    my $m = $self->month;
    if ($m == 2 && (($y%4==0 && $y%100) || ($y%400==0))){  # leap year
	return 29;
    } else {
	return $DateTime::Date::Days_Month[$m];
    }
}
1;
