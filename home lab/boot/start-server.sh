#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — Auto-Boot Server Startup Script
#   File: ~/.termux/boot/start-server.sh
#   Runs: Automatically on every phone reboot via Termux:Boot
#
#   Install: cp boot/start-server.sh ~/.termux/boot/
#            chmod +x ~/.termux/boot/start-server.sh
# ============================================================

# ── Setup ────────────────────────────────────────────────────
LOG="$HOME/server/logs/boot.log"
mkdir -p "$HOME/server/logs"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG"
}

log "======== SERVER BOOT STARTED ========"
log "Android: $(getprop ro.build.version.release 2>/dev/null || echo 'Unknown')"
log "Device:  $(getprop ro.product.model 2>/dev/null || echo 'Unknown')"

# ── Wait for Network ──────────────────────────────────────────
log "Waiting for network..."
WAIT=0
while ! ping -c 1 8.8.8.8 > /dev/null 2>&1; do
  sleep 2
  WAIT=$((WAIT + 2))
  if [ $WAIT -ge 60 ]; then
    log "WARNING: Network not available after 60s, continuing..."
    break
  fi
done
log "Network ready (waited ${WAIT}s)"

LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo 'unknown')
log "Local IP: $LOCAL_IP"

# ── 1. SSH Server ──────────────────────────────────────────────
log "Starting SSH server..."
pkill -x sshd 2>/dev/null
sleep 1
if sshd; then
  log "✓ SSH started on port 8022"
else
  log "✗ SSH failed to start!"
fi

# ── 2. Nginx Web Server ────────────────────────────────────────
log "Starting Nginx..."
pkill -x nginx 2>/dev/null
sleep 1
if nginx; then
  log "✓ Nginx started on port 8080"
else
  log "✗ Nginx failed! Check: nginx -t"
fi

# ── 3. MariaDB Database ────────────────────────────────────────
log "Starting MariaDB..."
pkill -x mysqld 2>/dev/null
sleep 2
mysqld_safe -u "$(whoami)" >> "$LOG" 2>&1 &
sleep 4
if pgrep -x mysqld > /dev/null; then
  log "✓ MariaDB started on port 3306"
else
  log "✗ MariaDB failed to start!"
fi

# ── 4. FileBrowser ─────────────────────────────────────────────
log "Starting FileBrowser..."
pkill -x filebrowser 2>/dev/null
sleep 1
if command -v filebrowser > /dev/null; then
  filebrowser \
    --database "$HOME/server/config/filebrowser.db" \
    >> "$LOG" 2>&1 &
  sleep 2
  if pgrep -x filebrowser > /dev/null; then
    log "✓ FileBrowser started on port 8081"
  else
    log "✗ FileBrowser failed to start!"
  fi
else
  log "→ FileBrowser not installed, skipping"
fi

# ── 5. Python System API ───────────────────────────────────────
if [ -f "$HOME/server/scripts/api.py" ]; then
  log "Starting Python API..."
  pkill -f "python.*api.py" 2>/dev/null
  sleep 1
  python "$HOME/server/scripts/api.py" >> "$LOG" 2>&1 &
  sleep 2
  if pgrep -f "api.py" > /dev/null; then
    log "✓ Python API started on port 5000"
  else
    log "→ Python API failed (non-critical)"
  fi
fi

# ── 6. PM2 Node.js Apps ────────────────────────────────────────
if command -v pm2 > /dev/null; then
  log "Restoring PM2 processes..."
  pm2 resurrect >> "$LOG" 2>&1 && log "✓ PM2 processes restored"
fi

# ── 7. Cloudflare Tunnel (uncomment to enable) ─────────────────
# if command -v cloudflared > /dev/null && [ -f "$HOME/.cloudflared/config.yml" ]; then
#   log "Starting Cloudflare tunnel..."
#   pkill cloudflared 2>/dev/null; sleep 1
#   cloudflared tunnel run >> "$LOG" 2>&1 &
#   sleep 3
#   pgrep cloudflared > /dev/null && log "✓ Cloudflare tunnel started" || log "✗ Tunnel failed"
# fi

# ── 8. rclone Cloud Mount (uncomment to enable) ────────────────
# if command -v rclone > /dev/null && [ -f "$HOME/.config/rclone/rclone.conf" ]; then
#   log "Mounting cloud storage..."
#   mkdir -p "$HOME/mnt/gdrive"
#   rclone mount gdrive: "$HOME/mnt/gdrive" --vfs-cache-mode writes --daemon >> "$LOG" 2>&1
#   log "✓ Cloud storage mounted"
# fi

# ── 9. Start Cron (uncomment to enable) ────────────────────────
# if command -v crond > /dev/null; then
#   crond && log "✓ Cron daemon started"
# fi

# ── Final Status ───────────────────────────────────────────────
log "======== BOOT COMPLETE ========"
log "SSH:         ssh -p 8022 $LOCAL_IP"
log "Web:         http://$LOCAL_IP:8080"
log "FileBrowser: http://$LOCAL_IP:8081"
log "API:         http://$LOCAL_IP:5000/status"
log "============================================"

# Optional: Send notification to phone
# termux-notification \
#   --title "🖥️ Server Started" \
#   --content "All services running at $LOCAL_IP" \
#   --priority high
