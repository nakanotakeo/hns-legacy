#!/bin/sh
# i system setup script for hns users
# 2000/4/10  Kenji Suzuki <kenji@h14m.org>

PATH=$PATH:/usr/sbin

HNSSETUP=$HOME/.hnssetup
if [ -f $HNSSETUP ]; then
 eval `cat $HNSSETUP`
else
 echo "Error: no $HNSSETUP!"
 exit
fi
DEFURL="${DEFURL}i/"
DEFHTML="${DEFHTML}/i"

PERL=`which perl`
SENDMAIL=`which sendmail`

sed -e "s!%USERMAIL%!$DEFMAIL!g" \
    -e "s!%SENDMAIL%!$SENDMAIL!g" \
    -e "s!%MYDIARYURI%!$DEFURL!g" \
    -e "s!%DIARYDIR%!$DEFDIARY!g" \
    -e "s!%DEFHTML%!$DEFHTML!g" \
    -e "s!%NIKKITITLE%!$DEFTITLE!g" \
		config.ph.in > config.ph

sed -e "s!%PERL_PATH%!$PERL!g" \
		index.cgi.in > index.cgi

if [ ! -d $DEFHTML ]; then
    mkdir $DEFHTML
fi

cp -p onccnv.pl config.ph index.cgi jcode.pl $DEFHTML
chmod +x $DEFHTML/index.cgi

cd $DEFDIARY/log

# files to log 
if [ ! -d lock ]; then
    mkdir lock
fi
touch isystem.cnt
touch isystem.dat
touch isystem.acc
chmod 777 lock
chmod 666 isystem.*



