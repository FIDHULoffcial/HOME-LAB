#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — One-Command Setup Script
#   Installs and configures the complete server environment
#   
#   Usage: bash setup.sh
#   Or:    bash <(curl -fsSL https://raw.githubusercontent.com/yourusername/androidlab/main/scripts/setup.sh)
# ============================================================

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
err()  { echo -e "${RED}[✗]${NC} $1"; }
info() { echo -e "${BLUE}[→]${NC} $1"; }
step() { echo -e "\n${CYAN}━━━ $1 ━━━${NC}"; }

echo ""
echo -e "${CYAN}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║   📱  AndroidLab — Auto Setup Script     ║"
echo "  ║   Transform your phone into a server     ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ── Phase 1: Update System ──────────────────────────────────
step "Phase 1: Updating System Packages"

info "Updating package manager..."
pkg update -y && pkg upgrade -y
log "System packages updated"

# ── Phase 2: Install Core Tools ─────────────────────────────
step "Phase 2: Installing Core Tools"

info "Installing essential packages..."
pkg install -y \
  curl wget git vim nano htop tree \
  zip unzip tar grep sed gawk \
  coreutils findutils diffutils \
  procps net-tools iproute2 nmap \
  tmux screen proot proot-distro \
  openssh openssl ca-certificates \
  termux-tools termux-api 2>/dev/null

log "Core tools installed"

# ── Phase 3: Create Directory Structure ──────────────────────
step "Phase 3: Creating Directory Structure"

mkdir -p ~/server/{www,scripts,logs,backups,config,databases,uploads,ssl,cron}
mkdir -p ~/.ssh
mkdir -p ~/.termux/boot
mkdir -p ~/mnt/{gdrive,dropbox,s3}
chmod 700 ~/.ssh

log "Directory structure created"

# ── Phase 4: Install Developer Tools ────────────────────────
step "Phase 4: Installing Developer Tools"

# Python
info "Installing Python 3..."
pkg install -y python python-pip 2>/dev/null
pip install --upgrade pip setuptools wheel 2>/dev/null
pip install flask psutil requests pyyaml schedule 2>/dev/null
log "Python 3 installed"

# Node.js
info "Installing Node.js..."
pkg install -y nodejs 2>/dev/null
npm install -g pm2 nodemon http-server 2>/dev/null
log "Node.js installed"

# ── Phase 5: Install Nginx ──────────────────────────────────
step "Phase 5: Installing Nginx"

pkg install -y nginx 2>/dev/null
log "Nginx installed"

# ── Phase 6: Install MariaDB ────────────────────────────────
step "Phase 6: Installing MariaDB & SQLite"

pkg install -y mariadb sqlite 2>/dev/null
log "MariaDB and SQLite installed"

# ── Phase 7: Configure SSH ──────────────────────────────────
step "Phase 7: Configuring SSH Server"

# Generate host keys
ssh-keygen -A 2>/dev/null
log "SSH host keys generated"

# Install SSH config
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$REPO_ROOT/config/sshd_config" ]; then
  cp "$REPO_ROOT/config/sshd_config" "$PREFIX/etc/ssh/sshd_config"
  log "SSH config installed from repo"
fi

if [ -f "$REPO_ROOT/config/ssh-banner.txt" ]; then
  cp "$REPO_ROOT/config/ssh-banner.txt" ~/server/config/ssh-banner.txt
  log "SSH banner installed"
fi

# ── Phase 8: Install Nginx Config ───────────────────────────
step "Phase 8: Configuring Nginx"

if [ -f "$REPO_ROOT/config/nginx.conf" ]; then
  cp "$REPO_ROOT/config/nginx.conf" "$PREFIX/etc/nginx/nginx.conf"
  log "Nginx config installed from repo"
fi

if [ -f "$REPO_ROOT/www/index.html" ]; then
  cp "$REPO_ROOT/www/index.html" ~/server/www/index.html
  log "Landing page installed"
fi

# ── Phase 9: Install Scripts ────────────────────────────────
step "Phase 9: Installing Server Scripts"

for script in server-ctl.sh api.py dashboard.sh backup.sh update.sh watchdog.sh scheduler.py; do
  if [ -f "$REPO_ROOT/scripts/$script" ]; then
    cp "$REPO_ROOT/scripts/$script" ~/server/scripts/
    chmod +x ~/server/scripts/"$script"
    log "Installed $script"
  fi
done

# ── Phase 10: Install Boot Script ───────────────────────────
step "Phase 10: Configuring Auto-Boot"

if [ -f "$REPO_ROOT/boot/start-server.sh" ]; then
  cp "$REPO_ROOT/boot/start-server.sh" ~/.termux/boot/start-server.sh
  chmod +x ~/.termux/boot/start-server.sh
  log "Boot script installed"
fi

# ── Phase 11: Configure Shell ───────────────────────────────
step "Phase 11: Configuring Shell Environment"

if [ -f "$REPO_ROOT/config/.bashrc-additions" ]; then
  if ! grep -q "AndroidLab Home Server" ~/.bashrc 2>/dev/null; then
    cat "$REPO_ROOT/config/.bashrc-additions" >> ~/.bashrc
    log "Shell configuration added to .bashrc"
  else
    warn "Shell config already present in .bashrc"
  fi
fi

# ── Phase 12: Initialize MariaDB ────────────────────────────
step "Phase 12: Initializing Database"

if ! [ -d "$PREFIX/var/lib/mysql/mysql" ]; then
  mysql_install_db 2>/dev/null
  log "MariaDB initialized"
else
  warn "MariaDB already initialized"
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${GREEN}  ╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}  ║    ✅ AndroidLab Setup Complete!         ║${NC}"
echo -e "${GREEN}  ╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${BLUE}Next steps:${NC}"
echo ""
echo -e "  1. Set your SSH password:"
echo -e "     ${YELLOW}passwd${NC}"
echo ""
echo -e "  2. Start all services:"
echo -e "     ${YELLOW}server start${NC}"
echo ""
echo -e "  3. Check service status:"
echo -e "     ${YELLOW}server status${NC}"
echo ""
echo -e "  4. Find your phone's IP:"
echo -e "     ${YELLOW}ip route get 1.1.1.1 | grep -oP 'src \K\S+'${NC}"
echo ""
echo -e "  5. Connect from your laptop:"
echo -e "     ${YELLOW}ssh -p 8022 <your-phone-ip>${NC}"
echo ""
echo -e "  ${BLUE}For the full guide, visit:${NC}"
echo -e "  ${CYAN}https://github.com/yourusername/androidlab${NC}"
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Reload shell
source ~/.bashrc 2>/dev/null || true
