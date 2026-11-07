# Godot

Tooling: **Godot 4** · **gdtoolkit** (gdformat, gdlint) · **GUT** for tests. The project also uses C# only if the user asks. Godot runs in devenv and in the CI container, so nothing is host-only. These recipes were run end to end with Godot 4.7.2, GUT 9.7.1 and gdtoolkit 4.x. Check the current versions when you scaffold.

## Init

There's no init command. Write these by hand:

`project.godot`:
```ini
config_version=5

[application]

config/name="<name>"
config/version="0.1.0"
run/main_scene="res://scenes/main.tscn"
config/features=PackedStringArray("<major>.<minor>")
```

`export_presets.cfg` needs one preset per platform. Exclude tests and test tools from what ships:
```ini
[preset.0]

name="Linux"
platform="Linux"
runnable=true
export_filter="all_resources"
include_filter=""
exclude_filter="addons/gut/*, test/*"
export_path=""
script_export_mode=2

[preset.0.options]

binary_format/embed_pck=false
binary_format/architecture="x86_64"
```

Add an empty `scenes/main.tscn` with one root node, and a `scripts/main.gd` attached to it.

Install GUT by copying `addons/gut` from the release that matches the Godot version. GUT's version table is in its README. Then enable the plugin in `project.godot`:

```ini
[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

## Layout

```
project.godot  export_presets.cfg
scenes/                 # .tscn files
scripts/                # .gd files
assets/                 # art and audio
addons/gut/             # test tool, excluded from exports
test/                   # GUT tests named test_*.gd
```

Add a `README.md` to `test/`, because git doesn't keep empty folders. Commit `.uid` files and `.import` files next to their sources, and never commit `.godot/`.

## Makefile recipes

| Target | Recipe |
| --- | --- |
| `setup` | `godot --headless --import` |
| `build` | `mkdir -p out/debug && godot --headless --export-debug "Linux" out/debug/<name>.x86_64` |
| `fmt` | `gdformat scripts test` |
| `fmt-check` | `gdformat --check scripts test` |
| `lint` | `gdlint scripts test` |
| `test` | `godot --headless -d -s --path "$(CURDIR)" addons/gut/gut_cmdln.gd -gdir=res://test -ginclude_subdirs -gexit` (exits 0 with no tests) |
| `release` | `rm -rf out/release && mkdir -p out/release && godot --headless --export-release "Linux" out/release/<name>.x86_64` |
| `test-release` | `timeout 60 out/release/<name>.x86_64 --headless --quit-after 60 2>&1 \| tee out/smoke.log` then `! grep -E 'SCRIPT ERROR\|^ERROR:' out/smoke.log` |
| `security-deps` | `@echo "Godot has no package audit. Review addons/ when you update them."` |
| `clean` | `rm -rf out .godot` |

Relative export paths resolve from the folder holding `project.godot`. The output folder must exist before you export. Add one `release` line for each extra platform preset.

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- `--export-debug` and `--export-release` use different templates, so `OS.is_debug_build()` code is excluded by the template, not by a setting. Don't put security checks behind it.
- GDScript `assert()` is removed in release templates. Use a normal condition for security checks.
- Godot's exit code doesn't report script errors that don't crash, which is why `test-release` searches the log. A crash does give a non-zero code.
- **Artefacts:** `out/release/`. **Symbols:** official templates ship without separate symbols, so there's nothing to keep. If you build custom templates, store their symbols per release.
- Set `config/version` from the release tag, so logs name the build.

## .gitignore

`.godot/ .devenv*/ devenv.local.nix .env docs/api/ out/`

## .gitattributes

Use `gitattributes-media` plus `gitattributes-godot`. See [Binary assets](../project-types.md#binary-assets).

## Doxygen

Doxygen can't read GDScript, so remove the `docs` block for GDScript-only projects. Doc comments stay unchecked. A project with C# scripts keeps the block, with `{{doxygen_input}}` set to the C# folder and `{{doxygen_file_patterns}}` set to `*.cs`.

## Pre-commit local hook

```yaml
      - id: lint
        name: gdformat + gdlint
        entry: make lint
        language: system
        pass_filenames: false
        files: \.gd$
```

## devenv

`{{devenv_packages}}`: `godot_4` and `gdtoolkit_4`

`{{devenv_languages}}` stays empty. Local `make build` and `make release` also need export templates for the same Godot version. Install them once from the editor's Export Template Manager, or use `make ci-release`, which is what ships anyway. nixpkgs may lag behind the CI container, so check that the two versions match.

## CI container

`ci/Containerfile`. Add a template to the `unzip` line for each extra platform, such as `templates/windows_*x86_64*`:

```dockerfile
FROM docker.io/library/debian:bookworm-slim
ARG GODOT_VERSION=<version>
RUN apt-get update && apt-get install -y --no-install-recommends make git bash ca-certificates curl unzip python3 python3-venv libfontconfig1 && rm -rf /var/lib/apt/lists/*
RUN python3 -m venv /opt/gdtoolkit && /opt/gdtoolkit/bin/pip install --no-cache-dir "gdtoolkit==<major>.*" && ln -s /opt/gdtoolkit/bin/gdformat /opt/gdtoolkit/bin/gdlint /usr/local/bin/
RUN set -eux; base="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}-stable"; \
    cd /tmp; curl -fsSLO "$base/SHA512-SUMS.txt"; \
    curl -fsSLO "$base/Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip"; \
    curl -fsSLO "$base/Godot_v${GODOT_VERSION}-stable_export_templates.tpz"; \
    grep -E "Godot_v${GODOT_VERSION}-stable_(linux.x86_64.zip|export_templates.tpz)$" SHA512-SUMS.txt | sha512sum -c -; \
    unzip -q "Godot_v${GODOT_VERSION}-stable_linux.x86_64.zip" -d /opt/godot; \
    ln -s "/opt/godot/Godot_v${GODOT_VERSION}-stable_linux.x86_64" /usr/local/bin/godot; \
    dest="/opt/godot-data/godot/export_templates/${GODOT_VERSION}.stable"; mkdir -p "$dest"; \
    unzip -q -j "Godot_v${GODOT_VERSION}-stable_export_templates.tpz" 'templates/linux_*x86_64' 'templates/version.txt' -d "$dest"; \
    rm -f /tmp/*.zip /tmp/*.tpz /tmp/SHA512-SUMS.txt
RUN chmod -R a+rwX /opt/godot-data
ENV HOME=/tmp XDG_DATA_HOME=/opt/godot-data XDG_CONFIG_HOME=/tmp/.config XDG_CACHE_HOME=/tmp/.cache
USER 65532:65532
```

Keep the data folder writable, because `user://` paths, including Godot's log, live there. The template archive is large, so the first image build takes a few minutes. See [CI image speed](../security.md#ci-image-speed).

Dependabot ecosystem: `docker` for `/ci`. Nothing tracks `addons/` or Godot itself, so tell the user to update those by hand.

Scanner extras: `{{semgrepignore_extra}}` is `.godot/` and `addons/`. `{{trivy_skip_extra}}` is `--skip-dirs .godot`.
