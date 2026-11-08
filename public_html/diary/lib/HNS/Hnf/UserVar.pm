package HNS::Hnf::UserVar;
# $Id: UserVar.pm,v 1.9 2000/10/21 11:32:05 kenji Exp $
################################################################

=head1 NAME

HNS::Hnf::UserVar - ユーザ変数クラス

=cut

################################################################
use strict;
use ObjectTemplate;
use vars qw(@ISA %Templates %Aliases);

@ISA = qw(ObjectTemplate);
attributes qw(content);

%Templates = (TENKI  => "[%value]",
	      BASHO  => "(%value)",
	      TAION  => " Temperature:%value",
	      TAIJU  => " Weight:%value" . "Kg",
	      SUIMIN => " Hours of Sleep:%value",
	      BGM    => " BGM:%value",
	      HOSU   => " %value" . " steps",
	      HON    => " %value",
	      KITAKU => " Homecoming: %value",
	      WALK   => " Walk: %value",
	      RUN    => " Run: %value");

%Aliases = (WEATHER     => "TENKI",
	    LOCATION    => "BASHO",
	    WEIGHT      => "TAIJU",
	    TEMPERATURE => "TAION",
	    SLEEP       => "SUIMIN",
	    STEP        => "HOSU",
	    BOOK	=> "HON",
	    HOMECOMING	=> "KITAKU");

################################################################	
sub initialize($)
{
    my $self = shift;
    $self->content({});
}

=head2 $u->Account($name, $value);

ユーザ変数 $name の値を $value と設定する

=cut

sub Account($$$)
{
    my ($self, $name, $value) = @_;

    if ($Aliases{$name}) {
	$name = $Aliases{$name};
    }
    $self->content->{$name} = $value;
    return exists $Templates{$name};
}

=head2 $u->Eval($name);

$name を eval して返す

=cut

sub Eval($$)
{
    my ($self, $name) = @_;

    if ($Aliases{$name}) {
        $name = $Aliases{$name};
    }
    my $template = $Templates{$name};

    if (! $template){                        # template is not set
	return $self->content->{$name};
    } else {
	if ($self->content->{$name}){
	    $template =~ s/%value/$self->content->{$name}/ge;
	    $template =~ s/%user{([A-Z]+)}/($1 eq $name) ? "'$name' FORMAT ERROR: self-reference" : $self->Eval($1)/ge; #call recursible
	    return $template;
	} else {
	    return undef;
	}
    }
}
1;
