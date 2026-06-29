<p align="center">
  <img src="icons/kyto.png" alt="Kyto" width="96" />
</p>

<h1 align="center">Kyto</h1>

<p align="center">
  <strong>Privacy-first config language for any project.</strong><br />
  Compile <code>.kyto</code> sources with <code>kura</code> - the Kyto toolchain.
</p>

<p align="center">
  <a href="https://github.com/voidmute/kyto/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/voidmute/kyto/ci.yml?branch=main&style=flat-square" alt="CI" /></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="License" /></a>
  <a href="https://www.rust-lang.org"><img src="https://img.shields.io/badge/rust-stable-orange?style=flat-square" alt="Rust" /></a>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> -
  <a href="#kyto-config">.kyto.config</a> -
  <a href="#kyto-toml">kyto.toml</a> -
  <a href="#kura-cli">Kura CLI</a> -
  <a href="docs/configuration.md">Configuration</a> -
  <a href="spec/grammar.md">Language</a>
</p>

---

## Why Kyto

| Problem | Kyto approach |
|---------|---------------|
| Users copied across SQL, TS, and shell | One compile step emits all artifacts |
| Secrets in git | Layered config + optional encryption |
| Heavy DSLs | Simple `.kyto.config` for everyday edits |
| Vendor lock-in to one stack | `kyto.toml` configures every output path |

Kyto is **local-only**: no network, no telemetry, no cloud dependency.

## Quick start

```bash
git clone https://github.com/voidmute/kyto.git
cd kyto
cargo build --release
./target/release/kura install
```

Scaffold a new project:

```bash
mkdir my-app && cd my-app
kura init --name my-app
cp .kyto.config.example .kyto.config
kura compile
```

## .kyto.config

Human-friendly overlay for domain and users. Comments use `+`.

```text
+ Production portal
DOMAIN app.example.com
ADMIN alice
USERS alice bob carol
```

- Names are case-insensitive (`BOB` becomes `bob`)
- `ADMIN` must be listed in `USERS`
- Run `kura compile` after every change

## kyto.toml

Project manifest - customize every emit target for **your** stack:

```toml
[project]
name = "my-app"
entry = "kyto/main.kyto"

[config]
file = ".kyto.config"

[emit.env]
file = ".env"
example = ".env.example"
redact_keys = ["SECRET", "TOKEN", "PASSWORD"]

[emit.users]
sql = "db/seed-users.sql"
sql_table = "users"
typescript = "src/config/users.ts"
typescript_export = "AUTHORIZED_USERS"
json = "generated/users.json"

[emit.deploy]
script = "scripts/generated/deploy-env.sh"

[emit.deploy.apply_roles]
enabled = true
command = "docker compose exec -T postgres psql -U app -d app"
admin_role = "ADMIN"
user_role = "USER"
```

Disable any emit block with `enabled = false`.

## Kura CLI

| Command | Description |
|---------|-------------|
| `kura init` | Create `kyto.toml`, `.kyto.config.example`, `kyto/main.kyto` |
| `kura compile` | Compile entry file and write artifacts |
| `kura check` | Parse and evaluate without writing files |
| `kura install` | Copy `kura` to `~/.local/bin` and update PATH |
| `kura encrypt` | Encrypt a secrets `.kyto` file |
| `kura decrypt` | Decrypt an encrypted file |

Entry resolution order:

1. `--entry` flag
2. `[project].entry` in `kyto.toml`
3. `kyto/main.kyto`

## Language snapshot

```kyto
import local from "./local.kyto"

fn build_env(secrets) -> map<string, string> {
  return {
    "APP_URL": "https://" + secrets.domain,
    "SESSION_SECRET": secrets.session_secret,
  }
}

emit env(build_env(local.secrets))
emit users(users)
emit deploy(deploy)
```

Comments in `.kyto` files: `+` at the beginning of a line.

Full reference: [spec/grammar.md](spec/grammar.md)

## Examples

| Example | Path | Description |
|---------|------|-------------|
| Minimal | [examples/minimal](examples/minimal) | Smallest working project |

```bash
cd examples/minimal
kura compile
```

## Privacy

- `portal.local.kyto` style secrets stay gitignored
- `kura encrypt` uses XChaCha20-Poly1305
- Key from `KYTO_KEY` env or `~/.config/kyto/key`

## Install scripts

```powershell
# Windows
.\scripts\install-kura.ps1
```

```bash
# Linux / macOS
./scripts/install-kura.sh
```

## Contributing

Issues and pull requests welcome. See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

[MIT](LICENSE) - voidmute
