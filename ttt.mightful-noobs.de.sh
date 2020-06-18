#!/bin/bash
BAKUPDIR=/root/backup
HOMEDIR=/root
FORMAT=$(date +%Y%m%d)-$(date +%H)
rclone delete --min-age 14d Nextcloud:/Backups/ttt.mightful-noobs.de
cd /
rsync -a --delete --exclude '/home/gmodserver/.steam' --exclude '/home/gmodserver/css/serverfiles' --exclude '/home/gmodserver/Steam' --exclude '/home/gmodserver/steamcmd' --exclude '/home/gmodserver/serverfiles/bin' --exclude '/home/gmodserver/serverfiles/platform' --exclude '/home/gmodserver/serverfiles/sourceengine' --exclude '/home/gmodserver/serverfiles/steam_cache' --exclude '/home/gmodserver/serverfiles/steamapps' --exclude '/home/gmodserver/serverfiles/garrysmod/*.vpk' --exclude '/home/gmodserver/serverfiles/garrysmod/*.pack' --exclude '/home/gmodserver/serverfiles/garrysmod/bin' --exclude '/home/gmodserver/serverfiles/garrysmod/cache' --exclude '/home/gmodserver/serverfiles/garrysmod/bin' --exclude '/home/gmodserver/serverfiles/garrysmod/backgrounds' --exclude '/home/gmodserver/serverfiles/garrysmod/download' --exclude '/home/gmodserver/serverfiles/garrysmod/downloadlists' --exclude '/home/gmodserver/serverfiles/garrysmod/fallbacks' --exclude '/home/gmodserver/serverfiles/garrysmod/gamemodes' --exclude '/home/gmodserver/serverfiles/garrysmod/html' --exclude '/home/gmodserver/serverfiles/garrysmod/maps' --exclude '/home/gmodserver/serverfiles/garrysmod/particles' --exclude '/home/gmodserver/serverfiles/garrysmod/resource' --exclude '/home/gmodserver/serverfiles/garrysmod/scenes' /home $BAKUPDIR
rsync -a --delete /etc $BAKUPDIR
rsync -a --delete --exclude '/root/backuputils/upload.tar.g*' --exclude '/root/backup' /root $BAKUPDIR
rsync -a --delete --exclude '/var/backups' --exclude '/var/cache' --exclude '/var/crash' --exclude '/var/lib' --exclude '/var/local' --exclude '/var/lock' --exclude '/var/log' --exclude '/var/mail' --exclude '/var/opt' --exclude '/var/run' --exclude '/var/snap' --exclude '/var/tmp' /var $BAKUPDIR
cd $BAKUPDIR
tar -zcvf $HOMEDIR/backuputils/upload.tar.gz *
cd $HOMEDIR/backuputils
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty upload.tar.gz
rclone copyto upload.tar.gz.gpg Nextcloud:/Backups/ttt.mightful-noobs.de/$FORMAT.tar.gz.gpg
