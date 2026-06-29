# Welcome to Kyto

<img src="https://raw.githubusercontent.com/voidmute/kyto/main/icons/kyto.png" alt="Kyto" width="96" />

**Kyto** is a privacy-first programming language for compiling project configuration into real artifacts — `.env` files, SQL seeds, TypeScript constants, JSON user lists, and deploy scripts — in **one local step**.

**kura** is the Kyto compiler (`kura compile`, `kura check`, …). It is written entirely in **NASM x86-64 Assembly** (~21 KB binary, no Rust/C runtime).

---

## Start here

| Goal | Page |
|:-----|:-----|
| Install kura and run a first compile | [Getting Started](Getting-Started) |
| Understand Kyto vs kura | [Kyto vs kura](Kyto-vs-Kura) |
| Learn the full language | [Language Tutorial](Language-Tutorial) |
| Configure a real project | [Configuration Guide](Configuration-Guide) |
| Use every CLI command | [Kura CLI Reference](Kura-CLI-Reference) |
| Download binaries or Docker | [Installing Kyto](Installing-Kyto) |
| Project highlights and technical facts | [Interesting Facts](Interesting-Facts) |
| See how the compiler is built | [Architecture](Architecture) |
| Encrypt secrets locally | [Encryption & Privacy](Encryption-and-Privacy) |
| Get quick answers | [FAQ](FAQ) |

---

## The 30-second pitch

Most teams duplicate the same data in five places:

- `.env` for the app
- SQL seed for users
- TypeScript for frontend auth lists
- Bash for deploy exports
- A secrets file nobody wants in git

**Kyto fixes that.** Teams edit `.kyto.config` (or `.kyto` for advanced logic), run `kura compile`, and get every artifact from one source of truth — **locally**, with **no cloud**, **no telemetry**.

---

## Quick example

`.kyto.config`:

```text
+ My app
DOMAIN app.example.com
ADMIN alice
USERS alice bob carol
DATABASE_URL postgresql://localhost/mydb
```

```bash
kura compile
```

**Output:** `.env`, `.env.example`, `generated/users.sql`, `generated/users.json`, `generated/deploy-env.sh` — paths controlled by `kyto.toml`.

---

## Project links

- **Repository:** https://github.com/voidmute/kyto
- **Releases:** https://github.com/voidmute/kyto/releases
- **Container package:** https://github.com/voidmute/kyto/pkgs/container/kyto
- **Grammar spec:** https://github.com/voidmute/kyto/blob/main/spec/grammar.md
- **Roadmap:** https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md

---

## License

MIT © [voidmute](https://github.com/voidmute)
