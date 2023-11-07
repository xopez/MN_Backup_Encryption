#!/bin/bash

# Konstanten für Verzeichnisse und Dateinamen
BACKUPDIR="/root/backup"
HOMEDIR="/root"
FORMAT=$(date +%Y%m%d)-$(date +%H)

# Funktion zum Durchführen des Backups
perform_backup() {
  SOURCE_DIR="$1"
  shift
  EXCLUDE_OPTIONS=("$@")

  echo "Backup von $SOURCE_DIR erstellen..."
  rsync -a --delete "${EXCLUDE_OPTIONS[@]}" "$SOURCE_DIR" "$BACKUPDIR" > /dev/null
}

# Funktion zum Löschen alter Archive
delete_old_archives() {
  echo "Lösche alte Archive..."
  rclone delete --min-age 30d SFTP:ttt.mightful-noobs.de > /dev/null
}

# Backup-Optionen für verschiedene Verzeichnisse
HOME_EXCLUDES=(
  '/home/ttt/.local'
  '/home/ttt/css' 
  '/home/ttt/serverfiles/bin'
  '/home/ttt/serverfiles/sourceengine'
  '/home/ttt/serverfiles/steamapps'
  '/home/ttt/serverfiles/steam_cache'
  '/home/ttt/serverfiles/garrysmod/*.vpk'
  '/home/ttt/serverfiles/garrysmod/cache'
)

ETC_EXCLUDES=()  # Füge hier ggf. die passenden Exclude-Optionen für /etc ein

ROOT_EXCLUDES=(
  '/root/.gnupg'
  '/root/backuputils/upload.tar.g*'
  '/root/backup'
)

VAR_EXCLUDES=(
  '/var/cache'
  '/var/lock'
  '/var/lib'
  '/var/mail'
  '/var/run'
)

cd /

# Backup von verschiedenen Verzeichnissen durchführen
perform_backup "/home" "${HOME_EXCLUDES[@]}"
perform_backup "/etc" "${ETC_EXCLUDES[@]}"
perform_backup "/root" "${ROOT_EXCLUDES[@]}"
perform_backup "/var" "${VAR_EXCLUDES[@]}"

# Alte Archive löschen
delete_old_archives

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
