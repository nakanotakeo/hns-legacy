package SimpleDB::Hash;
# $Id: Hash.pm,v 1.3 1999/11/23 15:56:32 tom Exp $
################################################################

=head1 NAME

SimpleDB::Hash - 簡易ハッシュデータベースクラス

=head1 SYNOPSIS

 use SimpleDB::Hash;

 my %h;
 tie %h, 'SimpleDB::Hash', $filename;
 #tie %h, 'SimpleDB::Hash', $filename, 1 # readonly
 $h{'foo'} = 'bar';

=cut

################################################################

use SimpleDB::Base;
@ISA = qw(SimpleDB::Base);

sub TIEHASH ($$;$)
{
    my ($class, $filename, $readonly) = @_;
    my $self = new SimpleDB::Base($filename, $readonly);
    bless $self, $class;
}
sub FETCH ($$)
{
    my ($self, $key) = @_;

    $self->SUPER::FETCH;
    return $self->{contents}->{$key};
}
sub STORE ($$$)
{
    my ($self, $key, $value) = @_;

    $self->SUPER::STORE;
    $self->{contents}->{$key} = $value;
}
sub DESTROY ($)
{
    my $self = shift;

    if ($self->SUPER::DESTROY){
	return;
    }
    unless (open(F, ">$self->{filename}")){
	$self->Error("cannot write : $self->{filename}");
	return;
    }
    eval 'flock(F, LOCK_EX)';
    my ($k, $c);
    while (($k, $c) = each(%{$self->{contents}})){
	print F "$k $c\n";
    }
    eval 'flock(F, LOCK_UN)';
    close (F);
}
sub FIRSTKEY
{
    my $self = shift;

    $self->Read unless $self->{fetched};
    return each (%{$self->{contents}});
}
sub NEXTKEY
{
    return each %{shift->{contents}};
}

################################################################
sub Read ($)
{
    my $self = shift;

    open(F, $self->{filename}) || return;
    eval 'flock(F, LOCK_EX)';
    while (<F>){
	chomp;
#	print "line:$_";
	my ($tkey, $content) = /^([^\s]*)\s*(.*)$/;
	$self->{contents}->{$tkey} = $content;
    }
    eval 'flock(F, LOCK_UN)';
    close (F);
}

1;
