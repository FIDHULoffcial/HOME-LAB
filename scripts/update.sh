#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#   AndroidLab — Package Update Script
#   Updates Termux packages, Python packages, and npm globals
#   Usage: bash update.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\n${BLUE}AndroidLab — System Update${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Termux packages
echo -e "\n${YELLOW}[1/3]${NC} Updating Termux packages..."
pkg update -y && pkg upgrade -y
echo -e "${GREEN}  ✓ Termux packages updated${NC}"

# Python packages
echo -e "\n${YELLOW}[2/3]${NC} Updating Python packages..."
if command -v pip > /dev/null; then
  pip install --upgrade pip setuptools wheel 2>/dev/null
  # Update all outdated packages
  pip list --outdated --format=freeze 2>/dev/null | \
    cut -d= -f1 | \
    xargs -n1 pip install --upgrade 2>/dev/null
  echo -e "${GREEN}  ✓ Python packages updated${NC}"
else
  echo -e "  → Python not installed, skipping"
fi

# npm global packages
echo -e "\n${YELLOW}[3/3]${NC} Updating npm global packages..."
if command -v npm > /dev/null; then
  npm update -g 2>/dev/null
  echo -e "${GREEN}  ✓ npm packages updated${NC}"
else
  echo -e "  → Node.js not installed, skipping"
fi

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}  Update complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
