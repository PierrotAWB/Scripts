#! /usr/bin/env bash

# Run only if user logged in (prevent cron errors)
pgrep -u "${USER:=$LOGNAME}" >/dev/null || { echo "$USER not logged in; sync will not run."; exit ;}

DAY=$(date '+%a')

FILES="/home/andrew/music /home/andrew/documents /home/andrew/.password-store /home/andrew/.local/bin /home/andrew/.local/share /usr/local/share/texmf/tex/latex/Andrew/Andrew.sty /var/spool/cron/andrew /etc/hosts /etc/profile /etc/fonts/local.conf"

SNAR=data.snar
TAR=data.${DAY}.tar.gz
MOUNT=/usr/bin/mount
UMOUNT=/usr/bin/umount
MNTPOINT="/mnt"
BACKUP="$MNTPOINT/backups"
ARCHIVE="$BACKUP/archived"
RECIPIENT=andrewwang298@gmail.com

# ADATA HD710
UUID="60d17d09-5fe6-46bf-9e48-56aff3aa5d94"

# Print start datetime.
date '+%nBackup started at %F %r.'

# Mount.
$MOUNT "UUID=$UUID"

if [ $DAY = 'Sun' ]; then
	LASTWEEK=$(date --date '7 days ago' +%F)
	test -e $BACKUP/$SNAR && mv $BACKUP/$SNAR $BACKUP/${SNAR}.$LASTWEEK
	mkdir $ARCHIVE/$LASTWEEK
	mv $BACKUP/data* $ARCHIVE/$LASTWEEK
fi

tar -czg $BACKUP/$SNAR -f $BACKUP/$TAR $FILES

#  Encrypt, then shred tar.
printf "Encrypting and shredding.\n"
gpg -r $RECIPIENT -e $BACKUP/$TAR
shred -u $BACKUP/$TAR

# Alternative to umount -l
sudo $MOUNT -o remount,ro "UUID=$UUID" && printf "Remount succeeded.\n"

# Notify.
notify-send 'Backup completed!' -t 5000
