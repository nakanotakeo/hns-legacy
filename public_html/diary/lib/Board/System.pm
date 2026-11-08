package Board::System;
################################################################
# Board::System

# 2002/01/27 Yoichi Imai <yoichi@silver-forest.com>

# Copyright (C) 2002 Yoichi Imai <yoichi@silver-forest.com>

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

# $Id: System.pm,v 1.6 2003/05/28 04:52:53 togawa Exp $
################################################################

=head1 NAME

Board::System - Boardシステムのライブラリ部分

=head1 SYNOPSIS

 my $board = Board::System->new();
 $board->Load();
 foreach my $article (@{$board->article_list}) { ... }

=head1 DESCRIPTION
Boardシステムの基幹部。

=cut
################################################################


use strict;
use Fcntl ':flock';
use ObjectTemplate;
use Exporter;
use DateTime::Format;
use CodeConv;
use Board::Article;
use vars qw(@ISA @EXPORT);
@ISA = qw(ObjectTemplate);
@EXPORT = qw(attributes);

__PACKAGE__->attributes(qw(article_list msgid_hash refid_hash));

sub Error($$)
{
    my ($self, $msg) = @_;
    die "Error: $self, $msg\n";
    exit 1;
}

sub Load
{
    my $self = shift;

    my @article_list;
    unless(open(FH, $Board::BoardData)) {
	$self->Error("cannot open : '$Board::BoardData'");
	return;
    }

    eval 'flock(FH, LOCK_EX)';
    foreach my $line (<FH>) {
	chomp($line);
	my @list = split("\t", $line);
	next if $#list == -1; # remove nothing line
	my $article = Board::Article->new();
	$article->Set(@list);
	push(@article_list, $article);
    }
    eval 'flock(FH, LOCK_UN)';
    close(FH);
    $self->article_list(\@article_list);
}

# this function doesn't read deleted or fake_root message
sub LoadLightly
{
    my $self = shift;
    my @article_list;

    unless(open(FH, $Board::BoardData)) {
	$self->Error("cannot open : '$Board::BoardData'");
	return;
    }

    eval 'flock(FH, LOCK_EX)';
    foreach my $line (<FH>) {
	chomp($line);
	my @list = split("\t", $line);
	next if ($#list == -1); # remove nothing line
	next if ($list[0] eq ''); # deleted message
	next if ($list[2] eq 'root' && $list[3] ne ''); # fake root message
	my $article = Board::Article->new();
	$article->Set(@list);
	push(@article_list, $article);
    }
    eval 'flock(FH, LOCK_UN)';
    close(FH);

    $self->article_list(\@article_list);
}
sub Save
{
    my $self = shift;
    my %skip_msgids;

    my @article_list = @{$self->article_list};

    if(@article_list > $Board::MaxArticle) {
	for(my $i = 0; $i < @article_list - $Board::MaxArticle; $i++) {
	    unless ($article_list[$i]->IsFakeRoot()) {
		$article_list[$i]->Delete();
	    }
	}
    }

    $self->CreateMsgidHash();
    $self->CreateRefidHash();

    # remove blank tree
    foreach my $root_article (@{$self->refid_hash->{'root'}}) {
	if($self->IsDeletedTree($root_article)) {
	    foreach my $msgid ($self->GetTreeMemberMsgids($root_article, ())) {
		$skip_msgids{$msgid} = 1;
	    }
	}
    }

    unless(open(FH, '>' . $Board::BoardData)) {
	$self->Error("cannot open(write) : '$Board::BoardData'");
	return;
    }
    eval 'flock(FH, LOCK_EX)';
    foreach my $article (@article_list) {
	print FH $article->GetStr() if $article && !($skip_msgids{$article->msgid} == 1);
    }
    eval 'flock(FH, LOCK_UN)';
    close(FH);
}

sub Add
{
    my ($self, $article) = @_;
    push(@{$self->article_list}, $article);
}

sub CreateMsgidHash
{
    my $self = shift;
    $self->msgid_hash({});
    foreach my $article (@{$self->article_list}) {
	$self->msgid_hash->{$article->msgid} = $article;
    }
}
sub CreateRefidHash
{
    my $self = shift;
    my $refid_hash = {};
    foreach my $article (@{$self->article_list}) {
	$refid_hash->{$article->refid} = [] unless (defined($refid_hash->{$article->refid}));
	push(@{$refid_hash->{$article->refid}}, $article);
    }
    $self->refid_hash($refid_hash);
}
sub GetNewMsgid
{
    my $self = shift;
    my $new_id;

    foreach my $article (@{$self->article_list}) {
	$new_id = $article->msgid if ($new_id < $article->msgid);
    }
    return $new_id + 1;
}
sub AddNewMsg
{
    my ($self, $delete_key, $refid, $diary, $ruri_code, $subject, $name, $email, $site, $host, $body) = @_;
    my $ref;

    my $article = Board::Article->new();

    CodeConv::toeuc(\$subject);
    CodeConv::toeuc(\$name);
    CodeConv::toeuc(\$email);
    CodeConv::toeuc(\$site);
    CodeConv::toeuc(\$body);

    $article->Set($delete_key, 
		  $self->GetNewMsgid,
		  $refid,
		  $diary,
		  $ruri_code,
		  time(),
		  $subject,
		  $name,
		  $email,
		  $site,
		  $host,
		  $body);

    $self->Add($article);

    return $article;
}
sub SearchFakeRoot
{
    my ($self, $diary) = @_;
    my $fake_root;

    foreach my $article (@{$self->article_list}) {
	$fake_root = $article if ($article->IsRoot() && $article->ref_diary == $diary);
    }
    return $fake_root;
}
sub IsDeletedTree
{
    my ($self, $root_article) = @_;

    return 0 if ($root_article->delete_key ne '' && !($root_article->IsFakeRoot()));
    foreach my $article (@{$self->refid_hash->{$root_article->msgid}}) {
	if ($self->IsDeletedTree($article) == 0) {
	    return 0;
	}
    }
    return 1;
}
sub GetTreeMemberMsgids
{
    my ($self, $root_article, @list) = @_;
    
    return @list unless ($root_article);

    push(@list, $root_article->msgid);
    foreach my $article (@{$self->refid_hash->{$root_article->msgid}}) {
	push(@list, $self->GetTreeMemberMsgids($article, @list));
    }

    return @list;
}
# not instance method
sub get_diary_title
{
    my $diary = shift;
    my ($title, $new_count);

    die "diary_title_error" unless $diary =~ /(\d{4})(\d{2})(\d{2})(\d+)/;

    my ($year, $month, $day, $section) = ($1, $2, $3, $4);
    my $file = "${HNS::System::DiaryDir}/${year}/d${year}${month}${day}.hnf";
    unless(open(FH, $file)) {
	die ("cannot open hnf : '$file'");
	return;
    }

    $new_count = 1;
    eval 'flock(FH, LOCK_EX)';
    foreach my $line (<FH>) {
	if ($line =~ /^NEW (.*)/) {
	    $title = $1;
	} elsif ($line =~ /^LNEW [^ ]* (.*)/) {
	    $title = $1;
	} elsif ($line =~ /^RLNEW [^ ]* [^ ]* (.*)/) {
	    $title = $1;
	}
	
	$new_count -= 1 if ($line =~ /^GRP/);
	if ($line =~ /^R?L?NEW /) {
	    last if ($new_count == $section);
	    $new_count++;
	}
    }
    eval 'flock(FH, LOCK_UN)';
    close(FH);

    CodeConv::toeuc(\$title);
    return $title;
}
1;
