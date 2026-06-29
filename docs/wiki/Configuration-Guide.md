# Configuration Guide

Complete reference for `kyto.toml` and `.kyto.config`.

---

## Two-layer model

```
kyto.toml          → WHERE outputs go (paths, toggles)
.kyto.config       → WHAT the values are (domain, users, env)
kyto/*.kyto        → HOW to transform (optional code)
```

---

## `kyto.toml`

### `[project]`

| Key | Default | Description |
|:----|:--------|:------------|
| `name` | `my-project` | Project label |
| `entry` | `kyto/main.kyto` | Main `.kyto` source |
| `config_only` | `false` | `true` = skip `.kyto`, compile from config only |

**Recommended for new projects:**

```toml
[project]
name = "my-app"
config_only = true
```

### `[config]`

| Key | Default | Description |
|:----|:--------|:------------|
| `file` | `.kyto.config` | Path to simple config overlay |

### `[emit.env]`

| Key | Default | Description |
|:----|:--------|:------------|
| `enabled` | `true` | Write env files |
| `file` | `.env` | Output env file |
| `example` | `.env.example` | Redacted example for git |
| `redact_keys` | `SECRET`, `TOKEN`, … | Substrings that trigger redaction in `.env.example` |

### `[emit.users]`

| Key | Default | Description |
|:----|:--------|:------------|
| `enabled` | `true` | Write user artifacts |
| `sql` | `generated/users.sql` | SQL seed path |
| `sql_table` | `users` | INSERT target table |
| `typescript` | `src/generated/users.ts` | TS output (`null` to skip) |
| `typescript_export` | `AUTHORIZED_USERS` | Exported const name |
| `json` | `generated/users.json` | JSON name list |

### `[emit.deploy]`

| Key | Default | Description |
|:----|:--------|:------------|
| `enabled` | `true` | Write deploy shell snippet |
| `script` | `scripts/generated/deploy-env.sh` | Output bash file |

### `[emit.deploy.apply_roles]` (optional)

| Key | Description |
|:----|:------------|
| `enabled` | Append `apply_user_roles()` SQL hook |
| `command` | Shell prefix before heredoc |
| `admin_role` | Role string for admins |
| `user_role` | Role string for non-admins |

---

## `.kyto.config` syntax

```text
+ Comment to end of line
DOMAIN host.example.com
ADMIN alice
USERS alice bob carol
DATABASE_URL postgresql://user:pass@host/db
REPO_SSH git@github.com:org/repo.git
REPO_DIR /var/www/app
CUSTOM_KEY any value with spaces
QUOTED "value with spaces"
```

### Directive rules

| Line pattern | Compiler behavior |
|:-------------|:------------------|
| `DOMAIN host` | Sets `APP_URL=https://host` |
| `USERS a b c` | Login names (lowercased) |
| `ADMIN a` | Admin subset of `USERS` |
| `KEY value` | Arbitrary env variable |
| `REPO_*` | Deploy map (`REPO_DIR` → export in deploy script) |
| `+ ...` | Comment (ignored) |

### Quoted values

```text
API_KEY "sk-live-abc 123"
```

Quotes are stripped; inner spaces preserved.

---

## Full example manifest

```toml
[project]
name = "cloud-portal"
config_only = true

[config]
file = ".kyto.config"

[emit.env]
file = ".env"
example = ".env.example"
redact_keys = ["SECRET", "TOKEN", "PASSWORD", "KEY"]

[emit.users]
sql = "generated/seed.sql"
json = "generated/users.json"
typescript = "src/generated/users.ts"
typescript_export = "AUTHORIZED_USERS"
sql_table = "users"

[emit.deploy]
script = "generated/deploy-env.sh"
```

---

## `.gitignore` recommendations

```gitignore
.env
.kyto.config
kyto/local.kyto
kyto/local.kyto.enc
generated/
```

**Safe to commit:** `kyto.toml`, `.kyto.config.example`, `.env.example`, `generated/*.example`

---

## CI pattern

```yaml
- run: kura check
- run: kura compile
- run: git diff --exit-code generated/
```

Fails CI if someone forgot to recompile after config changes.

---

## See also

- [Getting Started](Getting-Started)
- [Language Tutorial](Language-Tutorial)
- [Repo: docs/configuration.md](https://github.com/voidmute/kyto/blob/main/docs/configuration.md)
