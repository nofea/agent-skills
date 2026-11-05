---
name: scaffold-project
description: Scaffolds a software project workspace for spec-driven agentic coding. It sets up a specs/ folder, AGENTS.md with a CLAUDE.md import, a layout that fits the language, a Makefile with build/lint/fmt/test/security/check verbs, pre-commit hooks, GitHub Actions CI, security scanning (gitleaks, semgrep, trivy, dependency audit), and a README plus CONTRIBUTING guide. Works for new projects and existing repos, in one language or several (Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET, C/C++, or others). Use when the user asks to scaffold, bootstrap, set up, or initialize a project, repo, or workspace, to add specs/AGENTS.md/linting/CI/security scanning to an existing repo, or to make a repo ready for agentic coding.
---

# scaffold-project

Set up a workspace so humans and agents can build software from specs. Every project gets the same shape:

- `specs/` holds what to build. Agents read it before coding and update it as they work.
- `AGENTS.md` holds how to work in the repo. `CLAUDE.md` is one line, `@AGENTS.md`.
- `Makefile` provides the same verbs in every language: `build lint fmt test security check doctor`.
- Pre-commit hooks and a GitHub Actions workflow run those same verbs.
- `README.md` (for users) links to `CONTRIBUTING.md` (for developers). The project also gets `SECURITY.md`, `LICENSE`, `.editorconfig` and `.gitignore`.

## Ground rules

- **Never run git commands that change state.** That includes `git init`, `add`, `commit` and `pre-commit install`. List them as next steps for the user.
- **Never delete or overwrite existing files without approval.** In existing repos, follow [references/workflow-existing-repo.md](references/workflow-existing-repo.md).
- **Ask before installing anything** on the user's machine.
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
3. **Language(s).** Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET, C/C++, or other.
4. **Project type** for each component: CLI, library, web service/API, or web app. See [project-types.md](references/project-types.md).
5. **License.** Default MIT. Apache-2.0 is the other bundled option. "None" means proprietary: skip the LICENSE file and say so in the README.
6. **GitHub owner/repo.** Optional. Used for badges and the security contact.

Read the reference for each language: `references/languages/<lang>.md` (`python`, `typescript`, `go`, `rust`, `java-kotlin`, `csharp`, `cpp`). For anything else use [generic.md](references/languages/generic.md).

Then check the tools:

```bash
bash <skill-dir>/scripts/doctor.sh <lang> [<lang>...]
```

If something is missing, list it with the install command from [tool-install.md](references/tool-install.md). **Offer** to install it and wait for a yes. If the user says no, continue anyway: write by hand the files the init tool would have made, and mention the gap in the final report.

### 3. Confirm

Show one summary before writing anything:

- the answers from the intake
- a file plan with each path marked **create**, **modify** or **skip (exists)**
- in existing repos, the proposed feature list for the reverse-engineered specs

Wait for approval. Change the plan if the user asks.

### 4. Generate

Work in this order:

1. **Native init.** Run the language's init command from its reference. If the toolchain is missing, write the minimal manifest by hand.
2. **Layout.** Create the folders from the language reference and [project-types.md](references/project-types.md). Leave out sample code and sample tests. Each source folder gets only the minimum the toolchain needs to build, such as an empty entry point or module. If the init tool generated sample tests or demo logic, delete them and trim the entry point. The exception is a web app framework template's demo UI, which stays.
3. **Shared files** from `assets/`. Placeholders are `{{name}}`. Leave GitHub Actions expressions (`${{ … }}`) untouched. `{{ref:owner/action}}` means "pin to the latest release's commit SHA" (see [security.md](references/security.md#pinning-versions)). Fill every placeholder. If a section has nothing to put in it, remove it rather than leaving it empty. Copy `scripts/doctor.sh` into the project as `scripts/doctor.sh`. Files are stored without a leading dot, so rename them as you write:

   | Asset | Written to |
   | --- | --- |
   | `Makefile.tmpl` (or `Makefile.polyglot.tmpl`) | `Makefile` |
   | `editorconfig` | `.editorconfig` |
   | `pre-commit-config.yaml.tmpl` | `.pre-commit-config.yaml` |
   | `ci.yml.tmpl` | `.github/workflows/ci.yml` |
   | `dependabot.yml.tmpl` | `.github/dependabot.yml` |
   | `dockerignore` | `.dockerignore` (web service/API only) |
   | `licenses/<id>.txt` | `LICENSE` |
   | `gitleaks.toml` | `.gitleaks.toml` |
   | `semgrepignore` | `.semgrepignore` |
   | `eclipse-java-allman.xml` | `config/eclipse-java-allman.xml` (Java only) |

4. **Language glue** from the language reference: Makefile target bodies, tool config (lint, format, type-check, test), `.gitignore` entries, pre-commit hooks, CI setup steps, Dependabot ecosystem, and a Dockerfile for services. The wiring for security tools is in [security.md](references/security.md).

Test targets must **pass when no tests exist yet**. Each language reference says how.

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

For sections you can't fill yet (such as usage examples), leave a clearly marked `TODO:` instead of making something up.

### 7. Verify

Run `make doctor`, then `make check`. If a tool is missing, run the targets that can still work (`make lint build test`) and say which were skipped. Fix failures that the scaffold caused. In existing repos, failures that come from existing code are reported, not fixed.

### 8. Hand off

Report:

- what was created and what was modified
- the results of verification
- next steps, in this order:
  1. `git init` (if needed)
  2. `pre-commit install`
  3. review or complete `specs/product.md`
  4. write the first feature spec in `specs/features/001-<name>/`
  5. push to GitHub so CI runs

Never commit.

## Reference index

- [references/specs.md](references/specs.md): spec layout, EARS requirements, feature numbering and status
- [references/project-types.md](references/project-types.md): layout differences for CLI, library, service and web app
- [references/security.md](references/security.md): gitleaks, semgrep, trivy, dependency audit, Dependabot
- [references/polyglot.md](references/polyglot.md): `apps/` + `packages/`, delegating Makefile, per-component agent docs
- [references/workflow-existing-repo.md](references/workflow-existing-repo.md): detection, keep-existing rules, change plan, reverse-engineering specs
- [references/tool-install.md](references/tool-install.md): install commands per tool and OS
- `references/languages/`: [python](references/languages/python.md), [typescript](references/languages/typescript.md), [go](references/languages/go.md), [rust](references/languages/rust.md), [java-kotlin](references/languages/java-kotlin.md), [csharp](references/languages/csharp.md), [cpp](references/languages/cpp.md), [generic](references/languages/generic.md)
