<div align="center">

<img src="https://raw.githubusercontent.com/voidmute/kyto/main/icons/kyto.png" alt="Логотип Kyto" width="128" />

# Kyto

**Язык программирования и компилятор конфигурации с приоритетом приватности.**

Весь компилятор **kura** (CLI Kyto) написан на **NASM x86-64 Assembly** (Windows PE + Linux ELF).

<br />

### Языки

[![English](https://img.shields.io/badge/lang-English-red?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.md)
[![Русский](https://img.shields.io/badge/lang-Русский-blue?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.ru.md)
[![Español](https://img.shields.io/badge/lang-Español-yellow?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.es.md)
[![Français](https://img.shields.io/badge/lang-Français-blue?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.fr.md)
[![Deutsch](https://img.shields.io/badge/lang-Deutsch-black?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.de.md)
[![中文](https://img.shields.io/badge/lang-中文-orange?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.zh-CN.md)
[![日本語](https://img.shields.io/badge/lang-日本語-9B59B6?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.ja.md)
[![Português](https://img.shields.io/badge/lang-Português-green?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.pt-BR.md)
[![Українська](https://img.shields.io/badge/lang-Українська-55ACEE?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/README.uk.md)

<br />

[![CI](https://img.shields.io/github/actions/workflow/status/voidmute/kyto/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white&label=CI)](https://github.com/voidmute/kyto/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/LICENSE)
[![Release](https://img.shields.io/github/v/release/voidmute/kyto?style=for-the-badge&logo=github&label=release)](https://github.com/voidmute/kyto/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/voidmute/kyto/total?style=for-the-badge&color=2481D7&label=downloads)](https://github.com/voidmute/kyto/releases)
[![Package](https://img.shields.io/badge/container-ghcr.io-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://github.com/voidmute/kyto/pkgs/container/kyto)
[![NASM](https://img.shields.io/badge/toolchain-NASM%20x86--64-111111?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md)

<br />

[**Начать**](#быстрый-старт) · [**Релизы**](#релизы) · [**Конфигурация**](docs/configuration.md) · [**Примеры**](examples/minimal) · [**Грамматика**](spec/grammar.md)

</div>

---

## Зачем Kyto

| Проблема | Решение Kyto |
|:---------|:-------------|
| Пользователи дублируются в SQL, TS и shell | Одна компиляция — все артефакты |
| Секреты в git | Слои конфигурации + шифрование |
| Тяжёлые DSL | Простой `.kyto.config` |
| Привязка к стеку | Пути вывода в `kyto.toml` |

Kyto работает **только локально**: без сети, телеметрии и облака.

---

## Быстрый старт

### Windows

```powershell
git clone https://github.com/voidmute/kyto.git
cd kyto
.\asm\build.ps1
.\bin\kura-asm.exe install
```

### Linux

```bash
git clone https://github.com/voidmute/kyto.git
cd kyto
sudo apt install nasm
./asm/build.sh
./bin/kura-asm install
export PATH="$HOME/.local/bin:$PATH"
```

### Новый проект

```bash
kura init --name my-app
cp .kyto.config.example .kyto.config
kura compile
```

---

## Релизы

Релизы **Kyto** включают компилятор **kura**. Архивы — на **[GitHub Releases](https://github.com/voidmute/kyto/releases/latest)**.

| Платформа | Архив | Бинарник |
|:----------|:------|:---------|
| Windows x86-64 | `kyto-*-windows-x86_64.zip` | `kura.exe` |
| Linux x86-64 | `kyto-*-linux-x86_64.zip` | `kura` |

**Пакет (Docker):** [ghcr.io/voidmute/kyto](https://github.com/voidmute/kyto/pkgs/container/kyto)

```bash
docker pull ghcr.io/voidmute/kyto:latest
docker run --rm -v "$PWD:/work" -w /work ghcr.io/voidmute/kyto:latest compile
```

---

## `.kyto.config`

```text
+ Продакшен
DOMAIN app.example.com
ADMIN alice
USERS alice bob
DATABASE_URL postgresql://localhost/app
```

Комментарии — строки с `+`. Подробнее: [spec/kyto-lite.md](spec/kyto-lite.md)

---

## Kura — компилятор Kyto

| Команда | Описание |
|:--------|:---------|
| `kura init` | Создать проект (в каждом файле: **Kyto was here**) |
| `kura compile` | Скомпилировать |
| `kura check` | Проверить без записи |
| `kura install` | Установить в `~/.local/bin` |
| `kura encrypt` / `decrypt` | Шифрование ChaCha20-Poly1305 |

---

## Лицензия

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
