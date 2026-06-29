# Kura CLI Reference

Every command in the **kura** compiler (Kyto's CLI).

---

## Global

```bash
kura --version
```

Prints: `kura 0.5.0-asm`

```bash
kura
```

Prints usage when no subcommand given.

---

## `kura init`

Scaffold a new Kyto project.

```bash
kura init --name my-app
```

Creates:

- `kyto.toml`
- `.kyto.config.example`
- `kyto/main.kyto` (starter source)

---

## `kura compile`

Read project config and write all emit artifacts.

```bash
kura compile
```

**Reads:**

- `kyto.toml` (paths and toggles)
- `.kyto.config` (if present)
- `kyto/main.kyto` (unless `config_only = true`)

**Writes:**

- Env files, user SQL/JSON/TS, deploy script (per `kyto.toml`)

Exit `0` on success, non-zero on error.

---

## `kura check`

Parse and evaluate without writing files.

```bash
kura check
```

Use in CI to validate config before deploy.

---

## `kura install`

Copy compiler binary to user-local PATH.

```bash
kura install
```

| Platform | Destination |
|:---------|:------------|
| Linux | `~/.local/bin/kura` |
| Windows | `%USERPROFILE%\.local\bin\kura.exe` |

---

## `kura encrypt`

Encrypt a secrets file with ChaCha20-Poly1305 (RFC 8439).

```bash
export KYTO_KEY=$(openssl rand -hex 32)
kura encrypt kyto/local.kyto -o kyto/local.kyto.enc
```

**Key sources:**

1. `KYTO_KEY` environment variable (64 hex chars)
2. `~/.config/kyto/key` file

---

## `kura decrypt`

Decrypt an encrypted file.

```bash
kura decrypt kyto/local.kyto.enc -o kyto/local.kyto
```

Same key requirements as encrypt.

---

## Argument format (encrypt/decrypt)

```bash
kura encrypt <input> -o <output>
kura decrypt <input> -o <output>
```

---

## Environment variables

| Variable | Purpose |
|:---------|:--------|
| `KYTO_KEY` | 32-byte hex key for encrypt/decrypt |

---

## Docker equivalent

```bash
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest compile
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest check
```

Image entrypoint is `kura` — pass subcommands as arguments.

---

## Exit codes

| Code | Meaning |
|:-----|:--------|
| `0` | Success |
| `1` | Error (missing config, parse failure, I/O error) |

---

## See also

- [Installing Kyto](Installing-Kyto)
- [Encryption & Privacy](Encryption-and-Privacy)
