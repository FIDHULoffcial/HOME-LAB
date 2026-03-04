#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — Automated Backup Script
#   Backs up configs, web files, databases, and scripts
#   Schedule: Daily at 2 AM via cron
#   Usage: bash backup.sh
# ============================================================

BACKUP_DIR="$HOME/server/backups"
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG="$HOME/server/logs/backup.log"

mkdir -p "$BACKUP_DIR"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"; }

log "===== BACKUP STARTED: $TIMESTAMP ====="

# ── Backup Server Config Files ────────────────────────────────
log "Backing up config files..."
tar -czf "$BACKUP_DIR/config-$DATE.tar.gz" \
  ~/server/config/ \
  $PREFIX/etc/nginx/nginx.conf \
  $PREFIX/etc/ssh/sshd_config \
  ~/.bashrc \
  ~/.termux/boot/ \
  2>> "$LOG"
log "Config backup: $(du -sh "$BACKUP_DIR/config-$DATE.tar.gz" 2>/dev/null | cut -f1)"

# ── Backup Web Root ───────────────────────────────────────────
log "Backing up web files..."
tar -czf "$BACKUP_DIR/www-$DATE.tar.gz" \
  ~/server/www/ \
  2>> "$LOG"
log "Web backup: $(du -sh "$BACKUP_DIR/www-$DATE.tar.gz" 2>/dev/null | cut -f1)"

# ── Backup Scripts ────────────────────────────────────────────
log "Backing up scripts..."
tar -czf "$BACKUP_DIR/scripts-$DATE.tar.gz" \
  ~/server/scripts/ \
  2>> "$LOG"
log "Scripts backup: $(du -sh "$BACKUP_DIR/scripts-$DATE.tar.gz" 2>/dev/null | cut -f1)"

# ── Backup MariaDB Databases ─────────────────────────────────
if pgrep -x mysqld > /dev/null; then
  log "Backing up MariaDB databases..."
  mysqldump -u root --all-databases 2>> "$LOG" | \
    gzip > "$BACKUP_DIR/databases-$DATE.sql.gz"
  log "Database backup: $(du -sh "$BACKUP_DIR/databases-$DATE.sql.gz" 2>/dev/null | cut -f1)"
else
  log "MariaDB not running, skipping database backup"
fi

# ── Backup SQLite Databases ───────────────────────────────────
if ls ~/server/databases/*.db 2>/dev/null | grep -q .; then
  log "Backing up SQLite databases..."
  tar -czf "$BACKUP_DIR/sqlite-$DATE.tar.gz" ~/server/databases/ 2>> "$LOG"
  log "SQLite backup complete"
fi

# ── Sync Backups to Cloud (if rclone configured) ──────────────
# Uncomment the following lines if you have rclone configured:
# if command -v rclone > /dev/null && rclone listremotes 2>/dev/null | grep -q .; then
#   log "Syncing backups to cloud..."
#   rclone sync "$BACKUP_DIR" gdrive:AndroidLabBackups/ >> "$LOG" 2>&1
#   log "Cloud sync complete"
# fi

# ── Cleanup Old Backups (keep last 7 days) ────────────────────
log "Removing backups older than 7 days..."
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null
find "$BACKUP_DIR" -name "*.sql.gz" -mtime +7 -delete 2>/dev/null
find "$BACKUP_DIR" -name "*.sql" -mtime +7 -delete 2>/dev/null

# ── Summary ───────────────────────────────────────────────────
TOTAL_SIZE=$(du -sh "$BACKUP_DIR" 2>/dev/null | cut -f1)
FILE_COUNT=$(find "$BACKUP_DIR" -type f | wc -l)
log "Backup storage: $TOTAL_SIZE ($FILE_COUNT files)"
log "===== BACKUP COMPLETE ====="
