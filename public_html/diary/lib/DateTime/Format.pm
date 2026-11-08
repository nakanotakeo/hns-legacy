# $Id: Format.pm,v 1.3 1999/05/01 02:46:05 tom Exp $
package DateTime::Format;

use strict;
use Exporter;
use DateTime::Time;
use vars qw(@ISA @EXPORT $TZ);
@ISA = qw(Exporter);
@EXPORT = qw(strftime);
$TZ = 'GMT';

###############################################################
sub strftime($@) # static function
{
#    my ($self, $template, $r_lt) = @_;
    my ($template, @ta) = @_;

#    my $self = new Timefmt(year=>$ta[5]+1900, month=>$ta[4]+1, day=>$ta[3],
    my $date = new DateTime::Time
	(year=>$ta[5]+1900, month=>$ta[4]+1, day=>$ta[3],
	 hour=>$ta[2], min=>$ta[1], sec=>$ta[0]);
    
    $template =~ s/%([A-Za-z%])/convert($date, $1)/ge;
    return $template;
}
################################################################
sub convert($$)
{
    my ($date, $char) = @_;

    if ($_ = $date->convert($char)){
	return $_;
    } elsif ($char eq 'Z'){
	return $DateTime::Format::TZ;
    } elsif ($char eq '%'){
	return '%';
    } else {
	die " error: not supperted : $char";
    }
}    

1;

