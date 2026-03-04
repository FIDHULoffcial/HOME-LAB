#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — Server Control Script
#   Usage: server [start|stop|restart|status|logs|update]
# ============================================================

LOG="$HOME/server/logs/server.log"
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG"; }
ok()  { echo -e "${GREEN}  ✓ $1${NC}"; }
err() { echo -e "${RED}  ✗ $1${NC}"; }
inf() { echo -e "${BLUE}  → $1${NC}"; }

start_all() {
  echo -e "\n${CYAN}╔══════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║   AndroidLab — Starting Services     ║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${NC}"
  echo ""

  # SSH
  pkill -x sshd 2>/dev/null; sleep 1
  sshd > /dev/null 2>&1 && ok "SSH Server (port 8022)" || err "SSH failed"

  # Nginx
  pkill -x nginx 2>/dev/null; sleep 1
  nginx > /dev/null 2>&1 && ok "Nginx Web Server (port 8080)" || err "Nginx failed — run: nginx -t"

  # MariaDB
  pkill -x mysqld 2>/dev/null; sleep 1
  mysqld_safe -u "$(whoami)" >> "$LOG" 2>&1 &
  sleep 4
  pgrep -x mysqld > /dev/null && ok "MariaDB (port 3306)" || err "MariaDB failed"

  # FileBrowser
  pkill -x filebrowser 2>/dev/null; sleep 1
  if command -v filebrowser > /dev/null; then
    filebrowser --database "$HOME/server/config/filebrowser.db" >> "$LOG" 2>&1 &
    sleep 2
    pgrep -x filebrowser > /dev/null && ok "FileBrowser (port 8081)" || err "FileBrowser failed"
  else
    inf "FileBrowser not installed"
  fi

  # Python API
  if [ -f "$HOME/server/scripts/api.py" ]; then
    pkill -f "api.py" 2>/dev/null; sleep 1
    python "$HOME/server/scripts/api.py" >> "$LOG" 2>&1 &
    sleep 2
    pgrep -f "api.py" > /dev/null && ok "Python API (port 5000)" || err "Python API failed"
  fi

  echo ""
  LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo 'N/A')
  echo -e "${GREEN}  Server IP: $LOCAL_IP${NC}"
  echo ""
}

stop_all() {
  echo -e "\n${YELLOW}Stopping all services...${NC}"
  echo ""
  pkill -x sshd 2>/dev/null       && ok "SSH stopped"         || inf "SSH was not running"
  pkill -x nginx 2>/dev/null      && ok "Nginx stopped"       || inf "Nginx was not running"
  pkill -x mysqld 2>/dev/null     && ok "MariaDB stopped"     || inf "MariaDB was not running"
  pkill -x filebrowser 2>/dev/null && ok "FileBrowser stopped" || inf "FileBrowser was not running"
  pkill -f "api.py" 2>/dev/null   && ok "Python API stopped"  || inf "API was not running"
  echo ""
}

status_all() {
  LOCAL_IP=$(ip route get 1.1.1.1 2>/dev/null | grep -oP 'src \K\S+' || echo 'Not connected')
  RAM_USED=$(free -m 2>/dev/null | awk '/Mem:/{print $3}' || echo "?")
  RAM_TOTAL=$(free -m 2>/dev/null | awk '/Mem:/{print $2}' || echo "?")
  RAM_FREE=$(free -m 2>/dev/null | awk '/Mem:/{print $7}' || echo "?")
  DISK_FREE=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $4}' || echo "?")
  DISK_USED=$(df -h "$HOME" 2>/dev/null | awk 'NR==2{print $5}' || echo "?")

  echo ""
  echo -e "${CYAN}╔═══════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║       📱 AndroidLab — Server Status       ║${NC}"
  echo -e "${CYAN}╠═══════════════════════════════════════════╣${NC}"

  check_svc() {
    local label=$1 proc=$2 port=$3
    if pgrep -x "$proc" > /dev/null 2>&1; then
      printf "${CYAN}║${NC}  ${GREEN}●${NC} %-18s ${GREEN}RUNNING${NC}   :%-5s ${CYAN}║${NC}\n" "$label" "$port"
    else
      printf "${CYAN}║${NC}  ${RED}○${NC} %-18s ${RED}STOPPED${NC}   :%-5s ${CYAN}║${NC}\n" "$label" "$port"
    fi
  }

  check_svc "SSH"           "sshd"          "8022"
  check_svc "Nginx"         "nginx"         "8080"
  check_svc "MariaDB"       "mysqld"        "3306"
  check_svc "FileBrowser"   "filebrowser"   "8081"

  # Check Python API separately (not a standalone process name)
  if pgrep -f "api.py" > /dev/null 2>&1; then
    printf "${CYAN}║${NC}  ${GREEN}●${NC} %-18s ${GREEN}RUNNING${NC}   :%-5s ${CYAN}║${NC}\n" "Python API" "5000"
  else
    printf "${CYAN}║${NC}  ${RED}○${NC} %-18s ${RED}STOPPED${NC}   :%-5s ${CYAN}║${NC}\n" "Python API" "5000"
  fi

  echo -e "${CYAN}╠═══════════════════════════════════════════╣${NC}"
  printf "${CYAN}║${NC}  IP:   %-36s${CYAN}║${NC}\n" "$LOCAL_IP"
  printf "${CYAN}║${NC}  RAM:  %s/%sMB (Free: %sMB)%-*s${CYAN}║${NC}\n" "$RAM_USED" "$RAM_TOTAL" "$RAM_FREE" $((18 - ${#RAM_USED} - ${#RAM_TOTAL} - ${#RAM_FREE})) ""
  printf "${CYAN}║${NC}  Disk: %s free (%s used)%-*s${CYAN}║${NC}\n" "$DISK_FREE" "$DISK_USED" $((22 - ${#DISK_FREE} - ${#DISK_USED})) ""
  echo -e "${CYAN}╚═══════════════════════════════════════════╝${NC}"
  echo ""
}

show_help() {
  echo ""
  echo -e "${CYAN}AndroidLab Server Control${NC}"
  echo ""
  echo "Usage: server [command]"
  echo ""
  echo "Commands:"
  echo -e "  ${GREEN}start${NC}    — Start all services"
  echo -e "  ${GREEN}stop${NC}     — Stop all services"
  echo -e "  ${GREEN}restart${NC}  — Restart all services"
  echo -e "  ${GREEN}status${NC}   — Show service status"
  echo -e "  ${GREEN}logs${NC}     — Follow server log"
  echo -e "  ${GREEN}update${NC}   — Update all packages"
  echo -e "  ${GREEN}boot${NC}     — Run boot script manually"
  echo ""
}

case "${1}" in
  start)   start_all ;;
  stop)    stop_all ;;
  restart) stop_all; sleep 2; start_all ;;
  status)  status_all ;;
  logs)    tail -f "$LOG" ;;
  update)  pkg update -y && pkg upgrade -y && pip install --upgrade pip 2>/dev/null ;;
  boot)    bash ~/.termux/boot/start-server.sh ;;
  *)       show_help ;;
esac
