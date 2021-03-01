#!/bin/bash
BACKUPDIR=/root/backup
HOMEDIR=/root
FORMAT=$(date +%Y%m%d)-$(date +%H)
rclone delete --min-age 14d OneDrive:/Backups/mightful-noobs.de
cd $BACKUPDIR
rm *.sql
mysql -N -e 'show databases' | while read dbname; do mysqldump --complete-insert --routines --triggers --single-transaction "$dbname" > "$dbname".sql; done
cd /
rsync -a --delete --exclude '/var/backups' --exclude '/var/cache' --exclude '/var/crash' --exclude '/var/lib' --exclude '/var/local' --exclude '/var/lock' --exclude '/var/log' --exclude '/var/mail' --exclude '/var/opt' --exclude '/var/run' --exclude '/var/snap' --exclude '/var/tmp' /var $BACKUPDIR
rsync -a --delete --exclude /home $BACKUPDIR
rsync -a --delete --exclude '/root/backuputils/upload.tar.g*' --exclude '/root/backup' /root $BACKUPDIR
rsync -a --delete /etc $BACKUPDIR
cd $BACKUPDIR
tar -zcvf $HOMEDIR/backuputils/upload.tar.gz *
cd $HOMEDIR/backuputils
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty upload.tar.gz
rclone copyto upload.tar.gz.gpg OneDrive:/Backups/mightful-noobs.de/$FORMAT.tar.gz.gpg
