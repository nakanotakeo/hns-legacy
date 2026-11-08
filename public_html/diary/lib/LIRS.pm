package LIRS;
################################################################
# LIRS

# 2000/11/29  Akihiro Arisawa <ari@mbf.sphere.ne.jp>

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

# $Id: LIRS.pm,v 1.1 2000/12/07 11:16:53 kenji Exp $
################################################################

use strict;
use ObjectTemplate;
use vars qw(@ISA @EXPORT);
@ISA = qw(ObjectTemplate);
@EXPORT = qw(attributes);

__PACKAGE__->attributes(qw(lastmodified lmd lag contentlength url title author remote optional));

sub getLirs($;@)
{
	my $self = shift;
	my ($url, $author, $title, $remote);

	if (@_) {
		$self->lastmodified(shift);
		$self->lmd(shift);
		$self->lag(shift);
		$self->contentlength(shift);
		$self->url(shift);
		$self->title(shift);
		$self->author(shift);
		$self->remote(shift);
		$self->optional(shift);
	}

	($url = $self->url) =~ s/,/\\,/g;
	($author = $self->author) =~ s/,/\\,/g;
	($title = $self->title) =~ s/,/\\,/g;
	($remote = $self->remote) =~ s/,/\\,/g;

	sprintf("LIRS,%d,%d,%d,%d,%s,%s,%s,%s,%s\n",
		$self->lastmodified, $self->lmd, $self->lag,
		$self->contentlength, $url, $title, $author, $remote,
		$self->optional);
}

sub setLirs($$)
{
	my ($self, $line) = @_;

	chomp $line;

	split(/,/, $line); # escaped comma is not supported yet.
	return if (shift ne 'LIRS');

	$self->lastmodified(shift);
	$self->lmd(shift);
	$self->lag(shift);
	$self->contentlength(shift);
	$self->url(shift);
	$self->title(shift);
	$self->author(shift);
	$self->remote(shift);
	$self->optional(shift);
}

1;

