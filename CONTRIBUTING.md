# Contributing

Thanks for helping improve Kyto.

## Development

```bash
cargo test --workspace
cargo build --release
```

## Pull requests

1. Fork the repo
2. Create a feature branch
3. Add tests for behavior changes
4. Run `cargo test` and `cargo fmt`
5. Open a PR with a clear summary

## Style

- Use `-` in prose, not em dashes
- Keep `.kyto.config` simple for end users
- Prefer configurable `kyto.toml` over hardcoded emit paths
