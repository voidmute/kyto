<div align="center">

<img src="icons/kyto.png" alt="Kyto" width="128" />

# Kyto

**Мова програмування та компілятор конфігурації з акцентом на приватність.**

Весь toolchain `kura` написаний на **NASM x86-64 Assembly**.

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

[**Почати**](docs/configuration.md) · [**Приклади**](examples/minimal)

</div>

---

## Швидкий старт

```bash
git clone https://github.com/voidmute/kyto.git && cd kyto
./asm/build.sh && ./bin/kura-asm install
kura compile
```

Windows: `.\asm\build.ps1`

## `.kyto.config`

Файл з `DOMAIN`, `USERS`, `ADMIN` та довільними змінними середовища. Коментарі через `+`.

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
