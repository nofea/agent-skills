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

[profile.release]
overflow-checks = true           # the release default is false, so integers would wrap silently
debug = "line-tables-only"       # enough for readable crash reports
split-debuginfo = "packed"       # keeps those symbols out of the binary
```

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- `debug-assertions` stays off in release, so `debug_assert!` is for internal invariants only. Use a normal check that returns an error, or `assert!`, for anything security-related.
- `cargo test --release` uses the `release` profile, so it tests the shipped settings. The plain `test` profile inherits from `dev`.
- **Artefacts:** `target/release/<name>`. **Symbols:** the `.dwp` file beside it on Linux. Confirm the path on the first build, because it varies by platform.

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
| `release` | `cargo build --release --locked` |
| `test-release` | `cargo test --release --locked --all-features` |
| `security-deps` | `cargo deny check` |
| `clean` | `cargo clean` |

Each recipe goes tab-indented under its target.

## .gitignore

`.devenv*/ devenv.local.nix /target .env`. Commit `Cargo.lock` for binaries and libraries alike (current Cargo guidance).

## Pre-commit local hook

```yaml
      - id: lint
        name: rustfmt + clippy
        entry: make lint
        language: system
        pass_filenames: false
        types: [rust]
```

## devenv

`{{devenv_languages}}`:
```nix
  languages.rust.enable = true;
```

`{{devenv_packages}}`: `cargo-deny`

## CI container

`ci/Containerfile`:
```dockerfile
FROM docker.io/library/rust:1-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends make git && rm -rf /var/lib/apt/lists/*
RUN rustup component add rustfmt clippy
RUN cargo install --locked cargo-deny --version <version>    # slow: see "CI image speed" in security.md
ENV HOME=/tmp CARGO_HOME=/tmp/cargo
USER 65532:65532
```

Replace each `<version>` with the latest release. devenv's toolchain comes from nixpkgs and ignores `rust-toolchain.toml`. The CI container uses the toolchain file, so that's the version that counts.

Dependabot ecosystem: `cargo`, and `docker` for `/ci`. Docker ignore extras: `target`.

## Dockerfile (service)

```dockerfile
FROM docker.io/library/rust:1-slim-bookworm AS build
WORKDIR /src
COPY . .
RUN cargo build --release --locked

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=build /src/target/release/<name> /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```
