#!/bin/bash
BACKUPDIR=/root/backup
HOMEDIR=/root
FORMAT=$(date +%Y%m%d)-$(date +%H)
echo Deleting old archives...
rclone delete --min-age 14d SFTP:mightful-noobs.de > /dev/null
cd "$BACKUPDIR"/mariadb || exit
echo MariaDB Backup
count=$(find ./*.sql 2>/dev/null | wc -l)
if [ "$count" != 0 ]; then
	rm ./*.sql
fi
mysql -N -e 'show databases' | while read -r dbname; do mysqldump --complete-insert --routines --triggers --single-transaction "$dbname" > "$dbname".sql; done
cd / || exit
echo rsync /var
rsync -a --delete --exclude '/var/backups' --exclude '/var/cache' --exclude '/var/local' --exclude '/var/lock' --exclude '/var/lib' --exclude '/var/log' --exclude '/var/mail' --exclude '/var/spool/mail' --exclude '/var/opt' --exclude '/var/run' --exclude '/var/tmp' /var "$BACKUPDIR" > /dev/null
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
rm upload.tar.gz
echo Uploading...
rclone copyto upload.tar.gz.gpg SFTP:mightful-noobs.de/"$FORMAT".tar.gz.gpg > /dev/null
rm upload.tar.gz.gpg
