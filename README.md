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
| [simple-software-design](skills/simple-software-design/SKILL.md) | Keeps code structure simple and secure, with SOLID, DRY, KISS and current secure-coding standards in any language |
| [system-architecture](skills/system-architecture/SKILL.md) | Designs, changes, reviews and explains secure systems, using current security standards, and explains its reasoning as it goes |

### scaffold-project

Gives a repo the same shape in any language, so humans and agents can build from specs. Install it, then ask your agent to scaffold, bootstrap or set up a project, or to add specs, linting, CI, security scanning or release signing to an existing repo.

```bash
npx skills add nofea/agent-skills@scaffold-project
```

What a scaffolded project gets:

- **Specs:** `specs/` holds the product, the architecture and one folder per feature. Agents read it before coding and update it as they work.
- **Agent instructions:** `AGENTS.md` covers how to work in the repo, and `CLAUDE.md` imports it.
- **Language-appropriate layout:** folders and tool config for Python, TypeScript/Node, Go, Rust, Java/Kotlin, C#/.NET or C/C++, with a generic fallback for anything else. Projects can be a CLI, library, web service/API, web app, mobile app or desktop app.
- **Allman braces:** generated formatter configs use Allman in C, C++, C#, Java, PHP and Swift. Other languages keep their standard style.
- **Dev environment:** `devenv.nix` gives everyone the same tools, with `devenv.lock` pinning them.
- **CI/CD in containers:** `ci/Containerfile` holds CI's toolchain, so `make ci-check` runs the same under podman or Docker, locally and on the server. Linux releases are built there too, because a binary built in devenv can link to `/nix/store`.
- **Makefile:** the same verbs in every language: `build`, `test`, `release`, `test-release`, `ci-check`, `ci-release`, `lint`, `fmt`, `security`, `check` and `doctor`.
- **Debug and release builds:** `build` and `test` use the debug profile, with sanitizers where the language has them. `release` and `test-release` use what ships, with compiler hardening for C/C++, and CI tests both.
- **Doc comment check:** `make docs` builds API docs and `make docs-check` fails on undocumented functions and types, using Doxygen. It covers Python, Java, C#, C/C++ and PHP, among others, but not Go, Rust, TypeScript or Kotlin. In existing repos it only reports until you turn it on.
- **Automation:** pre-commit hooks, GitHub Actions CI and Dependabot.
- **Security scanning:** gitleaks, semgrep, trivy and a dependency audit.
- **Signed releases (optional):** name your distribution targets, and a tag-triggered `release.yml` builds, signs and publishes behind an approval step. It covers package registries, containers, GitHub releases, mobile app stores, and desktop stores with OS signing.
- **Docs:** `README.md` for users, `CONTRIBUTING.md` for developers, plus `SECURITY.md`, `LICENSE`, `.editorconfig` and `.gitignore`.

How it works:

1. It detects whether the repo is new, existing or polyglot.
2. It asks a few questions in one message: name, purpose, languages, project type, license, GitHub repo and distribution targets.
3. It shows a file plan and waits for your approval before writing anything.
4. It generates the files and specs. In an existing repo, it reverse-engineers the specs from the code.
5. It runs `make doctor` and `make check`, then reports the results and your next steps.

The skill never runs git commands that change state, so committing stays with you. It also asks before installing tools or overwriting existing files. It never creates signing keys or publishes anything. It lists that setup for you instead.

### readable-code

Makes agents write code in one consistent, readable style. Once installed, it applies whenever your agent writes or edits code.

```bash
npx skills add nofea/agent-skills@readable-code
```

The rules:

- **Allman braces** in C, C++, C#, Java, PHP and Swift, with braces on every block. Other languages keep their standard style, because their formatters can't do Allman or, in Go, it doesn't compile.
- **Blank lines** around `if`/`else`, loops, `switch`/`match`, `try`/`catch` and similar blocks, in every language.
- **Doc comments** on every named function and type, in a Doxygen-style format or the language's own where Doxygen can't read it.
- **Inline comments** only where the logic is complex or the code can't explain itself.
- **Core guidelines** for each language, such as the C++ Core Guidelines, PEP 8 and Effective Go. The agent reads only the ones it needs.

If a repo enforces its own style through a formatter, linter or CI check, that style wins and the agent tells you. Otherwise, new code uses these rules and small edits match the function around them. Unchanged code is left alone. The skill includes sample formatter configs, which are added to a repo only if you ask.

### simple-software-design

Makes agents design simple, elegant code structure in any language. Once installed, it applies whenever your agent writes or edits code, and when you ask it to review or audit a design. It covers functions, types, modules, and their boundaries and dependencies, and it follows secure-coding standards for your language. System-level decisions, such as adding a database or a service, go to [system-architecture](#system-architecture) if it's installed. Otherwise, the agent asks you first.

```bash
npx skills add nofea/agent-skills@simple-software-design
```

The rules:

- **Priority:** language requirements come first, then the security baseline, your repo's architecture docs, and SOLID, DRY and KISS, in that order.
- **Real needs only:** SOLID and DRY only win over a concrete problem in today's code. They never justify interfaces, layers or extension points for an imagined future.
- **DRY means knowledge:** two places that encode the same rule get merged straight away. Code that only looks alike stays separate.
- **Native idioms:** principles are applied through functions, modules, traits or protocols, with no classes added just to satisfy a principle.
- **Secure by design:** every change gets a short security check. Sensitive code and larger changes also get a lookup of current standards, such as OWASP and SEI CERT. Core controls can't be waived, and other practices need you to accept the specific risk.
- **Lifecycle:** code stays upgradable, production faults are diagnosed from logs and telemetry only, and developer-mode code can't reach production. These rules apply even if no standard covers them.

How it works:

- **Small changes** follow the existing structure, with a quick check against the principles.
- **Larger changes** that add a module, boundary, dependency or pattern get a few lines on the structure and trade-off, and then the agent carries on. It stops to ask only about choices that are hard to reverse, such as a new external dependency or a public API.
- **Existing code** is improved only where the task touches it. Other problems are flagged and left unchanged.
- **Reviews** start by confirming what to review and include security. Findings are ordered by severity, with the location, principle or control, harm and simplest fix. The agent then offers to apply the ones you choose.

### system-architecture

Makes your agent a mentor-architect for whole systems. It recommends a design, explains the trade-offs in plain language, and leaves hard-to-reverse choices to you. Ask it to design, change, review or explain a system. It also activates when a coding task would add a data store, service, queue, production dependency or hosting change.

```bash
npx skills add nofea/agent-skills@system-architecture
```

The rules:

- **Simplest shape first:** each system type has a simple starting shape, and each addition needs a stated requirement, ideally with a number. Security components can instead trace to a named threat or an applicable control.
- **Secure by design:** it looks up current standards for the system, such as OWASP, NIST, ETSI and IEC 62443, builds a threat model, and applies a security baseline that outranks recorded decisions. Core controls can't be waived, and other controls need you to accept the specific risk.
- **Lifecycle:** every design plans for upgrades and patching, field debugging through logs and telemetry only, and a developer mode that can't reach production. These rules apply even if no standard covers them, and a stricter standard wins.
- **You confirm the system type:** the skill covers services and web apps, data and event systems, AI and agent systems, local software, and embedded devices with firmware and electronics. Anything else uses a generic guide. A system can combine types.
- **Decision level:** it decides what to use, but doesn't write infrastructure config. For electronics, it stops at block diagrams, power trees and part requirements, with no schematics or PCB layouts.
- **Safety:** it flags physically dangerous or regulated systems, and work with mains voltage, lithium batteries or high current, as needing review by a qualified engineer. It also raises privacy, sector security standards and other legal duties, but never confirms compliance. Check any named part against its datasheet.

How it works:

- **Design and Change** gather requirements, confirm the type and propose an overall shape. Hard-to-reverse decisions then come one at a time, and easy ones are listed. Change also adds a migration path. Nothing is written to the repo until you approve.
- **Review** reports risks in an existing system, including unneeded components, without changing anything.
- **Explain** describes how an existing system works, with a diagram and the likely reasoning, without changing anything.
- **Unknown numbers** are estimated with visible arithmetic and labelled as assumptions, with a note on what would trigger a revisit.
- **Decisions,** threat models, standards used and accepted risks go into `specs/architecture.md`, or your repo's existing architecture doc or ADRs. If you have none, it offers to create one.

Explanations are on by default, including a short decision card for each hard-to-reverse choice. Say "skip the explanations" for terse output.

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
