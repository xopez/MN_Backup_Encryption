#!/bin/bash

# === Konfiguration ===
BACKUPDIR="/root/backup"
HOMEDIR="/root"
DATE="$(date +%Y%m%d)"
TIME="$(date +%H)"
ARCHIVE_NAME="backup.tar.gz"
ENCRYPTED_NAME="$ARCHIVE_NAME.gpg"
RSYNC_OPTS=(-a --delete)
REMOTE_TARGETS=("SFTP-Falkenstein" "SFTP-Helsinki")
LOGFILE="/var/log/backup_script.log"
BACKUP_GPG_RECIPIENT="xxxx@xxxxx.xx"

# === Logging-Funktion ===
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# === Alte Archive löschen ===
delete_old_archives() {
    for target in "${REMOTE_TARGETS[@]}"; do
        log "Lösche alte Dateien auf $target (ignoriere .zfs)"
        rclone delete --min-age 8d --exclude ".zfs/**" "$target:" || log "Fehler beim Löschen auf $target"

        log "Lösche leere Ordner auf $target (ignoriere .zfs)"
        rclone rmdirs "$target:" --leave-root --exclude ".zfs/**" || log "Fehler beim Ordnerlöschen auf $target"
    done
}

# === Backup-Funktion ===
perform_backup() {
    local source="$1"
    shift
    local excludes=("$@")

    log "Erstelle Backup von $source"
    rsync "${RSYNC_OPTS[@]}" "${excludes[@]/#/--exclude=}" "$source" "$BACKUPDIR" || log "Fehler beim Backup von $source"
}

# === Backup durchführen ===
delete_old_archives

cd / || {
    log "Fehler beim Wechsel ins Root-Verzeichnis"
    exit 1
}

perform_backup "/home" \
    '/home/ttt/.local' \
    '/home/ttt/serverfiles/bin' \
    '/home/ttt/serverfiles/sourceengine' \
    '/home/ttt/serverfiles/steamapps' \
    '/home/ttt/serverfiles/steam_cache' \
    '/home/ttt/serverfiles/garrysmod/*.vpk' \
    '/home/ttt/serverfiles/garrysmod/cache'

perform_backup "/etc"

perform_backup "/root" \
    '/root/.gnupg' \
    '/root/backuputils/backup.tar.g*' \
    '/root/backup'

perform_backup "/var" \
    '/var/cache' \
    '/var/lock' \
    '/var/lib' \
    '/var/mail' \
    '/var/run'

# === Archiv packen ===
log "Packe Archiv..."
cd "$BACKUPDIR" || {
    log "Fehler beim Wechsel ins Backup-Verzeichnis"
    exit 1
}
tar -zcf "$HOMEDIR/backuputils/$ARCHIVE_NAME" ./* || log "Fehler beim Packen des Archivs"

# === Verschlüsseln ===
log "Verschlüssle Archiv..."
cd "$HOMEDIR/backuputils" || {
    log "Fehler beim Wechsel ins backuputils-Verzeichnis"
    exit 1
}
gpg -e -r "$BACKUP_GPG_RECIPIENT" --batch --yes --no-tty "$ARCHIVE_NAME" || log "Fehler beim Verschlüsseln"
rm "$ARCHIVE_NAME"

# === Hochladen ===
upload_backup() {
    for target in "${REMOTE_TARGETS[@]}"; do
        log "Lade Backup auf $target hoch"
        rclone copyto "$ENCRYPTED_NAME" "$target:$DATE/${DATE}-${TIME}-$ENCRYPTED_NAME" || log "Fehler beim Hochladen auf $target"
    done
}

upload_backup

# === Aufräumen ===
rm "$ENCRYPTED_NAME"
log "Backup abgeschlossen."
