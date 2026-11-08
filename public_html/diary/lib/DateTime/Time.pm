package DateTime::Time;
# $Id: Time.pm,v 1.4 1999/11/23 15:56:25 tom Exp $
################################################################

=head1 NAME

DateTime::Time - 時刻クラス


=cut

use strict;
use DateTime::Date;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(DateTime::Date);
@EXPORT = qw(attributes);

attributes qw(hour min sec);

################################################################

=head2 $dt->SetTime($time);

time 値をセットする

=cut


sub SetTime ($$)
{
    my ($self, $time) = @_;
    my ($min, $sec, $hour, $day, $mon, $year) = gmtime($time);
    $self->Set($year+1900, $mon+1, $day, $hour, $sec, $min);
}

=head2 $dt->Set($year, $month, $day, $hour, $min, $sec);

年月日時分秒をセットする

=cut

sub Set($$$$)
{
    my ($self, $y, $m, $d, $H, $M, $S) = @_;
    $self->SUPER::Set($y, $m, $d);
    $self->hour($H);
    $self->min($M);
    $self->sec($S);
    $self;
}

sub convert ($$)
{
    my ($self, $char) = @_;

    if ($_ = $self->SUPER::convert($char)){
	return $_;
    } elsif ($char eq 'H'){
	return sprintf("%02d", $self->hour);
    } elsif ($char eq 'I'){
	return sprintf("%02d", $self->hour%12);
    } elsif ($char eq 'M'){
	return sprintf("%02d", $self->min);
    } elsif ($char eq 'S'){
	return sprintf("%02d", $self->sec);
    } elsif ($char eq 'p'){
	return ($self->hour < 12) ? 'AM' : 'PM';
    } else {
	return undef;
    }
}
1;
