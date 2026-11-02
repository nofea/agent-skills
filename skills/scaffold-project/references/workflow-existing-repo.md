# Existing repos

The goal is to add what's missing and keep what's there. Never delete anything. Never replace a working tool with our default. Never modify an existing file without approval.

## 1. Survey (read only)

Collect these facts before asking the user anything:

- **Languages and components:** manifests (`pyproject.toml`, `setup.py`, `requirements*.txt`, `package.json`, `go.mod`, `Cargo.toml`, `build.gradle*`, `pom.xml`, `*.csproj`/`*.sln`, `CMakeLists.txt`, `meson.build`) and where they sit. More than one manifest root means it's polyglot, so read [polyglot.md](polyglot.md). **Don't move existing components into `apps/`.** Keep their paths and list them in the root Makefile's `COMPONENTS`.
- **Existing tooling** (keep all of it):

  | Concern | Look for |
  | --- | --- |
  | Task runner | `Makefile`, `justfile`, `Taskfile.yml`, `package.json` scripts, `tox.ini`/`noxfile.py`, Gradle tasks |
  | Format/lint | ruff/black/flake8/pylint/mypy config, `.eslintrc*`/`eslint.config.*`/`biome.json`/`.prettierrc*`, `.golangci.*`, `rustfmt.toml`/`clippy.toml`, `.editorconfig`, `.clang-format`/`.clang-tidy`, spotless/checkstyle/ktlint |
  | Tests | the framework and test directories in use |
  | Hooks | `.pre-commit-config.yaml`, husky, lefthook |
  | CI | `.github/workflows/*`, `.gitlab-ci.yml`, others |
  | Security | gitleaks/trufflehog, semgrep/CodeQL, trivy/snyk, dependabot/renovate |
  | Docs | README, CONTRIBUTING, SECURITY, LICENSE, `docs/` |
  | Agent docs | AGENTS.md, CLAUDE.md, `.cursor/rules`, `.github/copilot-instructions.md` |
  | Specs | `specs/`, `docs/adr`, `.specify/`, RFCs |

- **Current state:** run the existing build/lint/test commands, if they're cheap and safe, so you know the baseline before changing anything. Don't run deploy scripts or anything that needs credentials.

## 2. Gap analysis

For each concern, choose one action:

| Situation | Action |
| --- | --- |
| Missing | **create** with our default |
| Present, different tool | **keep**. Wire it into the Makefile verbs. Don't add a competing tool (no ruff on a black+flake8 repo) |
| Present, partly covers it | **modify**: add the missing piece (e.g. a gitleaks hook in an existing pre-commit config) |
| Non-GitHub CI | **keep**. Offer to add the equivalent steps to it, and don't add GitHub Actions unless the user asks |
| Renovate instead of Dependabot | **keep**, and skip dependabot.yml |
| Existing task runner that isn't make | **create** a thin Makefile whose verbs call the existing runner (`lint: ; just lint`). Don't port the recipes |
| Existing Makefile | **modify**: add missing verbs only. Never rename or change existing targets. If a verb name is already used for something else, report the clash and ask |
| Existing CLAUDE.md, no AGENTS.md | Propose moving its content into AGENTS.md and making CLAUDE.md `@AGENTS.md`. **Ask first**, because it rewrites their file |
| Existing AGENTS.md | **modify**: add the missing sections (commands, spec workflow). Keep their wording |
| Existing README | **modify** only by adding missing sections (Development link, Security, License). Never rewrite their prose. If dev setup is mixed into README, offer to move it into CONTRIBUTING.md |
| Other agent rule files | Leave them alone. Mention that AGENTS.md could become the single source |

## 3. Change plan (must be approved)

Show it before writing anything:

```
CREATE  specs/product.md, specs/architecture.md, specs/features/001-…/ (×N)
CREATE  .github/workflows/security.yml        (existing ci.yml kept; security added as a separate workflow)
MODIFY  Makefile                              + security, security-*, check, doctor (existing targets untouched)
MODIFY  .pre-commit-config.yaml               + gitleaks hook
MODIFY  README.md                             + "Development" and "Security" sections
SKIP    .editorconfig                         (exists)
KEEP    black + flake8 + mypy                 (wired into `make lint`)
```

Then wait. Apply only what was approved. If CI exists, add security scanning as a **separate** `security.yml` workflow rather than editing their CI.

## Reverse-engineering specs

1. **Map the product.** Read the README, entry points (CLI commands, routes, public API exports, UI routes), tests, and the git log subjects (`git log --oneline -200` is read-only, so it's allowed).
2. **Propose features.** One per user-visible capability, named from the user's point of view, in rough dependency order. Show the list as a numbered table (`001-…`) with a one-line description and the main code paths. Ask the user to approve, merge, split or rename. For large codebases, also ask whether to spec everything now or the top N first and the rest as stubs (`requirements.md` with Status and summary only).
3. **Write the specs** for each approved feature:
   - `requirements.md`: `Status: Implemented`. EARS criteria describe **current behaviour**, derived from the code and tests. Mark criteria with no test coverage `(untested)`.
   - `design.md`: how it is actually built, with file paths and the interfaces involved.
   - `tasks.md`: no implementation tasks (it's already built). Under "Discovered while working", list the gaps you found: untested requirements, TODO/FIXME comments, apparent bugs, missing error handling, and security findings.
4. **Write `product.md` and `architecture.md`** from the code, marked `Status: Draft (reverse-engineered, needs review)`. Never invent users, goals or metrics. Write `TODO:` where the code can't tell you.
5. **Index** everything in `specs/features/README.md`.

If the repo already has `docs/adr`, RFCs or Spec Kit files, link to them from `architecture.md` and don't duplicate their content.
