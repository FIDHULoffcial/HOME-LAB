#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — Service Watchdog
#   Checks if critical services are running and restarts them
#   Schedule: Every 5 minutes via cron
#   Usage: bash watchdog.sh
# ============================================================

LOG="$HOME/server/logs/watchdog.log"

check_and_restart() {
  local name=$1
  local proc=$2
  local restart_cmd=$3

  if ! pgrep -x "$proc" > /dev/null 2>&1; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $name is DOWN — restarting..." >> "$LOG"
    eval "$restart_cmd" >> "$LOG" 2>&1
    sleep 2
    if pgrep -x "$proc" > /dev/null 2>&1; then
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] $name restarted successfully ✓" >> "$LOG"
    else
      echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $name FAILED to restart!" >> "$LOG"
    fi
  fi
}

# Check critical services
check_and_restart "SSH"    "sshd"   "sshd"
check_and_restart "Nginx"  "nginx"  "nginx"

# Optional: check MariaDB (uncomment if you want auto-restart)
# check_and_restart "MariaDB" "mysqld" "mysqld_safe -u $(whoami) &"

# Optional: check FileBrowser
# check_and_restart "FileBrowser" "filebrowser" "filebrowser --database $HOME/server/config/filebrowser.db &"

# Trim watchdog log if it gets too large (>1MB)
if [ -f "$LOG" ]; then
  LOG_SIZE=$(stat -c%s "$LOG" 2>/dev/null || echo 0)
  if [ "$LOG_SIZE" -gt 1048576 ]; then
    tail -100 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"
  fi
fi
