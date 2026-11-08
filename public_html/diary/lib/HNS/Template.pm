package HNS::Template;
# $Id: Template.pm,v 1.3 1999/11/23 15:56:27 tom Exp $
################################################################

=head1 NAME

HNS::Template - テンプレート展開クラス

=head1 SYNOPSIS

 parameters : %[A-Za-z0-9_]+

   use HNS::Template;
   use $templ = new HNS::Template;
   $cmd_name = "NEW";
   print $templ->Expand("command is %c.", {c=>$cmd_name});
       or
   $templ->SetTemplate("command is %c.");
   $templ->SetParamValues(c=>$cmd_name);
   print $templ->Expand;
   exit;

 result:
   command is NEW.


=cut

################################################################
use strict;
use ObjectTemplate;
$HNS::Template::ISA = qw(ObjectTemplate);

attributes qw(content template);

sub initialize($)
{
    my $self = shift;
    $self->content({});
}

=head2 $t->SetTemplate($template);

$template をテンプレートとして設定

=cut


sub SetTemplate($$)
{
    my ($self, $template) = @_;
    $self->template($template);
}

=head2 $t->SetParamValues(%param);

%param をパラメータとして設定

=cut

sub SetParamValues($%)
{
    my ($self, %parameters) = @_;

    while (my ($k, $v) = each(%parameters)){
	$self->content->{$k} = $v;
    }
}

=head2 $t->Expand($template, $params);

展開して返す

=cut

sub Expand($;$$)
{
    my ($self, $template, $params) = @_;
    $template ||= $self->template;
    $params ||= $self->content;

    $template =~ s/%%/\34/g;
    $template =~ s/%{?([A-Za-z0-9_]+)}?/$$params{$1}/g;
    $template =~ s/\34/%/g;
    return $template;
}
1;
