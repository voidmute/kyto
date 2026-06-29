#!/usr/bin/env bash
# Install kura on PATH (Linux/macOS). Run from repo root:
#   ./scripts/install-kura.sh
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
BIN_DIR="${HOME}/.local/bin"
TARGET="$BIN_DIR/kura"

SOURCE=""
for candidate in \
  "$REPO/target/release/kura" \
  "$REPO/bin/kura"
do
  if [ -f "$candidate" ]; then
    SOURCE="$candidate"
    break
  fi
done

if [ -z "$SOURCE" ]; then
  echo "Building kura..."
  cargo build --release --manifest-path "$REPO/Cargo.toml"
  SOURCE="$REPO/target/release/kura"
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
