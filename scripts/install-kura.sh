#!/usr/bin/env bash
# Install kura on PATH (Linux). Run from repo root:
#   ./scripts/install-kura.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
TARGET="$BIN_DIR/kura"
SOURCE="$REPO/bin/kura-asm"

if [ ! -f "$SOURCE" ]; then
  echo "Building kura (NASM)..."
  "$REPO/asm/build.sh"
fi

if [ ! -f "$SOURCE" ]; then
  echo "Build failed: $SOURCE not found" >&2
  exit 1
fi

mkdir -p "$BIN_DIR"
cp -f "$SOURCE" "$TARGET"
chmod +x "$TARGET"
echo "installed kura -> $TARGET"

if ! echo ":${PATH:-}:" | grep -q ":$BIN_DIR:"; then
  echo "note: add $BIN_DIR to PATH, e.g.:"
  echo "  export PATH=\"$BIN_DIR:\$PATH\""
fi

"$TARGET" --version
echo "Done. Run: kura compile"
