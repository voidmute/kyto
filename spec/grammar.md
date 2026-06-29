# Kyto grammar

See [docs/configuration.md](../docs/configuration.md) for project setup.

## Comments

- `.kyto` sources: `+` at line start
- `.kyto.config`: `+` to end of line

## Keywords

`let`, `fn`, `struct`, `enum`, `import`, `if`, `else`, `for`, `in`, `return`, `emit`, `true`, `false`

## Emit API

```
emit env(map<string, string>)
emit users(list<User>)
emit deploy(map<string, string>)
```

## Built-ins

| Function | Description |
|----------|-------------|
| `random_base64(n)` | Random base64 string |
| `len(x)` | Length of string, list, or map |
| `require(cond, msg)` | Abort compile if false |
