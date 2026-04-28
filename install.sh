#!/bin/bash

# ============================================================
# 🎨 Color Definitions
# ============================================================
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export MAGENTA='\033[0;35m'
export CYAN='\033[0;36m'
export BOLD='\033[1m'
export NC='\033[0m'

# ============================================================
# ⚙️ Configuration
# ============================================================
REMOTE_REPO="https://ungikim.me"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ============================================================
# 🔐 Authentication Key Input Function
# ============================================================
read_auth_key() {
    local var_name=$1
    local description=$2
    local value

    echo -e "${CYAN}💡 ${description}:${NC}"
    echo -n "${var_name}: "
    read -rs value < /dev/tty

    if [ -z "$value" ]; then
        echo -e "\n${RED}❌ ${description} was not entered.${NC}"
        exit 1
    else
        export "$var_name=$value"
        echo -e "\n${GREEN}✅ ${description} has been entered.${NC}"
    fi
    echo ""
}

# ============================================================
# 🖥️ OS Type Detection
# ============================================================
OS_TYPE=$(uname -s)
case "$OS_TYPE" in
    Darwin) OS_DIR="darwin" ;;
    *)      OS_DIR="unknown" ;;
esac

# ============================================================
# 📦 Module Execution Function
# ============================================================
run_module() {
    local module_path=$1
    local module_name
    module_name=$(basename "$module_path")
    echo -e "${CYAN}📂 Running module: ${BOLD}${module_name}${NC}"

    if [ "$IS_LOCAL" = true ]; then
        bash "$SCRIPT_DIR/modules/$OS_DIR/$module_name"
    else
        curl -sL "$REMOTE_REPO/modules/$OS_DIR/$module_name" | bash
    fi
}

# ============================================================
# 🔍 Execution Mode Detection
# ============================================================
if [ -d "$SCRIPT_DIR/modules" ]; then
    IS_LOCAL=true
    echo -e "${BLUE}🏠 Local Mode${NC} - Using ${SCRIPT_DIR}/modules"
else
    IS_LOCAL=false
    echo -e "${BLUE}🌐 Remote Mode${NC} - Fetching from ${REMOTE_REPO}"
fi

# ============================================================
# 🚀 Installation Start
# ============================================================
echo ""
echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${MAGENTA}  🎯 Starting ungikim's dotfiles installation${NC}"
echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# ============================================================
# 🔐 Authentication Information Input
# ============================================================
echo -e "${YELLOW}🔐 Please enter authentication information required for setup.${NC}"
echo ""

# Enter authentication keys
read_auth_key "TS_AUTHKEY" "Tailscale Auth Key"

# ============================================================
# 🚀 Run OS-specific modules
# ============================================================
echo -e "${BLUE}🔍 Checking operating system...${NC}"

if [ "$OS_DIR" == "unknown" ]; then
    echo -e "${RED}❌ Unsupported operating system: ${BOLD}${OS_TYPE}${NC}"
    exit 1
fi

case "$OS_DIR" in
    darwin) echo -e "${GREEN}🍎 macOS environment detected${NC}" ;;
esac

echo -e "${CYAN}📥 Loading ${OS_DIR}-related modules...${NC}"
echo ""

case "$OS_DIR" in
  darwin)
    run_module "00-xcode.sh"
    run_module "10-homebrew.sh"
    run_module "20-tailscale.sh"
esac

# ============================================================
# 🧹 Cleanup
# ============================================================
unset TS_AUTHKEY

# ============================================================
# ✨ Completion
# ============================================================
echo ""
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}${GREEN}    🎉 All configurations completed!${NC}"
echo -e "${BOLD}${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
