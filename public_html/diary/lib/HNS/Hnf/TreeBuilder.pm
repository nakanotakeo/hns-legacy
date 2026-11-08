package HNS::Hnf::TreeBuilder;
# $Id: TreeBuilder.pm,v 1.40 2002/06/19 13:37:20 kenji Exp $
################################################################

=head1 NAME

HNS::Hnf::TreeBuilder - 木構造構築クラス


=head1 DESCRIPTION

parse the hnf, and construct tree-structure

=cut

################################################################
use strict qw(vars);
use Image::Size;                # CAT image
use HNS::Hnf::Command;
use HNS::Hnf::Warning;
use HNS::Template;
use HNS::CategoryList;
use HNS::System;
use HNS::Diary::Template;

BEGIN {
	$HNS::Hnf::TreeBuilder::debug = 0;
	print "content-type: text/html\r\n\r\n" 
		if ($HNS::Hnf::TreeBuilder::debug);
}
#@HNS::Hnf::TreeBuilder::ISA = qw(HNS::Hnf::Command::HNF);

################################################################
sub new ($)
{
    my $class = shift;
    my $self = {
	top=>new HNS::Hnf::Command::HNF('HNF')    # top element of parse tree
	};
    bless $self, $class;
}
################################################################

=head2 $t->Parse($line);

$line を解析し、ノードを適切な場所に追加する。

=cut

sub Parse($$)
{
    my ($self, $line) = @_;

    # comment
    if ($line =~ /^!\#\s/){
	return;
    } elsif ($line =~ s/^!\s//){
	chomp($line);
	$line = "<!-- $line -->\n";
    }
    # translate ~ to <BR>
    $line =~ s/~$/<br>/;
#      if ($line =~ m!^(/?[A-Z]+)\s(.*)$!){    # may be hnf-command
    if ($line =~ m!^(/?[A-Z]+)(\s+(.*)$|$)!){    # may be hnf-command
	my $cmd_name = $1;
	my $is_end = $cmd_name =~ s!^/!!;
#    	my @vars = ($cmd_name, split(/ /, $2));
  	my @vars = ($cmd_name, split(/ /, $3));
	if (!$is_end){
	    $self->start(@vars);          # start command. ex) UL
	} else {
	    $self->end(@vars);            # end command. ex) /UL
	}
    } else {                              # plain text
	$self->text($line);
    }
}

=head2 $t->start(@vars);

 private:
 if start command apeared,
 first create new command object($e),
 second insert the object to valid position of the tree($self->{pos}).

 (*) checking command validation and placement.
     insert end tag when the command could be omit end-command.

=cut

sub start($@)
{
    my ($self, @vars) = @_;

    my $cmd_name = $vars[0];
    my $e;
    my $pos = $self->{top}->{pos} || $self->{top};
    my $class = "HNS::Hnf::Command::$cmd_name";
    eval("\$e = new $class(qq($cmd_name));");
    if ($@){    # invalid command
	$pos->PushContent(join(' ', @vars));
	$pos->PushContent("\n");
	$pos->PushContent(HNS::Hnf::Warning::Message('Reserved', $cmd_name))
	    unless (($HNS::System::IgnoreReserved eq 'ON') ||
	    ($pos->{name} eq "PRE"));	# don't warn if in PRE
	print "pos->{name}: $pos->{name}\n" if ($HNS::Hnf::TreeBuilder::debug);
	return;
    }
    # set attributes and element to new Command
    {
	my $n_attr = "${class}::NumAttr";
	# if line is "LINK url explain of anchor", and $n_attr == 1,
	# $e->{attr} = ['LINK', 'url']
	# $e->{arg_content} = 'explain of ahchor';
	$n_attr = $$n_attr;
	$e->{attr} = [@vars[0..$n_attr]];
	$e->{arg_content} = join(' ', @vars[$n_attr+1..$#vars]);
    }
    # check structure
    {
	my $pos_name = $pos->{name};

	print "start[" . $pos->{name} . "]: @vars\n" 
		if ($HNS::Hnf::TreeBuilder::debug);
	# check allowed
	if (!$pos->allowed($cmd_name)){
	    if ($pos_name ne $cmd_name && !$pos->OmittableEnd){
		$pos->PushContent(HNS::Hnf::Warning::Message('NoMatch',
							     $cmd_name,
							     $pos_name));
	    }
	    # complete end command automatically if omittable
	    $self->end($cmd_name);
	    print "end: $pos_name,", $pos->{name}, ",", $e->{name}, ",", 
		$e->{parent}->{name}, "\n" if ($HNS::Hnf::TreeBuilder::debug);
	}

	# CAT must have only one New element
	if ($e->IsBeginSection && $pos->{name} ne 'CAT'){
	print $e->{name}, "\n" if ($HNS::Hnf::TreeBuilder::debug);
	    $self->{top}->InsertCommand('CAT');
	}
	print "$cmd_name in $pos_name\n" if ($HNS::Hnf::TreeBuilder::debug);
    }
    # insert new command
    $self->{top}->InsertCommand($e);

    # if oneline command, insert end tag immidiately
    if ($e->IsOneline){
    print "oneline:$cmd_name\n" if ($HNS::Hnf::TreeBuilder::debug);
	$self->end($cmd_name);
    }
}
# private:

=head2 $t->end($cmd_name);

コマンド $cmd_name の終わりを指定する。
現在ノードを移動。

=cut

sub end($$)
{
    my ($self, $cmd_name) = @_;
    print "end: $cmd_name\n" if ($HNS::Hnf::TreeBuilder::debug);
    my $p = $self->{top}->{pos} || $self;

    $cmd_name =~ s/^R?L(NEW|SUB)/$1/;
    
    # enclose until self tag
    while (defined $p){
	my $p_name = $p->{name};
	$p_name =~ s/^R?L(NEW|SUB)/$1/;
#	last if $p->{name} =~ /$cmd_name/;
	last if $p_name eq $cmd_name;
	$p = $p->{parent};
    }
    $self->{top}->{pos} = (defined $p) ?
	$p->{parent} : $self->{top}->{pos}->{parent};
}

=head2 $t->text($text);

$text を現在位置へ push する

=cut

sub text($$)
{
    my ($self, $text) = @_;
    my $pos = $self->{top}->{pos} || $self->{top};
    print "text[" . $pos->{name} . "]:$text\n" 
	if ($HNS::Hnf::TreeBuilder::debug);
    $pos->PushContent($text);
}

################################################################

=head2 $t->Print($year, $month, $day, $section);

表示する

=cut

sub Print($$$$)
{
    my ($self, $year, $month, $day, $section) = @_;
    print "TreeBuilder Print: $self, $year, $month, $day, $section\n"
	if ($HNS::Hnf::TreeBuilder::debug);    
    my $html;

    # for footnote
    my $in_fn = 0;
    my @footnotes;

    # for group command
    my ($grpCount, $grpFlg, $tmpnewCount, $newDisplay);

    # for eval template
    my ($newCount, $subCount, $pCount, $fnCount);	#added
    my $abc;
    if ($day < 11) {
        $abc = "a";
    }
    elsif ($day < 21) {
        $abc = "b";
    }
    else {
        $abc = "c";
    }
    my $code_params = q({year=>$year, month=>$month, day=>$day,
			 high=>int($day/10), abc=>$abc,
			 new=>$newCount, sub=>$subCount, p=>$pCount, fn=>$fnCount,
			 cat=>$cat, mark=>$newDisplay, 
			 boardlink=>Board::get_linkstr("$year$month$day$newCount"),
		         boarddata=>Board::get_commentstr("$year$month$day$newCount")});

    my $grp;
    # category presentation
    my $cat;
    my $selected_cat;	#add

    # traverse the tree-structure and print
    # FN, /FN and CAT is special command
    $self->{top}->Traverse(sub {
	my ($node, $start, $depth) = @_;
	if (ref $node){            # HNF command
	    my $name = $node->{name};
	    if ($name eq 'FN'){    # FN command
		if ($start){
		    $fnCount++;
		}
		$in_fn = $start;   # whether $node is content of FN
		HNS::Diary::HnfPrint ($node->AsHTML($start, eval($code_params))); 
	    } else {               # else command
		if ($HNS::CategoryList::CatDir && $name eq 'CAT' && $start){
		    my $params = eval($code_params);
		    $cat = get_category($params, $node->{arg_content});

		    if ($cat) {
			$selected_cat = $node->{arg_content};
		    } else {
			$selected_cat = "";
		    }
		}
		if ($in_fn){
		    $footnotes[$fnCount] .= $node->AsHTML($start,
							  eval($code_params));
		} else {
		    my $count_name;
		    if ($start && ($count_name = $node->CountName)){
                        if (($grpFlg) && ($name eq "NEW" || $name eq "LNEW" || $name eq "RLNEW")) {
                            $grpFlg = 0;
                            $newCount = $tmpnewCount - 1;
                        }
			my $code = "\$${count_name}Count++;";
			eval($code);
			$newDisplay = $newCount;
                        # xhnf control code
                        HNS::Diary::HnfPrint ("\n<!-- xhnf_break -->\n")
			    if ($name eq "NEW" || $name eq "LNEW" || $name eq "RLNEW");
			if ($grp) {
				HNS::Diary::HnfPrint ("<!-- xhnf_grp $grp -->\n");
				$grpCount++;
				$tmpnewCount = $newCount;
				$newCount = "G" . $grpCount;
				$newDisplay = $HNS::Hnf::Command::GRP::Mark;
				$grpFlg = 1;
				$grp = undef;
			}

  		        HNS::Diary::HnfPrint ("<!-- xhnf_cat $selected_cat -->\n")
			    if ($name eq "NEW" || $name eq "LNEW" || $name eq "RLNEW");

		    }
		    if ($name eq "GRP") {
			$cat = undef;
			$grp = $node->{arg_content};
		    }
		    # beginning of section : NEW, SNEW
		    print "parent:", $node->{parent}->{name}
			if ($HNS::Hnf::TreeBuilder::debug);
		    print " node name:", $node->{name}, " start?:$start\n"
			if ($HNS::Hnf::TreeBuilder::debug);
		    if (!$start && $node->IsBeginSection){
			# clear count
			$subCount = 0;
			$pCount = 0;	#added
			$fnCount = 0 if ($HNS::System::FNCountStyle == 0);
			# if current section has any FN content,
			# print it in here.
			if (@footnotes){
			    my $params = eval($code_params);
			    my $footnote = new HNS::Hnf::TreeBuilder::Footnote;
			    $footnote->print($params, @footnotes); 
			    # reset footnotes
			    @footnotes = ();
			}
		    }
		    HNS::Diary::HnfPrint ($node->AsHTML($start, eval($code_params)));
		}
	    }
	} else {                        # plain text
	    if ($in_fn){
		$footnotes[$fnCount] .= $node;
	    } else {
		HNS::Diary::HnfPrint ($node);
	    }
	}1;});

    return;
}

sub get_category ($$)
{
    my ($params, $arg_content) = @_;
    my $templ = new HNS::Template;
    $templ->SetParamValues(%$params);
  
    my $cat;
    # CAT arg1 arg2 arg3..
    for my $c (split(/ /, $arg_content)){
	my $img;
	my $enc_c = $c;
	$enc_c =~ s/([^a-zA-Z0-9~\-\_\.\/\:\%])/
                sprintf("%%%02X",ord($1))/ge;

	if ($img = $HNS::CategoryList::DB{$c}){
	    my $src = "$HNS::CategoryList::CatDir/$img";
	    my ($width, $height) = imgsize($src);
	    if ($width ne undef) {
		my $tmp = qq(<img src="$src" width="$width" height="$height" alt="[$c]">);
		$templ->SetTemplate(SelectTemplate($HNS::Hnf::Command::CAT::ImgTemplate,
						   %HNS::Hnf::Command::CAT::ImgTemplate));
		$templ->SetParamValues('enc_var'=>$enc_c);
		$templ->SetParamValues('img'=>$tmp);
		$cat .= $templ->Expand;
	    }
	    else {
		$templ->SetTemplate(SelectTemplate($HNS::Hnf::Command::CAT::Template,
						   %HNS::Hnf::Command::CAT::Template));
		$templ->SetParamValues('var'=>$c);
		$templ->SetParamValues('enc_var'=>$enc_c);
                $cat .= $templ->Expand;
	    }
	} elsif ($c) {
	    $templ->SetTemplate(SelectTemplate($HNS::Hnf::Command::CAT::Template,
					       %HNS::Hnf::Command::CAT::Template));
	    $templ->SetParamValues('var'=>$c);
	    $templ->SetParamValues('enc_var'=>$enc_c);
	    $cat .= $templ->Expand;
	}
    }
    return $cat;
}
package HNS::Hnf::TreeBuilder::Footnote;
use vars qw(@ISA);
use vars qw($BaseTemplate $NameTemplate $HrefTemplate
	    %BaseTemplate %NameTemplate %HrefTemplate);	# HNS::Diary::Template
@ISA = qw(HNS::Diary::Template);
$NameTemplate = $HNS::Hnf::Command::FN::NameTemplate;
sub print ($$@)
{
    my ($self, $params, @footnotes) = @_;
    
    my $templ = new HNS::Template;
    $self->ExpandTempl($templ);
    $templ->SetParamValues(%$params);
    # fn header
    $templ->SetTemplate
	($HNS::Hnf::Command::FN::HeaderTemplate);
    HNS::Diary::HnfPrint ($templ->Expand);
    # fn content
    my $cnt;
    for (@footnotes[1..$#footnotes]){
	$cnt++;
	next if (($_ eq "") && ($HNS::System::FNCountStyle));
	$templ->SetTemplate
	    ($HNS::Hnf::Command::FN::ContentTemplate);
	$templ->SetParamValues('fn'=>$cnt);
	$templ->SetParamValues('content'=>$_);
	$self->ExpandTempl($templ);
	HNS::Diary::HnfPrint ($templ->Expand);
    }
    # fn footer
    $templ->SetTemplate
	($HNS::Hnf::Command::FN::FooterTemplate);
    HNS::Diary::HnfPrint ($templ->Expand);
}
1;


