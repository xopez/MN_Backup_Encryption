#!/bin/bash

# Verzeichnisse und Dateinamen definieren
BACKUPDIR="/root/backup"
HOMEDIR="/root"
DATE="$(date +%Y%m%d)"
TIME="$(date +%H)"
RSYNC_OPTS=(-a --delete)

# Funktion zur Durchführung des Backups
perform_backup() {
  SOURCE_DIR="$1"
  EXCLUDE_OPTIONS=("${@:2}")

  echo "Backup von $SOURCE_DIR erstellen..."
  rsync "${RSYNC_OPTS[@]}" "${EXCLUDE_OPTIONS[@]/#/--exclude=}" "$SOURCE_DIR" "$BACKUPDIR"
}

# Funktion zum Löschen alter Archive
delete_old_archives() {
  echo "Lösche alte Archive auf $1"
  rclone delete --rmdirs --min-age 30d "$1:"
}

# Alte Archive löschen
delete_old_archives "SFTP-Falkenstein"
delete_old_archives "SFTP-Helsinki"

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
  '/root/backuputils/backup.tar.g*'
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
tar -zcf "$HOMEDIR"/backuputils/backup.tar.gz ./*

# Verschlüsseln
echo "Verschlüsseln..."
cd "$HOMEDIR"/backuputils || exit
gpg --passphrase-file encryption.txt -c --batch --yes --no-tty backup.tar.gz
rm backup.tar.gz

# Hochladen
upload_backup() {
  echo "Hochladen auf $1"
  rclone copyto "backup.tar.gz.gpg" "$1:$DATE/$DATE-$TIME-backup.tar.gz.gpg"
}

upload_backup "SFTP-Falkenstein"
upload_backup "SFTP-Helsinki"

rm backup.tar.gz.gpg
