#!/bin/bash
# Fetch bundled model files before flutter build. CI hook; safe to run locally.
# Files land in assets/models/ and are referenced by pubspec.yaml.
#
# Usage:
#   ./scripts/fetch_bundled_models.sh
#
# Idempotent — skips already-downloaded files of the expected size.

set -euo pipefail

DEST="$(cd "$(dirname "$0")/.." && pwd)/assets/models"
mkdir -p "$DEST"

TINY_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.en.bin"
TINY_PATH="$DEST/ggml-tiny.en.bin"
TINY_MIN_SIZE=70000000  # ~75 MB; refuse anything smaller

if [ -f "$TINY_PATH" ] && [ "$(stat -f%z "$TINY_PATH" 2>/dev/null || stat -c%s "$TINY_PATH")" -ge "$TINY_MIN_SIZE" ]; then
  echo "ggml-tiny.en.bin already present and large enough — skipping"
else
  echo "Downloading ggml-tiny.en.bin (~75 MB) to $TINY_PATH"
  curl -L --fail --progress-bar -o "$TINY_PATH.part" "$TINY_URL"
  mv "$TINY_PATH.part" "$TINY_PATH"
  echo "Done."
fi
