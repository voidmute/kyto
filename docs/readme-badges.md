# README badge block (maintainers)

Use **absolute** URLs so badges and the logo render on every GitHub file view (no broken images).

- Logo: `https://raw.githubusercontent.com/voidmute/kyto/main/icons/kyto.png`
- Language links: `https://github.com/voidmute/kyto/blob/main/README.<lang>.md`
- Ukrainian badge color: `55ACEE` (hex — `lightblue` is invalid on shields.io and shows a red X)
- Japanese badge color: `9B59B6` (hex — safer than named `purple`)

Releases workflow: `.github/workflows/release.yml` (tag `v*` or manual dispatch).

- **Kyto** = language / project name on releases and packages
- **kura** = compiler CLI inside release zips and container (`ENTRYPOINT kura`)
- Container package: `ghcr.io/voidmute/kyto` → repo **Packages** tab
- Release archives: `kyto-*-linux-x86_64.zip`, `kyto-*-windows-x86_64.zip`
