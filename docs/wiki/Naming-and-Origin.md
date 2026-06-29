# Naming & Origin

Why the project is called **Kyto** and why the compiler is called **kura**.

---

## The short version

| Name | Role | Idea |
|:-----|:-----|:-----|
| **Kyto** | The programming language | A short, ownable name for the language and its files (`.kyto`, `kyto.toml`) |
| **kura** | The compiler CLI | From Japanese **蔵** (*kura*) — a **storehouse** or **vault**; local, private, under your control |

The language is **Kyto**. The program that compiles it is **kura** — like Rust and `rustc`, but with a name that reflects where config and secrets are meant to live.

---

## Kyto — the language name

**Kyto** was chosen as the public name for the language and project format.

Design goals for the name:

- **Short** — easy to type in repos, docs, and file extensions
- **Distinct** — unlikely to collide with common package names or CLI tools
- **Neutral** — reads clearly in terminals and URLs (`voidmute/kyto`)
- **File-native** — natural extensions: `.kyto`, `.kyto.config`, `kyto.toml`, `kyto/main.kyto`

Kyto is what a repository is "written in." Releases, documentation, and the GitHub project use the **Kyto** name because they describe the language and ecosystem—not a single binary.

---

## kura — the compiler name

**kura** is the compiler: the tool invoked as `kura compile`, `kura check`, `kura encrypt`, and so on.

The name comes from Japanese **蔵** (*kura*), meaning **storehouse** or **vault**—a place where valuable things are kept **locally**, not broadcast or outsourced. That fits the toolchain's core ideas:

| Concept | How kura fits |
|:--------|:--------------|
| Privacy-first | Compilation stays on the machine; no network, no telemetry |
| Secrets | Optional `encrypt` / `decrypt`; keys in `KYTO_KEY` or `~/.config/kyto/key` |
| Config as treasure | `.kyto.config` and `.kyto` sources are the canonical store; `kura compile` unlocks and distributes artifacts |
| Local-only | The vault does not phone home |

So **kura** is not just a random CLI name—it is the **vault keeper**: it reads what is stored in a Kyto project and produces `.env`, SQL, TypeScript, JSON, and deploy scripts without sending data elsewhere.

---

## Why two names instead of one?

Mature language ecosystems separate **language identity** from **compiler binary**:

| Language | Compiler |
|:---------|:---------|
| Rust | `rustc` |
| Go | `go` |
| Haskell | `ghc` |
| **Kyto** | **`kura`** |

Practical reasons:

1. **GitHub releases** are labeled **Kyto** (the project); the zip contains the **kura** binary.
2. **PATH** stays short: `kura compile` is faster to type than `kyto-compile`.
3. **Mental model** stays clear: "Kyto project, compiled with kura."

There is no `kyto` executable today—only **kura**.

---

## How the names work together

```
Kyto project/                 ← language & layout
  kyto.toml
  .kyto.config
  kyto/main.kyto
        │
        ▼
   kura compile               ← vault keeper reads & emits
        │
        ▼
  .env, generated/*.sql, …   ← artifacts leave the vault in controlled form
```

---

## Pronunciation

| Name | Suggestion |
|:-----|:-----------|
| **Kyto** | *KY-toh* — two syllables, stress on the first |
| **kura** | *KOO-rah* — as in Japanese 蔵 |

Exact pronunciation is flexible; consistency within a team matters more than one "correct" accent.

---

## Related pages

- [Kyto vs kura](Kyto-vs-Kura) — quick comparison table
- [kura commands](Kura-Commands) — full command list
- [Interesting Facts](Interesting-Facts) — technical highlights

---

## Credits

Naming and design intent documented by [voidmute](https://github.com/voidmute), creator of the Kyto project.
