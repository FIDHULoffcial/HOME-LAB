#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — Live Terminal Dashboard
#   Shows real-time server status in the terminal
#   Usage: dashboard (or: bash dashboard.sh)
# ============================================================

while true; do
  clear
  LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo 'N/A')
  RAM_USED=$(free -m 2>/dev/null | awk '/Mem:/{print $3}' || echo '?')
  RAM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/{print $2}' || echo '?')
  RAM_PCT=$(free -m 2>/dev/null | awk '/Mem:/{printf "%.0f", $3/$2*100}' || echo '?')
  DISK_USED=$(df -h ~ 2>/dev/null | awk 'NR==2{print $3}' || echo '?')
  DISK_TOTAL=$(df -h ~ 2>/dev/null | awk 'NR==2{print $2}' || echo '?')
  DISK_PCT=$(df -h ~ 2>/dev/null | awk 'NR==2{print $5}' || echo '?')
  CPU_CORES=$(nproc 2>/dev/null || echo '?')
  UPTIME=$(uptime -p 2>/dev/null || uptime | awk '{print $3,$4}')
  NOW=$(date '+%Y-%m-%d %H:%M:%S')

  echo "╔══════════════════════════════════════════════════════════╗"
  echo "║            📱 AndroidLab — Server Dashboard              ║"
  echo "╠══════════════════════════════════════════════════════════╣"
  printf "║  Time    : %-46s║\n" "$NOW"
  printf "║  IP      : %-46s║\n" "$LOCAL_IP"
  printf "║  Uptime  : %-46s║\n" "$UPTIME"
  echo "╠══════════════════════════════════════════════════════════╣"
  printf "║  RAM     : %s/%sMB (%s%%)%-*s║\n" "$RAM_USED" "$RAM_TOTAL" "$RAM_PCT" $((33 - ${#RAM_USED} - ${#RAM_TOTAL} - ${#RAM_PCT})) ""
  printf "║  Disk    : %s/%s (%s)%-*s║\n" "$DISK_USED" "$DISK_TOTAL" "$DISK_PCT" $((37 - ${#DISK_USED} - ${#DISK_TOTAL} - ${#DISK_PCT})) ""
  printf "║  CPUs    : %-46s║\n" "$CPU_CORES cores"
  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║  Services:                                               ║"

  print_svc() {
    local name=$1 proc=$2 port=$3
    if pgrep -x "$proc" > /dev/null 2>&1; then
      printf "║    ● %-16s RUNNING   :%-5s                  ║\n" "$name" "$port"
    else
      printf "║    ○ %-16s STOPPED   :%-5s                  ║\n" "$name" "$port"
    fi
  }

  print_svc "SSH"          "sshd"        "8022"
  print_svc "Nginx"        "nginx"       "8080"
  print_svc "MariaDB"      "mysqld"      "3306"
  print_svc "FileBrowser"  "filebrowser" "8081"

  echo "╠══════════════════════════════════════════════════════════╣"
  echo "║  Top Processes (by CPU):                                 ║"
  ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=6 {
    printf "║    %-14s CPU: %-6s MEM: %-6s              ║\n", substr($11,1,14), $3"%", $4"%"
  }' 2>/dev/null || echo "║    (process info unavailable)                             ║"
  echo "╚══════════════════════════════════════════════════════════╝"
  echo "  Press Ctrl+C to exit  •  Refreshes every 5 seconds"

  sleep 5
done
