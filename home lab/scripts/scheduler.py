#!/usr/bin/env python3
"""
AndroidLab — Python Task Scheduler
Alternative to cron for scheduling recurring tasks.

Features:
  - Daily backups at 2 AM
  - Hourly disk usage check with warnings
  - Service watchdog every 5 minutes
  - Weekly package updates

Usage: python scheduler.py
"""

import schedule
import time
import subprocess
import datetime
import os
import shutil

LOG = os.path.expanduser("~/server/logs/scheduler.log")


def log(msg):
    """Write a timestamped message to the scheduler log."""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    entry = f"[{timestamp}] {msg}"
    with open(LOG, 'a') as f:
        f.write(entry + "\n")
    print(entry)


def run_backup():
    """Execute the backup script."""
    log("Running scheduled backup...")
    script = os.path.expanduser("~/server/scripts/backup.sh")
    if os.path.exists(script):
        result = subprocess.run(['bash', script], capture_output=True, text=True)
        log(f"Backup completed (exit code: {result.returncode})")
    else:
        log("WARNING: backup.sh not found!")


def check_disk():
    """Check disk usage and warn if above threshold."""
    home = os.path.expanduser('~')
    total, used, free = shutil.disk_usage(home)
    pct = used / total * 100
    free_gb = free / 1024**3

    if pct > 90:
        log(f"CRITICAL: Disk {pct:.1f}% full! Only {free_gb:.1f}GB free!")
    elif pct > 80:
        log(f"WARNING: Disk {pct:.1f}% full ({free_gb:.1f}GB free)")
    else:
        log(f"Disk check OK: {pct:.1f}% used ({free_gb:.1f}GB free)")


def watchdog():
    """Check if critical services are running."""
    services = [
        ('SSH', 'sshd'),
        ('Nginx', 'nginx'),
    ]
    for name, proc in services:
        result = subprocess.run(
            ['pgrep', '-x', proc],
            capture_output=True
        )
        if result.returncode != 0:
            log(f"WARNING: {name} ({proc}) is DOWN!")
            # Attempt restart
            try:
                subprocess.run([proc], capture_output=True, timeout=5)
                log(f"{name} restarted successfully")
            except Exception as e:
                log(f"ERROR: Failed to restart {name}: {e}")


def run_update():
    """Execute the update script."""
    log("Running scheduled package update...")
    script = os.path.expanduser("~/server/scripts/update.sh")
    if os.path.exists(script):
        result = subprocess.run(['bash', script], capture_output=True, text=True)
        log(f"Update completed (exit code: {result.returncode})")


# ── Schedule Tasks ──────────────────────────────────────────

schedule.every().day.at("02:00").do(run_backup)
schedule.every().hour.do(check_disk)
schedule.every(5).minutes.do(watchdog)
schedule.every().sunday.at("03:00").do(run_update)


# ── Main Loop ───────────────────────────────────────────────

if __name__ == '__main__':
    log("━━━ Scheduler started ━━━")
    log(f"Scheduled tasks: {len(schedule.get_jobs())}")
    for job in schedule.get_jobs():
        log(f"  → {job}")

    try:
        while True:
            schedule.run_pending()
            time.sleep(30)
    except KeyboardInterrupt:
        log("Scheduler stopped by user")
