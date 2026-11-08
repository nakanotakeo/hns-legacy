package SimpleDB::Scalar;
# $Id: Scalar.pm,v 1.3 1999/11/23 15:56:32 tom Exp $
################################################################

=head1 NAME

SimpleDB::Scalar - 簡易スカラーデータベースクラス

=head1 SYNOPSIS

 use SimpleDB::Scalar;

 my $s;
 tie $s, 'SimpleDB::Scalar', $filename;
 #tie $s, 'SimpleDB::Scalar', $filename, 1 # readonly
 $s = "foo";

=cut

################################################################
use Fcntl ':flock';

use SimpleDB::Base;
@ISA = qw(SimpleDB::Base);

sub TIESCALAR ($$;$)
{
    my ($class, $filename, $readonly) = @_;
    my $self = new SimpleDB::Base($filename, $readonly);
    bless $self, $class;
}
sub FETCH ($)
{
    my $self = shift;
    $self->SUPER::FETCH;
    return $self->{content};
}
    
sub STORE ($$)
{
    my ($self, $value) = @_;

    $self->SUPER::STORE;
    $self->{content} = $value;
}
sub DESTROY ($)
{
    my $self = shift;

    if ($self->SUPER::DESTROY){
	return;
    }
    unless (open(F, ">$self->{filename}")){
	$self->Error("cannot write : $self->{filename}");
    }
    eval 'flock(F, LOCK_EX)';
    print F $self->{content};
    eval 'flock(F, LOCK_UN)';
    close (F);
}
################################################################
sub Read($)
{
    my $self = shift;
    
    open(F, $self->{filename}) ||  return;
    eval 'flock(F, LOCK_EX)';
#    local($/) = undef;
#    $self->{content} = <F>;
    my $c;
    while (<F>){
	$c .= $_;
    }
    $self->{content} = $c;
    eval 'flock(F, LOCK_UN)';
    close (F);
}

1;

    
    

