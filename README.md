# agent-skills

Reusable agent skills (Claude Code and other agents that support `SKILL.md`). You install them with the [Skills CLI](https://github.com/vercel-labs/skills).

## Install

```bash
npx skills add nofea/agent-skills                        # choose from all skills
npx skills add nofea/agent-skills@<skill-name>           # one skill
npx skills add nofea/agent-skills@<skill-name> -g -y     # global, no prompts
```

## Skills

| Skill | Description |
| --- | --- |
| [scaffold-project](skills/scaffold-project/SKILL.md) | Sets up a new or existing repo for spec-driven agentic coding |
| [readable-code](skills/readable-code/SKILL.md) | Writes clean, human-readable code in any language |
| [simple-software-design](skills/simple-software-design/SKILL.md) | Keeps code structure simple, with SOLID, DRY and KISS in any language |

### scaffold-project

Gives a repo the same shape in any language, so humans and agents can build from specs. Install it, then ask your agent to scaffold, bootstrap or set up a project, or to add specs, linting, CI or security scanning to an existing repo.

```bash
npx skills add nofea/agent-skills@scaffold-project
```

What a scaffolded project gets:

- **Specs:** `specs/` holds the product, the architecture and one folder per feature. Agents read it before coding and update it as they work.
- **Agent instructions:** `AGENTS.md` covers how to work in the repo, and `CLAUDE.md` imports it.
- **Language-appropriate layout:** folders and tool config for Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET or C/C++, with a generic fallback for anything else. Projects can be a CLI, library, web service/API or web app.
- **Allman braces:** generated formatter configs use Allman in C, C++, C#, Java, PHP and Swift. Other languages keep their standard style.
- **Makefile:** the same verbs in every language: `build`, `lint`, `fmt`, `test`, `security`, `check` and `doctor`.
- **Automation:** pre-commit hooks, GitHub Actions CI and Dependabot.
- **Security scanning:** gitleaks, semgrep, trivy and a dependency audit.
- **Docs:** `README.md` for users, `CONTRIBUTING.md` for developers, plus `SECURITY.md`, `LICENSE`, `.editorconfig` and `.gitignore`.

How it works:

1. It detects whether the repo is new, existing or polyglot.
2. It asks a few questions in one message: name, purpose, languages, project type, license and GitHub repo.
3. It shows a file plan and waits for your approval before writing anything.
4. It generates the files and specs. In an existing repo, it reverse-engineers the specs from the code.
5. It runs `make doctor` and `make check`, then reports the results and your next steps.

The skill never runs git commands that change state, so committing stays with you. It also asks before installing tools or overwriting existing files.

### readable-code

Makes agents write code in one consistent, readable style. Once installed, it applies whenever your agent writes or edits code.

```bash
npx skills add nofea/agent-skills@readable-code
```

The rules:

- **Allman braces** in C, C++, C#, Java, PHP and Swift, with braces on every block. Other languages keep their standard style, because their formatters can't do Allman or, in Go, it doesn't compile.
- **Blank lines** around `if`/`else`, loops, `switch`/`match`, `try`/`catch` and similar blocks, in every language.
- **Core guidelines** for each language, such as the C++ Core Guidelines, PEP 8 and Effective Go. The agent reads only the ones it needs.

If a repo enforces its own style through a formatter, linter or CI check, that style wins and the agent tells you. Otherwise, new code uses these rules and small edits match the function around them. Unchanged code is left alone. The skill includes sample formatter configs, which are added to a repo only if you ask.

### simple-software-design

Makes agents design simple, elegant code structure in any language. Once installed, it applies whenever your agent writes or edits code, and when you ask it to review or audit a design. It covers functions, types, modules, and their boundaries and dependencies. It only covers system design, such as microservices or databases, if you ask.

```bash
npx skills add nofea/agent-skills@simple-software-design
```

The rules:

- **Priority:** language requirements come first, then your repo's architecture docs, then SOLID, DRY and KISS, in that order.
- **Real needs only:** SOLID and DRY only win over a concrete problem in today's code. They never justify interfaces, layers or extension points for an imagined future.
- **DRY means knowledge:** two places that encode the same rule get merged straight away. Code that only looks alike stays separate.
- **Native idioms:** principles are applied through functions, modules, traits or protocols, with no classes added just to satisfy a principle.

How it works:

- **Small changes** follow the existing structure, with a quick check against the principles.
- **Larger changes** that add a module, boundary, dependency or pattern get a few lines on the structure and trade-off, and then the agent carries on. It stops to ask only about choices that are hard to reverse, such as a new external dependency or a public API.
- **Existing code** is improved only where the task touches it. Other problems are flagged and left unchanged.
- **Reviews** start by confirming what to review. Findings are ordered by severity, with the location, principle, harm and simplest fix. The agent then offers to apply the ones you choose.

## Adding a skill

1. Run `./scripts/new-skill.sh my-skill`. This creates `skills/my-skill/SKILL.md` from `templates/SKILL.template.md`.
2. Edit the `description` (it decides when the skill triggers) and write the body.
3. Optional: add `references/`, `scripts/`, or `assets/` folders next to `SKILL.md`.
4. Add a row to the table above.
5. Test it locally: `npx skills add . --list`.

## Layout

```
skills/<name>/SKILL.md     # one folder per skill; frontmatter `name` must match the folder
templates/                 # starter files (not installable)
scripts/                   # repo tooling
```
