# Specs

Specs are the source of truth for **what** to build and **why**. Code is how it was built. Agents read the relevant spec before changing code. If the code and the spec disagree, the agent updates the spec in the same change, or stops and asks.

## Layout

```
specs/
  product.md              # vision, users, problems, scope, non-goals, success measures
  architecture.md         # components, data flow, key decisions, constraints, tech stack
  features/
    README.md             # index table: id, name, status, owner (keep it updated)
    001-user-login/
      requirements.md     # user stories + EARS acceptance criteria
      design.md           # approach, interfaces, data, error handling, alternatives rejected
      tasks.md            # ordered, checkable implementation tasks linked to requirements
```

The templates are in `assets/specs/`. `specs/features/README.md` is created from `assets/specs/features-README.md.tmpl`.

## Feature folders

- Name them `NNN-kebab-name`, with a 3-digit, zero-padded, increasing number. Never reuse a number.
- One folder per **user-visible capability**, such as "export report as CSV". Use "the reporting module" only when there's no user-facing framing.
- The `Status:` header in `requirements.md` is one of these:
  - `Draft`: being written
  - `Approved`: ready to build
  - `In progress`
  - `Implemented`: code matches the spec
  - `Deprecated`
- Mirror the status in the `features/README.md` index.

## EARS acceptance criteria

Write each requirement as one testable sentence using an EARS pattern. Give each one an ID (`R1`, `R2`, …) so tasks and tests can refer to it.

| Pattern | Template |
| --- | --- |
| Ubiquitous | The `<system>` shall `<response>`. |
| Event-driven | When `<trigger>`, the `<system>` shall `<response>`. |
| State-driven | While `<state>`, the `<system>` shall `<response>`. |
| Unwanted behaviour | If `<condition>`, then the `<system>` shall `<response>`. |
| Optional feature | Where `<feature is included>`, the `<system>` shall `<response>`. |

Example: `R3: If the uploaded file exceeds 10 MB, then the API shall reject it with HTTP 413 and an error message naming the limit.`

## Tasks

`tasks.md` is a checklist. Each task is small enough for one focused change, names the requirement IDs it satisfies, and says how it will be verified:

```
- [ ] T1 Add CSV serializer for Report (R1, R2), unit tests for quoting and empty reports
- [ ] T2 Wire `export --format csv` flag (R1), CLI integration test
```

Agents tick tasks off as they finish them and add any new tasks they discover. They never silently drop a task.

## The spec-first loop (goes into AGENTS.md)

1. Find the feature in `specs/features/`. If it's missing and the change isn't trivial, draft the spec and ask for review before writing code.
2. Read `requirements.md` and `design.md`, then work through `tasks.md` in order.
3. Write tests that cover the requirement IDs.
4. Run `make check`.
5. Update `tasks.md`, the status, and `architecture.md` if the structure changed.
