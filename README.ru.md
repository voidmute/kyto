<div align="center">

<img src="icons/kyto.png" alt="Логотип Kyto" width="128" />

# Kyto

**Язык программирования и компилятор конфигурации с приоритетом приватности.**

Весь инструментарий `kura` написан на **NASM x86-64 Assembly** (Windows PE + Linux ELF).

<br />

### Языки

[![English](https://img.shields.io/badge/lang-English-red?style=for-the-badge)](README.md)
[![Русский](https://img.shields.io/badge/lang-Русский-blue?style=for-the-badge)](README.ru.md)
[![Español](https://img.shields.io/badge/lang-Español-yellow?style=for-the-badge)](README.es.md)
[![Français](https://img.shields.io/badge/lang-Français-blue?style=for-the-badge)](README.fr.md)
[![Deutsch](https://img.shields.io/badge/lang-Deutsch-black?style=for-the-badge)](README.de.md)
[![中文](https://img.shields.io/badge/lang-中文-orange?style=for-the-badge)](README.zh-CN.md)
[![日本語](https://img.shields.io/badge/lang-日本語-purple?style=for-the-badge)](README.ja.md)
[![Português](https://img.shields.io/badge/lang-Português-green?style=for-the-badge)](README.pt-BR.md)
[![Українська](https://img.shields.io/badge/lang-Українська-lightblue?style=for-the-badge)](README.uk.md)

<br />

[![CI](https://img.shields.io/github/actions/workflow/status/voidmute/kyto/ci.yml?branch=main&style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/voidmute/kyto/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)
[![Assembly](https://img.shields.io/badge/toolchain-NASM%20x86--64-111?style=for-the-badge)](spec/asm-roadmap.md)
[![Version](https://img.shields.io/badge/kura-0.5.0--asm-informational?style=for-the-badge)](https://github.com/voidmute/kyto/releases)

<br />

[**Начать**](#быстрый-старт) · [**Конфигурация**](docs/configuration.md) · [**Примеры**](examples/minimal) · [**Грамматика**](spec/grammar.md)

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

## Kura CLI

| Команда | Описание |
|:--------|:---------|
| `kura init` | Создать проект |
| `kura compile` | Скомпилировать |
| `kura check` | Проверить без записи |
| `kura install` | Установить в `~/.local/bin` |
| `kura encrypt` / `decrypt` | Шифрование ChaCha20-Poly1305 |

---

## Лицензия

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
