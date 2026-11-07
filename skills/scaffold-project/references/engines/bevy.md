# Bevy

Bevy is a Rust library, so start from [rust.md](../languages/rust.md) and apply the differences below. These recipes were run end to end with Bevy 0.19.1. Check the current version when you scaffold, because Bevy's API changes between releases.

## Init

```bash
cargo init --lib --name <name> .     # game logic
touch src/main.rs                    # thin entry point
cargo add bevy
cargo deny init
```

## Layout

```
src/lib.rs              # GamePlugin: game logic, tested without a window
src/main.rs             # thin entry point
assets/                 # art and audio, loaded by Bevy's asset server
tests/                  # integration tests (empty)
```

## Entry point

The shipped build needs a [smoke test](../project-types.md#shipped-build-smoke-test). `DefaultPlugins` needs a window and a GPU, so the flag uses `MinimalPlugins`:

```rust
fn main() {
    if std::env::args().any(|arg| arg == "--smoke-test") {
        let mut app = App::new();
        app.add_plugins((MinimalPlugins, GamePlugin));

        for _ in 0..SMOKE_TEST_FRAMES {
            app.update();
        }

        return;
    }

    App::new().add_plugins((DefaultPlugins, GamePlugin)).run();
}
```

This exercises game logic in the shipped binary, but not rendering, audio or the window. Say so in the hand-off.

## Config

Add to the `Cargo.toml` settings from [rust.md](../languages/rust.md#config):

```toml
[lints.clippy]
pedantic = { level = "warn", priority = -1 }
needless_pass_by_value = "allow"   # systems take Res<T> and Query<T> by value
type_complexity = "allow"          # queries read better inline

[profile.dev]
opt-level = 1                      # your code: fast rebuilds

[profile.dev.package."*"]
opt-level = 3                      # Bevy: playable frame rates

[profile.release]
strip = "debuginfo"                # keep symbols in the .dwp file only
```

Keep `unsafe_code = "forbid"`. Bevy's derive macros work with it.

For faster local builds, developers can run `cargo run --features bevy/dynamic_linking`. Never ship with that feature, so don't add it to `Cargo.toml` defaults.

## deny.toml

Add `MIT-0` and `CC0-1.0` to `[licenses] allow`, because Bevy's dependencies use them. Review new licences as usual.

`cargo deny check` can fail on a fresh project, because of advisories in Bevy's dependency tree. Run `cargo update` first. If one remains, report it to the user. Don't add it to `ignore` unless they agree, and give the reason in a comment, following [Handling findings](../security.md#handling-findings).

## Makefile recipes

Use the recipes in [rust.md](../languages/rust.md#makefile-recipes), except:

| Target | Recipe |
| --- | --- |
| `release` | `cargo build --release --locked && rm -rf out && mkdir -p out/release out/symbols && cp target/release/<name> out/release/ && cp target/release/<name>.dwp out/symbols/ && { [ ! -d assets ] \|\| cp -R assets out/release/; }` |
| `test-release` | `cargo test --release --locked --all-features` then `timeout 60 out/release/<name> --smoke-test` |
| `clean` | `cargo clean && rm -rf out` |

## Build profiles

Follow [build-profiles.md](../build-profiles.md) and rust.md. The game needs `assets/` next to the binary at run time, which is why `release` copies both.

**Artefacts:** `out/release/`. **Symbols:** `out/symbols/`, on Linux. Confirm the path for other platforms on the first build.

`target/` gets large. Debug, release and lint output together can pass 15 GB, so CI runners need room.

## .gitattributes

Use `gitattributes-media`. See [Binary assets](../project-types.md#binary-assets).

## devenv

Add to `{{devenv_packages}}`, with rust.md's `cargo-deny`: `pkg-config alsa-lib udev libxkbcommon wayland vulkan-loader xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXrandr`

Add `env.LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [ pkgs.vulkan-loader pkgs.libxkbcommon pkgs.wayland pkgs.alsa-lib pkgs.udev ];` to `{{devenv_languages}}`. On a machine that isn't NixOS, running the game from devenv may also need NixGL for graphics drivers.

## CI container

`ci/Containerfile`, on top of rust.md's, with this `apt-get` line:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends make git g++ pkg-config libx11-dev libasound2-dev libudev-dev libxkbcommon-x11-0 libwayland-dev libxkbcommon-dev && rm -rf /var/lib/apt/lists/*
```

Dependabot ecosystem: `cargo`, and `docker` for `/ci`.
