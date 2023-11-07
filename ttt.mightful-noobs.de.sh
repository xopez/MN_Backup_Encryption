#!/bin/bash

# Verzeichnisse und Dateinamen definieren
BACKUPDIR="/root/backup"
HOMEDIR="/root"
FORMAT=$(date +%Y%m%d)-$(date +%H)
RSYNC_OPTS=(-a --delete)

# Funktion zur Durchführung des Backups
perform_backup() {
  SOURCE_DIR="$1"
  EXCLUDE_OPTIONS=("${@:2}")

  echo "Backup von $SOURCE_DIR erstellen..."
  rsync "${RSYNC_OPTS[@]}" "${EXCLUDE_OPTIONS[@]/#/--exclude=}" "$SOURCE_DIR" "$BACKUPDIR" > /dev/null
}

# Alte Archive löschen
echo "Lösche alte Archive..."
rclone delete --min-age 30d SFTP:ttt.mightful-noobs.de > /dev/null

# Wechseln zum Stammverzeichnis
cd / || exit

# Backup von /home erstellen
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

perform_backup "/home" "${HOME_EXCLUDES[@]}"

# Backup von /etc erstellen
ETC_EXCLUDES=()  # Hier ggf. die passenden Exclude-Optionen für /etc einfügen

perform_backup "/etc" "${ETC_EXCLUDES[@]}"

# Backup von /root erstellen
ROOT_EXCLUDES=(
  '/root/.gnupg'
  '/root/backuputils/upload.tar.g*'
  '/root/backup'
)

perform_backup "/root" "${ROOT_EXCLUDES[@]}"

# Backup von /var erstellen
VAR_EXCLUDES=(
  '/var/cache'
  '/var/lock'
  '/var/lib'
  '/var/mail'
  '/var/run'
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
