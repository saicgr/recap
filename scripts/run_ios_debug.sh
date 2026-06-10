#!/bin/bash
# iOS Debug Build Script for Recap (hot reload via `flutter attach`)
# Usage: ./run_ios_debug.sh [simulator_name]
# Default simulator: "iPhone 17 Pro"

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Recap iOS DEBUG Build Script ===${NC}"

FLUTTER_PATH="/opt/homebrew/bin/flutter"
BUNDLE_ID="com.recapfreenote.recap"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

TARGET_SIM="${1:-iPhone 17 Pro}"

get_simulator_id() {
    local name="$1"
    xcrun simctl list devices available | grep "$name (" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}'
}

echo -e "${YELLOW}Looking for simulator: $TARGET_SIM${NC}"
DEVICE_ID=$(get_simulator_id "$TARGET_SIM")
if [ -z "$DEVICE_ID" ]; then
    echo -e "${YELLOW}$TARGET_SIM not found, falling back to any iPhone...${NC}"
    DEVICE_ID=$(xcrun simctl list devices available | grep "iPhone" | head -1 | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}')
fi
if [ -z "$DEVICE_ID" ]; then
    echo -e "${RED}No iPhone simulators found. Install one via Xcode > Settings > Platforms.${NC}"
    exit 1
fi

DEVICE_STATE=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -c "Booted" || true)
if [ "$DEVICE_STATE" -eq "0" ]; then
    echo -e "${YELLOW}Booting $TARGET_SIM ($DEVICE_ID)${NC}"
    xcrun simctl boot "$DEVICE_ID"
    open -a Simulator
    for i in $(seq 1 30); do
        BOOT_STATUS=$(xcrun simctl list devices | grep "$DEVICE_ID" | grep -c "Booted" || true)
        [ "$BOOT_STATUS" -gt "0" ] && break
        [ "$i" -eq 30 ] && { echo -e "${RED}Simulator failed to boot${NC}"; exit 1; }
        sleep 2
    done
    echo -e "${GREEN}Simulator ready: $TARGET_SIM${NC}"
else
    open -a Simulator
    echo -e "${GREEN}$TARGET_SIM already running${NC}"
fi

echo -e "${YELLOW}Cleaning build cache...${NC}"
$FLUTTER_PATH clean

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

echo -e "${YELLOW}Removing existing app...${NC}"
xcrun simctl terminate "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl uninstall "$DEVICE_ID" "$BUNDLE_ID" 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

echo -e "${GREEN}Building DEBUG for $TARGET_SIM...${NC}"
$FLUTTER_PATH run --debug -d "$DEVICE_ID"

echo -e "${GREEN}=== Done! ===${NC}"
