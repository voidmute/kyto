# Kyto / kura — Assembly roadmap

Kyto is being implemented as a **native x86-64 Assembly toolchain** with no runtime dependency on Rust or other host languages. The goal is a self-contained programming language: lexer, parser, evaluator, crypto, and emitters — all in NASM.

## Current status (v0.2 ASM)

| Component | Windows x64 | Linux ELF | Notes |
|-----------|-------------|-----------|-------|
| `kura compile` (config-only) | yes | yes | `.kyto.config` + `kyto.toml` paths |
| `kura install` | yes | yes | `~/.local/bin/kura` |
| `kura --version` | yes | yes | `kura 0.2.0-asm` |
| Emit `.env`, users SQL/TS/JSON, deploy script | partial | partial | parity improving |
| Full `.kyto` language | no | no | Rust legacy only today |
| `encrypt` / `decrypt` | no | no | planned |

Build:

```bash
# Linux / Ubuntu
./asm/build.sh          # -> bin/kura-asm

# Windows
./asm/build.ps1         # -> bin/kura-asm.exe
```

## Architecture

```
asm/src/
  kura.asm          Windows entry (main)
  kura_linux.asm    Linux entry (_start)
  inc/kura_cmds.asm Shared dispatch + compile
  inc/io_buf.asm    Shared file buffers
  win_io.asm        Win32 I/O
  linux_io.asm      Linux syscalls
  config*.asm       .kyto.config parser
  emit_*.asm        Artifact writers
  str.asm           String helpers
```

Both platforms link the **same** parser and emitter modules; only the entry point and I/O layer differ.

## Milestones to “full language in ASM”

### M1 — Config parity (current)
- [x] v2 config: `DOMAIN`, `USERS`, `ADMIN`, arbitrary `KEY value`, `+` comments
- [x] `REPO_*` deploy keys
- [x] Linux ELF build
- [ ] Stable emit parity with Rust on real projects (Cloud portal)

### M2 — Lexer + AST (`.kyto`)
- [x] Tokenizer for identifiers, strings, numbers, operators (`lexer.asm`)
- [ ] AST nodes: `let`, `map`, `list`, `if`, calls
- [ ] Symbol table + scopes

### M3 — Evaluator
- [ ] Builtin functions (`users`, `env`, `deploy`, …)
- [ ] Map/list literals
- [ ] String ops and concatenation
- [x] Config-only compile path wired via `config_only_flag`

### M4 — Crypto
- [ ] ChaCha20 / AES helpers in ASM (or minimal C-free crypto lib)
- [ ] `kura encrypt` / `kura decrypt` for `.kyto.secrets` (stub returns error today)

### M5 — CLI completeness
- [x] `kura init`, `kura check`
- [ ] `kura compile --entry` argv parsing
- [ ] Remove Rust from default install path; keep only for regression tests until cutover

### M6 — Beyond x86-64
- [ ] aarch64 Linux (optional)

## Rust legacy

The `crates/` tree remains for regression tests and features not yet ported. **ASM `kura` is the primary toolchain** on Windows and Ubuntu. Once M1–M5 are done, Rust becomes optional.

## Contributing

1. Pick a milestone item
2. Add tests under `asm/tests/` or extend CI smoke `.kyto.config.example`
3. Keep modules platform-agnostic; isolate OS code in `win_io.asm` / `linux_io.asm`
