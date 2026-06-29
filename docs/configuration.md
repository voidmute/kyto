# Configuration reference

Kyto projects are configured with two layers:

1. **`kyto.toml`** - project manifest (paths, emit targets, hooks)
2. **`.kyto.config`** - simple user/domain overlay

## kyto.toml

### `[project]`

| Key | Default | Description |
|-----|---------|-------------|
| `name` | `my-project` | Project label |
| `entry` | `kyto/main.kyto` | Main `.kyto` source file |

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
```

Comments: `+` to end of line.

## Encryption

```bash
export KYTO_KEY=$(openssl rand -hex 32)
kura encrypt kyto/local.kyto -o kyto/local.kyto.enc
```

Key file alternative: `~/.config/kyto/key` (64 hex chars).
