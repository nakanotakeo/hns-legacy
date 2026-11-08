package Image::Size;
# $Id: Size.pm,v 1.11 2000/03/18 11:54:48 kenji Exp $
################################################################

=head1 NAME

Image::Size - 画像サイズの取得

=head1 SYNOPSIS

 use Image::Size;

 ($w, $h) = imgsize("foo.gif");


=head1 DESCRIPTION

取得可能なファイル形式は、gif, jpeg, png のみ。

=head1 STATIC FUNCTIONS

=cut

use strict;
use Exporter;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);
@EXPORT = qw(imgsize);


=head2 imgsize($file, $width_maxsize);

$file の画像サイズを ($width, $height) で返す。
$width_maxsize を指定すると、
それを最大サイズに縮尺したサイズを返す。

=cut

sub imgsize ($;$)
{
    my ($file, $width_maxsize) = @_;
    
    my ($width, $height);
    if ($file =~ /\.gif$/i){
	($width, $height) = gif_size($file);
    } elsif ($file =~ /\.png$/i){
	($width, $height) = png_size($file);
    } elsif (($file =~ /\.jpeg$/i) || ($file =~ /\.jpg$/i)) {
	($width, $height) = jpeg_size($file);
    } else {
        return undef;
    }
    # check max width size
    if ($width_maxsize > 0 && $width_maxsize < $width) {
	($width, $height) = ($width_maxsize,
			     int($height*($width_maxsize/$width)));
    }
    return ($width, $height);
}
################################################################
# 以下下請け

sub gif_size ($)
{
    my $file = shift;
    my $tmp;
    
    open(IN, $file) || return undef;
    read(IN, $tmp, 6);	# skip 6 bytes
    read(IN, $tmp, 4);	# width, height
    close(IN);

    my ($wl, $wh, $hl, $hh) = unpack("CCCC", $tmp);
    my $width = $wl + ($wh << 8);
    my $height = $hl + ($hh << 8);

    return ($width, $height);
}

sub png_size ($)
{
  my $file = shift;
  my $tmp;

  # PNG ファイル 16バイト目から 4バイトとってきて ビックエンディアン
  # それがwidth 次が height
  open(IN, $file);          # /* ひらきます */
  read(IN, $tmp, 16);        # /* 16byte スキップです */
  read(IN, $tmp, 8);         # /* width と height の順です */
  close(IN);                    # /* 閉じます */

                              # /* unpack で戻します */
  my ($width3, $width2, $width1, $width0,
  $height3, $height2, $height1, $height0) = unpack("CCCCCCCC",$tmp);
#  print "$tmp\n";
#  print "$width3 $width2 $width1 $width0 \n";
#  print "$height3 $height2 $height1 $height0 \n";

  my $width = $width0+($width1 << 8)+($width2 << 16)+($width3 << 24);
  my $height = $height0+($height1 << 8)+($height2 << 16)+($height3 << 24);

  return ($width, $height);
}

sub jpeg_size ($) {
  my $file = shift;
  my ($tmp, $m, $c, $l, $d, $width, $height);

  open(IN, $file) || return undef;
  binmode(IN);                          # for DOS
  read(IN, $tmp, 2);			# skip 2byte

  while(1) {
    read(IN, $tmp, 4);	# header
			# (marker,code,length(big endian)
    ($m, $c, $l) = unpack("a a n", $tmp);
    if( ord($m) ne 0xff ) {
#	print "error \n";
	last;
    }
    if( (ord($c) >= 0xc0) && ( ord($c) <= 0xc3 ) ) {
	read(IN, $tmp, 5);	# /* size
				# (dummy,x(big endian),y(big endian)) */
	($d, $height, $width) = unpack("a n n", $tmp);
	last;
    }
    read(IN, $tmp, $l - 2);
  }
  close(IN);	# /* 閉じます */

  return ($width, $height);
}

