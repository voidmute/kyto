# Language Tutorial

Learn Kyto from basics to a full compile pipeline.

> **Beginner tip:** Start with [Getting Started](Getting-Started) and `config_only = true`. Come back here when you need custom logic in `.kyto` files.

---

## Part 1 — Kyto Lite (no code)

Most projects only need [`.kyto.config`](Configuration-Guide) + `kura compile`. No `.kyto` files required.

See [Configuration Guide](Configuration-Guide) for every directive.

---

## Part 2 — Your first `.kyto` file

Create `kyto/main.kyto`:

```kyto
+ Minimal Kyto program
emit env({
  "APP_URL": "https://demo.local",
  "NODE_ENV": "development",
})
```

Set in `kyto.toml`:

```toml
[project]
config_only = false
entry = "kyto/main.kyto"
```

Run `kura compile`. The `emit env(...)` call writes your `.env` file.

---

## Part 3 — Comments

```kyto
+ This is a comment (plus at line start)
let x = 1   + inline comments also work after code on same line in some contexts
```

In `.kyto.config`, `+` comments run to end of line.

---

## Part 4 — Types and structures

```kyto
enum Role {
  Admin
  User
}

struct User {
  name: string
  role: Role
}

let users: User[] = []
```

Structs and enums define the shape of data you emit.

---

## Part 5 — Functions

```kyto
fn build_env(secrets) -> map<string, string> {
  return {
    "APP_URL": "https://" + secrets.domain,
    "SESSION_SECRET": secrets.session_secret,
  }
}
```

Functions return values used by `emit` calls.

---

## Part 6 — Imports

Split logic across files:

```kyto
import local from "./local.kyto"
```

`kyto/local.kyto` can hold secrets structs:

```kyto
struct Secrets {
  domain: string
  session_secret: string
}

let secrets = Secrets {
  domain: "demo.local",
  session_secret: "",
}
```

---

## Part 7 — The emit API

Kyto programs **do not print to stdout**. They **emit artifacts**:

| Statement | Output |
|:----------|:-------|
| `emit env(map<string,string>)` | `.env` + `.env.example` |
| `emit users(list<User>)` | SQL, JSON, TypeScript user lists |
| `emit deploy(map<string,string>)` | Bash export script |

Full program example (from `examples/minimal`):

```kyto
import local from "./local.kyto"

enum Role { Admin User }

struct User {
  name: string
  role: Role
}

let users: User[] = []

fn build_env(secrets) -> map<string, string> {
  let secret = secrets.session_secret
  if secret == "" {
    secret = random_base64(32)
  }
  return {
    "APP_URL": "https://" + secrets.domain,
    "SESSION_SECRET": secret,
    "NODE_ENV": "development",
  }
}

let deploy = { repo_dir: "." }

emit env(build_env(local.secrets))
emit users(users)
emit deploy(deploy)
```

---

## Part 8 — Built-in functions

| Function | Description |
|:---------|:------------|
| `random_base64(n)` | Cryptographically useful random string (length `n`) |
| `len(x)` | Length of string, list, or map |
| `require(cond, msg)` | Stop compile with error if condition is false |

Example:

```kyto
require(len(secrets.domain) > 0, "domain must not be empty")
```

---

## Part 9 — Control flow

```kyto
if secret == "" {
  secret = random_base64(32)
} else {
  + keep existing
}

for user in users {
  + loop body (evaluator support evolving)
}
```

---

## Part 10 — Keywords reference

```
let  fn  struct  enum  import
if  else  for  in  return
emit  true  false
```

Full grammar: https://github.com/voidmute/kyto/blob/main/spec/grammar.md

---

## Part 11 — Config + code together

The power move: `.kyto.config` for daily edits, `.kyto` for logic.

1. Users and domain live in `.kyto.config` (ops-friendly)
2. `kyto/main.kyto` merges them into env maps and deploy scripts
3. `kura compile` produces everything

Set `config_only = false` in `kyto.toml` when using both layers.

---

## Part 12 — Check before ship

```bash
kura check     # parse + evaluate, no file writes
kura compile   # write all artifacts
```

Use `kura check` in CI before deploy.

---

## Common mistakes

| Mistake | Fix |
|:--------|:----|
| Empty `.env` after compile | Set `config_only` correctly; ensure `.kyto.config` exists |
| Users not in SQL output | Define `USERS` in `.kyto.config` or populate `users` in `.kyto` |
| Secrets in git | Gitignore `.env` and `.kyto.config`; commit `.env.example` only |
| `kura: command not found` | Run `kura install` or add `bin/` to PATH |

---

## Next steps

- [Configuration Guide](Configuration-Guide) — every `kyto.toml` key
- [Encryption & Privacy](Encryption-and-Privacy) — protect `local.kyto`
- [Architecture](Architecture) — how the evaluator works inside kura
