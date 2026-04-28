#!/bin/bash

# ============================================================
# 🍺 Homebrew
# ============================================================

echo -e "${BLUE}🍺 Checking Homebrew...${NC}"

if command -v brew >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Homebrew already installed.${NC}"
else
    echo -e "${YELLOW}📥 Installing Homebrew...${NC}"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Configure path for the current shell session
    if [[ $(uname -m) == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    echo -e "${GREEN}✅ Homebrew installed and configured.${NC}"
fi
