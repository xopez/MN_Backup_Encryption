#!/bin/bash
BAKUPDIR=/root/backup
HOMEDIR=/root
FORMAT=$(date +%Y%m%d)-$(date +%H)
rclone delete --min-age 14d Nextcloud:/Backups/ts.mightful-noobs.de
cd /
rsync -a --delete --exclude '/var/backups' --exclude '/var/cache' --exclude '/var/crash' --exclude '/var/lib' --exclude '/var/local' --exclude '/var/lock' --exclude '/var/log' --exclude '/var/mail' --exclude '/var/opt' --exclude '/var/run' --exclude '/var/snap' --exclude '/var/tmp' /var $BAKUPDIR
rsync -a --delete --exclude '/home/ts3server/serverfiles/doc' --exclude '/home/ts3server/serverfiles/redist' --exclude '/home/ts3server/serverfiles/serverquerydocs' --exclude '/home/ts3server/serverfiles/sql' --exclude '/home/ts3server/serverfiles/tsdns' --exclude '/home/ts3server/serverfiles/*.so' --exclude '/home/ts3server/serverfiles/*.2' /home $BAKUPDIR
rsync -a --delete /etc $BAKUPDIR
rsync -a --delete --exclude '/root/backuputils/upload.tar.g*' --exclude '/root/backup' /root $BAKUPDIR
cd $BAKUPDIR
tar -zcvf $HOMEDIR/backuputils/upload.tar.gz *
cd $HOMEDIR/backuputils
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty upload.tar.gz
rclone copyto upload.tar.gz.gpg Nextcloud:/Backups/ts.mightful-noobs.de/$FORMAT.tar.gz.gpg
