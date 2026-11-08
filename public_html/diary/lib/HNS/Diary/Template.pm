package HNS::Diary::Template;

# $Id: Template.pm,v 1.3 2001/11/15 12:44:36 kenji Exp $
################################################################

=head1 NAME

  HNS::Diary::Template - diary template class

=head1 SYNOPSIS

  package ModuleName;
  use HNS::Diary::Template;
  @ISA = qw(HNS::Diary::Template);

  sub func($) {
	  my $self = shift ($);
	  my $templ = new HNS::Template;
	  $self->ExpandTempl($templ);
	  $templ->Expand;
  }

=cut

################################################################
use strict vars;
use Exporter;
use vars qw(@ISA @EXPORT);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);
@ISA = qw(Exporter);
@EXPORT = qw(SelectTemplate);

$BaseTemplate = "$HNS::System::MyDiaryURI?%year%month%abc";
$NameTemplate = "%year%month%{day}0";
$HrefTemplate = "%base&amp;to=%name#%name";

sub get_template_variable ($$)
{
    my ($self, $var_name) = @_;

    my $full_var_name = (ref $self) . "::$var_name";
    return $full_var_name->{$HNS::Status->mode}
      if defined $full_var_name->{$HNS::Status->mode};
    return $$full_var_name if defined $$full_var_name;

    # if undefined the class, get from parent class
    my $tmp = (ref $self) . "::ISA";
    my @isa = @$tmp;
    while (@isa){
        my $class = shift(@isa);
	$full_var_name = "${class}::$var_name";
	return $full_var_name->{$HNS::Status->mode}
	  if defined $full_var_name->{$HNS::Status->mode};
	return $$full_var_name if defined $$full_var_name;
	my $tmp = "${class}::ISA";
	unshift(@isa, @$tmp);
    }
    return undef;
}

sub ExpandTempl($$;$)
{
	my ($self, $templ, $params) = @_;

	if ($params) {
		$params->{base} = $templ->Expand($self->get_template_variable('BaseTemplate'),
						 $params);
		$params->{name} = $templ->Expand($self->get_template_variable('NameTemplate'),
						 $params);
		$params->{href} = $templ->Expand($self->get_template_variable('HrefTemplate'),
						 $params);
	} else {
		$templ->SetParamValues(base => $templ->Expand($self->get_template_variable('BaseTemplate')));
		$templ->SetParamValues(name => $templ->Expand($self->get_template_variable('NameTemplate')));
		$templ->SetParamValues(href => $templ->Expand($self->get_template_variable('HrefTemplate')));
	}
}

sub SelectTemplate($%)
{
	my ($common_templ, %mode_templ) = @_;

	$mode_templ{$HNS::Status->mode} || $common_templ;
}
1;

