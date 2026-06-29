<div align="center">

<img src="icons/kyto.png" alt="Kyto" width="128" />

# Kyto

**注重隐私的编程语言与配置编译器。**

整个 `kura` 工具链使用 **NASM x86-64 汇编** 编写。

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

[**快速开始**](#快速开始) · [**文档**](docs/configuration.md) · [**示例**](examples/minimal)

</div>

---

## 快速开始

```bash
git clone https://github.com/voidmute/kyto.git && cd kyto
./asm/build.sh && ./bin/kura-asm install
kura compile
```

## `.kyto.config`

使用 `DOMAIN`、`USERS`、`ADMIN` 和任意环境变量。`+` 开头为注释。

## 命令

`init` · `compile` · `check` · `install` · `encrypt` · `decrypt`

[MIT](LICENSE) © [voidmute](https://github.com/voidmute)
