# Kyto vs kura

People often confuse the two names. Here is the mental model.

---

## One sentence each

| | |
|:--|:--|
| **Kyto** | The **programming language** and project format (`.kyto`, `.kyto.config`, `kyto.toml`) |
| **kura** | The **compiler** — the program you run in the terminal |

---

## Analogy

| Ecosystem | Language | Compiler |
|:----------|:---------|:---------|
| Rust | Rust | `rustc` |
| Go | Go | `go` |
| C | C | `gcc` / `clang` |
| **Kyto** | **Kyto** | **`kura`** |

You say: *"I wrote this in Kyto"* and *"I compiled it with kura."*

---

## What lives where

```
Kyto project/
  kyto.toml           ← Kyto manifest (project config)
  .kyto.config        ← Kyto Lite (simple config overlay)
  kyto/main.kyto      ← Kyto source (optional advanced layer)
  generated/          ← output from kura compile
```

The **binary** on your PATH is named `kura` (after `kura install`).

Release archives are named `kyto-*-linux-x86_64.zip` because they are **Kyto project releases** that ship the **kura** compiler inside.

---

## Why two names?

- **Kyto** — the language identity (like Python, Zig, Lua)
- **kura** — short CLI name, easy to type (`kura compile` fits in muscle memory)

The compiler itself is implemented in NASM Assembly and is only ~21 KB — unusually small for a language toolchain.

---

## Commands are always `kura …`

```bash
kura init
kura compile
kura check
kura encrypt
kura decrypt
kura install
kura --version
```

There is no `kyto` binary today. The project/repo name is `kyto`; the tool name is `kura`.

---

## Releases vs Packages

| | Ships | Named |
|:--|:------|:------|
| [GitHub Releases](https://github.com/voidmute/kyto/releases) | `.zip` with `kura` / `kura.exe` | **Kyto** v0.5.1-asm |
| [GitHub Packages](https://github.com/voidmute/kyto/pkgs/container/kyto) | Docker image with `kura` entrypoint | `ghcr.io/voidmute/kyto` |

Both deliver the **kura** compiler for **Kyto** projects.
