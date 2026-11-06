# Polyglot (multi-language) projects

Use this when the repo has more than one component in different languages, or more than one deployable. An example is a Go API with a TypeScript web app.

## Layout

```
.
├── apps/                    # deployables: services, CLIs, web apps
│   ├── api/                 # its own toolchain (e.g. Go module)
│   │   ├── Makefile         # same verbs as the root, language-specific
│   │   ├── AGENTS.md        # short: language, commands, local conventions
│   │   └── CLAUDE.md        # @AGENTS.md
│   └── web/
├── packages/                # shared libraries consumed by apps
├── specs/                   # ONE spec tree for the whole product
├── scripts/doctor.sh
├── Makefile                 # from Makefile.polyglot.tmpl, delegates to components
├── AGENTS.md                # repo-wide: workflow, layout, how components relate
├── CLAUDE.md                # @AGENTS.md
└── .github/workflows/ci.yml # one check job per component + one security job
```

- Every component is a complete project as described in its language reference (manifest, src/test layout, tool config), but **without** a README.md, CONTRIBUTING.md, LICENSE, SECURITY.md, `.github/` or a pre-commit config. Those live at the root.
- Each component Makefile comes from `Makefile.tmpl` **with the `repo-wide` block removed**. Its `security` target becomes just `security: security-deps`. Secrets, SAST and filesystem scans run once at the root.
- Where a language ecosystem has a native workspace (pnpm workspaces, Cargo workspace, `go.work`), add the workspace file at the root **only** if two or more components share that language.
- Shared code between languages goes through a contract (OpenAPI, protobuf, JSON Schema) kept in `packages/<name>-contract/`. Mention it in `specs/architecture.md`.

## Root Makefile

`{{components}}` lists each component directory, separated by spaces, in dependency order (packages first). The root runs per-component targets in a loop and runs the repo-wide scans once.

## Doxygen

Each component in a Doxygen language has its own `Doxyfile`, set up as `SKILL.md` describes. List those components in `{{docs_components}}`. Components in other languages stay out of it, and their Makefiles lose the `docs` block.

`docs-check.sh` lives once at the root, so in component Makefiles write its path relative to the component, such as `@bash ../../scripts/docs-check.sh`. If no component uses Doxygen, remove the `docs` block and `docs-check` from the root Makefile too.

## Agent docs

- Root `AGENTS.md`: the full template. The `{{component_commands}}` section explains that `make -C apps/<name> <verb>` runs a target for one component.
- Component `AGENTS.md`: 10–30 lines. Language and version, the commands, layout, and conventions specific to that component. It refers back to the root AGENTS.md for the workflow. Agents that read nested agent files (Claude Code and Codex both do) pick it up when they work in that folder.

## Pre-commit

Write one local hook per component, limited to that component's files:

```yaml
      - id: api-fmt-lint
        name: api fmt-check + lint
        entry: make -C apps/api lint
        language: system
        files: ^apps/api/
        pass_filenames: false
```

## CI

One `check-<name>` job per component, with `defaults.run.working-directory: apps/<name>`, using that language's setup steps. Use `paths` filters only if the user asks: on a fresh repo, running every job keeps things simple.

## Dependabot

One entry per component directory and ecosystem.
