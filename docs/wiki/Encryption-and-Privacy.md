# Encryption & Privacy

How Kyto keeps secrets local and optional encrypted at rest.

---

## Privacy model

| Property | Kyto behavior |
|:---------|:--------------|
| Network | **None** — compiler never connects |
| Telemetry | **None** |
| Cloud account | **Not required** |
| Secret storage | Your disk, your keys |

Kyto is designed for developers who do not want config tooling that "phones home."

---

## What to gitignore

```gitignore
.env
.kyto.config
kyto/local.kyto
kyto/local.kyto.enc
~/.config/kyto/key
```

**Safe for git:**

- `.env.example` (redacted)
- `.kyto.config.example` (no real secrets)
- `kyto.toml`

---

## `.env.example` redaction

`kyto.toml` controls which keys get redacted in the example file:

```toml
[emit.env]
redact_keys = ["SECRET", "TOKEN", "PASSWORD", "KEY"]
```

Any env key **containing** those substrings is masked in `.env.example`.

---

## Encrypting source files

Store sensitive `.kyto` sources encrypted:

```bash
# Generate a 32-byte key (64 hex chars)
export KYTO_KEY=$(openssl rand -hex 32)

# Encrypt
kura encrypt kyto/local.kyto -o kyto/local.kyto.enc

# Decrypt when editing
kura decrypt kyto/local.kyto.enc -o kyto/local.kyto
```

Delete plaintext `local.kyto` after encrypting. Commit only `.enc` if your workflow allows encrypted blobs (or keep `.enc` local too).

---

## Key storage options

### Option 1 — Environment variable

```bash
export KYTO_KEY=0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef
```

Good for CI secrets and one-off scripts.

### Option 2 — Key file

```bash
mkdir -p ~/.config/kyto
openssl rand -hex 32 > ~/.config/kyto/key
chmod 600 ~/.config/kyto/key
```

kura reads this automatically when `KYTO_KEY` is unset.

---

## Algorithm

| Property | Value |
|:---------|:------|
| Cipher | ChaCha20 |
| MAC | Poly1305 |
| Standard | RFC 8439 (AEAD) |
| Implementation | `crypto.asm` in NASM |

Encrypted files include a `KYTO` magic header for format identification.

---

## Threat model (honest)

**Kyto protects against:**

- Accidental secret commits (`.env.example` redaction)
- Casual disk reads (encrypted `.kyto` sources)
- Cloud config vendor lock-in

**Kyto does not protect against:**

- Attacker with your `KYTO_KEY` and encrypted files
- Malware on your machine
- Someone with access to live `.env` on a server

Use OS-level permissions (`chmod 600`) on key files.

---

## Docker note

Container runs as root inside the image. Mount projects read-only where possible:

```bash
docker run --rm -v "$PWD:/work:ro" -w /work ghcr.io/voidmute/kyto:latest check
```

Do not bake `KYTO_KEY` into images.

---

## See also

- [Kura CLI Reference](Kura-CLI-Reference)
- [Configuration Guide](Configuration-Guide)
