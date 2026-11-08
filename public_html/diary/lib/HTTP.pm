package HTTP;
################################################################
# HTTP

# 2000/11/28  Akihiro Arisawa <ari@mbf.sphere.ne.jp>

# Copyright (C) 2000  Akihiro Arisawa, HyperNikkiSystem Project

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

# $Id: HTTP.pm,v 1.1 2000/12/07 12:49:34 kenji Exp $
################################################################

use strict;
use ObjectTemplate;
use Exporter;
use vars qw(@ISA @EXPORT);
@ISA = qw(ObjectTemplate);
@EXPORT = qw(attributes);

attributes qw(agent referer);

use IO::Socket;

sub Request($$$;$$)
{
	my ($self, $method, $uri, $header, $content) = @_;
	my ($host, $port, $path);
	my $response;

	if ($uri =~ m|http://([^/:]*)(:(\d+))?(/.*)|i) {
		$host = $1;
		$port = $3 || 80;
		$path = $4;
	} else {
		return;
	}

	my $sock = IO::Socket::INET->new(PeerAddr => $host,
					 PeerPort => $port);

	if ($sock) {
		$sock->autoflush(1);
		print $sock "$method $path HTTP/1.0\r\n";
		print $sock "Host: $host\r\n";
		print $sock "User-Agent: ", $self->agent, "\r\n" if ($self->agent);
		print $sock "Referer: ", $self->referer, "\r\n" if ($self->referer);
		if ($header && ref($header) eq 'HASH') {
			foreach (keys(%$header)) {
				print $sock "$_: ", $header->{$_}, "\r\n";
			}
		}
		print $sock "Content-Length: ", length($content), "\r\n";
		print $sock "\r\n";
		print $sock $content if ($content);

		my (@ret, $ret);
		if (wantarray) {
			@ret = $sock->getlines;
		} else {
			$ret = $sock->getline;
		}
		$sock->close;
		wantarray ? @ret : $ret;
	}
}

sub GET($$;$)
{
	my ($self, $uri, $header) = @_;
	$self->Request('GET', $uri, $header);
}

sub POST($$;$$)
{
	my ($self, $uri, $header, $content) = @_;
	$self->Request('POST', $uri, $header, $content);
}

1;

