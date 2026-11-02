# Rust

Tooling: **cargo** · **rustfmt** · **clippy** (`-D warnings`) · **cargo test** · **cargo-deny** (RustSec advisories, licenses, bans, sources; this covers what cargo-audit checks). The toolchain is pinned in `rust-toolchain.toml`.

## Init

```bash
cargo init --bin --name <name> .     # CLI / service
cargo init --lib --name <name> .     # library
cargo deny init                      # deny.toml, then edit as below
```

## Layout

```
src/main.rs  (bin)  or  src/lib.rs  (lib)
tests/                    # integration tests (empty)
Cargo.toml  Cargo.lock  rust-toolchain.toml  deny.toml
```

- **CLI:** `cargo add clap --features derive`. Keep `main.rs` thin and put the logic in `src/lib.rs`, so it can be tested.
- **Library:** fill in `[package]` metadata (`description`, `license`, `repository`, `readme`, `keywords`, `rust-version`).
- **Service:** `cargo add axum tokio --features tokio/full` and `cargo add tracing tracing-subscriber`. Config comes from the environment. Add `.env.example`.

## Config

`rust-toolchain.toml`:
```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
```

Append to `Cargo.toml`:
```toml
[lints.rust]
unsafe_code = "forbid"

[lints.clippy]
pedantic = { level = "warn", priority = -1 }
```

`deny.toml`: keep the generated file. Set `[licenses] allow` to the project's license plus common permissive ones (`MIT`, `Apache-2.0`, `BSD-2-Clause`, `BSD-3-Clause`, `ISC`, `Unicode-3.0`, `Zlib`). Set `[advisories]` to deny vulnerabilities and `[bans] multiple-versions = "warn"`.

## Makefile recipes

| Target | Recipe |
| --- | --- |
| `setup` | `cargo fetch` |
| `build` | `cargo build --all-targets` |
| `fmt` | `cargo fmt --all` |
| `fmt-check` | `cargo fmt --all -- --check` |
| `lint` | `cargo clippy --all-targets --all-features -- -D warnings` |
| `test` | `cargo test --all-features` (passes with zero tests) |
| `security-deps` | `cargo deny check` |
| `clean` | `cargo clean` |

Each recipe goes tab-indented under its target.

## .gitignore

`/target .env`. Commit `Cargo.lock` for binaries and libraries alike (current Cargo guidance).

## Pre-commit local hook

```yaml
      - id: lint
        name: rustfmt + clippy
        entry: make lint
        language: system
        pass_filenames: false
        types: [rust]
```

## CI setup steps

```yaml
      - uses: dtolnay/rust-toolchain@stable     # branch-based action; pin to a commit SHA
        with:
          components: rustfmt, clippy
      - uses: Swatinem/rust-cache@<sha> # vX
      - uses: taiki-e/install-action@<sha> # vX
        with:
          tool: cargo-deny
```

Dependabot ecosystem: `cargo`. Docker ignore extras: `target`.

## Dockerfile (service)

```dockerfile
FROM rust:1-slim-bookworm AS build
WORKDIR /src
COPY . .
RUN cargo build --release --locked

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=build /src/target/release/<name> /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```
