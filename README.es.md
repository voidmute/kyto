<div align="center">

<img src="icons/kyto.png" alt="Kyto" width="128" />

# Kyto

**Lenguaje de programación y compilador de configuración centrado en la privacidad.**

Todo el toolchain `kura` está escrito en **NASM x86-64 Assembly**.

<br />

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

[![CI](https://img.shields.io/github/actions/workflow/status/voidmute/kyto/ci.yml?branch=main&style=for-the-badge)](https://github.com/voidmute/kyto/actions/workflows/ci.yml)
[![License MIT](https://img.shields.io/badge/license-MIT-blue?style=for-the-badge)](LICENSE)

<br />

[**Empezar**](#inicio-rápido) · [**Documentación**](docs/configuration.md) · [**Ejemplos**](examples/minimal)

</div>

---

## Inicio rápido

```bash
git clone https://github.com/voidmute/kyto.git && cd kyto
./asm/build.sh          # Linux
./bin/kura-asm install
kura compile
```

Windows: `.\asm\build.ps1` y `.\bin\kura-asm.exe install`

## `.kyto.config`

Archivo simple con `DOMAIN`, `USERS`, `ADMIN` y variables de entorno. Comentarios con `+`.

## CLI

`init` · `compile` · `check` · `install` · `encrypt` · `decrypt`

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
