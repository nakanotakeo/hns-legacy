package CGI::QueryString;
# $Id: QueryString.pm,v 1.3 1999/11/23 15:56:25 tom Exp $
################################################################

=head1 NAME

 CGI::QueryString - クエリーの処理

=cut

use strict;
use Exporter;
use vars qw(@ISA @EXPORT $QueryString %Parameter);
@ISA = qw(Exporter);
@EXPORT = qw(query_string param);

BEGIN{
    my $method = $ENV{'REQUEST_METHOD'};
    
    if ($method =~ /^(GET|HEAD)$/){
	$QueryString = $ENV{'QUERY_STRING'};
    } elsif ($method eq 'POST'){
	read(STDIN, $QueryString, $ENV{'CONTENT_LENGTH'});
    } else {                # command line
	$QueryString = join('&', @ARGV);
    }
    for (split("&", $QueryString)){
	my ($key, $value) = split("=");
	if (defined $value){
	    $Parameter{$key} = $value;
#	    print "$key, $value : $Parameter{$key} ";
	} else {
	    $Parameter{keywords} = $key;
	}
    }
}
################################################################

=head2 query_string;

クエリーをそのまま返す

=cut

sub query_string()
{
    return $QueryString;
}

=head2 param($name);

パラメータ $name の値を返す

=cut

sub param($)
{
    my $key = shift;
#    print "param($key):$Parameter{$key}";
    my $value = $Parameter{$key};
    $value =~ tr/+/ /;       # pluses become spaces
    $value =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $value;
}
1;
