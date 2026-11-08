package HNS::Hnf::Command;
# $Id: Command.pm,v 1.40 2005/10/04 10:14:38 kenji Exp $
################################################################

=head1 NAME

HNS::Hnf::Command - hnf command class


=cut

use strict qw(vars subs);
use HNS::System;
use HNS::Template;
use SimpleDB::Hash;
use SimpleDB::Scalar;
use HNS::Diary::Template;

use vars qw(%Entities);
use vars qw($Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $CountName $OmittableEnd);


################################################################
# entity definition
# used in $AllowCommands

$Entities{'Link'} = ['LINK', 'RLINK', 'URL'];
$Entities{'Decoration'} = ['FONT', 'STRIKE', 'LSTRIKE', 'STRONG','SPAN'];
$Entities{'Image'} = ['IMG', 'LIMG', 'MARK'];
$Entities{'Replace'} = ['ALIAS'];
$Entities{'Comment'} = ['FN'];

$Entities{'Inline'} = [$Entities{'Link'}, $Entities{'Decoration'},
			$Entities{'Image'}, $Entities{'Replace'},
			$Entities{'Comment'}];

$Entities{'Cite'} = ['CITE', 'PRE','INCLUDE','RT'];
$Entities{'List'} = ['UL', 'OL', 'DL'];
$Entities{'Block'} = [$Entities{'Cite'}, $Entities{'List'}, 'P', 'DIV'];

$Entities{'Flow'} = [$Entities{'Inline'}, $Entities{'Block'}];

$Entities{'New'} = ['NEW', 'LNEW', 'RLNEW'];
$Entities{'Sub'} = ['SUB', 'LSUB', 'RLSUB'];



sub new ($$)
{
    my ($class, $name) = @_;
    my $self = {name=>$name,    # name of command
		attr=>[],       # array of attributes
		arg_content=>undef, # content in argument
		parent=>undef,  # parent command
		pos=>undef,     # position which new command is inserted
		content=>[]};   # content element(command or text)
    bless $self, $class;
}
################################################################

=head2 $c->InsertCommand($elem);

 insert new command at legal position
 if $elem is not HNS::Hnf::Command object,
 it's regarded as a command name, and insert new object

=cut

sub InsertCommand($$)
{
    my ($self, $elem) = @_;
    unless (ref $elem){
	$elem = new HNS::Hnf::Command($elem);
    }
    my $pos = $self->{pos} || $self;
    $pos->PushContent($elem);
    $self->{pos} = $elem;
    return $elem;
}

=head2 $c->PushContent(@lines);

push new command or plain text as content

=cut

sub PushContent($@)
{
    my $self = shift;
    for (@_){
	if (ref $_){
	    $_->{parent} = $self;
#	    print "push parent:";
#	    print $_->{name}, "-";
#	    print $_->{parent}->{name} . "<br>";
	}
	push(@{$self->{content}}, $_);
    }
}

=head2 $c->UnshiftContent(@lines);

@lines を unshift する

=cut

sub UnshiftContent($@)
{
    my $self = shift;
    for (@_){
	if (ref $_){
	    $_->{parent} = $self;
	}
	unshift(@{$self->{content}}, $_);
    }
}


=head2 $c->Traverse($callback);

traverse the tree-structure

=cut

sub Traverse
{
    my ($self, $callback) = @_;

    if (&$callback($self, 1)) {	
	for (@{$self->{content}}) {
	    if (ref $_) {
		$_->Traverse($callback);
	    } else {
		&$callback($_, 1);
	    }
	}
	&$callback($self, 0) unless $self->IsOneline;
    }
    $self;
}
################################################################
# access method to static variable of object class
sub get_static_variable ($$)    # private
{
    my ($self, $var_name) = @_;
    my $full_var_name = (ref $self) . "::$var_name";
    return $$full_var_name if defined $$full_var_name;

    # if undefined the class, get from parent class
    my $tmp = (ref $self) . "::ISA";
    my @isa = @$tmp;
    for my $class (@isa){
	$full_var_name = "${class}::$var_name";
	return $$full_var_name if defined $$full_var_name;
	my $tmp = "${class}::ISA";
	push(@isa, @$tmp);
    }
    return undef;
}
sub CountName ($)
{
    return shift->get_static_variable('CountName');
}
sub OmittableEnd ($)
{
    return shift->get_static_variable('OmittableEnd');
}
sub IsOneline ($)
{
    return shift->get_static_variable('IsOneline');
}
sub IsBeginSection($)
{
    return shift->get_static_variable('IsBeginSection');
}
# check $cmd_name is permitted as content of $self
sub allowed($$)
{
    my ($self, $cmd_name) = @_;

#    print "<br>check allowed: $cmd_name: in " . ($self->{name}) . ": ";
    my $AllowCommands = $self->get_static_variable('AllowCommands');
    return 1 unless defined $AllowCommands;
    my @tmp = @$AllowCommands;
    for (@tmp){
	if (ref $_){                    # entity assc array
	    push(@tmp, @$_);
	} elsif ($cmd_name eq $_){      # command type
	    return 1;
	}
    }
    return 0;                  # not allowed $cmd_name in $self
}
################################################################

=head2 $c->AsHTML($start, $params);

translate to HTML

=cut

sub AsHTML ($$$)
{
    my ($self, $start, $params) = @_;
#    my ($year, $month, $day, $newCount, $subCount, $fnCount, $cat_img) = @$params;
#    print "NC:$newCount\n";
    my $class = ref $self;
    my $cmd_name = $self->{name};

#    print "$cmd_name($start)<br>";
    # template
    my $template = sprintf("%s::%sTemplate",
			   $class,
			   ($start)?'':'End');
    my $comment = ($start) ? "<!-- $cmd_name -->": "";

    my $templ = new HNS::Template;
    $params->{content} = $self->{arg_content};
    for (1..3){
	$params->{$_} = $self->{attr}->[$_];
    }
    return $templ->Expand(SelectTemplate($$template, %$template), $params);
}

################################################################
################################################################
# class for extension.
package HNS::Hnf::Command::ConvTemplate;
use HNS::Diary::Template;
use vars qw(@ISA);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template
@ISA = qw(HNS::Diary::Template HNS::Hnf::Command);
sub AsHTML ($$$)
{
    my ($self, $start, $params) = @_;
    my $class = ref $self;
    my $cmd_name = $self->{name};

    # template
    my $template = sprintf("%s::%sTemplate",
			   $class,
			   ($start)?'':'End');
    my $comment = ($start) ? "<!-- $cmd_name -->": "";

    my $templ = new HNS::Template;
    $params->{content} = $self->{arg_content};
    $self->ExpandTempl($templ, $params);
    for (1..3){
	$params->{$_} = $self->{attr}->[$_];
    }
    return $templ->Expand(SelectTemplate($$template, %$template), $params);
}

package HNS::Hnf::Command::ConvUrl;
use HNS::Template;
use HNS::Diary::Template;
use vars qw (@ISA %Template);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template
@ISA = qw(HNS::Diary::Template);
$HrefTemplate = "%base#%name";
$Template{mydiary} = "%href";
$Template{ISBN} = "http://www.bk1.co.jp/search/search.asp?kywd=%param";
$Template{CD} = "http://www.hmv.co.jp/search/title.asp?category=CATALOGUENO&amp;keyword=%param";

sub new($)
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

sub ConvUrl($;$)
{
    my $self = shift;
    my $attr = shift || \$self->{attr}->[1];
    my $templ = new HNS::Template;

    if ($$attr =~ /^#(\d{4})(\d{2})(\d{2})((\d+)(S(\d+))?)?$/ ||
	$$attr =~ /^#\{(\d{4}),(\d+),(\d+)(,(\d+)(,(\d+))?)?\}$/ ||
	$$attr =~ /^#{.*#(\d{4})(\d{2})(\d{2})((\d+)(S(\d+))?)?}$/) {
	my ($new, $sub)  = ($5, $7);
	my $my_diary_params = { 'year' => $1,
			        'month' => sprintf("%02d", $2),
			        'day' => sprintf("%02d", $3),
			        'abc' => $3 < 11 ? 'a' : $3 < 21 ? 'b' : 'c',
			        'new' => $new,
			        'sub' => $sub};
	my $tmp = new HNS::Hnf::Command::ConvUrl;

	if (! $new) {
	    @ISA = qw(HNS::Diary);
	} elsif (! $sub) {
	    @ISA = qw(HNS::Hnf::Command::New);
	} else {
	    @ISA = qw(HNS::Hnf::Command::Sub);
	}
	$tmp->ExpandTempl($templ, $my_diary_params);
	@ISA = qw(HNS::Diary::Template);
	$$attr = $templ->Expand(SelectTemplate($Template{mydiary},
					      %{$Template{mydiary}}),
			       $my_diary_params);
    } elsif ($$attr =~ /^([\d\w-]+):/ && defined($Template{$1})) {
	if (ref($Template{$1}) eq "CODE") {
	    $$attr = &{$Template{$1}}($');
	} else {
	    $$attr = $templ->Expand(SelectTemplate($Template{$1},
						   %{$Template{$1}}),
				    { param => $' });
	}
    }
}

################################################################
################################################################
# derived class from HNS::Hnf::Command
# top command (implicit);
package HNS::Hnf::Command::HNF;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command);
$OmittableEnd = 1;
$AllowCommands = ['CAT','GRP'];

################################################################
# body commands:
# (*) if you want to add new command, you must account it in
#     $HNS::Hnf::[A-Z][a-z]+::entity

# static variable:
# $Template            [str]  begin template
# $EndTemplate        [str]  end templte
# $NumAttr              [int]  number of attributes
# $IsOneline             [bool] no need end command
# $IsBeginSection       [bool] beginning of section (Section)
# $AllowCommands      [array]commands which can be element of self class
# $CountName          [str] if countable, set name for use of counter variable
# $OmittableEnd            [bool] ]is end-command omittable

################################################################
package HNS::Hnf::Command::CAT;
use vars qw(@ISA $Template $ImgTemplate $EndTemplate $NumAttr $IsOneline 
	$AllowCommands $CountName $OmittableEnd);
use vars qw(%Template %ImgTemplate);
#use vars qw(%DB);

$Template = qq([<a href="./title.cgi?CAT=%enc_var">%var</a>]);
$ImgTemplate = qq(<a href="./title.cgi?CAT=%enc_var">%img</a>);

@ISA = qw(HNS::Hnf::Command);

$AllowCommands = [$HNS::Hnf::Command::Entities{'New'}];

sub AsHTML() {undef}

################################################################
package HNS::Hnf::Command::GRP;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
            $CountName $OmittableEnd $Mark);
#use vars qw(%DB);

$Template = "";
@ISA = qw(HNS::Hnf::Command);
$IsOneline = 1;
$AllowCommands = ['CAT',$HNS::Hnf::Command::Entities{'New'}];
$Mark = "*";

sub AsHTML() {undef}

################################################################
# New Entities
package HNS::Hnf::Command::New;;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template


@ISA = qw(HNS::Hnf::Command::ConvTemplate);
$IsBeginSection = 1;
$OmittableEnd = 1;
$CountName = 'new';
$AllowCommands = [$HNS::Hnf::Command::Entities{'Sub'},
		   $HNS::Hnf::Command::Entities{'Flow'}];
$NameTemplate = "%year%month%day%new";

package HNS::Hnf::Command::NEW;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::New);
$Template = q(<dt><font size='+1'>
	      <a name='%name' href='%href'>#%new</a>
	      <strong>%cat %content</strong></font></dt><dd>);

$EndTemplate = "</dd>\n";

package HNS::Hnf::Command::LNEW;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::New HNS::Hnf::Command::ConvUrl);
$Template = q(<dt><font size='+1'>
	      <a name='%name' href='%href'>#%new</a>
	      <strong>%cat <a href="%1">%content</a></strong></font></dt>
	      <dd>);
	      
$EndTemplate = "</dd>\n";
$NumAttr = 1;

sub AsHTML ($$$) {
    my ($self, $start, $params) = @_;
    $self->ConvUrl();
    $self->SUPER::AsHTML($start, $params);
}

package HNS::Hnf::Command::RLNEW;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::New);
use vars qw(%DB);
$Template = q(<dt><font size='+1'>
	      <a name='%name' href='%href'>#%new</a>
	      <strong>%cat <a href="%url%2">%content</a></strong></font></dt>
	      <dd>);
	      
$EndTemplate = "</dd>\n";
$NumAttr = 2;
%DB = ();
sub AsHTML($$$)
{
    my ($self, $start, $params) = @_;

    unless (defined %DB){
	tie %DB, 'SimpleDB::Hash',
	"$HNS::System::DiaryDir/conf/rlink.txt", 1;
    }
    my $url = $DB{$self->{attr}->[1]};
    unless ($url){
	return &HNS::Hnf::Warning::Message('NotDefined',
					   $self->{name},undef,
					   $self->{attr}->[1]);
    } else {
	$params->{url} = $url;
	return $self->SUPER::AsHTML($start, $params);
    }
}

# P command
package HNS::Hnf::Command::P;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	$CountName $OmittableEnd);
@ISA = qw(HNS::Hnf::Command::Block);
$AllowCommands = [$HNS::Hnf::Command::Entities{'Inline'}];
$OmittableEnd = 1; # or 0
$Template = "<p>\n";
$EndTemplate = "</p>\n";

# DIV command
package HNS::Hnf::Command::DIV;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
        $CountName $OmittableEnd);
@ISA = qw(HNS::Hnf::Command::Block);
$AllowCommands = [$HNS::Hnf::Command::Entities{'Inline'}];
$OmittableEnd = 1; # or 0
$NumAttr = 1;
$Template = qq(<div class="%1">\n);
$EndTemplate = "</div>\n";


################################################################
# Sub Entities
package HNS::Hnf::Command::Sub;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate); # HNS::Diary::Template

@ISA = qw(HNS::Hnf::Command::ConvTemplate);
$CountName = 'sub';
$OmittableEnd = 1;
$AllowCommands = [$HNS::Hnf::Command::Entities{'Flow'}];
$NameTemplate = "%year%month%day%{new}S%sub";

package HNS::Hnf::Command::SUB;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Sub);
$Template = q(<dd>
  <a name='%name' href='%href'>＠</a>
  <strong>%content</strong>: );

package HNS::Hnf::Command::LSUB;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Sub HNS::Hnf::Command::ConvUrl);
$Template = q(<dd>
  <a name='%name' href='%href'>＠</a>
  <strong><a href="%1">%content</a></strong>: );

$NumAttr = 1;

sub AsHTML ($$$) {
    my ($self, $start, $params) = @_;
    $self->ConvUrl();
    $self->SUPER::AsHTML($start, $params);
}

package HNS::Hnf::Command::RLSUB;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Sub);
use vars qw(%DB);
$Template = q(<dd>
  <a name='%name' href='%href'>＠</a>
  <strong><a href="%url%2">%content</a></strong>: );

$NumAttr = 2;
%DB = ();
sub AsHTML($$$)
{
    my ($self, $start, $params) = @_;

    unless (defined %DB) {
	tie %DB, 'SimpleDB::Hash',
	"$HNS::System::DiaryDir/conf/rlink.txt", 1;
    }
    my $url = $DB{$self->{attr}->[1]};
    unless ($url){
	return &HNS::Hnf::Warning::Message('NotDefined',
					   $self->{name},undef,
					   $self->{attr}->[1]);
    } else {
	$params->{url} = $url;
	return $self->SUPER::AsHTML($start, $params);
    }
}

################################################################
# Inline Elements
# these element has no content commands,
# so $EndTemplate, $AllowCommands has no means.

package HNS::Hnf::Command::Inline;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command);
$IsOneline = 1;

# Link Entity
package HNS::Hnf::Command::Link;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Inline);

# LINK
package HNS::Hnf::Command::LINK;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Link HNS::Hnf::Command::ConvUrl);
$Template = qq(<a href="%1">%content</a> );
$NumAttr = 1;

sub AsHTML ($$$) {
    my ($self, $start, $params) = @_;
    $self->ConvUrl();
    $self->SUPER::AsHTML($start, $params);
}

# RLINK
package HNS::Hnf::Command::RLINK;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Link);
use vars qw(%DB);
$Template = qq(<a href="%url%2">%content</a>);
$NumAttr = 2;
%DB = ();
sub AsHTML($$$)
{
    my ($self, $start, $params) = @_;

    unless (defined %DB){
	tie %DB, 'SimpleDB::Hash',
	"$HNS::System::DiaryDir/conf/rlink.txt", 1;
    }
    my $url = $DB{$self->{attr}->[1]};
    unless ($url){
	return &HNS::Hnf::Warning::Message('NotDefined',
					   $self->{name},undef,
					   $self->{attr}->[1]);
    } else {
	$params->{url} = $url;
	return $self->SUPER::AsHTML($start, $params);
    }
}

# URL
package HNS::Hnf::Command::URL;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Link HNS::Hnf::Command::ConvUrl);

$Template = qq(<img alt="*" src="./icons/mark01.gif" width="16" height="16"><a href="%1">%content(%1)</a>);
$NumAttr = 1;

sub AsHTML ($$$) {
    my ($self, $start, $params) = @_;
    $self->ConvUrl();
    $self->SUPER::AsHTML($start, $params);
}

# Decoration Commands
package HNS::Hnf::Command::Decoration; 
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Inline);

# STRIKE
package HNS::Hnf::Command::STRIKE;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Decoration);
$Template = q(<strike>%content</strike>);

# LSTRIKE
package HNS::Hnf::Command::LSTRIKE;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Decoration HNS::Hnf::Command::ConvUrl);
$Template = q(<strike><a href="%1">%content</a></strike>);
$NumAttr = 1;

sub AsHTML ($$$) {
    my ($self, $start, $params) = @_;
    $self->ConvUrl();
    $self->SUPER::AsHTML($start, $params);
}

# STRONG
package HNS::Hnf::Command::STRONG;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Decoration);
$Template = q(<strong>%content</strong>);

# FONT
package HNS::Hnf::Command::FONT;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Decoration);
$Template = q(<font %1="%2">%content</font>);
$NumAttr = 2;

# SPAN
package HNS::Hnf::Command::SPAN;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
            $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Decoration);
$Template = q(<span class="%1">%content</span>);
$NumAttr = 1;

# Image Commands
package HNS::Hnf::Command::Image;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);
use vars qw($AllowRemoteImage);

@ISA = qw(HNS::Hnf::Command::Inline);
$AllowRemoteImage = 0;

# IMG 
package HNS::Hnf::Command::IMG;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);
use vars qw($TemplateNosize $TemplateWithsize);

use Image::Size;

@ISA = qw(HNS::Hnf::Command::Image);
$TemplateWithsize = 
    qq(<img %align src="%2" alt="%content" width="%width" height="%height">\n);
$TemplateNosize = qq(<img %align src="%2" alt="%content">\n);
$NumAttr = 2;

sub AsHTML ($$$)
{
    my ($self, $start, $params) = @_;
    my %loc = (r=>'align="right"', l=>'align="left"' , n=>'' );
    my ($src, $alt) = ($self->{attr}->[2], $self->{arg_content});
    my $align = $loc{$self->{attr}->[1]};
    my ($width, $height) = imgsize($src, $HNS::System::ImgWidthMaxSize);
    
    $params->{align} = $align;
    if ($width && $height) {
           $params->{width} = $width;
           $params->{height} = $height;
           $Template = $TemplateWithsize;
    }
    elsif ($self->get_static_variable('AllowRemoteImage') 
	|| $src !~ m|^http://|) {
           $Template = $TemplateNosize;
    }
    else {
           return HNS::Hnf::Warning::Message('RemoteImage');
    }
    return $self->SUPER::AsHTML($start, $params);
}

# LIMG 
# Usage: LIMG <url> <align> <src> alt
#
package HNS::Hnf::Command::LIMG;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	$IsBeginSection $CountName $OmittableEnd);
use vars qw($TemplateNosize $TemplateWithsize);

use Image::Size;

@ISA = qw(HNS::Hnf::Command::Image);
$TemplateWithsize = q(<a href="%1"><img %align src="%3" alt="%content" width="%width" height="%height" border="2"></a>);
$TemplateNosize = q(<a href="%1"><img %align src="%3" alt="%content" border="2"></a>);
$NumAttr = 3;

sub AsHTML ($$$)
{
    my ($self, $start, $params) = @_;
    my %loc = (r=>'align="right"', l=>'align="left"' , n=>'' );
    my ($src, $alt) = ($self->{attr}->[3], $self->{arg_content});
    my $align = $loc{$self->{attr}->[2]};
    my ($width, $height) = imgsize($src, $HNS::System::ImgWidthMaxSize);
          
    $params->{align} = $align;
    if ($width && $height) {
           $params->{width} = $width;
           $params->{height} = $height;
           $Template = $TemplateWithsize;
    }
    elsif ($self->get_static_variable('AllowRemoteImage') || 
	$src !~ m|^http://|) {
           $Template = $TemplateNosize;
    }
    else {
           return HNS::Hnf::Warning::Message('RemoteImage');
    }
    return $self->SUPER::AsHTML($start, $params);
}

# MARK
package HNS::Hnf::Command::MARK;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

use Image::Size;

@ISA = qw(HNS::Hnf::Command::Image);
use vars qw(%List);
$Template = qq(<img src="%src" alt="%1" width=%width height=%height>);
$NumAttr = 1;
%List = ("(^^)" => "icons/nomal_13.gif",
	 "(^^;" => "icons/ase_13.gif",
	 "(;_;)" => "icons/naku_13.gif",
	 "v(^^)" => "icons/v_13.gif",
	 "!!" => "icons/neko_13.gif",
	 "??" => "icons/hatena_13.gif");

sub AsHTML ($$$){
    my ($self, $start, $params) = @_;
    my $mark = $self->{attr}->[1];
    my $src = $List{$mark};
    my ($width, $height) = imgsize($src);
    $params->{src} = $src;
    $params->{width} = $width;
    $params->{height} = $height;
    return $self->SUPER::AsHTML($start, $params);
}

# Replace Commands
# ALIAS
package HNS::Hnf::Command::ALIAS;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Inline);
use vars qw(%DB);
$Template = "%term";
%DB = ();

sub AsHTML ($$$)
{
    my ($self, $start, $params) = @_;
    my $term = $self->{arg_content};
    unless (defined %DB) {                             # if first use
	tie %DB, 'SimpleDB::Hash',                     # then tie hash
	"$HNS::System::DiaryDir/conf/alias.txt", 1;
    }
    my $replaced_term = $DB{$term};
    unless ($replaced_term) {
	return HNS::Hnf::Warning::Message('NotDefined', $self->{name},undef,
					  $term);
    } else {
	$params->{term} = $replaced_term;
	$self->SUPER::AsHTML($start, $params);
    }
}

################################################################
# Block Commands
package HNS::Hnf::Command::Block;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command);

# Cite Commands
package HNS::Hnf::Command::Cite;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Block);

# PRE
package HNS::Hnf::Command::PRE;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Cite);
$AllowCommands = [$HNS::Hnf::Command::Entities{'Inline'}];
$Template = "<pre>";
$EndTemplate = "</pre>";

# CITE
package HNS::Hnf::Command::CITE;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd $TemplateWithURI);

@ISA = qw(HNS::Hnf::Command::Cite);
$NumAttr = 1;
$Template = qq(<blockquote>\n);
$TemplateWithURI = qq(<blockquote cite="%1">\n);
$EndTemplate = "</blockquote>\n";
$AllowCommands = [$HNS::Hnf::Command::Entities{'Flow'}];

sub AsHTML ($$$){
    my ($self, $start, $params) = @_;
    my $uri = $self->{attr}->[1];
    if ($uri) {
	$Template = $TemplateWithURI;
    }
    return $self->SUPER::AsHTML($start, $params);
}

# INCLUDE
package HNS::Hnf::Command::INCLUDE;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
            $IsBeginSection $CountName $OmittableEnd);
use vars qw($file);

@ISA = qw(HNS::Hnf::Command::Cite);
$IsOneline = 1;
$Template = qq(<pre>\n%content\n</pre>);
$NumAttr = 1;
sub AsHTML($$$)
{
    my ($self, $start, $params) = @_;
    my $tmp;

    # restrict path of file
    $self->{attr}->[1] =~ s/\.\.\///g;
    $self->{attr}->[1] =~ s/\.\.\///g;
    if ($self->{attr}->[1] =~ /^\//) {
	$self->{attr}->[1] = $HNS::System::DiaryDir . $self->{attr}->[1];
    }
    else {
	$self->{attr}->[1] = "$HNS::System::IncludeDir/$self->{attr}->[1]";
    }

    if (! -f $self->{attr}->[1]) {     
	return &HNS::Hnf::Warning::Message('NotFound',
		$self->{name}, undef, $self->{attr}->[1]);
    }
    else {
	tie $tmp, 'SimpleDB::Scalar', "$self->{attr}->[1]", 1;
	my $file = $tmp;

	$file =~ s/&/&amp;/g;
	$file =~ s/</&lt;/g;
	$file =~ s/>/&gt;/g;

	$self->{arg_content} = $file;
	return $self->SUPER::AsHTML($start, $params);
    }
}

# List Commands
package HNS::Hnf::Command::List;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Block);
$AllowCommands = ['LI'];

# UL
package HNS::Hnf::Command::UL;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::List);
$Template = "<ul>";
$EndTemplate = "</ul>";

# OL
package HNS::Hnf::Command::OL;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::List);
$Template = "<ol>";
$EndTemplate = "</ol>";

# LI
package HNS::Hnf::Command::LI;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Block);
$Template = q(<li>%content );
$EndTemplate = "</li>";
$OmittableEnd = 1;
$AllowCommands = [$HNS::Hnf::Command::Entities{'Flow'}];


# DL
package HNS::Hnf::Command::DL;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
            $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::List);
$Template = "<dl>\n";
$EndTemplate = "</dl>\n";
$AllowCommands = ['DT', 'DD'];

# DT
package HNS::Hnf::Command::DT;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
            $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Block);
$Template = "<dt>%content";
$EndTemplate = "</dt>\n";
$OmittableEnd = 1;
$AllowCommands = [$HNS::Hnf::Command::Entities{'Inline'}];

# DD
package HNS::Hnf::Command::DD;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
            $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Block);
$Template = "<dd>%content";
$EndTemplate = "</dd>\n";
$OmittableEnd = 1;
$AllowCommands = [$HNS::Hnf::Command::Entities{'Flow'}];

# HR
package HNS::Hnf::Command::HR;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Block);
$IsOneline = 1;
$Template = q(<hr>\n);

# Comment Commands
package HNS::Hnf::Command::Comment;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);

@ISA = qw(HNS::Hnf::Command::Inline);

# FN
package HNS::Hnf::Command::FN;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
	    $IsBeginSection $CountName $OmittableEnd);
use vars qw($HeaderTemplate $FooterTemplate $ContentTemplate);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template

@ISA = qw(HNS::Hnf::Command::ConvTemplate HNS::Hnf::Command::Comment);
$IsOneline = 0;
$NameTemplate = "%year%month%day%{new}F%fn";

$Template = qq(<a href="%href"><small>*%fn</small></a>);

$HeaderTemplate = qq(<hr width="40%" align="left"><dt><small>\n);
$FooterTemplate = qq(</small></dd>);

$ContentTemplate = qq(<dd><a name="%name" href="%href">
		      <small>*%fn</small></a>:%content);

$AllowCommands = ['LINK', 'STRIKE'];


# RT
package HNS::Hnf::Command::RT;
use vars qw(@ISA $Template $EndTemplate $NumAttr $IsOneline $AllowCommands
$IsBeginSection $CountName $OmittableEnd);
@ISA = qw(HNS::Hnf::Command::Cite);
$AllowCommands = [''];
$Template = "<!--RT START-->\n";
$EndTemplate = "<!--RT END-->\n";
$OmittableEnd = 1;

sub rt2html(@){

    my @lines = @_;

    my @tbl_col=();
    my @tbl_row=();
    my @tbl_align=();
    my @tbl_item=();

    my @value_align=("left", "center", "right");
    my $caption    = "";
    my $delimiter  = ",\t";	# デリミタ

    my $tbl_width  = 1;
    my $tbl_height = 0;
    my $tbl_header = -1;	# THEAD領域の行数
    my $tbl_body   = -1;	# TBODY領域の行数

    my %style_table;	# <TABLE> 追加属性
    my %style_thead;	# <THEAD> 追加属性
    my %style_tindex;	# <TBODY> 追加属性(見出し部)
    my %style_tbody;	# <TBODY> 追加属性(本体)

    my $theme	= 0;
    my $status	= 0;
    my $rttype  = 0;    # 0:<TBODY> 1:<THEAD>&<TBODY>
    my $x;
    my $y;
    my $line;

    ### default
    $style_table{'border'} = 1;
    $style_tindex{'span'}  = 0;

    ### read
    foreach $line (@lines){
#  		print " LINE=",$line,"<br>";
	if( $line =~ /^\s*#/ ){
	    next;
	}
	if( $status == 0 ){	# ConfigBlock
	    if( $line =~ /^\s*caption\s*=\s*(.*)\s*$/i ){
		$caption = $1;
		next;
	    }
	    if( $line =~ /^\s*delimiter\s*=\s*(.*)\s*$/i ){
		$delimiter = $1;
		next;
	    }
	    if( $line =~ /^\s*(table|thead|tindex|tbody)_(\w+)\s*=\s*([\w#%]+)\s*/i ){
		my $type  = $1;
		my $key   = $2;
		my $value = $3;
		if( $type =~ /table/ ){ $style_table{$key} = $value;}
		if( $type =~ /thead/ ){ $style_thead{$key} = $value;}
		if( $type =~ /tindex/){ $style_tindex{$key}= $value;}
		if( $type =~ /tbody/ ){ $style_tbody{$key} = $value;}
		next;
	    }
	    if( $line =~ /^\s*theme\s*=\s*(\d+)\s*$/i ){
		$theme = $1;
		next;
	    }
	}

	if( $line =~ /^\s*\n$/ ){
	    if( $status == 1 ){
		$rttype = 1;			# <thead> と <tbody> が存在する表である		
		$tbl_header = $tbl_height;
	    }
	    next;
	}

	# デリミタとその前後の空白がセパレータとなる
	my @items = split(/\s*[$delimiter]\s*/, $line, -1);
	my $w = @items;				# 配列の個数
	if( $w >= $tbl_width ){
	    $tbl_width = $w;
	    $status = 1;
	}
	if( $w == $tbl_width ){
	    my $x = 0;
	    my $item;
	    foreach $item (@items){
		my $align;			# 0:left 1:center 2:right
		$item =~ s/^(\s*)//g;
		$item =~ s/(\s*)$//g;
		if( $item =~ /^[0-9]+.?[0-9]*/ ){
		    $align = 2;			# 数字は右詰め
		} else {
		    $align = 0;			# 他は左詰め
		}
		$tbl_item[$x][$tbl_height] = $item;
		$tbl_align[$x][$tbl_height]= $align; # align
		$tbl_col[$x][$tbl_height] = 1;		# clospan
		$tbl_row[$x][$tbl_height] = 1;		# rowspan
		$x++;
	    }
	    $tbl_height++;
	}

    }
    ### 
    if( $rttype == 0 ){
	$tbl_header = 0;
	$tbl_body   = $tbl_height;
    }else{
	$tbl_body = $tbl_height - $tbl_header;
    } 

    ### parse
    for( $y=$tbl_height-1 ; $y >= 0 ; $y-- ){
	for( $x=$tbl_width-1 ; $x >= 0 ; $x-- ){
	    my $tmp = $tbl_item[$x][$y];
	    if( $tmp =~ /^\s*==\s*$/ ){
		if( $x > 0 ){
		    $tbl_col[$x-1][$y] += $tbl_col[$x][$y];	# 左側のセルに結合(colspan 増加)
		    $tbl_col[$x][$y] = 0;
		    $tbl_row[$x][$y] = 0;			# このセルは消滅するので０を入れておく
		}
	    }
	    if( $tmp =~ /^\s*\|\|\s*$/ ){
		if( $y > 0 ){
		    $tbl_row[$x][$y-1] += $tbl_row[$x][$y];	# 上のセルに結合(rowspan 増加)
		    $tbl_row[$x][$y] = 0;
		    $tbl_col[$x][$y] = 0;			# このセルは消滅するので０を入れておく
		}	
	    }
	}
    }

    ### generate
    my $hnf_  ="";
    $hnf_ .= "<table";
    my $key;
    my $value;
    while( ($key, $value) = each %style_table ){
	$hnf_ .= " $key='$value'";
    }
    $hnf_ .= ">\n";
    $hnf_ .= "<caption><strong>$caption</strong></caption>\n";

    # <colgroup>
    if( $style_tindex{'span'} > 0 ){
	$hnf_ .= "<colgroup";
	while( ($key, $value) = each %style_tindex ){
	    $hnf_ .= " $key='$value'";
	}
	$hnf_ .= ">\n";
    }

    $style_tbody{'span'} = $tbl_width unless exists( $style_tbody{'span'});
    $hnf_ .= "<colgroup";
    while( ($key, $value) = each %style_tbody ){
	$hnf_ .= " $key='$value'";
    }
    $hnf_ .= ">\n";

    ### <THEAD>
    if( $tbl_header > 0 ){
	$hnf_ .= "<thead";
	while( ($key, $value) = each %style_thead ){
	    $hnf_ .= " $key='$value'";
	}
	$hnf_ .= ">\n";
	for( $y=0 ; $y < $tbl_header ; $y++ ){
	    $hnf_ .= "<tr>";
	    for( $x=0 ; $x < $tbl_width ; $x++ ){
		my $item = $tbl_item[$x][$y];
		if( $item =~ /^\s*$/ ){ $item ="<br>";}
		my $col  = $tbl_col[$x][$y];
		my $row  = $tbl_row[$x][$y];
		my $align= 1;
		my $tag  = "th";
		if(($col > 0)&&($row > 0)){
		    $hnf_ .= sprintf("<%s",$tag);
		    $hnf_ .= sprintf(" align='%s'",$value_align[$align]);
		    $hnf_ .= sprintf(" colspan='%d'",$col) if $col > 1;
		    $hnf_ .= sprintf(" rowspan='%d'",$row) if $row > 1;
		    $hnf_ .= sprintf(">%s</%s>",$item,$tag);
		}
	    }
	    $hnf_ .= "</tr>\n";
	}
	$hnf_ .= "</thead>\n";
    }

    ### <TBODY>
    $hnf_ .= "<tbody>";	

    # 本体
    for( $y=$tbl_header ; $y < $tbl_height ; $y++ ){
	$hnf_ .= "\n";
	$hnf_ .= "<tr>";
	for( $x=0 ; $x < $tbl_width ; $x++ ){
	    my $item = $tbl_item[$x][$y];
	    if( $item =~ /^\s*$/ ){ $item ="<br>";}
	    my $align= $tbl_align[$x][$y];
	    my $col  = $tbl_col[$x][$y];
	    my $row  = $tbl_row[$x][$y];
	    my $tag  = "td";
	    my $x_strong = 0;
	    $x_strong = $style_tindex{'span'} if exists( $style_tindex{'span'});
	    if( $x <= ($x_strong - 1) ){
		$tag   = "th";
		$align = 1;
	    }
	    if(($col > 0)&&($row > 0)){
		$hnf_ .= sprintf("<%s",$tag);
		$hnf_ .= sprintf(" align='%s'",$value_align[$align])
		    unless ((($tag == "th") && exists( $style_tindex{'align'}))
			    ||(($tag == "td") && exists( $style_tbody{'align'})));
		$hnf_ .= sprintf(" colspan='%d'",$col) if $col > 1;
		$hnf_ .= sprintf(" rowspan='%d'",$row) if $row > 1;
		$hnf_ .= sprintf(">%s</%s>",$item,$tag);
	    }
	}
	$hnf_ .= "</tr>";
    }
    $hnf_ .= "\n";
    $hnf_ .= "</tbody>\n";
    $hnf_ .= "</table>\n";

    return $hnf_;

}

1;
