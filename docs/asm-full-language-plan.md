# Kyto 100% Assembly — implementation plan

Goal: every `kura` command and the full `.kyto` language in NASM x86-64, no Rust at runtime.

## Done (v0.5 ASM)

| Item | Status |
|------|--------|
| `kura compile` / `check` | ASM — config-only + full `.kyto` eval path |
| `kura install` | ASM — Windows + Linux |
| `kura init` | ASM — writes `kyto.toml` + `.kyto.config.example` |
| `kura --version` | ASM — `kura 0.5.0-asm` |
| `.kyto.config` v2 parser + emitters | ASM — DOMAIN, USERS, ADMIN, env KV lines |
| `kyto.toml` paths + `config_only` + `entry` | ASM scraper |
| `.kyto` lexer + evaluator | ASM — `lexer.asm`, `kyto_eval.asm` |
| `build_env` / `random_base64` / `emit env` | ASM — minimal example (`config_only = false`) |
| `encrypt` / `decrypt` | ASM — ChaCha20-Poly1305, `KYTO` magic + nonce + tag |
| Linux crypto | ASM — `KYTO_KEY` / `~/.config/kyto/key`, `write_binary_file` |
| CI | ASM-only smoke (no Rust `cargo test` gate) |

## Remaining polish

### M5 — Finish CLI
- `kura init --name` (argv parsing)
- `kura compile --entry path`
- Archive Rust `crates/` from default docs once cross-platform smoke is green

## Architecture

```
asm/src/
  lexer.asm          ✓ tokenize .kyto
  kyto_eval.asm      ✓ interpret emit env/users/deploy + build_env
  crypto.asm         ✓ ChaCha20-Poly1305 (RFC 8439)
  kyto_compile.asm   ✓ orchestrate config_only vs full
  config_parse_simple.asm  ✓ .kyto.config v2
  emit_*.asm         ✓ .env, users, deploy outputs
  cmd_init.asm       ✓
  cmd_crypto.asm     ✓
  kura.asm           ✓ Windows PE
  kura_linux.asm     ✓ Linux ELF
```

## Verification

```powershell
cd kyto
powershell -File asm\build.ps1

cd examples\minimal
..\..\bin\kura-asm.exe check
..\..\bin\kura-asm.exe compile
Get-Content .env

$env:KYTO_KEY = "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
..\..\bin\kura-asm.exe encrypt plain.txt -o cipher.bin
..\..\bin\kura-asm.exe decrypt cipher.bin -o plain-out.txt
```

Rust `crates/kyto-core` remains as reference only; runtime is 100% NASM on Windows and Linux.
