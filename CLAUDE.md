# agent-skills

This repo holds reusable agent skills. Users install them with `npx skills add nofea/agent-skills@<name>`.

## Conventions

- One skill per folder: `skills/<name>/SKILL.md`. Create new skills with `./scripts/new-skill.sh <name>`.
- `name` in the frontmatter must be kebab-case and match the folder name exactly.
- `description` is the text that decides when the skill triggers. Say what the skill does **and** when to use it, including concrete phrases or situations.
- Keep `SKILL.md` focused. Put long material in `references/`, helper code in `scripts/`, and static files in `assets/`, all inside the skill's folder. Link to them from `SKILL.md`.
- Never put a file named `SKILL.md` outside `skills/`, because the CLI would treat it as an installable skill.
- When you add or remove a skill, update the skills table in `README.md`.
- Never commit or push. A human does that.
