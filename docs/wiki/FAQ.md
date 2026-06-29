# FAQ

Frequently asked questions about Kyto and kura.

---

## General

### Is Kyto a "real" programming language?

Yes. Kyto has syntax, types (`struct`, `enum`), functions, control flow, imports, and a compile-to-artifacts model. It is specialized for **configuration compilation** rather than general app logic — similar to how SQL is a real language for queries.

### What's the difference between Kyto and kura?

**Kyto** = language. **kura** = compiler. See [Kyto vs kura](Kyto-vs-Kura).

### Why Assembly?

Small binary, no runtime dependency, full control, and proof that the toolchain can be self-contained. The repo is ~96% NASM on GitHub.

### Is this production-ready?

**Kyto Lite** (`config_only = true`) is stable for config-driven workflows. Full `.kyto` evaluator features are still maturing — check the [roadmap](https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md).

---

## Usage

### Do I need to learn `.kyto` syntax?

No. Start with `.kyto.config` only. Set `config_only = true` in `kyto.toml`.

### Where do I put secrets?

- **Development:** `.kyto.config` (gitignored) or `kyto/local.kyto`
- **CI:** environment variables injected at deploy time
- **Encrypted:** `kura encrypt` → `local.kyto.enc`

Never commit `.env` with real secrets.

### Why didn't my users appear in SQL?

Ensure `USERS` is set in `.kyto.config`:

```text
USERS alice bob
```

Or populate the `users` list in `.kyto` and use `emit users(users)`.

### `kura: command not found`

Run `kura install` after building/downloading, or add `bin/` to PATH.

---

## Technical

### What platforms are supported?

| Platform | Status |
|:---------|:-------|
| Windows x86-64 | ✓ |
| Linux x86-64 | ✓ |
| macOS | ✗ (no build yet) |
| ARM | ✗ (roadmap optional item) |

### Does kura need internet?

No. Fully offline after install.

### What crypto does encrypt use?

ChaCha20-Poly1305 (RFC 8439), implemented in Assembly.

### Can I use Kyto with Docker only?

Yes:

```bash
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest compile
```

### How is this different from dotenv?

dotenv loads `.env` at runtime. Kyto **generates** `.env`, SQL, TS, JSON, and deploy scripts from a single config source at **compile time**.

---

## Project

### Where is the source?

https://github.com/voidmute/kyto

### How do I contribute?

See [CONTRIBUTING.md](https://github.com/voidmute/kyto/blob/main/CONTRIBUTING.md). Assembly experience welcome but not required for docs and examples.

### What license?

MIT.

### Why is the GitHub Packages count sometimes 0?

Packages tab loads separately from Releases. Container is at [ghcr.io/voidmute/kyto](https://github.com/voidmute/kyto/pkgs/container/kyto). Refresh or open the package link directly.

---

## Still stuck?

Open an issue: https://github.com/voidmute/kyto/issues

Include:

- `kura --version` output
- `kyto.toml` and redacted `.kyto.config`
- Full error message from `kura compile`
