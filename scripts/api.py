#!/usr/bin/env python3
"""
AndroidLab — System Status REST API
Provides real-time server metrics via HTTP endpoints.

Endpoints:
  GET /           → API info
  GET /status     → Full system status (CPU, RAM, disk, services)
  GET /processes  → Top processes by CPU
  GET /services   → Service running status
  GET /disk       → Disk usage details
  GET /network    → Network info
"""

from flask import Flask, jsonify
import psutil
import subprocess
import datetime
import os
import socket
import re

app = Flask(__name__)


# ── Helpers ──────────────────────────────────────────────────

def check_service(proc_name):
    """Check if a process is running by name."""
    for p in psutil.process_iter(['name']):
        try:
            if p.info['name'] == proc_name:
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
    return False


def get_local_ip():
    """Get the device's local IP address."""
    try:
        result = subprocess.run(
            ['ip', 'route', 'get', '1.1.1.1'],
            capture_output=True, text=True, timeout=3
        )
        match = re.search(r'src (\S+)', result.stdout)
        return match.group(1) if match else 'unknown'
    except Exception:
        try:
            return socket.gethostbyname(socket.gethostname())
        except Exception:
            return 'unknown'


def get_uptime():
    """Get system uptime in seconds."""
    try:
        return int(datetime.datetime.now().timestamp() - psutil.boot_time())
    except Exception:
        return 0


def format_uptime(seconds):
    """Convert seconds to human-readable uptime."""
    days = seconds // 86400
    hours = (seconds % 86400) // 3600
    minutes = (seconds % 3600) // 60
    parts = []
    if days > 0:
        parts.append(f"{days}d")
    if hours > 0:
        parts.append(f"{hours}h")
    parts.append(f"{minutes}m")
    return " ".join(parts)


# ── Routes ─────────────────────────────────────────────────

@app.route('/')
def index():
    """API information endpoint."""
    return jsonify({
        "name": "AndroidLab API",
        "version": "1.0.0",
        "description": "System monitoring API for AndroidLab Home Server",
        "endpoints": [
            {"path": "/status",    "method": "GET", "description": "Full system status"},
            {"path": "/processes", "method": "GET", "description": "Top processes by CPU"},
            {"path": "/services",  "method": "GET", "description": "Service status"},
            {"path": "/disk",      "method": "GET", "description": "Disk usage"},
            {"path": "/network",   "method": "GET", "description": "Network info"},
        ],
        "github": "https://github.com/yourusername/androidlab"
    })


@app.route('/status')
def status():
    """Full system status endpoint."""
    mem = psutil.virtual_memory()
    disk = psutil.disk_usage(os.path.expanduser('~'))
    cpu_freq = psutil.cpu_freq()
    uptime_sec = get_uptime()

    return jsonify({
        "server": "AndroidLab Home Server",
        "timestamp": datetime.datetime.now().isoformat(),
        "uptime": {
            "seconds": uptime_sec,
            "human": format_uptime(uptime_sec)
        },
        "cpu": {
            "cores": psutil.cpu_count(logical=False),
            "threads": psutil.cpu_count(logical=True),
            "percent": psutil.cpu_percent(interval=1),
            "frequency_mhz": round(cpu_freq.current) if cpu_freq else None
        },
        "memory": {
            "total_mb": round(mem.total / 1024 / 1024),
            "used_mb": round(mem.used / 1024 / 1024),
            "free_mb": round(mem.available / 1024 / 1024),
            "percent": mem.percent
        },
        "disk": {
            "total_gb": round(disk.total / 1024**3, 2),
            "used_gb": round(disk.used / 1024**3, 2),
            "free_gb": round(disk.free / 1024**3, 2),
            "percent": disk.percent
        },
        "network": {
            "local_ip": get_local_ip(),
            "hostname": socket.gethostname()
        },
        "services": {
            "ssh":          check_service("sshd"),
            "nginx":        check_service("nginx"),
            "mariadb":      check_service("mysqld"),
            "filebrowser":  check_service("filebrowser"),
            "python_api":   True  # This service itself
        }
    })


@app.route('/processes')
def processes():
    """Top processes sorted by CPU usage."""
    procs = []
    for p in psutil.process_iter(['pid', 'name', 'cpu_percent', 'memory_percent', 'status']):
        try:
            info = p.info
            info['cpu_percent'] = p.cpu_percent(interval=0.1)
            procs.append(info)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass

    procs.sort(key=lambda x: x.get('cpu_percent', 0), reverse=True)
    return jsonify({
        "processes": procs[:25],
        "total": len(procs)
    })


@app.route('/services')
def services():
    """Check which services are running."""
    service_list = {
        "ssh":         {"running": check_service("sshd"),        "port": 8022, "description": "Remote terminal access"},
        "nginx":       {"running": check_service("nginx"),        "port": 8080, "description": "Web server & reverse proxy"},
        "mariadb":     {"running": check_service("mysqld"),       "port": 3306, "description": "MySQL-compatible database"},
        "filebrowser": {"running": check_service("filebrowser"),  "port": 8081, "description": "Web file manager"},
    }

    running_count = sum(1 for s in service_list.values() if s["running"])
    total_count = len(service_list)

    return jsonify({
        "services": service_list,
        "summary": f"{running_count}/{total_count} services running"
    })


@app.route('/disk')
def disk():
    """Disk usage details."""
    partitions = []
    for part in psutil.disk_partitions():
        try:
            usage = psutil.disk_usage(part.mountpoint)
            partitions.append({
                "device": part.device,
                "mountpoint": part.mountpoint,
                "fstype": part.fstype,
                "total_gb": round(usage.total / 1024**3, 2),
                "used_gb": round(usage.used / 1024**3, 2),
                "free_gb": round(usage.free / 1024**3, 2),
                "percent": usage.percent
            })
        except PermissionError:
            pass

    return jsonify({"partitions": partitions})


@app.route('/network')
def network():
    """Network statistics."""
    stats = psutil.net_io_counters()
    return jsonify({
        "local_ip": get_local_ip(),
        "hostname": socket.gethostname(),
        "io": {
            "bytes_sent": stats.bytes_sent,
            "bytes_recv": stats.bytes_recv,
            "packets_sent": stats.packets_sent,
            "packets_recv": stats.packets_recv,
            "bytes_sent_human": f"{stats.bytes_sent / 1024 / 1024:.1f} MB",
            "bytes_recv_human": f"{stats.bytes_recv / 1024 / 1024:.1f} MB"
        }
    })


# ── Main ───────────────────────────────────────────────────

if __name__ == '__main__':
    port = int(os.environ.get('API_PORT', 5000))
    print(f"")
    print(f"  AndroidLab System API")
    print(f"  ─────────────────────")
    print(f"  Status:  http://0.0.0.0:{port}/status")
    print(f"  Services: http://0.0.0.0:{port}/services")
    print(f"  Processes: http://0.0.0.0:{port}/processes")
    print(f"")
    app.run(host='0.0.0.0', port=port, debug=False, threaded=True)
