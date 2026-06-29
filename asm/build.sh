#!/usr/bin/env bash
# Build kura ASM (Linux x86-64 ELF)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ASM="$ROOT/asm"
BUILD="$ASM/build"
OUT="${1:-$ROOT/bin/kura-asm}"

mkdir -p "$BUILD" "$(dirname "$OUT")"
cd "$ASM/src"

if ! command -v nasm >/dev/null 2>&1; then
  echo "asm/build.sh: nasm not found. Install: sudo apt install nasm" >&2
  exit 1
fi

nasm -f elf64 -o "$BUILD/kura_linux.o" kura_linux.asm
ld -o "$OUT" "$BUILD/kura_linux.o"
chmod +x "$OUT"
echo "Built $OUT"
