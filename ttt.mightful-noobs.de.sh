#!/bin/bash

# Verzeichnisse und Dateinamen definieren
BACKUPDIR="/root/backup"
HOMEDIR="/root"
FORMAT=$(date +%Y%m%d)-$(date +%H)

# Funktion zur Durchführung des Backups
perform_backup() {
  SOURCE_DIR="$1"
  shift
  EXCLUDE_OPTIONS=("$@")

  echo "Backup von $SOURCE_DIR erstellen..."
  rsync -a --delete "${EXCLUDE_OPTIONS[@]}" "$SOURCE_DIR" "$BACKUPDIR" > /dev/null
}

# Alte Archive löschen
echo "Lösche alte Archive..."
rclone delete --min-age 30d SFTP:ttt.mightful-noobs.de > /dev/null

# Backup von /home erstellen
HOME_EXCLUDES=(
  --exclude '/home/ttt/.local' 
  --exclude '/home/ttt/css' 
  --exclude '/home/ttt/serverfiles/bin' 
  --exclude '/home/ttt/serverfiles/sourceengine' 
  --exclude '/home/ttt/serverfiles/steamapps' 
  --exclude '/home/ttt/serverfiles/steam_cache' 
  --exclude '/home/ttt/serverfiles/garrysmod/*.vpk' 
  --exclude '/home/ttt/serverfiles/garrysmod/cache'
)

perform_backup "/home" "${HOME_EXCLUDES[@]}"

# Backup von /etc erstellen
ETC_EXCLUDES=()  # Hier ggf. die passenden Exclude-Optionen für /etc einfügen

perform_backup "/etc" "${ETC_EXCLUDES[@]}"

# Backup von /root erstellen
ROOT_EXCLUDES=(
  --exclude '/root/.gnupg' 
  --exclude '/root/backuputils/upload.tar.g*' 
  --exclude '/root/backup'
)

perform_backup "/root" "${ROOT_EXCLUDES[@]}"
# Backup von /var erstellen
VAR_EXCLUDES=(
  --exclude '/var/cache' 
  --exclude '/var/lock' 
  --exclude '/var/lib' 
  --exclude '/var/mail' 
  --exclude '/var/run' 
)

perform_backup "/var" "${VAR_EXCLUDES[@]}"

# Archiv packen
echo "Packen..."
cd "$BACKUPDIR" || exit
tar -zcvf "$HOMEDIR"/backuputils/upload.tar.gz ./* > /dev/null

# Verschlüsseln
echo "Verschlüsseln..."
cd "$HOMEDIR"/backuputils || exit
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty upload.tar.gz > /dev/null
rm upload.tar.gz

# Hochladen
echo "Hochladen..."
rclone copyto upload.tar.gz.gpg SFTP:ttt.mightful-noobs.de/"$FORMAT".tar.gz.gpg > /dev/null
rm upload.tar.gz.gpg
