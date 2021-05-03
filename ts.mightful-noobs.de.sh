#!/bin/bash
BACKUPDIR=/root/backup
HOMEDIR=/root
FORMAT=$(date +%Y%m%d)-$(date +%H)
echo Deleting old archives...
rclone delete --min-age 14d SFTP:ts.mightful-noobs.de > /dev/null
cd / || exit
echo rsync /var
rsync -a --delete --exclude '/var/backups' --exclude '/var/cache' --exclude '/var/local' --exclude '/var/lock' --exclude '/var/lib' --exclude '/var/log' --exclude '/var/mail' --exclude '/var/spool/mail' --exclude '/var/opt' --exclude '/var/run' --exclude '/var/tmp' /var "$BACKUPDIR" > /dev/null
echo rsync /home
rsync -a --delete /home "$BACKUPDIR" > /dev/null
echo rsync /root
rsync -a --delete --exclude '/root/.gnupg' --exclude '/root/backuputils/upload.tar.g*' --exclude '/root/backup' /root "$BACKUPDIR" > /dev/null
echo rsync /etc
rsync -a --delete /etc "$BACKUPDIR" > /dev/null
echo Packing...
cd "$BACKUPDIR" || exit
tar -zcvf "$HOMEDIR"/backuputils/upload.tar.gz ./* > /dev/null
echo Encrypting...
cd "$HOMEDIR"/backuputils || exit
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty upload.tar.gz > /dev/null
echo Uploading...
rclone copyto upload.tar.gz.gpg SFTP:ts.mightful-noobs.de/"$FORMAT".tar.gz.gpg > /dev/null
