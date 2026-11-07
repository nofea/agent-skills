# Build profiles

Every project has two build profiles. Debug is for finding bugs. Release is what ships. Testing only debug proves nothing about the shipped build, because checks, optimisations and code paths differ between them.

| | Debug | Release |
| --- | --- | --- |
| Commands | `make build`, `make test` | `make release`, `make test-release` |
| Goal | Find bugs fast | Ship safely |
| Assertions | On | Off where the language removes them |
| Sanitizers, race detector | On where the language has them | Off |
| Exploit hardening | Not needed | On |
| Symbols | Included | Kept apart from the artefact |
| Developer mode | Allowed, with fake data | Excluded |
| Published | Never | Yes, after signing |

Exact recipes are in each [language reference](languages/). Language-specific rules go there, not here.

## Rules

Each rule applies in every language.

1. **`make release` only builds.** It never signs, uploads or tags anything. Signing and publishing belong to [release-signing.md](release-signing.md).
2. **Security checks are never debug-only.** Authentication, authorization, input validation and bounds checks must not sit in `assert`, or behind a debug flag or `NDEBUG`. Those checks vanish in release, so the protected action runs unchecked. Use a normal condition that returns an error. Assertions are for internal invariants only.
3. **The build excludes developer mode.** Use a compile-time switch, a build tag or a separate target. A config flag or environment variable alone is not enough, and neither is a check that production could skip.
4. **No debug surface in release.** No debug endpoints, debug menus, verbose errors to callers, or logging of secrets. Diagnosis in production uses logs and telemetry.
5. **Test what ships.** CI runs `make release` and `make test-release` on every change, in the CI container. Dockerfiles run the same commands as `make release`, so the image holds the same build.
6. **Warnings don't fail builds that users compile.** Where users build from source, as in C and C++, warnings-as-errors stays in debug and in `make lint`. A newer compiler can add warnings, and that mustn't break their build. Project-only builds can keep it, such as C#, where it's what fails the build on vulnerable packages.
7. **Keep symbols out of the artefact, but keep them.** Crash reports can't be read without symbols. Store them per release, matched by build version. In a private project, keep them somewhere private.
8. **Don't serve source maps publicly.** Release web builds leave them out, or upload them only to the error tracker.
9. **Embed the build version** so that logs and crash reports can name the exact release.
10. **Remove local paths** from release output where the toolchain has a stable option for it.
11. **Keep release builds rebuildable.** Lockfiles and pinned toolchains make it possible to rebuild any released version when reproducing a fault.
12. **Only containers build what ships.** `make ci-release` builds the release in the CI container. `make release` in devenv is for trying a build locally. A binary built there can link to `/nix/store`, so it won't run on another machine. macOS and Windows builds, which can't use Linux containers, build natively on CI runners.

## Game engines

Rule 5 needs care, because engines test inside the editor or a debug player, and often strip test code from what ships. Unreal's Shipping build has no console commands, for example.

- `make test` runs the engine's tests on the debug or development configuration.
- `make test-release` runs the [shipped-build smoke test](project-types.md#shipped-build-smoke-test), plus any tests that can use the release settings, such as `cargo test --release`.

This is the only exception to testing the shipped build fully, and the smoke test still runs the exact artefact. Report what it doesn't reach.

Rule 12 still applies. Godot, Bevy and MonoGame build in the CI container. Unity and Unreal do too, but from licensed images the user provides. On a host-installed editor, `make release` is for trying a build locally, as with devenv.

## Existing repos

- `release` is a common target name, and it often publishes. If the repo's `release` target signs, uploads or tags anything, report the clash and ask, as [workflow-existing-repo.md](workflow-existing-repo.md) describes. Don't change the target.
- Keep existing build profiles and flags. Report gaps against the rules above, and offer the missing flags as a proposed change.
- Hardening flags can break code that relies on undefined behaviour. Report any failure in existing code, and don't fix it unless the user asks.
