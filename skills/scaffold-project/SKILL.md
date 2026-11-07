---
name: scaffold-project
description: Scaffolds a software project workspace for spec-driven agentic coding. It sets up specs/, AGENTS.md with a CLAUDE.md import, a layout that fits the language, a Makefile with build/release/lint/fmt/test/security/check verbs, debug and release profiles, pre-commit, GitHub Actions CI, security scanning (gitleaks, semgrep, trivy, dependency audit), an optional signed release workflow for registries, app stores and game stores, a Doxygen doc comment check, README and CONTRIBUTING. Works for new and existing repos, in one language or several (Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET, C/C++, or others), and for games built with Godot, Unity, Unreal, Bevy, MonoGame or another engine. Use when the user asks to scaffold, bootstrap, set up, or initialize a project, repo, or workspace, including a game project, to add specs/AGENTS.md/linting/CI/security scanning/Doxygen/release builds/release signing to an existing repo, to set up publishing to a marketplace, or to make a repo ready for agentic coding.
---

# scaffold-project

Set up a workspace so humans and agents can build software from specs. Every project gets the same shape:

- `specs/` holds what to build. Agents read it before coding and update it as they work.
- `AGENTS.md` holds how to work in the repo. `CLAUDE.md` is one line, `@AGENTS.md`.
- `devenv.nix` provides the development environment, and `ci/Containerfile` provides CI's. CI/CD runs in containers, under podman or docker, so `make ci-check` works the same locally and on the server.
- `Makefile` provides the same verbs in every language: `build test release test-release ci-check ci-release lint fmt security check doctor`. `build` and `test` are the debug profile, and `release` and `test-release` are what ships. Languages Doxygen supports also get `docs` and `docs-check`.
- Pre-commit hooks and a GitHub Actions workflow run those same verbs, the workflow in the CI container. `docs-check` runs in `make check` and CI, not in pre-commit.
- If the user names distribution targets, `.github/workflows/release.yml` signs and publishes the release build when a version tag is pushed.
- `README.md` (for users) links to `CONTRIBUTING.md` (for developers). The project also gets `SECURITY.md`, `LICENSE`, `.editorconfig` and `.gitignore`.

## Ground rules

- **Never run git commands that change state.** That includes `git init`, `add`, `commit` and `pre-commit install`. List them as next steps for the user.
- **Never delete or overwrite existing files without approval.** In existing repos, follow [references/workflow-existing-repo.md](references/workflow-existing-repo.md).
- **Ask before installing anything** on the user's machine.
- **Never create signing keys, certificates, accounts or secrets, and never sign or publish.** List these as next steps for the user.
- Report verification results as they are. If a check fails or was skipped, say so.

## Workflow

### 1. Detect the mode

Look at the target directory (default: the current directory).

| What you find | Mode | Also read |
| --- | --- | --- |
| Empty, or only `README`, `LICENSE` or `.git` | **new** | — |
| Source code, manifests or tool configs | **existing** | [workflow-existing-repo.md](references/workflow-existing-repo.md) |
| More than one language, or the user asks for several components | **polyglot** (combines with new or existing) | [polyglot.md](references/polyglot.md) |

### 2. Intake

Ask these in **one** message. Show a default for each. In existing repos, fill in what you can infer first and only ask about the rest.

1. **Project name.** Default: the folder name.
2. **One-line purpose.** This goes into README, `specs/product.md` and AGENTS.md.
3. **Language(s).** Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET, C/C++, GDScript, or other.
4. **Project type** for each component: CLI, library, web service/API, web app, mobile app, desktop app, or game. For a game, also ask which engine: Godot, Unity, Unreal, Bevy, MonoGame, or other. See [project-types.md](references/project-types.md).
5. **License.** Default MIT. Apache-2.0 is the other bundled option. "None" means proprietary: skip the LICENSE file and say so in the README.
6. **GitHub owner/repo.** Optional. Used for badges and the security contact.
7. **Distribution targets.** Default: none. Where releases go: package registries (PyPI, npm, crates.io, NuGet, Maven Central), containers, GitHub releases, mobile stores (Google Play, Apple App Store), desktop stores and OS signing (Microsoft Store, Mac App Store, Windows, macOS), or game stores (Steam, itch.io, Epic Games Store, GOG). If the user names any, read [release-signing.md](references/release-signing.md). Otherwise, skip it and write no `release.yml`.

Read the reference for each language: `references/languages/<lang>.md` (`python`, `typescript`, `go`, `rust`, `java-kotlin`, `csharp`, `cpp`). For anything else use [generic.md](references/languages/generic.md). A game also has an engine reference, `references/engines/<engine>.md` (`godot`, `unity`, `unreal`, `bevy`, `monogame`, `generic`), which comes first where the two differ. Godot has no language reference, so its engine reference covers GDScript.

Then check the tools. Add `doxygen` to the list if a language uses Doxygen (see [Doc comment check](#doc-comment-check)), `signing` if the project has distribution targets, and `git-lfs` for a game. Godot, Unity and Unreal are names on this list too. Bevy uses `rust`, and MonoGame uses `csharp`:

```bash
bash <skill-dir>/scripts/doctor.sh <lang> [<lang>...] [doxygen]
```

Run this inside `devenv shell` once `devenv.nix` exists. Until then, it reports the host's tools. devenv and a container engine are the only tools the host needs, apart from the licensed Unity and Unreal editors, which stay on the host. If something is missing, list it with the install command from [tool-install.md](references/tool-install.md). **Offer** to install it and wait for a yes. If the user says no, continue anyway: write by hand the files the init tool would have made, and mention the gap in the final report.

### 3. Confirm

Show one summary before writing anything:

- the answers from the intake
- a file plan with each path marked **create**, **modify** or **skip (exists)**
- in existing repos, the proposed feature list for the reverse-engineered specs

Wait for approval. Change the plan if the user asks.

### 4. Generate

Work in this order:

1. **Dev environment.** Write `devenv.nix` and `devenv.yaml` first, and run the steps below inside `devenv shell`.
2. **Native init.** Run the language's init command from its reference. If the toolchain is missing, write the minimal manifest by hand.
3. **Layout.** Create the folders from the language reference and [project-types.md](references/project-types.md). Leave out sample code and sample tests. Each source folder gets only the minimum the toolchain needs to build, such as an empty entry point or module. If the init tool generated sample tests or demo logic, delete them and trim the entry point. The exception is a web app framework template's demo UI, which stays. In Doxygen languages, give any code you keep the doc comments it needs, so `make docs-check` passes.
4. **Shared files** from `assets/`. Placeholders are `{{name}}`. Leave GitHub Actions expressions (`${{ … }}`) untouched. `{{ref:owner/action}}` means "pin to the latest release's commit SHA" (see [security.md](references/security.md#pinning-versions)). Fill every placeholder. If a section has nothing to put in it, remove it rather than leaving it empty. `{{ci_env}}`, `{{semgrepignore_extra}}` and `{{trivy_skip_extra}}` stay empty unless the language or engine reference sets them. Copy `scripts/doctor.sh` into the project as `scripts/doctor.sh`. In Doxygen languages, also copy `scripts/docs-check.sh`. Files are stored without a leading dot, so rename them as you write:

   | Asset | Written to |
   | --- | --- |
   | `Makefile.tmpl` (or `Makefile.polyglot.tmpl`) | `Makefile` |
   | `devenv.nix.tmpl` | `devenv.nix` |
   | `devenv.yaml` | `devenv.yaml` |
   | `editorconfig` | `.editorconfig` |
   | `pre-commit-config.yaml.tmpl` | `.pre-commit-config.yaml` |
   | `ci.yml.tmpl` | `.github/workflows/ci.yml` |
   | `dependabot.yml.tmpl` | `.github/dependabot.yml` |
   | `release.yml.tmpl` | `.github/workflows/release.yml` (distribution targets only) |
   | `dockerignore` | `.dockerignore` (web service/API only) |
   | `licenses/<id>.txt` | `LICENSE` |
   | `gitleaks.toml` | `.gitleaks.toml` |
   | `semgrepignore` | `.semgrepignore` |
   | `eclipse-java-allman.xml` | `config/eclipse-java-allman.xml` (Java only) |
   | `Doxyfile.tmpl` | `Doxyfile` (Doxygen languages only) |
   | `gitattributes-media`, plus the engine's file | `.gitattributes` (games only) |

5. **Language glue** from the language or engine reference: Makefile target bodies, tool config (lint, format, type-check, test), `.gitignore` entries, pre-commit hooks, `{{devenv_languages}}` and `{{devenv_packages}}`, `ci/Containerfile`, Dependabot ecosystem, and a Dockerfile for services. The wiring for security tools is in [security.md](references/security.md). The rules for debug and release builds are in [build-profiles.md](references/build-profiles.md).

Test targets must **pass when no tests exist yet**. Each language reference says how.

#### Doc comment check

Doxygen checks that functions and types have doc comments. It covers Python, Java, C#, C/C++ and the other languages listed in [generic.md](references/languages/generic.md#doxygen). It can't read Go, Rust, TypeScript or Kotlin, so skip this for those. Their doc comments stay unchecked. A project with both Java and Kotlin checks only the Java.

For a Doxygen language:

1. Fill `Doxyfile.tmpl` and `{{docs_check_args}}` from the language reference's Doxygen section. List only `INPUT` folders that exist, because a missing one fails the check.
2. Add `doxygen` to `{{languages}}` in the Makefile.
3. Add `docs/api/` to `.gitignore`, and add the `apt-get` line from [security.md](references/security.md#check_jobs-in-ciymltmpl) to CI.

For anything else, remove the `docs` block from the Makefile and `docs-check` from `check` and `ci-check`, and remove the `make docs` rows from AGENTS.md and CONTRIBUTING.md.

`make docs-check` checks that doc comments exist, not that they're accurate. It ignores undocumented fields and constants on purpose. See [scripts/docs-check.sh](scripts/docs-check.sh).

### 5. Specs

Follow [specs.md](references/specs.md).

- **New project:** write `specs/product.md` and `specs/architecture.md` from the templates, filled with what the intake told you. Leave `specs/features/` with only its `README.md`. Features get added as the user plans them.
- **Existing repo:** reverse-engineer the specs as described in [workflow-existing-repo.md](references/workflow-existing-repo.md#reverse-engineering-specs).

### 6. Docs

Fill from `assets/`:

- `AGENTS.md`: commands, layout, spec-first workflow, conventions. Keep it under about 150 lines.
- `CLAUDE.md`: the single line `@AGENTS.md`.
- `README.md`: for **users**. What it is, install, quick start, usage, configuration, license. Its short Development section links to CONTRIBUTING.md.
- `CONTRIBUTING.md`: for **developers**. Prerequisites, setup, make verbs, layout, spec workflow, PR checklist.
- `SECURITY.md`

The `{{release_section}}`, `{{verify_link}}` and `{{release_security_section}}` placeholders come from [release-signing.md](references/release-signing.md#filling-releaseymltmpl). Remove them if there are no distribution targets. For C/C++, set `{{hardening_note}}` to ` Release builds use compiler hardening.` Otherwise remove it.

For sections you can't fill yet (such as usage examples), leave a clearly marked `TODO:` instead of making something up.

### 7. Verify

Inside `devenv shell`, run `make doctor`, then `make check`. Then run `make ci-check`, because the CI container is what proves the build. If a tool is missing, run the targets that can still work (`make lint build test`) and say which were skipped. Fix failures that the scaffold caused. In existing repos, failures that come from existing code are reported, not fixed.

### 8. Hand off

Report:

- what was created and what was modified
- the results of verification
- next steps, in this order:
  1. `git init` (if needed)
  2. `devenv shell`, then `pre-commit install`. Commit `devenv.lock` with the rest. For a game, also run `git lfs install` before the first commit
  3. review or complete `specs/product.md`
  4. write the first feature spec in `specs/features/001-<name>/`
  5. push to GitHub so CI runs
  6. with distribution targets: the setup steps from [release-signing.md](references/release-signing.md#user-setup-for-the-hand-off), including any `unverified` targets to check, and whether the repo's plan supports required reviewers

Never commit.

## Reference index

- [references/specs.md](references/specs.md): spec layout, EARS requirements, feature numbering and status
- [references/project-types.md](references/project-types.md): layout differences for each project type, including games, the shipped-build smoke test and Git LFS
- [references/security.md](references/security.md): gitleaks, semgrep, trivy, dependency audit, Dependabot
- [references/build-profiles.md](references/build-profiles.md): debug and release rules for every language
- [references/release-signing.md](references/release-signing.md): signing and publishing to registries, containers, app stores and game stores
- [references/polyglot.md](references/polyglot.md): `apps/` + `packages/`, delegating Makefile, per-component agent docs
- [references/workflow-existing-repo.md](references/workflow-existing-repo.md): detection, keep-existing rules, change plan, reverse-engineering specs
- [references/tool-install.md](references/tool-install.md): install commands per tool and OS
- [scripts/docs-check.sh](scripts/docs-check.sh): the doc comment check, copied into Doxygen projects
- `references/languages/`: [python](references/languages/python.md), [typescript](references/languages/typescript.md), [go](references/languages/go.md), [rust](references/languages/rust.md), [java-kotlin](references/languages/java-kotlin.md), [csharp](references/languages/csharp.md), [cpp](references/languages/cpp.md), [generic](references/languages/generic.md)
- `references/engines/`: [godot](references/engines/godot.md), [unity](references/engines/unity.md), [unreal](references/engines/unreal.md), [bevy](references/engines/bevy.md), [monogame](references/engines/monogame.md), [generic](references/engines/generic.md)
