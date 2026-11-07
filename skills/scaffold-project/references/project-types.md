# Project types

Each type changes the layout described in the language reference. These are the differences that apply in every language. The language files give the exact paths.

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

## Mixed (polyglot)

Each component picks its own type. See [polyglot.md](polyglot.md).
