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
| [hello-skill](skills/hello-skill/SKILL.md) | Sample skill that checks the install works (delete it later) |
| [scaffold-project](skills/scaffold-project/SKILL.md) | Scaffolds a new or existing repo for spec-driven agentic coding: specs/, AGENTS.md + CLAUDE.md, a language-appropriate layout, a Makefile (build/lint/test/security), pre-commit hooks, GitHub Actions CI, and README + CONTRIBUTING |

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
