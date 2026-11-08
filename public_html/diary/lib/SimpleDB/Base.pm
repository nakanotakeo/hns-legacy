package SimpleDB::Base;
# $Id: Base.pm,v 1.6 2000/07/20 03:53:31 kenji Exp $
################################################################

=head1 NAME

SimpleDB::Base - 簡易データベース基本クラス

=cut

sub new ($$$)
{
    my ($class, $filename, $readonly) = @_;
    my $self = {filename=>$filename, stored=>0, fetched=>0, readonly=>$readonly};
    bless $self, $class;
}

sub FETCH
{
    my $self = shift;
    unless ($self->{fetched}){
	$self->Read;
    }
    $self->{fetched} = 1;
}
sub STORE
{
    my $self = shift;
    if ($self->{readonly}){
	$self->Error("readonly");
    }
    $self->Read() unless $self->{fetched};
    $self->{fetched} = 1;
    $self->{stored} = 1;
}
sub DESTROY
{
    my $self = shift;
    if (!$self->{stored} || $self->{readonly}){
	return 1;
    } else {
	return 0;
    }
}
################################################################
sub Read($)
{
    my $self = shift;
}
sub Error($$)
{
    my ($self, $msg) = @_;
    print "Error: $self, $msg";
    exit 1;
}
1;

