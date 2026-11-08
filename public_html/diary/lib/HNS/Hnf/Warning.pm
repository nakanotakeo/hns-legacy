package HNS::Hnf::Warning;
# $Id: Warning.pm,v 1.6 2000/07/24 14:39:32 kenji Exp $
################################################################

=head1 NAME

HNS::Hnf::Warning - 警告クラス

=cut

use strict;
use HNS::Template;


################################################################
# warning messages
# parameters:
#  c: $cmd_name
#  p: $pos_name

use vars qw($Head $Foot %Messages);
# appended header, footer
$Head = "<br><font color=red>\[- Warning: ";
$Foot = "-\]</font><br>\n";

# message's template
%Messages =
    ('IllegalHeader' => "illegal header.",
     'Reserved' => "command '%c' is reserved. ",
     'NotDefined' => "term '%t' is not defined in %c definition file.",
     'UndefinedUserVar' => 'undefined user variable: %c',
     'NoMatch' => "command '%c' is not allowed in command '%p'. 
	command '%c' is lost ?",
     'RemoteImage' => "remote image is not supported.",
     'NotFound' => "file '%t' is not found.");

################################################################

=head2 Message($cmd_name, $pos_name, $term);

警告メッセージを返す

=cut

sub Message($;$$$)    # static function
{
    my ($kind, $cmd_name, $pos_name, $term) = @_;

#    my $msg = $Messages{$kind};
    my $template = $Messages{$kind};
    if (! exists $Messages{$kind}){
	return "$Head No such Warning Message: $kind $Foot";
    }
    if ($template){
	my $templ = "HNS::Template"->new();
	$template = "$Head$template$Foot";
	return $templ->Expand($template,
			      {c=>$cmd_name, p=>$pos_name,t=>$term});
    } else {
	return '';
    }
}

1;
