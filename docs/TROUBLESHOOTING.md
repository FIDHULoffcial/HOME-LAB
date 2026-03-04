# 🔧 AndroidLab — Troubleshooting Guide

Common issues and their solutions.

---

## SSH Issues

### `sshd` fails to start

```bash
# 1. Check config for syntax errors
sshd -t

# 2. Check if port is in use
ss -tulnp | grep 8022

# 3. Kill existing instances and retry
pkill -f sshd; sleep 1; sshd

# 4. Verify host keys exist
ls $PREFIX/etc/ssh/ssh_host_*
# If empty, regenerate: ssh-keygen -A

# 5. Run in debug mode for detailed errors
sshd -d
```

### "Connection refused" from laptop

```bash
# Step 1: Is SSH actually running?
ps aux | grep sshd | grep -v grep

# Step 2: Correct IP?
myip   # Run on your phone

# Step 3: Test locally first
ssh -p 8022 localhost

# Step 4: Same Wi-Fi network?
# Check: Phone Settings → Wi-Fi → SSID
# Laptop should be on the same SSID

# Step 5: Ping test
ping YOUR_PHONE_IP   # From laptop
```

### "Permission denied" during login

```bash
# Reset password
passwd

# Fix key file permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys

# Debug the connection
sshd -d   # Run on phone, then try connecting
```

---

## Nginx Issues

### Nginx won't start

```bash
# ALWAYS run this first
nginx -t

# Common errors:
# "Address in use" → check what's on port 8080:
ss -tulnp | grep 8080

# "No such file" → check paths in nginx.conf
grep "root" $PREFIX/etc/nginx/nginx.conf

# Check error log for more details
cat ~/server/logs/nginx-error.log | tail -20
```

### 403 Forbidden

```bash
# Check the web root directory exists
ls ~/server/www/

# Check index.html exists
ls ~/server/www/index.html

# Verify nginx.conf root path
grep "root" $PREFIX/etc/nginx/nginx.conf
# Should be: /data/data/com.termux/files/home/server/www
```

### 502 Bad Gateway (proxy_pass)

```bash
# Backend service isn't running!

# For Python API (port 5000):
pgrep -f api.py || echo "Not running — start it:"
python ~/server/scripts/api.py &

# For Node.js app (port 3000):
pgrep node || echo "Not running — start it"
```

---

## MariaDB Issues

### MariaDB won't start

```bash
# Try starting manually to see errors
mysqld_safe -u $(whoami)

# Check if already running
pgrep mysqld

# Remove stale lock files
rm -f $PREFIX/var/lib/mysql/mysql.sock
rm -f $PREFIX/var/lib/mysql/*.pid

# Last resort: reinitialize (WARNING: deletes all data!)
# mysql_install_db --force
```

### "Access denied for user root"

```bash
# Start without authentication
mysqld_safe --skip-grant-tables -u $(whoami) &
sleep 3

# Reset password
mysql -u root << 'SQL'
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewPassword!';
FLUSH PRIVILEGES;
SQL

# Restart normally
pkill mysqld; sleep 2
mysqld_safe -u $(whoami) &
```

---

## Boot Script Issues

### Services don't start on reboot

```bash
# 1. Is Termux:Boot installed?
# Open F-Droid → search Termux:Boot → must be installed

# 2. Did you open Termux:Boot at least once?
# Open the app → close it → try again

# 3. Battery optimization disabled?
# Settings → Battery → Termux → "Unrestricted"
# Settings → Battery → Termux:Boot → "Unrestricted"

# 4. Script exists and is executable?
ls -la ~/.termux/boot/start-server.sh
chmod +x ~/.termux/boot/start-server.sh

# 5. Script runs manually?
bash ~/.termux/boot/start-server.sh
cat ~/server/logs/boot.log

# 6. Correct shebang?
head -1 ~/.termux/boot/start-server.sh
# Must be: #!/data/data/com.termux/files/usr/bin/bash
```

---

## Storage Issues

### "No space left on device"

```bash
# Check storage
df -h

# Find what's using space
du -sh ~/server/* | sort -rh | head -20
du -sh ~/.cache/ $PREFIX/var/cache/ 2>/dev/null

# Clean caches
pkg clean
pip cache purge 2>/dev/null
npm cache clean --force 2>/dev/null

# Remove old logs
find ~/server/logs -name "*.log" -mtime +30 -delete

# Remove old backups
find ~/server/backups -mtime +7 -delete
```

---

## Performance Issues

### Server is very slow

```bash
# Check CPU usage
htop

# Check RAM (if "available" < 100MB, you may need fewer services)
free -m

# Top memory consumers
ps aux --sort=-%mem | head -10

# Check phone temperature
cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null | \
  awk '{print $1/1000"°C"}'

# Reduce MariaDB memory usage
mysql -u root -p -e "SET GLOBAL innodb_buffer_pool_size = 32*1024*1024;"
```

---

## Phone-Specific Issues

### Samsung: Services killed in background

1. Settings → Battery → Background usage limits
2. Remove Termux from "Sleeping apps" and "Deep sleeping apps"
3. Lock Termux in Recent Apps (swipe it, tap the lock icon)

### Xiaomi/MIUI: Auto-start blocked

1. Settings → Apps → Manage apps → Termux → Autostart → Enable
2. Settings → Battery → App battery saver → Termux → No restrictions
3. Security app → Permissions → Autostart → Enable Termux

### Huawei/EMUI: App killed aggressively

1. Settings → Battery → App launch → Termux → Manual → Enable all toggles
2. Phone Manager → Power saving → Protected apps → Add Termux

---

## Quick Diagnostic Commands

```bash
# Full system check
server status          # Service overview
free -m                # Memory
df -h ~                # Disk
ss -tulnp              # Open ports
ps aux | head -20      # Top processes

# Network check
myip                   # Local IP
ping 8.8.8.8 -c 3     # Internet connectivity
curl -s ifconfig.me    # Public IP

# Log check
cat ~/server/logs/boot.log     # Last boot
cat ~/server/logs/watchdog.log # Watchdog activity
tail ~/server/logs/nginx-error.log  # Nginx errors
```
