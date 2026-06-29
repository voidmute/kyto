# Interesting Facts

Things that make Kyto unusual — and worth knowing.

---

## 1. The compiler is ~21 KB of Assembly

**kura** is not written in Rust, C, or Go. The entire compiler toolchain is **NASM x86-64 Assembly**:

- Windows PE binary (~21 KB)
- Linux ELF binary (similar size)

GitHub reports the repo as **~96% Assembly**. That is not a labeling trick — the Rust crates were removed; kura runs without a Rust runtime.

---

## 2. A language built from scratch

Kyto is not a thin wrapper around another toolchain. It includes:

- Its own **grammar** (`let`, `fn`, `struct`, `emit`, …)
- Its own **lexer and evaluator** in `.asm` files
- Its own **config format** (`.kyto.config`)
- Its own **project manifest** (`kyto.toml`)

This is not a fork of Python or a YAML preprocessor with a new name.

---

## 3. Kyto vs kura naming

| | |
|:--|:--|
| **Kyto** | Language (like Rust) |
| **kura** | Compiler (like `rustc`) |

Release zips are named `kyto-*` because they are **Kyto project releases**. The binary inside is `kura`.

---

## 4. Privacy is architectural, not marketing

- **No network calls** in the compiler
- **No telemetry**
- **No cloud account** required
- Secrets stay on disk; optional **local encryption** (ChaCha20-Poly1305)

`kura compile` never phones home.

---

## 5. One compile, many artifacts

A single `kura compile` can emit simultaneously:

- `.env` + `.env.example`
- SQL user seeds
- TypeScript constants
- JSON user lists
- Bash deploy export scripts

Most stacks need 3–5 separate tools or copy-paste for this.

---

## 6. Kyto Lite: config without code

`config_only = true` means operators edit `.kyto.config` like a simple flat file — no programming required.

```text
DOMAIN app.example.com
USERS alice bob
```

Power users can add `.kyto` later without changing the workflow.

---

## 7. Comments use `+`

Both `.kyto` and `.kyto.config` use `+` for comments — visually distinct from `#` (shell) and `//` (JS), so mixed repos stay readable.

---

## 8. Crypto implemented in Assembly

`kura encrypt` / `kura decrypt` use **ChaCha20-Poly1305** (RFC 8439) implemented in `crypto.asm` — compatible with the original design, no OpenSSL dependency in the hot path.

---

## 9. Dual-platform from one codebase

Windows and Linux share:

- `lexer.asm`, `kyto_eval.asm`, `crypto.asm`, `config.asm`, `emit_*.asm`

Only entry points and I/O differ:

- `kura.asm` + `win_io.asm` (Windows)
- `kura_linux.asm` + `linux_io.asm` (Linux)

---

## 10. CI builds on every push

GitHub Actions compiles kura on **Ubuntu** and **Windows** for every push to `main`. Releases publish:

- Zip archives (Windows + Linux)
- `ghcr.io/voidmute/kyto` container

---

## 11. Comparable projects (for context)

| Tool | What it does | Kyto difference |
|:-----|:-------------|:----------------|
| dotenv | `.env` files only | Kyto also emits SQL, TS, deploy |
| Helm values | K8s config | Kyto is local-first, any stack |
| Dhall / CUE | Config languages | Kyto targets app dev artifacts directly |
| Terraform | Infrastructure | Kyto focuses on app env + users + deploy exports |

Kyto sits in the **"compile my app config"** niche, not **"provision cloud resources."**

---

## 12. The binary was bootstrapped in public

The journey (visible in git history):

1. Early toolchain (including Rust) proved the design
2. Full port to NASM Assembly
3. Rust removed — Assembly-only repo
4. Linux port, crypto, CI, releases, wiki

---

## 13. Real-world usage

Projects can run Kyto in `config_only` mode to generate portal env, users, and deploy scripts from `.kyto.config`. See `examples/minimal` in the repository for a minimal working setup.

---

## 14. What's still evolving

Honest roadmap items:

- Full `emit env(build_env(...))` eval parity for random secrets merge
- `kura init --name` / `kura compile --entry` CLI flags
- Richer `.kyto` control flow in evaluator

See [Architecture](Architecture) and the [asm roadmap](https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md).

---

## 15. By the numbers

| Fact | Detail |
|:-----|:-------|
| Compiler size | ~21 KB NASM binary |
| Platforms | Windows x86-64, Linux x86-64 |
| Repo language split | ~96% Assembly on GitHub |
| One `kura compile` | `.env`, SQL, JSON, TypeScript, deploy script |
| Network at compile time | None |

Kyto is a small, self-contained toolchain aimed at teams that want one local compile step instead of maintaining parallel config in several formats.
