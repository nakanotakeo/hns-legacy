#!/bin/sh
# $Id: test.sh,v 1.1 2006/03/06 12:51:37 kenji Exp $

# testing perl syntax in cgi

cgi="admini.cgi  headline.cgi       make-rurimap.cgi   view.cgi
board.cgi        index.cgi          rotate_log.cgi     webif.cgi
clear_cache.cgi  intelli-search.pl  rss.cgi
config.ph        log.cgi            title.cgi
di.cgi           logging.pl         title_wrapper.cgi
"

for i in $cgi
do
  #echo $i
  perl -c $i
done

