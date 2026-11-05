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

### scaffold-project

Gives a repo the same shape in any language, so humans and agents can build from specs. Install it, then ask your agent to scaffold, bootstrap or set up a project, or to add specs, linting, CI or security scanning to an existing repo.

```bash
npx skills add nofea/agent-skills@scaffold-project
```

What a scaffolded project gets:

- **Specs:** `specs/` holds the product, the architecture and one folder per feature. Agents read it before coding and update it as they work.
- **Agent instructions:** `AGENTS.md` covers how to work in the repo, and `CLAUDE.md` imports it.
- **Language-appropriate layout:** folders and tool config for Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET or C/C++, with a generic fallback for anything else. Projects can be a CLI, library, web service/API or web app.
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
