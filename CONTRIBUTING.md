# Contributing

Thanks for helping improve Kyto.

## Development

Kyto is implemented entirely in NASM x86-64 Assembly. Build and test locally:

```bash
# Linux
sudo apt install nasm
./asm/build.sh
./bin/kura-asm --version
./bin/kura-asm compile
cd examples/minimal && ../../bin/kura-asm check && ../../bin/kura-asm compile
```

```powershell
# Windows
.\asm\build.ps1
.\bin\kura-asm.exe --version
.\bin\kura-asm.exe compile
cd examples\minimal; ..\..\bin\kura-asm.exe check; ..\..\bin\kura-asm.exe compile
```

Source lives under `asm/src/`. Platform I/O is isolated in `win_io.asm` and `linux_io.asm`.

## Pull requests

1. Fork the repo
2. Create a feature branch
3. Run ASM smoke tests (see above)
4. Open a PR with a clear summary

## Style

- Use `-` in prose, not em dashes
- Keep `.kyto.config` simple for end users
- Prefer configurable `kyto.toml` over hardcoded emit paths
- Match existing NASM naming and module layout in `asm/src/`
