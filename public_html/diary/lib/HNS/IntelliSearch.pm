package HNS::IntelliSearch;
################################################################
# HNS::IntelliSearch
# $Id: IntelliSearch.pm,v 1.22 2005/08/21 02:12:40 kenji Exp $
################################################################
use ObjectTemplate;
@ISA = qw(ObjectTemplate);

use strict;
use CodeConv;

use vars qw(@ISA %search_engines);

__PACKAGE__->attributes(qw(referer keyword search_engine));

################################################################
%search_engines = (
      "altavista" => { url_pat => 
	'http://www\.altavista\.com/(cgi-bin/query|sites/search/web)',
	key_param => 'q' },

      "yahoo" => { url_pat => 
        'http://(ink|search|google)\.yahoo\.com/(search|bin/query)',
	key_param => 'p' },

      "yahoo-japan" => { url_pat => 
	'http://(search|google|websearch)\.yahoo\.co\.jp/bin/(search|query)',
	key_param => 'p'},

      # mc7.metacrawler.com, search.metacrawler.com
      "metacrawler" => { url_pat => 'http://.*\.metacrawler\.com/crawler',
	key_param => 'general' },

      "excite" => { url_pat => 'http://www\.excite\.co\.jp/search.gw',
	key_param => '(search|s)' },

      "goo" => { url_pat => 'http://www\.goo\.ne\.jp/default.asp',
	key_param => 'MT' },

      "IEresult goo" => { url_pat => 
	'http://www\.goo\.ne\.jp/ie[\d.]+/msResult.asp',
        key_param => 'MT' },

      "google" => { url_pat => 
	'http://www\.(google|gogle)\.(com|co\.jp)/search',
	key_param => '(q|as_q)' },

      "hotbot" => { url_pat => 'http://www\.hotbot\.com/',
	key_param => 'MT' },

      "icqit" => { url_pat => 'http://www\.icqit\.com/dirsearch.adp',
	key_param=> 'query' },

      "lycos" => { url_pat => 
        'http://search\.lycos\.co\.jp/(main|websites)\.html',
	key_param => 'query' },

      "lycos2" => { url_pat => 
        'http://search\.lycos\.co\.jp/',
	key_param => 'q' },

      "wisenut(lycos)" => { url_pat => 'http://wisenut\.lycos\.co\.jp/',
	key_param => 'q' },

      "northernlight" => { url_pat => 
	'http://www\.northernlight\.com/nlquery\.fcg',
	key_param => 'qr' },

      "infoseek" => { url_pat => 'http://www\.infoseek\.co\.jp/Titles',
	key_param => 'qt' },

      "fresheye" => { url_pat => 'http://search\.fresheye\.com/',
	key_param => 'kw' },

      "msn" => { url_pat => 'http://search\.msn\.co\.jp/(results|spresults)\.(asp|aspx)',
	key_param => 'q' },

      "IEresult msn" => { url_pat => 'http://search\.msn\.co\.jp/spbasic\.htm',
	key_param => 'MT' },

      # closed?
      "netplaza(robo3)" => { url_pat => 
	'http://rex1\.netplaza\.biglobe\.ne\.jp/cgi-bin/search-robo3',
	key_param => 'key' },

      # closed?
      "netplaza(lycos)" => { url_pat => 
	'http://rex1\.netplaza\.biglobe\.ne\.jp/cgi-bin/search_lycos\.cgi',
        key_param => 'key' },

      # closed?
      "netplaza(fresheye)" => { url_pat => 
	'http://rex1\.netplaza\.biglobe\.ne\.jp/cgi-bin/search-fresheye\.cgi',
        key_param => 'key' },

      # closed?
      "netplaza(yahoo)" => { url_pat => 
	'http://rex1\.netplaza\.biglobe\.ne\.jp/cgi-bin/search_yahoo\.cgi',
        key_param => 'key' },

      "BIGLOBE(google)" => { url_pat =>
        'http://cgi\.search\.biglobe\.ne\.jp/cgi-bin/search',
        key_param => 'q' },

      "aol" => { url_pat => 
        'http://(aolsearch|search)\.aol\.com/dirsearch\.adp',
	key_param => 'query' },

      "aol-japan" => { url_pat => 'http://search\.jp\.aol\.com/webdir\.adp',
        key_param => 'query' },

      "Verno" => { url_pat => 
	'http://verno\.ueda\.info\.waseda\.ac\.jp/verno-099\.cgi',
        key_param => 'index-and' },

      "kensaku" => { url_pat =>
        'http://kensaku\.(org|jp)/search\.cgi',
        key_param => 'key' },

      "nifty" => { url_pat =>
        'http://(www|search)\.nifty\.com/cgi-bin/search\.cgi',
        key_param => 'Text' },

      "infoNavigator" => { url_pat =>
        'http://para\.cab\.infoweb\.ne\.jp/cgi-bin/para',
        key_param => 'QueryString' },

      "NAVER" => { url_pat =>
        'http://search\.naver\.co\.jp/search\.naver',
        key_param => 'query' },

      "AccessUp.ORG" => { url_pat =>
        'http://www2s\.biglobe\.ne\.jp/~hikarine/find/accessup\.cgi',
        key_param => 'key' },

       "TOCC" => { url_pat =>
	'http://www\.tocc\.co\.jp/search/servlet/SearchServlet',
	key_param => 'QRY' },

      "Metcha" => { url_pat =>
	'http://bach\.cs\.kobe-u\.ac\.jp/cgi-bin/metcha\.cgi',
	key_param => 'q' },

      "ODN" => { url_pat =>
        'http://search\.odn\.ne\.jp/LookSmartSearch\.jsp',
        key_param => '(QueryString|key)' },

      "DION" => { url_pat =>
        'http://dir\.dion\.ne\.jp/LookSmartSearch\.jsp',
        key_param => '(QueryString|key)' },

      "OCN(excite)" => { url_pat => 'http://ocn\.excite\.co\.jp/search.gw',
  key_param => '(search|s)' },

      "alltheweb" => { url_pat =>
        'http://www\.alltheweb\.com/search',
        key_param => '(q)' },


      "namazu" => { url_pat => '.+/namazu.cgi',
	key_param => '(key|query)' },
     );

################################################################
sub GetKeyword($;$)
{
    my $self = shift;
    my $referer = shift || $self->referer;

    return unless ($referer);

#print "Content-Type: text/html; charset=EUC-JP\r\n\r\n";
#print "$referer<br>";
                        
    foreach my $s (keys(%search_engines)) {
	my $url_pat = $search_engines{$s}->{url_pat};
	if ($referer =~ /$url_pat[^?]*\?/) {
	    my @query = split(/&/, $');
            foreach (@query) {
		my $key_param = $search_engines{$s}->{key_param};
		if (/^$key_param=/) {
		    $_ = $';
		    s/%([\dA-Fa-f][\dA-Fa-f])/pack("C", hex($1))/ge;
		    # CodeConv::toeuc(*_); won't work with Jcode.pm?
		    CodeConv::toeuc(\$_);
		    s/\+/ /g;
		    s/"//g;
		    s/&/&amp;/g;	# fix Cross Site Scripting bug 
		    s/</&lt;/g;		#
		    s/>/&gt;/g;		#
		    $self->search_engine($s);
		    $self->keyword($_);
		    return $_;
                }
            }
            next;
        }
    }

}

1;

