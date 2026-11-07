# Project types

Each type changes the layout described in the language reference. These are the differences that apply in every language. The language and engine files give the exact paths.

## CLI tool

- One thin entry point that parses arguments and calls into library code. Keep the logic out of `main`, so it can be tested.
- Argument parser: the language default, listed in the language reference.
- README: install (package manager, or a release binary), a `--help` excerpt, and common examples.
- CI: `make ci-release` produces the binary or package in the CI container. Signing and publishing need distribution targets from the intake. See [release-signing.md](release-signing.md).
- Exit codes and stderr/stdout conventions get a section in `specs/architecture.md`.

## Library

- The public API surface is explicit: exports, `pub`, `__all__`, an `internal/` package, etc.
- Packaging metadata goes in the manifest: description, license, repository, keywords.
- An `examples/` folder, left empty except for a README that says what goes there.
- README: install, a minimal usage snippet (`TODO:` until the API exists), versioning policy (semver), and the supported language/runtime versions.
- `specs/architecture.md` has a "Public API and stability" section.

## Web service / API

- Entry point (`main`/server bootstrap), plus separate layers: transport (handlers/routes), domain, and adapters (db, external APIs).
- Configuration comes from environment variables only. Write a `.env.example`, and add `.env` to `.gitignore`.
- A health endpoint is listed in the spec as a requirement. It isn't implemented, because the scaffold has no sample code.
- `Dockerfile` (multi-stage, non-root user, base image pinned by tag and named in full with its registry) and `.dockerignore`. Base images are in the language reference.
- Makefile: `image-build` and `security-image` targets, which work with podman or docker.
- README: run locally, configuration table (env vars), API docs pointer, and the container run command.
- `specs/architecture.md` sections: endpoints overview, data storage, observability (logs, metrics), and deployment.

## Web app (frontend)

- Usually TypeScript. Use the framework's official create command (Vite: `pnpm create vite@latest <name> --template react-ts`, or the template the user names). Then apply this scaffold's lint, test and security setup on top, replacing the template's default linter with Biome only if the template brought ESLint and the user agrees. Otherwise keep the template's ESLint.
- The build output folder (`dist/`) is ignored by git, Biome and semgrep.
- Static deploy: the Dockerfile is optional (nginx-unprivileged) and only written if the user asks.
- README: the dev server command, build, and environment variables (`VITE_*`).
- The framework template's demo components are template output, not our sample code. Keep them; the user can delete them.

## Mobile app

- Use the platform's official project template. Android: Kotlin with Gradle, from [java-kotlin.md](languages/java-kotlin.md). iOS: Swift, from [generic.md](languages/generic.md). For cross-platform frameworks, use the framework's own create command.
- Debug and release are separate build types or configurations, each with its own signing setup. No signing details in build files: read them from environment variables or a git-ignored file.
- Store metadata, screenshots and release notes go in `store/`. Write a `README` there that says what goes where.
- Signing and upload need distribution targets. See [release-signing.md](release-signing.md).
- README: supported OS versions and how to run on a device or emulator.
- `specs/architecture.md` sections: minimum OS versions, permissions and why each one is needed, and offline behaviour.

## Desktop app

- Use the toolkit the user names, and follow its layout. There's no default.
- `make release` builds the unsigned app. Packaging as an installer, `.dmg` or MSIX is part of the release, and needs one runner per platform.
- Signing, notarization and store submission need distribution targets. See [release-signing.md](release-signing.md).
- README: supported platforms, and how users verify a download.
- `specs/architecture.md` sections: supported platforms, update mechanism, and where user data is stored.

## Game

Ask which engine, then read its reference: [godot](engines/godot.md), [unity](engines/unity.md), [unreal](engines/unreal.md), [bevy](engines/bevy.md) or [monogame](engines/monogame.md). For anything else, use [generic](engines/generic.md). The engine reference comes before the language reference, because the engine decides the layout, build and test commands.

- Use the engine's own project layout. Keep game rules in plain code that tests can run without a window.
- The Makefile keeps the same verbs. `build` and `test` use the engine's debug or development configuration, and `release` makes what ships.
- Consoles aren't scaffolded, because their tools are under NDA. If the user targets one, say that the toolchain and submission steps come from the platform holder, and scaffold the rest.
- Store art and text go in `store/`, with a `README` that says what goes where.
- Publishing needs distribution targets. See [release-signing.md](release-signing.md).
- `CONTRIBUTING.md`: list any host-installed editor under `{{prerequisites}}`, with its version and the variable that points to it.
- `AGENTS.md`: add to `{{conventions}}` that logic goes in code, and that agents don't edit binary assets. See below for visual scripts.
- README: supported platforms, minimum hardware, and controls.
- `specs/architecture.md` sections: frame budget, target platforms and minimum hardware, save format and its version, networking model, and update approach. If `system-architecture` is installed, it can fill these in.

### Shipped-build smoke test

Engines test inside their editor or a debug player, and often strip test code from what ships. So `test-release` runs **the exact build that ships**: it starts headless, runs a fixed number of frames, exits by itself, and must exit 0 with no errors in its log.

- Prefer the engine's own switches, as Godot has. Otherwise, add a `--smoke-test` flag.
- The flag only makes the game exit early. It adds no cheats, debug menus or logging, and it can't skip any checks. It stays in release builds on purpose, so it follows [build-profiles.md](build-profiles.md#rules).
- Use `timeout`, so a hang fails the job.
- Report what the test doesn't reach. Most runs have no real GPU or audio device.

### Binary assets

New game projects get a `.gitattributes` that keeps binaries in Git LFS, built from `assets/gitattributes-media` plus the engine's own file, if it has one. History can't easily be slimmed later, so set this up first.

- Add `git-lfs` to `{{devenv_packages}}`. `git lfs install` changes git config, so it's a next step in the hand-off. Don't run it.
- Add `lfs: true` under `actions/checkout` in `ci.yml` and `release.yml` jobs that build the game.
- Existing repos: report large binaries and offer this as a change. See [workflow-existing-repo.md](workflow-existing-repo.md#game-projects).
- `check-added-large-files` in pre-commit ignores files tracked by LFS, so it still catches a missed file type.

Perforce is common on large teams. This scaffold is built around git and GitHub Actions, so it doesn't set Perforce up. Mention it for projects with large binary-heavy teams.

### Visual scripts

Unreal Blueprints and Unity Visual Scripting aren't text, so linters, reviews and agents can't see them.

- Write systems in code. Leave visual scripts to designer-facing tuning and content.
- Never edit a binary asset directly.
- Doc comment and lint checks don't cover them. Say so in the hand-off if the project has any.

## Mixed (polyglot)

Each component picks its own type. See [polyglot.md](polyglot.md).
