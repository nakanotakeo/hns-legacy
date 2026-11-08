package HNS::Calendar::Direct;
# $Id: Direct.pm,v 1.5 2002/10/05 13:55:58 kenji Exp $
################################################################


=head1 NAME

HNS::Calendar::Direct - 直接カレンダークラス

=head1 SYNOPSIS

  my $cal = new HNS::Calendar::Direct(year=>$y, month=>$m, day=>$d);
  print $cal->AsHTML;

=cut

################################################################
use strict;
use HNS::DateSelect;
@HNS::Calendar::Direct::ISA = qw(HNS::DateSelect);

attributes qw(year month day);
use vars qw($SubmitLabel);

$SubmitLabel = "Go!";
################################################################
sub AsHTML ($)
{
    my $self = shift;
    my $html;

    $html = qq(<form action="$HNS::System::MyDiaryURI" method="get">);
    $html .= $self->SUPER::AsHTML($self->year, $self->month, $self->day, $SubmitLabel);
    $html .= qq(</form>);
    return $html;
}
1;

