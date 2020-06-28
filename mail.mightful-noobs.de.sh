#!/bin/bash
BAKUPDIR=/root/backup
HOMEDIR=/root
FORMAT=$(date +%Y%m%d)-$(date +%H)
export MAILCOW_BACKUP_LOCATION=$BAKUPDIR/mailcow
rclone delete --min-age 14d Nextcloud:/Backups/mail.mightful-noobs.de
cd /opt/mailcow-dockerized
helper-scripts/backup_and_restore.sh backup --delete-days 0 all
cd /
rsync -a --delete --exclude '/var/backups' --exclude '/var/cache' --exclude '/var/crash' --exclude '/var/lib' --exclude '/var/local' --exclude '/var/lock' --exclude '/var/log' --exclude '/var/mail' --exclude '/var/opt' --exclude '/var/run' --exclude '/var/snap' --exclude '/var/tmp' /var $BAKUPDIR
rsync -a --delete --exclude '/root/backuputils/upload.tar.g*' --exclude '/root/backup' /root $BAKUPDIR
rsync -a --delete /etc $BAKUPDIR
cd $BAKUPDIR
tar -zcvf $HOMEDIR/backuputils/upload.tar.gz *
cd $HOMEDIR/backuputils
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty upload.tar.gz
rclone copyto upload.tar.gz.gpg Nextcloud:/Backups/mail.mightful-noobs.de/$FORMAT.tar.gz.gpg
