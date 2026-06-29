# kura — Kyto compiler (ASM)

**kura** is the command-line compiler for the **Kyto** language. Implementation: x86-64 **NASM** (Windows PE + Linux ELF).

[![CI](https://img.shields.io/github/actions/workflow/status/voidmute/kyto/ci.yml?branch=main&style=flat-square&label=CI)](https://github.com/voidmute/kyto/actions/workflows/ci.yml)
[![Release](https://img.shields.io/github/v/release/voidmute/kyto?style=flat-square&label=Kyto)](https://github.com/voidmute/kyto/releases/latest)
[![Package](https://img.shields.io/badge/ghcr.io-kyto-2496ED?style=flat-square&logo=docker&logoColor=white)](https://github.com/voidmute/kyto/pkgs/container/kyto)

Main docs: [README.md](../README.md) · Releases: [Kyto releases](https://github.com/voidmute/kyto/releases/latest) · Package: [ghcr.io/voidmute/kyto](https://github.com/voidmute/kyto/pkgs/container/kyto)

## Requirements

- [NASM](https://www.nasm.us/) 2.15+
- **Windows:** [GoLink](http://www.godevtool.com/) or MSVC `link.exe` (`build.ps1` can download portable NASM + GoLink)
- **Linux:** `ld` (binutils)

## Build

### Windows

```powershell
.\asm\build.ps1
```

Output: `bin/kura-asm.exe`

### Linux

```bash
./asm/build.sh
```

Output: `bin/kura-asm`

## Commands

| Command | Description |
|:--------|:------------|
| `kura compile` | Read `.kyto.config` + `kyto.toml`, write env/users/deploy artifacts |
| `kura check` | Parse and evaluate without writing files |
| `kura init` | Scaffold project files |
| `kura install` | Install to `~/.local/bin` |
| `kura encrypt` / `decrypt` | ChaCha20-Poly1305 (RFC 8439) |
| `kura --version` | Print `kura 0.5.0-asm` |

## Layout

| File | Role |
|:-----|:-----|
| `src/kura.asm` | Windows entry, command-line parsing |
| `src/kura_linux.asm` | Linux ELF entry |
| `src/win_io.asm` / `linux_io.asm` | File I/O |
| `src/crypto.asm` | ChaCha20-Poly1305 |
| `src/config.asm` | `.kyto.config` parser (v2) |
| `src/kyto_compile.asm` | Full `.kyto` compile path |

See [spec/asm-roadmap.md](../spec/asm-roadmap.md) for the full roadmap.
