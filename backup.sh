#! /usr/bin/env bash

# Run only if user logged in (prevent cron errors)
pgrep -u "${USER:=$LOGNAME}" >/dev/null || { echo "$USER not logged in; sync will not run."; exit ;}

DAY=$(date '+%a')

FILES="/home/andrew/music /home/andrew/documents /home/andrew/.password-store /home/andrew/.local/bin /home/andrew/.local/share /usr/local/share/texmf/tex/latex/Andrew/Andrew.sty /var/spool/cron/andrew /etc/hosts /etc/profile /etc/fonts/local.conf /etc/dnsmasq.conf"

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
date '+Backup started at %F %r.'

# Mount.
$MOUNT "UUID=$UUID"

# If oldest backup is older than a week old, stash it and start anew.
if [ $(date -d "6 days 1 hour + $(ls -clt $BACKUP/*.gpg | tail -1 | tr -s ' ' | cut -d' ' -f6-8)" "+%s") -lt $(date "+%s") ]; then
	printf "Current cycle is stale (oldest backup is from more than 6 days ago).\n"
	printf "Archiving, and starting anew.\n"
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

# Print end datetime.
date '+Backup completed at %F %r.'
