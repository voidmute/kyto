# Kyto / kura — Assembly implementation

Kyto is a **native x86-64 Assembly programming language and toolchain**. The `kura` compiler is implemented entirely in NASM: lexer, evaluator, config parser, crypto, and emitters. No Rust, no C runtime dependency beyond the OS.

## Current status (v0.5 ASM)

| Component | Windows x64 | Linux ELF |
|-----------|-------------|-----------|
| `kura compile` / `check` | yes | yes |
| `kura init` / `install` | yes (init stamps **Kyto was here** in scaffold files) | yes |
| `kura --version` | yes | yes |
| `.kyto.config` v2 + emitters | yes | yes |
| `.kyto` lexer + evaluator | yes | partial |
| `encrypt` / `decrypt` | yes | yes |
| CI | ASM smoke | ASM smoke |

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
  kura.asm          Windows entry
  kura_linux.asm    Linux entry (_start)
  inc/kura_cmds.asm Shared dispatch + compile
  lexer.asm         .kyto tokenizer
  kyto_eval.asm     Expression evaluator + emit
  crypto.asm        ChaCha20-Poly1305
  config*.asm       .kyto.config parser
  emit_*.asm        Artifact writers
  win_io.asm        Win32 I/O
  linux_io.asm      Linux syscalls
  str.asm           String helpers
```

Both platforms share the same language modules; only entry and I/O differ.

## Remaining work

- `kura init --name` / `kura compile --entry` argv parsing
- Full `emit env(build_env(...))` parity (random `SESSION_SECRET` merge)
- aarch64 Linux (optional)

## Contributing

1. Pick an item from [docs/asm-full-language-plan.md](../docs/asm-full-language-plan.md)
2. Extend CI smoke in `.github/workflows/ci.yml`
3. Keep modules platform-agnostic; isolate OS code in `win_io.asm` / `linux_io.asm`
