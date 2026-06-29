# Installing Kyto

Install the **kura** compiler on your machine.

> Remember: you install **kura** to work on **Kyto** projects. See [Kyto vs kura](Kyto-vs-Kura).

---

## Method 1 — GitHub Releases (recommended)

**[Download latest release](https://github.com/voidmute/kyto/releases/latest)**

| Platform | File | Binary inside |
|:---------|:-----|:--------------|
| Windows x86-64 | `kyto-*-windows-x86_64.zip` | `kura.exe` |
| Linux x86-64 | `kyto-*-linux-x86_64.zip` | `kura` |

### Windows

```powershell
Expand-Archive kyto-0.5.1-asm-windows-x86_64.zip
cd kyto-0.5.1-asm-windows-x86_64
.\kura.exe install
kura --version
```

Add `%USERPROFILE%\.local\bin` to PATH if needed.

### Linux

```bash
unzip kyto-0.5.1-asm-linux-x86_64.zip
cd kyto-0.5.1-asm-linux-x86_64
chmod +x kura
./kura install
export PATH="$HOME/.local/bin:$PATH"
kura --version
```

---

## Method 2 — Docker (Linux / CI)

**[Package: ghcr.io/voidmute/kyto](https://github.com/voidmute/kyto/pkgs/container/kyto)**

```bash
docker pull ghcr.io/voidmute/kyto:latest

# Run compile in current project
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest compile

# Specific version
docker pull ghcr.io/voidmute/kyto:v0.5.1-asm
```

Entrypoint is `kura` — pass any subcommand.

---

## Method 3 — Build from source

### Requirements

| Platform | Tools |
|:---------|:------|
| Linux | NASM 2.15+, `ld` (binutils) |
| Windows | NASM 2.15+, GoLink or MSVC `link.exe` |

### Linux

```bash
git clone https://github.com/voidmute/kyto.git
cd kyto
sudo apt install nasm    # Debian/Ubuntu
./asm/build.sh
./bin/kura-asm install
```

### Windows

```powershell
git clone https://github.com/voidmute/kyto.git
cd kyto
.\asm\build.ps1        # auto-downloads NASM + GoLink if missing
.\bin\kura-asm.exe install
```

Output binaries:

- Linux: `bin/kura-asm`
- Windows: `bin/kura-asm.exe`

`kura install` copies to a shorter name on PATH (`kura` / `kura.exe`).

---

## Method 4 — Install script

```bash
curl -fsSL https://raw.githubusercontent.com/voidmute/kyto/main/scripts/install-kura.sh | bash
```

(Requires a published release asset — falls back to build if script expects source.)

---

## Verify installation

```bash
kura --version
# kura 0.5.0-asm

kura check    # in a project directory
```

---

## Updating

1. Download newer release zip **or** `docker pull ghcr.io/voidmute/kyto:latest`
2. Run `kura install` again to overwrite `~/.local/bin/kura`

---

## Uninstall

```bash
rm ~/.local/bin/kura          # Linux
rm $env:USERPROFILE\.local\bin\kura.exe   # Windows
```

---

## See also

- [Getting Started](Getting-Started)
- [Kura CLI Reference](Kura-CLI-Reference)
