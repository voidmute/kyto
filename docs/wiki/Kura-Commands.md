# kura commands

Quick reference for every **kura** subcommand. Full details: [Kura CLI Reference](Kura-CLI-Reference).

---

## Command list

| Command | Summary |
|:--------|:--------|
| `kura --version` | Print compiler version (`kura 0.5.0-asm`) |
| `kura` | Print usage when no subcommand is given |
| `kura init` | Scaffold `kyto.toml`, `.kyto.config.example`, `kyto/main.kyto` |
| `kura compile` | Read project files and write all emit artifacts |
| `kura check` | Parse and evaluate without writing files |
| `kura install` | Copy the compiler binary to `~/.local/bin` |
| `kura encrypt <input> -o <output>` | Encrypt a file (ChaCha20-Poly1305) |
| `kura decrypt <input> -o <output>` | Decrypt a file encrypted by `kura encrypt` |

---

## Cheat sheet

```bash
# Version
kura --version

# New project
kura init --name my-app
cp .kyto.config.example .kyto.config

# Daily workflow
kura check          # validate only (CI-friendly)
kura compile        # write .env, SQL, JSON, TS, deploy script

# Install compiler to PATH
kura install        # Linux/mac-style: ~/.local/bin/kura
kura.exe install    # Windows

# Secrets (requires KYTO_KEY or ~/.config/kyto/key)
kura encrypt kyto/local.kyto -o kyto/local.kyto.enc
kura decrypt kyto/local.kyto.enc -o kyto/local.kyto
```

---

## By task

### Project setup

```bash
kura init --name my-portal
```

### Compile artifacts

```bash
kura compile
```

Reads `kyto.toml`, `.kyto.config`, and optionally `kyto/main.kyto` (unless `config_only = true`).

**Typical outputs** (paths from `kyto.toml`):

- `.env` / `.env.example`
- `generated/users.sql`, `generated/users.json`, `generated/users.ts`
- `generated/deploy-env.sh`

### CI / validation

```bash
kura check
```

Same parsing as `compile`; exits non-zero on error; does not write files.

### Toolchain install

```bash
kura install
```

| Platform | Installs to |
|:---------|:------------|
| Linux | `~/.local/bin/kura` |
| Windows | `%USERPROFILE%\.local\bin\kura.exe` |

### Encryption

```bash
export KYTO_KEY=$(openssl rand -hex 32)   # 64 hex characters
kura encrypt secrets.kyto -o secrets.kyto.enc
kura decrypt secrets.kyto.enc -o secrets.kyto
```

---

## Docker

Image entrypoint is `kura`:

```bash
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest compile
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest check
docker run --rm ghcr.io/voidmute/kyto:latest --version
```

---

## Exit codes

| Code | Meaning |
|:-----|:--------|
| `0` | Success |
| `1` | Error (usage, missing config, parse/eval failure, I/O) |

---

## Environment variables

| Variable | Used by |
|:---------|:--------|
| `KYTO_KEY` | `kura encrypt`, `kura decrypt` (64-char hex; 32 bytes) |

Alternative key file: `~/.config/kyto/key`

---

## See also

- [Kura CLI Reference](Kura-CLI-Reference) — full documentation per command
- [Getting Started](Getting-Started) — first project walkthrough
- [Encryption & Privacy](Encryption-and-Privacy) — key handling and threat model
- [Naming & Origin](Naming-and-Origin) — why the project is called Kyto and kura
