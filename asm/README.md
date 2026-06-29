# Kyto kura (ASM)

x86-64 Windows implementation of `kura` in NASM. Config-only `kura compile` for v1.

## Requirements

- [NASM](https://www.nasm.us/) 2.15+
- [GoLink](http://www.godevtool.com/) or MSVC `link.exe`

`build.ps1` can download a portable NASM zip and GoLink when they are not on PATH.

## Build

```powershell
.\asm\build.ps1
```

Output: `bin/kura-asm.exe`

## Commands (v1)

| Command | Description |
|---------|-------------|
| `kura compile` | Read `.kyto.config` + `kyto.toml` paths, write env/users/deploy artifacts |
| `kura install` | Copy binary to `%USERPROFILE%\.local\bin\kura.exe` |
| `kura --version` | Print `kura 0.2.0-asm` |

## Modules

| File | Role |
|------|------|
| `src/kura.asm` | Entry, command dispatch |
| `src/win_io.asm` | CreateFile, ReadFile, WriteFile |
| `src/str.asm` | strcmp, strcat, trim, parse lists |
| `src/config.asm` | `.kyto.config` parser (v2) |
| `src/toml_min.asm` | Scrape emit paths from `kyto.toml` |
| `src/emit_env.asm` | `.env` / `.env.example` |
| `src/emit_users.asm` | SQL, TypeScript, JSON |
| `src/emit_deploy.asm` | Bash export script |

Deferred: full `.kyto` lexer/parser, encrypt/decrypt, Linux ELF.
