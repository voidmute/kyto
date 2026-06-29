# Architecture

How **kura** compiles Kyto projects — inside the ~21 KB binary.

---

## High-level pipeline

```
kyto.toml ──┐
.kyto.config├──► parse config ──► merge ──► emit writers ──► artifacts
.kyto ──────┘         ▲              ▲
                      │              │
                 toml_min.asm    kyto_eval.asm
                 config.asm      lexer.asm
```

---

## Module map

```
asm/src/
  kura.asm           Windows entry, command-line parsing
  kura_linux.asm     Linux ELF _start, argv → cmdline_rest
  inc/kura_cmds.asm  Shared: compile, check, init, dispatch

  lexer.asm          Tokenize .kyto sources
  parse_util.asm     AST helpers, string parsing
  kyto_eval.asm      Expression evaluator + emit calls
  kyto_compile.asm   Orchestrate full project compile

  config.asm         .kyto.config v2 parser
  toml_min.asm       Scrape paths from kyto.toml (minimal TOML)

  emit_env.asm       Write .env / .env.example
  emit_users.asm     SQL, JSON, TypeScript user outputs
  emit_deploy.asm    Bash export script

  crypto.asm         ChaCha20-Poly1305 encrypt/decrypt
  cmd_crypto.asm     encrypt/decrypt CLI
  cmd_init.asm       kura init scaffolding

  str.asm            strcpy, strcat, strcmp, trim
  win_io.asm         Windows file I/O
  linux_io.asm       Linux syscalls, read/write files
```

---

## Platform split

| Layer | Shared | Windows | Linux |
|:------|:-------|:--------|:------|
| Language | ✓ all `.asm` modules above | | |
| Entry | | `kura.asm` | `kura_linux.asm` |
| I/O | | `win_io.asm` | `linux_io.asm` |
| Install path | | `%USERPROFILE%\.local\bin` | `~/.local/bin` |

---

## Compile paths

### Config-only (`config_only = true`)

1. Read `kyto.toml` → output paths
2. Parse `.kyto.config` → domain, users, env keys, REPO_*
3. Emit directly — **no lexer**

Fast. Used by Cloud portal and most Kyto Lite projects.

### Full path (`config_only = false`)

1. Read `kyto.toml` + `.kyto.config`
2. Lex + parse `kyto/main.kyto`
3. Evaluate `emit env(...)`, `emit users(...)`, `emit deploy(...)`
4. Merge with config overlay where applicable
5. Write artifacts

---

## Config parser (`.kyto.config` v2)

- Line-oriented `KEY value` format
- `+` comments
- Special keys: `DOMAIN`, `USERS`, `ADMIN`
- `REPO_*` → deploy map
- Quoted values with `unquote_value` (stack-safe rewrite in ASM)

---

## Emitter design

Each emitter is a separate `.asm` module:

| Module | Output |
|:-------|:-------|
| `emit_env.asm` | Key=value lines, redaction for `.env.example` |
| `emit_users.asm` | SQL INSERTs, JSON array, TS export |
| `emit_deploy.asm` | `export KEY="value"` bash script |

Paths come from `toml_min.asm` scraping `kyto.toml`.

---

## Crypto subsystem

`crypto.asm` implements RFC 8439:

- ChaCha20 stream cipher
- Poly1305 MAC (AEAD)
- Key from `KYTO_KEY` or `~/.config/kyto/key`
- `KYTO` magic header on encrypted files

Used by `kura encrypt` / `kura decrypt` — no external crypto library.

---

## Build system

```bash
# Linux
nasm -f elf64 -o kura_linux.o kura_linux.asm
ld -o kura-asm kura_linux.o

# Windows
nasm -f win64 -o kura.obj kura.asm
GoLink.exe /fo kura.exe kura.obj
```

`build.ps1` can bootstrap portable NASM + GoLink on Windows.

---

## CI architecture

```
push to main
  ├── asm-linux  (ubuntu + nasm + build.sh + smoke compile)
  └── asm-windows (windows + build.ps1 + smoke compile)

tag v*
  ├── build zip artifacts
  ├── push ghcr.io/voidmute/kyto
  └── GitHub Release "Kyto v*"
```

---

## Design principles

1. **No runtime dependency** beyond OS syscalls / Win32 API
2. **Shared language core** — one bug fix applies to both platforms
3. **Config-first** — `.kyto.config` works without a parser for 90% of users
4. **Local-only** — no network code in compiler path
5. **Small binary** — entire tool fits in L1 cache folklore territory

---

## Contributing to internals

1. Pick item from [asm roadmap](https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md)
2. Change shared modules first; touch `win_io`/`linux_io` only for I/O
3. Extend smoke test in `.github/workflows/ci.yml`
4. Run `kura check` on `examples/minimal`

---

## See also

- [Interesting Facts](Interesting-Facts)
- [Language Tutorial](Language-Tutorial)
