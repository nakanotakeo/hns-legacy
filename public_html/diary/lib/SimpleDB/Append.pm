package SimpleDB::Append;
# $Id: Append.pm,v 1.3 1999/11/23 15:56:31 tom Exp $
################################################################

=head1 NAME

SimpleDB::Append - 追加のみのデータベースクラス

=head1 SYNOPSIS

 use SimpleDB::Append;

 my $db = new SimpleDB::Append($filename);
 $db->Append($line);

=cut

use Fcntl ':flock';

sub new ($$)
{
    my ($class, $filename) = @_;
    bless {filename=>$filename}, $class;
}


=head2 $a->Append($line);

$line をログに追加

=cut


sub Append ($$)
{
    my ($self, $line) = @_;

    open(F, ">>$self->{filename}") || die "can't append : $self->{filename}";
    eval 'flock(F, LOCK_EX)';
    print F $line;
    eval 'flock(F, LOCK_UN)';
    close F;
}
1;
