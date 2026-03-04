# 🔒 AndroidLab — Security Hardening Guide

A comprehensive security guide for your AndroidLab home server.

---

## Security Checklist

Use this checklist to track your security hardening progress:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ANDROIDLAB SECURITY CHECKLIST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  SSH
  ☐ Password is strong (12+ chars, mixed case/numbers/symbols)
  ☐ SSH key authentication enabled and tested
  ☐ Password authentication disabled (after keys work)
  ☐ SSH port changed from default 8022
  ☐ MaxAuthTries set to 3

  Database
  ☐ Root password changed from default
  ☐ Admin user created with strong password
  ☐ Anonymous users removed
  ☐ Test database removed
  ☐ Remote root login disabled

  Services
  ☐ Only needed services are running
  ☐ Unused services removed from boot script
  ☐ FileBrowser has strong unique password
  ☐ Default credentials changed everywhere

  Network
  ☐ Phone Wi-Fi uses WPA2/WPA3
  ☐ Cloudflare Tunnel used (not port forwarding)
  ☐ No ports directly exposed to internet
  ☐ Server not on public/hotel Wi-Fi

  Maintenance
  ☐ Regular backups running (daily)
  ☐ Backup restoration tested
  ☐ Packages updated weekly
  ☐ Watchdog monitoring services
  ☐ Log files reviewed periodically

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 1. SSH Hardening

### Strong Passwords

```bash
# Set a strong password (12+ characters)
passwd

# Good: S3rv3r@Home2024!Secure
# Bad: password123, admin, 12345678
```

### SSH Key Authentication

Always prefer SSH keys over passwords:

```bash
# On your LAPTOP — generate keys
ssh-keygen -t ed25519 -C "androidlab" -f ~/.ssh/androidlab_key

# Copy public key to phone
ssh-copy-id -i ~/.ssh/androidlab_key.pub -p 8022 PHONE_IP
```

### Disable Password Auth (After Keys Work!)

```bash
# On your phone, edit SSH config:
nano $PREFIX/etc/ssh/sshd_config

# Change:
#   PasswordAuthentication yes
# To:
#   PasswordAuthentication no

# Restart SSH
pkill sshd && sshd
```

### Change SSH Port

```bash
# Edit sshd_config
nano $PREFIX/etc/ssh/sshd_config

# Change: Port 8022
# To:     Port 9022  (or any port above 1024)

# Restart and test with new port
pkill sshd && sshd
ssh -p 9022 PHONE_IP
```

---

## 2. Database Security

### Secure MariaDB

```bash
mysql -u root << 'SQL'
-- Change root password
ALTER USER 'root'@'localhost' IDENTIFIED BY 'YourStrongPassword!';

-- Remove anonymous users
DELETE FROM mysql.user WHERE User = '';

-- Remove remote root access
DELETE FROM mysql.user WHERE User = 'root'
  AND Host NOT IN ('localhost', '127.0.0.1', '::1');

-- Remove test database
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db = 'test' OR Db = 'test_%';

FLUSH PRIVILEGES;
SQL
```

### Create Limited Users

```bash
# Create app-specific users with limited permissions
mysql -u root -p << 'SQL'
CREATE USER 'webapp'@'localhost' IDENTIFIED BY 'AppUserPassword!';
GRANT SELECT, INSERT, UPDATE, DELETE ON myapp_db.* TO 'webapp'@'localhost';
-- No GRANT OPTION, no DROP, no ALTER
FLUSH PRIVILEGES;
SQL
```

---

## 3. File Permissions

```bash
# SSH directory permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
chmod 600 ~/.ssh/config

# Config files
chmod 600 $PREFIX/etc/ssh/sshd_config
chmod 600 ~/server/config/filebrowser.db

# Scripts should be executable but not writable by others
chmod 755 ~/server/scripts/*.sh
chmod 755 ~/.termux/boot/start-server.sh
```

---

## 4. Network Security

### Use Cloudflare Tunnel (Recommended)

Never expose ports directly to the internet. Use Cloudflare Tunnel instead:

```bash
# Install cloudflared
wget -O $PREFIX/bin/cloudflared \
  "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-arm64"
chmod +x $PREFIX/bin/cloudflared

# Create a tunnel (free Cloudflare account required)
cloudflared tunnel login
cloudflared tunnel create androidlab
```

### Check Open Ports

```bash
# See what's listening
ss -tulnp

# Only these should be running (on local network only):
# 8022 — SSH
# 8080 — Nginx
# 8081 — FileBrowser
# 5000 — API
# 3306 — MariaDB (localhost only!)
```

---

## 5. Automated Backups

Run daily backups to prevent data loss:

```bash
# Install the backup script
cp scripts/backup.sh ~/server/scripts/backup.sh
chmod +x ~/server/scripts/backup.sh

# Schedule daily backup at 2 AM
crontab -e
# Add: 0 2 * * * bash ~/server/scripts/backup.sh

# Sync backups to cloud (if rclone configured)
# rclone sync ~/server/backups gdrive:AndroidLabBackups/
```

### Test Backup Restoration

```bash
# Periodically test that backups actually work:
mkdir /tmp/restore-test
tar -xzf ~/server/backups/config-$(date +%Y-%m-%d).tar.gz -C /tmp/restore-test
ls /tmp/restore-test  # Verify files are there
rm -rf /tmp/restore-test
```

---

## 6. Log Monitoring

```bash
# Check SSH login attempts
cat ~/server/logs/boot.log | grep -i "auth\|fail\|denied"

# Monitor Nginx access
tail -f ~/server/logs/nginx-access.log

# Check for errors
tail -f ~/server/logs/nginx-error.log

# Watch the watchdog log
cat ~/server/logs/watchdog.log
```

---

## 7. Keep Everything Updated

```bash
# Run weekly (or schedule with cron):
server update

# This updates:
# - Termux packages
# - Python packages
# - npm global packages
```

---

## Emergency Procedures

### If You Get Locked Out of SSH

1. Open Termux directly on the phone
2. Reset password: `passwd`
3. Re-enable password auth if needed:
   ```bash
   sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' $PREFIX/etc/ssh/sshd_config
   pkill sshd && sshd
   ```

### If Database is Compromised

```bash
# Stop MariaDB
pkill mysqld

# Start without authentication
mysqld_safe --skip-grant-tables -u $(whoami) &
sleep 3

# Reset all passwords
mysql -u root << 'SQL'
FLUSH PRIVILEGES;
ALTER USER 'root'@'localhost' IDENTIFIED BY 'NewStrongPassword!';
DROP USER IF EXISTS 'suspicious_user'@'%';
FLUSH PRIVILEGES;
SQL

# Restart normally
pkill mysqld && sleep 2
mysqld_safe -u $(whoami) &
```
