#!/bin/bash
# iOS Release Build Script for Recap
# Usage: ./run_ios.sh

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Recap iOS Build Script ===${NC}"

FLUTTER_PATH="/opt/homebrew/bin/flutter"
BUNDLE_ID="com.recapfreenote.recap"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

get_simulator() {
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone 17 Pro (" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
    if [ -z "$DEVICE_ID" ]; then
        DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
    fi
    echo "$DEVICE_ID"
}

echo -e "${YELLOW}Checking iOS simulator state...${NC}"
BOOTED_DEVICES=$(xcrun simctl list devices booted | grep -c "Booted" || true)

if [ "$BOOTED_DEVICES" -eq "0" ]; then
    DEVICE_ID=$(get_simulator)
    if [ -z "$DEVICE_ID" ]; then
        echo -e "${RED}No iPhone simulators found. Install one via Xcode > Settings > Platforms.${NC}"
        exit 1
    fi
    echo -e "${GREEN}Booting simulator: $DEVICE_ID${NC}"
    xcrun simctl boot "$DEVICE_ID"
    open -a Simulator
    echo -e "${YELLOW}Waiting for simulator to boot...${NC}"
    sleep 5
else
    DEVICE_ID=$(xcrun simctl list devices booted | grep "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
    open -a Simulator
    echo -e "${GREEN}Simulator already running: $DEVICE_ID${NC}"
fi

echo -e "${YELLOW}Running flutter clean...${NC}"
$FLUTTER_PATH clean

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

echo -e "${YELLOW}Uninstalling existing app...${NC}"
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

echo -e "${GREEN}Building and running on simulator: $DEVICE_ID${NC}"
$FLUTTER_PATH run -d "$DEVICE_ID"

echo -e "${GREEN}=== Done! ===${NC}"
