<div align="center">

<img src="https://raw.githubusercontent.com/voidmute/kyto/main/icons/kyto.png" alt="Kyto" width="128" />

# Kyto

**Мова програмування та компілятор конфігурації з акцентом на приватність.**

Весь toolchain `kura` написаний на **NASM x86-64 Assembly** (Windows PE + Linux ELF).

<br />

### Мови

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
[![NASM](https://img.shields.io/badge/toolchain-NASM%20x86--64-111111?style=for-the-badge)](https://github.com/voidmute/kyto/blob/main/spec/asm-roadmap.md)

<br />

[**Почати**](#швидкий-старт) · [**Релізи**](https://github.com/voidmute/kyto/releases/latest) · [**Приклади**](examples/minimal)

</div>

---

## Швидкий старт

```bash
git clone https://github.com/voidmute/kyto.git && cd kyto
./asm/build.sh && ./bin/kura-asm install
kura compile
```

Windows: `.\asm\build.ps1`

Готові бінарники: **[GitHub Releases](https://github.com/voidmute/kyto/releases/latest)**.

## `.kyto.config`

Файл з `DOMAIN`, `USERS`, `ADMIN` та довільними змінними середовища. Коментарі через `+`.

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
