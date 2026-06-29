# Kyto Lite

Kyto Lite is the config-first mode. Most projects only need [`.kyto.config`](../.kyto.config.example) and [`kyto.toml`](../kyto.toml).

## Daily workflow

1. Edit `.kyto.config`
2. Run `kura compile`
3. Commit generated artifacts or let CI compile

## .kyto.config syntax

```text
+ comment line
DOMAIN myapp.example.com
ADMIN alice
USERS alice bob
DATABASE_URL postgresql://localhost/app
REPO_DIR /var/www/app
ANY_KEY any value with spaces
QUOTED "value with spaces"
```

| Directive | Meaning |
|-----------|---------|
| `DOMAIN host` | Sets `APP_URL=https://host` |
| `USERS names...` | Login names (lowercased) |
| `ADMIN names...` | Admin subset of `USERS` |
| `ANYTHING else` | Env variable (uppercase key) |
| `REPO_*` | Deploy map (`REPO_DIR` -> `dir`) |

Comments use `+` to end of line.

## kyto.toml

Set `config_only = true` to skip `.kyto` files entirely.

```toml
[project]
name = "my-app"
config_only = true
```

See [docs/configuration.md](../docs/configuration.md) for emit paths.

## Optional .kyto layer

Advanced projects can add `kyto/main.kyto` for custom logic:

```kyto
+ optional advanced layer
import local from "./local.kyto"
emit env(build_env(local.secrets))
emit users(users)
emit deploy(deploy)
```

90% of projects never need this file.

## Toolchain

- **kura** — x86-64 NASM compiler (Windows PE + Linux ELF)
- Build: `./asm/build.sh` or `.\asm\build.ps1`
- Install: `kura install` copies to `~/.local/bin`
