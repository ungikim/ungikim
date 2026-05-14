#!/bin/bash

# ============================================================
# 🔐 Tailscale + Tailscale SSH
# ============================================================

echo -e "${BLUE}🔐 Checking Tailscale...${NC}"

TAILSCALE_ERROR_LOG=$(mktemp -t tailscale-bootstrap.XXXXXX)

cleanup() {
    rm -f "$TAILSCALE_ERROR_LOG"
}

trap cleanup EXIT

print_manual_steps() {
    echo -e "${YELLOW}💡 Manual next steps:${NC}"
    echo "  1. Start or restart the Tailscale service with: sudo \"$BREW_BIN\" services start tailscale"
    echo "  2. Authenticate and enable Tailscale SSH with: sudo \"$TAILSCALE_BIN\" up --auth-key=\"\$TS_AUTHKEY\" --advertise-tags=tag:server --ssh --timeout=30s"
    echo "  3. Confirm the node is online with: sudo \"$TAILSCALE_BIN\" status"
    echo "  4. Ensure your tailnet SSH policy allows access to this node"
}

BREW_BIN=$(command -v brew || true)

if [ -z "$BREW_BIN" ]; then
    echo -e "${RED}❌ Homebrew is required before installing Tailscale.${NC}"
    exit 1
fi

if command -v tailscale >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Tailscale already installed.${NC}"
else
    echo -e "${YELLOW}📥 Installing Tailscale...${NC}"
    if "$BREW_BIN" install tailscale; then
        echo -e "${GREEN}✅ Tailscale installed.${NC}"
    else
        echo -e "${RED}❌ Failed to install Tailscale.${NC}"
        exit 1
    fi
fi

TAILSCALE_BIN=$(command -v tailscale || true)
PLIST_PATH="/Library/LaunchDaemons/homebrew.mxcl.tailscale.plist"

if [ -z "$TAILSCALE_BIN" ]; then
    echo -e "${RED}❌ Tailscale was not found in PATH after installation.${NC}"
    exit 1
fi

echo -e "${BLUE}🚦 Starting Tailscale service...${NC}"
if sudo "$BREW_BIN" services start tailscale >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Tailscale service is running.${NC}"
else
    echo -e "${YELLOW}⚠️ Could not start the Tailscale service automatically.${NC}"
fi

if [ -f "$PLIST_PATH" ]; then
    sudo launchctl bootstrap system "$PLIST_PATH" 2>/dev/null || true
    sudo launchctl kickstart -kp system/homebrew.mxcl.tailscale
    echo -e "${GREEN}✅ Tailscale daemon bootstrapped.${NC}"
else
    echo -e "${RED}❌ Service plist not found at $PLIST_PATH${NC}"
    exit 1
fi

sleep 2

STATUS_JSON=$(sudo "$TAILSCALE_BIN" status --json 2>/dev/null || true)

if [ -z "$STATUS_JSON" ]; then
    echo -e "${YELLOW}⚠️ Tailscale is installed, but the daemon is not reachable yet.${NC}"
    print_manual_steps
    exit 0
fi

if echo "$STATUS_JSON" | grep -q '"BackendState": "Running"'; then
    echo -e "${GREEN}✅ Tailscale is already authenticated.${NC}"
    echo -e "${BLUE}🔐 Enabling Tailscale SSH...${NC}"
    if sudo "$TAILSCALE_BIN" set --ssh >/dev/null 2>"$TAILSCALE_ERROR_LOG"; then
        echo -e "${GREEN}✅ Tailscale SSH is enabled.${NC}"
    else
        echo -e "${YELLOW}⚠️ Tailscale is connected, but SSH setup still needs manual action.${NC}"
        cat "$TAILSCALE_ERROR_LOG"
        print_manual_steps
        exit 0
    fi
else
    if [ -z "${TS_AUTHKEY:-}" ]; then
        echo -e "${YELLOW}⚠️ TS_AUTHKEY is not available for Tailscale authentication.${NC}"
        print_manual_steps
        exit 0
    fi

    echo -e "${BLUE}🔑 Authenticating Tailscale and enabling Tailscale SSH...${NC}"
    if sudo "$TAILSCALE_BIN" up --auth-key="$TS_AUTHKEY" --advertise-tags=tag:server --reset --ssh --timeout=30s >/dev/null 2>"$TAILSCALE_ERROR_LOG"; then
        echo -e "${GREEN}✅ Tailscale is connected and Tailscale SSH is enabled.${NC}"
    else
        echo -e "${YELLOW}⚠️ Tailscale install completed, but auth or SSH setup still needs manual action.${NC}"
        cat "$TAILSCALE_ERROR_LOG"
        print_manual_steps
        exit 0
    fi
fi

if sudo "$TAILSCALE_BIN" status >/dev/null 2>&1; then
    echo -e "${GREEN}✅ Tailscale status check succeeded.${NC}"
else
    echo -e "${YELLOW}⚠️ Tailscale installed, but status could not be confirmed automatically.${NC}"
    print_manual_steps
fi
