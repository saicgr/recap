#!/bin/bash
# Foldable / large-screen Android Build Script for Recap
# Usage: ./scripts/run_foldable.sh [avd_name]
# Default AVD: Pixel_Fold_API_36

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}=== Recap Foldable Build Script ===${NC}"

FLUTTER_PATH="/opt/homebrew/bin/flutter"
ADB_PATH="$HOME/Library/Android/sdk/platform-tools/adb"
EMULATOR_PATH="$HOME/Library/Android/sdk/emulator/emulator"
APP_ID="com.recapfreenote.recap"
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_DIR"

FOLD_AVD="${1:-Pixel_Fold_API_36}"

# Detect if the foldable AVD is already running.
FOLD_SERIAL=""
for SERIAL in $($ADB_PATH devices | grep "emulator-" | awk '{print $1}'); do
    AVD_NAME=$($ADB_PATH -s "$SERIAL" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')
    if [ "$AVD_NAME" = "$FOLD_AVD" ]; then
        FOLD_SERIAL="$SERIAL"
        echo -e "${GREEN}$FOLD_AVD already running on $FOLD_SERIAL${NC}"
        break
    fi
done

if [ -z "$FOLD_SERIAL" ]; then
    echo -e "${YELLOW}Launching foldable emulator: $FOLD_AVD${NC}"
    $EMULATOR_PATH -avd "$FOLD_AVD" -no-snapshot-save -gpu auto -allow-host-audio &

    echo -e "${YELLOW}Waiting for emulator to connect...${NC}"
    $ADB_PATH wait-for-device

    echo -e "${YELLOW}Detecting foldable emulator serial...${NC}"
    for i in $(seq 1 30); do
        for SERIAL in $($ADB_PATH devices | grep "emulator-" | awk '{print $1}'); do
            AVD_NAME=$($ADB_PATH -s "$SERIAL" emu avd name 2>/dev/null | head -n 1 | tr -d '\r')
            if [ "$AVD_NAME" = "$FOLD_AVD" ]; then
                FOLD_SERIAL="$SERIAL"; break 2
            fi
        done
        sleep 1
    done

    if [ -z "$FOLD_SERIAL" ]; then
        echo -e "${RED}Could not detect foldable emulator. Falling back to first emulator.${NC}"
        FOLD_SERIAL=$($ADB_PATH devices | grep "emulator-" | head -n 1 | awk '{print $1}')
    fi
    [ -z "$FOLD_SERIAL" ] && { echo -e "${RED}No emulator detected.${NC}"; exit 1; }

    echo -e "${YELLOW}Waiting for boot on $FOLD_SERIAL...${NC}"
    while [ "$($ADB_PATH -s "$FOLD_SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
        sleep 2
        echo -e "${YELLOW}Still waiting for boot...${NC}"
    done

    echo -e "${GREEN}Foldable emulator ready on $FOLD_SERIAL${NC}"
fi

echo -e "${YELLOW}Getting dependencies...${NC}"
$FLUTTER_PATH pub get

echo -e "${YELLOW}Uninstalling existing app...${NC}"
$ADB_PATH -s "$FOLD_SERIAL" uninstall "$APP_ID" 2>/dev/null || echo -e "${YELLOW}App was not installed.${NC}"

echo -e "${GREEN}Building and running on foldable ($FOLD_SERIAL)...${NC}"
$FLUTTER_PATH run -d "$FOLD_SERIAL"

echo -e "${GREEN}=== Done! ===${NC}"
