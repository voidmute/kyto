<div align="center">

<img src="https://raw.githubusercontent.com/voidmute/kyto/main/icons/kyto.png" alt="Kyto logo" width="128" />

# Kyto

**A privacy-first programming language and config compiler.**

**Kyto** is the language. **kura** is its compiler CLI (`kura compile`, `kura check`, …). The compiler is written in **NASM x86-64 Assembly** (Windows PE + Linux ELF).

<br />

### Languages

[![English](https://img.shields.io/badge/lang-English-red?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.md)
[![Русский](https://img.shields.io/badge/lang-Русский-blue?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.ru.md)
[![Español](https://img.shields.io/badge/lang-Español-yellow?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.es.md)
[![Français](https://img.shields.io/badge/lang-Français-blue?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.fr.md)
[![Deutsch](https://img.shields.io/badge/lang-Deutsch-black?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.de.md)
[![中文](https://img.shields.io/badge/lang-中文-orange?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.zh-CN.md)
[![日本語](https://img.shields.io/badge/lang-日本語-9B59B6?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.ja.md)
[![Português](https://img.shields.io/badge/lang-Português-green?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.pt-BR.md)
[![Українська](https://img.shields.io/badge/lang-Українська-55ACEE?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.uk.md)

<br />

[![CI](https://img.shields.io/github/actions/workflow/status/voidmute/kyto/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=CI)](https://github.com/voidmute/kyto/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/LICENSE)
[![Release](https://img.shields.io/github/v/release/voidmute/kyto?style=for-the-badge&logo=github&label=release)](https://github.com/voidmute/kyto/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/voidmute/kyto/total?style=for-the-badge&color=2481D7&label=downloads)](https://github.com/voidmute/kyto/releases)
[![Package](https://img.shields.io/badge/container-ghcr.io-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://github.com/voidmute/kyto/pkgs/container/kyto)
[![NASM](https://img.shields.io/badge/toolchain-NASM%20x86--64-111111?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md)

<br />

[![Windows](https://img.shields.io/badge/Windows-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/voidmute/kyto/releases/latest)
[![Linux](https://img.shields.io/badge/Linux-FCC624?style=for-the-badge&logo=linux&logoColor=black)](https://github.com/voidmute/kyto/releases/latest)
[![Privacy](https://img.shields.io/badge/privacy-local--only-success?style=for-the-badge)](#privacy)
[![Encrypt](https://img.shields.io/badge/crypto-ChaCha20--Poly1305-critical?style=for-the-badge)](#privacy)

<br />

[**Get Started**](#quick-start) · [**Wiki**](https://github.com/voidmute/kyto/wiki) · [**Releases**](#releases) · [**Packages**](#packages) · [**Configuration**](docs/configuration.md) · [**Examples**](examples/minimal) · [**Grammar**](spec/grammar.md) · [**Roadmap**](spec/asm-roadmap.md)

</div>

---

## Table of Contents

- [Why Kyto](#why-kyto)
- [Quick Start](#quick-start)
- [Releases](#releases)
- [Packages](#packages)
- [`.kyto.config`](#kytoconfig)
- [`kyto.toml`](#kytotoml)
- [Kura CLI](#kura-cli)
- [Language Snapshot](#language-snapshot)
- [Examples](#examples)
- [Privacy](#privacy)
- [Contributing](#contributing)

---

## Why Kyto

| Problem | Kyto approach |
|:--------|:--------------|
| Users copied across SQL, TS, and shell | One compile step emits all artifacts |
| Secrets in git | Layered config + optional encryption |
| Heavy DSLs | Simple `.kyto.config` for everyday edits |
| Vendor lock-in | `kyto.toml` configures every output path |

Kyto is **local-only**: no network, no telemetry, no cloud dependency.

---

## Quick Start

### Windows

```powershell
git clone https://github.com/voidmute/kyto.git
cd kyto
.\asm\build.ps1
.\bin\kura-asm.exe install
kura --version
```

### Linux

```bash
git clone https://github.com/voidmute/kyto.git
cd kyto
sudo apt install nasm    # if needed
./asm/build.sh
./bin/kura-asm install
export PATH="$HOME/.local/bin:$PATH"
kura --version
```

### New project

```bash
mkdir my-app && cd my-app
kura init --name my-app
cp .kyto.config.example .kyto.config
kura compile
```

> Set `config_only = true` in `kyto.toml` to skip `.kyto` sources and compile from config only.

---

## Releases

**Kyto** releases ship the **kura** compiler. Download archives from **[GitHub Releases](https://github.com/voidmute/kyto/releases/latest)**.

| Platform | Archive | Binary inside |
|:---------|:--------|:--------------|
| Windows x86-64 | `kyto-*-windows-x86_64.zip` | `kura.exe` |
| Linux x86-64 | `kyto-*-linux-x86_64.zip` | `kura` |

### Windows (from release)

```powershell
# Extract kyto-*-windows-x86_64.zip, then:
.\kura.exe install
kura --version
```

### Linux (from release)

```bash
# Extract kyto-*-linux-x86_64.zip, then:
chmod +x kura
./kura install
export PATH="$HOME/.local/bin:$PATH"
kura --version
```

Tags follow `v*` (for example `v0.5.1-asm`).

---

## Packages

Linux builds are also published as a **GitHub Container** package (shows under the repo **Packages** tab):

**[ghcr.io/voidmute/kyto](https://github.com/voidmute/kyto/pkgs/container/kyto)**

```bash
docker pull ghcr.io/voidmute/kyto:latest
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest compile
```

The image contains the `kura` compiler; mount your Kyto project at `/work`.

---

## `.kyto.config`

Human-friendly config for domain, users, and **any env key**. Comments use `+`.

```text
+ Production portal
DOMAIN app.example.com
ADMIN alice
USERS alice bob carol
DATABASE_URL postgresql://localhost/app
REPO_DIR /var/www/app
```

| Rule | Behavior |
|:-----|:---------|
| `DOMAIN` | Sets `APP_URL=https://host` |
| `USERS` / `ADMIN` | Login names (lowercased) |
| Other `KEY value` | Becomes an env variable |
| `REPO_*` | Deploy map entries |

See [spec/kyto-lite.md](spec/kyto-lite.md) for the config-first workflow.

---

## `kyto.toml`

Project manifest — customize every emit target:

```toml
[project]
name = "my-app"
entry = "kyto/main.kyto"

[config]
file = ".kyto.config"

[emit.env]
file = ".env"
example = ".env.example"

[emit.users]
sql = "generated/users.sql"
typescript = "generated/users.ts"
json = "generated/users.json"

[emit.deploy]
script = "generated/deploy-env.sh"
```

---

## Kura — the Kyto compiler

`kura` is the command-line compiler for Kyto projects:

| Command | Description |
|:--------|:------------|
| `kura init` | Scaffold `kyto.toml`, `.kyto.config.example`, `kyto/main.kyto` |
| `kura compile` | Compile and write artifacts |
| `kura check` | Parse and evaluate without writing files |
| `kura install` | Install to `~/.local/bin` |
| `kura encrypt` | Encrypt a secrets file |
| `kura decrypt` | Decrypt an encrypted file |

---

## Language Snapshot

```kyto
import local from "./local.kyto"

fn build_env(secrets) -> map<string, string> {
  return {
    "APP_URL": "https://" + secrets.domain,
    "SESSION_SECRET": secrets.session_secret,
  }
}

emit env(build_env(local.secrets))
emit users(users)
emit deploy(deploy)
```

Full reference: [spec/grammar.md](spec/grammar.md)

---

## Examples

| Example | Path | Description |
|:--------|:-----|:------------|
| Minimal | [examples/minimal](examples/minimal) | Smallest working project |

```bash
cd examples/minimal && kura compile
```

---

## Privacy

- Secrets files stay gitignored
- `kura encrypt` uses ChaCha20-Poly1305 (RFC 8439)
- Key from `KYTO_KEY` or `~/.config/kyto/key`

---

## Contributing

Issues and pull requests welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
