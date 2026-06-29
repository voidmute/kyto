# Getting Started

This tutorial takes you from **zero** to a working Kyto project in about 10 minutes.

---

## Step 0: What you are installing

| Name | What it is |
|:-----|:-----------|
| **Kyto** | The language and project format |
| **kura** | The compiler binary you run in the terminal |

You do **not** install "Kyto" as a separate program — you install **kura**, which compiles Kyto projects.

---

## Step 1: Install kura

Pick one method.

### Option A — GitHub Release (fastest)

1. Open [Releases](https://github.com/voidmute/kyto/releases/latest)
2. Download:
   - Windows: `kyto-*-windows-x86_64.zip` → contains `kura.exe`
   - Linux: `kyto-*-linux-x86_64.zip` → contains `kura`
3. Run `kura install` (or `kura.exe install` on Windows) to copy into `~/.local/bin`

### Option B — Docker (Linux)

```bash
docker pull ghcr.io/voidmute/kyto:latest
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest --version
```

### Option C — Build from source

```bash
git clone https://github.com/voidmute/kyto.git
cd kyto
./asm/build.sh          # Linux (needs nasm)
# or .\asm\build.ps1    # Windows
./bin/kura-asm install
```

Verify:

```bash
kura --version
# kura 0.5.0-asm
```

---

## Step 2: Create a project

```bash
mkdir my-portal && cd my-portal
kura init --name my-portal
cp .kyto.config.example .kyto.config
```

You now have:

```
my-portal/
  kyto.toml
  .kyto.config.example
  .kyto.config          ← you create this
  kyto/main.kyto        ← optional advanced layer
```

---

## Step 3: Edit `.kyto.config`

This is the **human-friendly** file you edit daily. Comments start with `+`.

```text
+ Production portal
DOMAIN portal.example.com
ADMIN alice
USERS alice bob guest
DATABASE_URL postgresql://localhost/portal
REPO_DIR /var/www/portal
NODE_ENV production
```

**Rules:**

- `DOMAIN host` → compiler sets `APP_URL=https://host`
- `USERS` / `ADMIN` → login names (lowercased automatically)
- Any other `KEY value` → becomes an environment variable
- `REPO_*` keys → deploy script exports

---

## Step 4: Configure output paths (`kyto.toml`)

Default manifest:

```toml
[project]
name = "my-portal"
config_only = true    # ← recommended for beginners: skip .kyto files

[config]
file = ".kyto.config"

[emit.env]
file = ".env"
example = ".env.example"

[emit.users]
sql = "generated/users.sql"
json = "generated/users.json"
typescript = "generated/users.ts"

[emit.deploy]
script = "generated/deploy-env.sh"
```

Set `config_only = true` if you only use `.kyto.config` — **90% of projects never need `.kyto` source files.**

---

## Step 5: Compile

```bash
kura compile
```

**Generated files** (paths from `kyto.toml`):

| File | Contents |
|:-----|:---------|
| `.env` | Full secrets for local dev |
| `.env.example` | Redacted template safe for git |
| `generated/users.sql` | `INSERT INTO users ...` |
| `generated/users.json` | `["alice","bob","guest"]` |
| `generated/users.ts` | `export const APP_USERS = [...]` |
| `generated/deploy-env.sh` | `export KEY=value` for servers |

Check without writing:

```bash
kura check
```

---

## Step 6: Try the minimal example

```bash
git clone https://github.com/voidmute/kyto.git
cd kyto/examples/minimal
kura compile
ls generated/
```

---

## Step 7: Add to `.gitignore`

```gitignore
.env
.kyto.config
kyto/local.kyto
generated/
```

Commit `.env.example` and your `kyto.toml` — **never** commit real secrets.

---

## What next?

| Goal | Page |
|:-----|:-----|
| Write custom compile logic | [Language Tutorial](Language-Tutorial) |
| Every `kyto.toml` key | [Configuration Guide](Configuration-Guide) |
| Encrypt a secrets file | [Encryption & Privacy](Encryption-and-Privacy) |
| How kura is built in ASM | [Interesting Facts](Interesting-Facts) |

---

## Daily workflow (Kyto Lite)

```
edit .kyto.config  →  kura compile  →  commit generated/ or let CI compile
```

That is the entire loop. No cloud dashboard. No vendor lock-in.
