#!/bin/bash

# ============================================================
# 🛠️ Xcode Command Line Tools
# ============================================================

echo -e "${BLUE}🛠️ Checking Xcode Command Line Tools...${NC}"

if xcode-select -p >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Xcode Command Line Tools already installed.${NC}"
else
    echo -e "${YELLOW}📥 Installing Xcode Command Line Tools...${NC}"
    
    # Create the placeholder file that the softwareupdate tool expects
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    
    # Find the latest Command Line Tools for the current OS version
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
    
    if [ -n "$PROD" ]; then
        echo -e "${CYAN}📦 Found: $PROD${NC}"
        # --verbose and --agree-to-license if supported (though softwareupdate usually is non-interactive)
        softwareupdate -i "$PROD" --verbose
        echo -e "${GREEN}✅ Xcode Command Line Tools installed.${NC}"
    else
        echo -e "${RED}❌ Could not find Xcode Command Line Tools via softwareupdate.${NC}"
        echo -e "${YELLOW}💡 Please install manually using 'xcode-select --install' if needed.${NC}"
    fi
    
    # Clean up
    rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
fi
