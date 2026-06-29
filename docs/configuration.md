# Configuration reference

Kyto projects are configured with two layers:

1. **`kyto.toml`** - project manifest (paths, emit targets, hooks)
2. **`.kyto.config`** - config-first overlay (domain, users, arbitrary env keys)

Set `config_only = true` under `[project]` to compile from `.kyto.config` alone (no `.kyto` parser).

## kyto.toml

### `[project]`

| Key | Default | Description |
|-----|---------|-------------|
| `name` | `my-project` | Project label |
| `entry` | `kyto/main.kyto` | Main `.kyto` source file (optional when `config_only = true`) |
| `config_only` | `false` | When `true`, skip `.kyto` and compile from `.kyto.config` only |

### `[config]`

| Key | Default | Description |
|-----|---------|-------------|
| `file` | `.kyto.config` | Simple config overlay path |

### `[emit.env]`

| Key | Default | Description |
|-----|---------|-------------|
| `enabled` | `true` | Write env files |
| `file` | `.env` | Output env file |
| `example` | `.env.example` | Redacted example |
| `redact_keys` | `SECRET`, `TOKEN`, ... | Substrings that trigger redaction |

### `[emit.users]`

| Key | Default | Description |
|-----|---------|-------------|
| `enabled` | `true` | Write user artifacts |
| `sql` | `generated/users.sql` | SQL seed path |
| `sql_table` | `users` | INSERT target table |
| `typescript` | `src/generated/users.ts` | TS output (`null` to skip) |
| `typescript_export` | `AUTHORIZED_USERS` | TS const name |
| `json` | `generated/users.json` | JSON name list |

### `[emit.deploy]`

| Key | Default | Description |
|-----|---------|-------------|
| `enabled` | `true` | Write deploy shell snippet |
| `script` | `scripts/generated/deploy-env.sh` | Output bash file |

### `[emit.deploy.apply_roles]` (optional)

| Key | Description |
|-----|-------------|
| `enabled` | Append `apply_user_roles()` SQL hook |
| `command` | Shell prefix before heredoc (e.g. `docker compose exec ... psql`) |
| `admin_role` | Role string for admins |
| `user_role` | Role string for everyone else |

## .kyto.config directives

```text
DOMAIN host.example.com
ADMIN admin_user
USERS user_one user_two admin_user
DATABASE_URL postgresql://user:pass@host/db
REPO_SSH git@github.com:org/repo.git
REPO_DIR /var/www/app
```

| Line | Rule |
|------|------|
| `DOMAIN host` | Sets `APP_URL=https://host` |
| `USERS a b c` | Login names (lowercased) |
| `ADMIN a` | Admin subset of `USERS` |
| `KEY value` | Any other env variable (quoted values supported) |
| `REPO_*` | Deploy map entries (`REPO_DIR` -> `export DIR=...`) |

Comments: `+` to end of line.

Full spec: [spec/kyto-lite.md](../spec/kyto-lite.md)

## Encryption

```bash
export KYTO_KEY=$(openssl rand -hex 32)
kura encrypt kyto/local.kyto -o kyto/local.kyto.enc
```

Key file alternative: `~/.config/kyto/key` (64 hex chars).
