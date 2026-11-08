package HNS::Cache;
################################################################
# HNS::Cache  : Cache Management
# $Id: Cache.pm,v 1.6 2002/02/03 05:47:11 bonaim Exp $
################################################################

=head1 NAME

HNS::Cache - cacheクラス

=cut

use ObjectTemplate;
@HNS::Admini::ISA = qw(ObjectTemplate);

use strict;
use HNS::Status;
use HNS::System;
use SimpleDB::Append;

=head1 MEMBER VARIABLES

 status         HNS::Status オブジェクト

=cut

__PACKAGE__->attributes(qw(status));

################################################################

sub initialize($)
{
    my $self = shift;
    $self->status("HNS::Status"->new());
}

################################################################

=head2 $cache->Clear($auto);

cache を消去する。
$auto = 1 なら system による自動消去。メッセージを表示しない。

=cut


sub Clear($:$)
{
    my ($self, $auto) = @_;
    my $DiaryDir = $HNS::System::DiaryDir;
    my $CacheDir = $HNS::System::CacheDir;

    my @years;

    opendir(DIR, $CacheDir);
    my ($dir, $file);
    while ($file = readdir(DIR)) {
        push (@years, $1) if $file =~ /^(\d{4,})$/;
    }

    my $year;

    foreach $year (@years) {
	opendir(DIR, "$CacheDir/$year");
	while ($file = readdir(DIR)) {
	    unlink "$CacheDir/$year/$file" if ($file ne "." && $file ne "..");
	}
	rmdir "$CacheDir/$year";
	print "Year $year cache files in $CacheDir/$year cleared!<br>\n"
	unless $auto;
    }

    # logging
    my $date_time = sprintf(qq(%s), $self->status->date_time);
    my $cache_file = "$DiaryDir/log/cache_log";
    if ($HNS::System::CacheLog eq 'ON') {
        my $cache_log = SimpleDB::Append->new("$cache_file");
        if ($auto) {
            $cache_log->Append("$date_time clear system\n");
        }
	else {
	    $cache_log->Append("$date_time clear administrator\n");
        }
    }

}

sub AutoClear {
    my $self = shift;

    if ($HNS::System::AutoCacheClear && $HNS::System::Caching &&
	!$HNS::System::AllowCacheOnly) {
	my $dirty = 0;
	my $alias_lm  = (stat("$HNS::System::DiaryDir/conf/alias.txt"))[9];
	my $config_lm = (stat("./config.ph"))[9];
	my $rlink_lm  = (stat("$HNS::System::DiaryDir/conf/rlink.txt"))[9];
	my $theme_lm  = (stat("$HNS::System::Theme/theme.ph"))[9];
	my $cat_lm    = (stat("$HNS::CategoryList::CatDir/cat.txt"))[9];
	my $board_lm = (stat("$Board::BoardData"))[9];
	my $alias_log  = "$HNS::System::DiaryDir/log/LM/alias.txt";
	my $config_log = "$HNS::System::DiaryDir/log/LM/config.ph";
	my $rlink_log  = "$HNS::System::DiaryDir/log/LM/rlink.txt";
	my $theme_log  = "$HNS::System::DiaryDir/log/LM/theme.ph";
	my $cat_log    = "$HNS::System::DiaryDir/log/LM/cat.txt";
	my $board_log = "$HNS::System::DiaryDir/log/LM/board.txt";
	clear ("$alias_log")  unless (-f $alias_log);
	clear ("$config_log") unless (-f $config_log);
	clear ("$rlink_log")  unless (-f $rlink_log);
	clear ("$theme_log")  unless (-f $theme_log);
	clear ("$cat_log")    unless (-f $cat_log);
	clear ("$board_log") unless (-f $board_log);
	my $alias_lm_log  = (stat("$alias_log"))[9];
	my $config_lm_log = (stat("$config_log"))[9];
	my $rlink_lm_log  = (stat("$rlink_log"))[9];
	my $theme_lm_log  = (stat("$theme_log"))[9];
	my $cat_lm_log    = (stat("$cat_log"))[9];
	my $board_lm_log = (stat("$board_log"))[9];

	if ($alias_lm != $alias_lm_log) {
	    $dirty = 1;
	    utime($alias_lm, $alias_lm, $alias_log);
	}
	if ($config_lm != $config_lm_log) {
	    $dirty = 1;
	    utime($config_lm, $config_lm, $config_log);
	}
	if ($rlink_lm != $rlink_lm_log) {
	    $dirty = 1;
	    utime($rlink_lm, $rlink_lm, $rlink_log);
	}
	if ($theme_lm != $theme_lm_log) {
	    $dirty = 1;
	    utime($theme_lm, $theme_lm, $theme_log);
	}
	if ($cat_lm != $cat_lm_log) {
	    $dirty = 1;
	    utime($cat_lm, $cat_lm, $cat_log);
	}
	if ($board_lm != $board_lm_log) {
	    $dirty = 1;
	    utime($board_lm, $board_lm, $board_log);
	}

	if ($dirty) {
	    my $cache = HNS::Cache->new();
	    $self->Clear(1);
	}
	return $dirty;
    }
    return 1;
} 

sub clear ($) {
  my ($file) = @_;

  open(F, ">$file") || die "$file: $!\n";
    print F;
  close(F);
}

################################################################

1;
