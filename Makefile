###############################################################
## Makefile for hns 2.2
## $Id: Makefile,v 1.79 2006/11/05 01:04:32 kenji Exp $

# diary title
NIKKITITLE	= HNS: Hoge's Diary
# mail address for web diary page
USERMAIL        = hoge@example.ne.jp
# Author
AUTHOR		= 
# mail address for receiving message (null is no receiving)
MESMAIL		= 
# To: address for mail2nikki (only used in webif)
DIARYMAIL	= hoge@example.ne.jp
# From: address for mail2nikki
FROMADDR	= hoge@example.ne.jp
# password to update for mail2nikki 
PASSWORD	= hirakegoma
# ON if want Form of Namazu for hns
UNAGIUSE        = OFF
# diary URL
MYDIARYURI	= http://www.example.ne.jp/~hoge/diary/
# theme name (default = japanese)
THEME		= japanese
# Permit Hoshino Antenna(http://www.h14m.org/hoshino/) Registration?
# OK or NG
ANTENNA		= NG
# new reverse display? 0 -> No, 1 -> Yes 
NEWREVERSE	= 0
# starting year of your diary
STARTYEAR	= 2001
# use board? 0 -> No, 1 -> Yes 
USEBOARD	= 0

PERL_PATH       = /usr/local/bin/perl
SENDMAIL_PATH	= /usr/sbin/sendmail
NKF_PATH	= /usr/local/bin/nkf
FTP_PATH	= /usr/bin/ftp

# ftp server name (used only in webif ftp mode)
FTPHOST		= localhost
# ftp user name (used only in webif ftp mode)
FTPUSER		= hoge

HOMEDIR		= $(HOME)
DIARYDIR	= $(HOMEDIR)/diary
HTMLDIR		= $(HOMEDIR)/public_html/diary
CONFDIR		= $(DIARYDIR)/conf
LOGDIR		= $(DIARYDIR)/log
DATADIR	        = $(DIARYDIR)/data
BINDIR		= $(DIARYDIR)/bin
POSPEDIR	= $(DIARYDIR)/pospe
ICONDIR		= $(HTMLDIR)/icons
CATDIR		= $(HTMLDIR)/cat
# diary directory path at ftp login
# (used only webif ftp mode)
FTPDIARYDIR	= $(HOMEDIR)/diary

ISYSTEMDIR	= contrib/isystem
IDIR		= $(HTMLDIR)/i

HNS_CONFIG	= config.ph
HNS_CGI		= log.cgi title.cgi clear_cache.cgi \
		  title_wrapper.cgi rotate_log.cgi admini.cgi webif.cgi \
		  view.cgi make-rurimap.cgi index.cgi \
		  di.cgi headline.cgi board.cgi rss.cgi
HNS_TOOLS	= mail2nikki.pl make-diary.pl pospe2hnf.pl
HNS_SSI		= logging.pl intelli-search.pl
ISYSTEM		= i-system-config.ph i-system-index.cgi

HNS_CONFIG_REAL	= $(HNS_CONFIG:%=public_html/diary/%)
HNS_CGI_REAL	= $(HNS_CGI:%=public_html/diary/%)
HNS_TOOLS_REAL	= $(HNS_TOOLS:%=tools/%)
HNS_SSI_REAL	= $(HNS_SSI:%=public_html/diary/%)

hns:		$(HNS_CONFIG_REAL) $(HNS_CGI_REAL) $(HNS_TOOLS_REAL) $(HNS_SSI_REAL)
isystem:	$(ISYSTEM)
all:		hns isystem

$(HNS_CONFIG_REAL): $(HNS_CONFIG_REAL).in
	rm -f $@
	sed -e "s!%NIKKITITLE%!$(NIKKITITLE)!g" \
	    -e 's!%USERMAIL%!$(USERMAIL)!g' \
	    -e 's!%DIARYDIR%!$(DIARYDIR)!g' \
	    -e 's!%UNAGIUSE%!$(UNAGIUSE)!g' \
	    -e 's!%MYDIARYURI%!$(MYDIARYURI)!g' \
	    -e 's!%THEME%!$(THEME)!g' \
	    -e 's!%ANTENNA%!$(ANTENNA)!g' \
	    -e 's!%HTMLDIR%!$(HTMLDIR)!g' \
	    -e 's!%AUTHOR%!$(AUTHOR)!g' \
	    -e 's!%MESMAIL%!$(MESMAIL)!g' \
	    -e 's!%NEWREVERSE%!$(NEWREVERSE)!g' \
	    -e 's!%STARTYEAR%!$(STARTYEAR)!g' \
	    -e 's!%USEBOARD%!$(USEBOARD)!g' \
	    -e 's!%NKF_PATH%!$(NKF_PATH)!g' \
	    $< > $@

%.cgi: %.cgi.in
	rm -f $@
	sed -e 's!%PERL_PATH%!$(PERL_PATH)!g' \
	    -e 's!%HTMLDIR%!$(HTMLDIR)!g' \
	    -e 's!%DIARYDIR%!$(DIARYDIR)!g' \
	    -e 's!%FROMADDR%!$(FROMADDR)!g' \
	    -e 's!%SENDMAIL_PATH%!$(SENDMAIL_PATH)!g' \
	    -e 's!%DIARYMAIL%!$(DIARYMAIL)!g' \
	    -e 's!%SENDMAIL_PATH%!$(SENDMAIL_PATH)!g' \
	    -e 's!%FTP_PATH%!$(FTP_PATH)!g' \
	    -e 's!%FTP_HOST%!$(FTPHOST)!g' \
	    -e 's!%FTP_USER%!$(FTPUSER)!g' \
	    -e 's!%FTP_DIARY_DIR%!$(FTPDIARYDIR)!g' \
	   $< > $@

public_html/diary/%.pl: public_html/diary/%.pl.in
	rm -f $@
	sed -e 's!%PERL_PATH%!$(PERL_PATH)!g' \
	   $< > $@

tools/%.pl: tools/%.pl.in
	rm -f $@
	sed -e 's!%PERL_PATH%!$(PERL_PATH)!g' \
	    -e 's!%HTMLDIR%!$(HTMLDIR)!g' \
	    -e 's!%DIARYDIR%!$(DIARYDIR)!g' \
	    -e 's!%FROMADDR%!$(FROMADDR)!g' \
	    -e 's!%PASSWORD%!$(PASSWORD)!g' \
	    -e 's!%SENDMAIL_PATH%!$(SENDMAIL_PATH)!g' \
	    -e 's!%NKF_PATH%!$(NKF_PATH)!g' \
	   $< > $@

i-system-config.ph:
	if [ -d $(ISYSTEMDIR) ]; then \
	rm -f $(ISYSTEMDIR)/config.ph; \
	sed -e "s!%USERMAIL%!$(USERMAIL)!g" \
	    -e "s!%SENDMAIL%!$(SENDMAIL_PATH)!g" \
	    -e "s!%MYDIARYURI%!$(MYDIARYURI)!g" \
	    -e "s!%DIARYDIR%!$(DIARYDIR)!g" \
	    -e "s!%DEFHTML%!$(IDIR)!g" \
	    -e "s!%NIKKITITLE%!$(NIKKITITLE)!g" \
	    $(ISYSTEMDIR)/config.ph.in > $(ISYSTEMDIR)/config.ph; \
	fi

i-system-index.cgi:
	if [ -d $(ISYSTEMDIR) ]; then \
	rm -f $(ISYSTEMDIR)/index.cgi; \
	sed -e "s!%PERL_PATH%!$(PERL_PATH)!g" \
	    $(ISYSTEMDIR)/index.cgi.in > $(ISYSTEMDIR)/index.cgi; \
	fi

################################################################
# install

install-hns: hns
	if [ ! -d $(DIARYDIR) ]; then \
	  mkdir -p $(DIARYDIR); \
	fi

	for I in $(HTMLDIR) $(CONFDIR) $(LOGDIR) $(DATADIR) \
	           $(BINDIR) $(ICONDIR) $(CATDIR) $(DIARYDIR)/cache_static; do \
	  if [ ! -d $$I ]; then \
	    mkdir -p $$I; \
	  fi; \
	done

	for I in $(DIARYDIR)/mail $(POSPEDIR); do \
	  if [ ! -d $$I ]; then \
	    mkdir -p $$I; \
	    chmod 700 $$I; \
	  fi; \
	done

	for I in $(LOGDIR)/OLD $(LOGDIR)/LM $(DIARYDIR)/cache; do \
	  if [ ! -d $$I ]; then \
	    mkdir -p $$I; \
	    chmod 757 $$I; \
	  fi; \
	done

	################
	# diary/conf
	for I in robotlist browser_list i_browser browser_style; do \
	  if [ -f $(CONFDIR)/$${I}.txt ]; then \
	    mv $(CONFDIR)/$${I}.txt $(CONFDIR)/$${I}.txt-old; \
	  fi; \
	  cp -p diary/conf/$$I.txt $(CONFDIR); \
	done
	for I in head foot ruri_map auth_ruri rlink alias group; do \
	  touch $(CONFDIR)/$${I}.txt; \
	done

	################
	# diary/log

	for I in LastModified referer_log referer_batta_log denial_log cache_log dns_cache link_log; do \
	  touch $(LOGDIR)/$$I; \
	  chmod 646 $(LOGDIR)/$$I; \
	done

	for I in message-by-user.txt ruri-map-by-user.txt; do \
	  if [ ! -f $(LOGDIR)/$$I ]; then \
	    touch $(LOGDIR)/$$I; \
	    chmod 646 $(LOGDIR)/$$I; \
	  fi; \
	done

	################
	# diary/data
	touch $(DATADIR)/boarddata.txt
	chmod 646 $(DATADIR)/boarddata.txt

	################
	# diary/cache
	touch $(DIARYDIR)/cache/rss.txt
	chmod 646 $(DIARYDIR)/cache/rss.txt

	################
	# diary/bin
	for I in mail2nikki.pl make-diary.pl; do \
	  if [ -f $(BINDIR)/$$I ]; then \
	    mv $(BINDIR)/$$I $(BINDIR)/$${I}-old; \
	  fi; \
	  cp -p tools/$$I $(BINDIR); \
	  chmod 700 $(BINDIR)/$$I; \
	done

	################
	# diary/pospe
	if [ -f $(POSPEDIR)/pospe2hnf.pl ]; then \
	  mv $(POSPEDIR)/pospe2hnf.pl $(POSPEDIR)/pospe2hnf.pl-old; \
	fi
	cp -p tools/pospe2hnf.pl $(POSPEDIR)
	chmod 700 $(POSPEDIR)/pospe2hnf.pl

	################
	# tools
	if [ -f $(HTMLDIR)/log.cgi ]; then \
	  mv $(HTMLDIR)/log.cgi $(HTMLDIR)/log.cgi-old; \
	fi
	cp -p public_html/diary/logging.pl $(HTMLDIR)
	chmod 705 $(HTMLDIR)/logging.pl

	################
	# icons, cat, themes
	cp -p public_html/diary/icons/README* $(ICONDIR)
	cp -p public_html/diary/icons/*.png $(ICONDIR)
	for theme in anti-windoze ruribaka japanese english; do \
	  cp -pr public_html/diary/$${theme} $(HTMLDIR); \
	done
	touch $(CATDIR)/cat.txt
	cp -p public_html/diary/cat/*.png $(CATDIR)

	################
	# hnf sample
	if [ ! -d $(DIARYDIR)/2006 ]; then \
	  mkdir -p $(DIARYDIR)/2006; \
	  cp -p diary/2006/d20061105.hnf $(DIARYDIR)/2006; \
	  cp -p diary/2006/y200611 $(DIARYDIR)/2006; \
	fi
	for I in todo repeat link; do \
	  if [ ! -f $(DIARYDIR)/$$I ]; then \
	    cp -p diary/$$I $(DIARYDIR); \
	  fi; \
	done

	################
	# lib, cgi, config.ph, .htaccess
	if [ -f $(HTMLDIR)/config.ph ]; then \
	  mv -f $(HTMLDIR)/config.ph $(HTMLDIR)/config.ph-old; \
	fi
	cp -p $(HNS_CONFIG_REAL) $(HTMLDIR)
	cp -pr public_html/diary/lib $(HTMLDIR)
	cp -p public_html/diary/*.html $(HTMLDIR)
	cp -p $(HNS_CGI_REAL) $(HNS_SSI_REAL) $(HTMLDIR)
	if [ -f $(HTMLDIR)/.htaccess ]; then \
	  cp -p $(HTMLDIR)/.htaccess $(HTMLDIR)/.htaccess-old; \
	fi
	cp -p public_html/diary/dot.htaccess $(HTMLDIR)/.htaccess
	chmod 705 $(HTMLDIR)/*.cgi

	rm -rf $(HTMLDIR)/*/CVS
	rm -rf $(HTMLDIR)/lib/*/CVS
	rm -rf $(HTMLDIR)/lib/*/*/CVS
	################
	# README
	cat README.ja

install-isystem: isystem
	################
	# i system
	if [ ! -d $(IDIR) ]; then \
	  mkdir $(IDIR); \
	fi
	if [ -d $(ISYSTEMDIR) ]; then \
	  cp -p $(ISYSTEMDIR)/onccnv.pl $(IDIR); \
	  cp -p $(ISYSTEMDIR)/config.ph $(IDIR); \
	  cp -p $(ISYSTEMDIR)/index.cgi $(IDIR); \
	  chmod +x $(IDIR)/index.cgi; \
	fi
	if [ ! -d $(LOGDIR)/lock ]; then \
	  mkdir $(LOGDIR)/lock; \
	fi
	touch $(LOGDIR)/isystem.cnt
	touch $(LOGDIR)/isystem.dat
	touch $(LOGDIR)/isystem.acc
	chmod 777 $(LOGDIR)/lock
	chmod 666 $(LOGDIR)/isystem.*
	echo -n 'Redirect permanent $(MYDIARYURI)i/ $(MYDIARYURI)' | \
	  sed -e 's/http:\/\/[^/]*//' > $(IDIR)/.htaccess
	echo >> $(IDIR)/.htaccess

install:	all install-hns install-isystem

clean:
	rm -f $(HNS_CGI_REAL) $(HNS_SSI_REAL) $(HNS_TOOLS_REAL)

