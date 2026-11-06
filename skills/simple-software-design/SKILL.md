---
name: simple-software-design
description: Designs simple, elegant software structure in any programming language, with SOLID, DRY and KISS applied to functions, types, modules, and their boundaries and dependencies. Use whenever writing, editing, implementing or refactoring code, including new features and bug fixes, and when designing modules or interfaces, deciding where code belongs, or reviewing or auditing a codebase's design or architecture. Not for formatting or code style, or for system design such as microservices, databases or hosting unless the user asks.
---

# simple-software-design

Build the simplest structure that keeps the code correct and easy to change. Apply these rules to the code you write, change or review.

This skill owns structure. It doesn't cover formatting or style, so it can run alongside a style skill such as `readable-code`.

## Which rule wins

When rules conflict, the first match in this list wins:

1. **What the language requires.** Code must compile and keep its meaning.
2. **The repo's architecture docs.** Decisions recorded in `specs/architecture.md`, ADRs or similar are binding. If the best design contradicts one, follow the doc and flag it to the user.
3. **SOLID.**
4. **DRY.**
5. **KISS.** It decides everything the rules above leave open.

**The real-needs guard applies to all of this.** SOLID and DRY only win over a concrete problem in today's code. They never justify structure for an imagined future.

A concrete problem is something you can point at:

- a module with two unrelated reasons to change
- two implementations that exist now
- a rule that's written in two places
- behaviour you can't test because of a hard-wired dependency

"We might need this later" isn't a concrete problem. Without one, don't add the interface, layer, factory or extension point. Write the plain code, which is easy to restructure when a real need arrives.

## The principles

Read [references/principles.md](references/principles.md) for warning signs, pseudocode examples and how each principle can be overdone.

### SOLID

- **Single responsibility:** give each function, type and module one reason to change.
- **Open/closed:** when variation already exists, add new behaviour by adding code, not by editing a growing conditional.
- **Liskov substitution:** anything that claims to fulfil a contract must honour all of it, with no surprises for callers.
- **Interface segregation:** make callers depend only on what they use.
- **Dependency inversion:** keep business rules independent of I/O and infrastructure details, by passing those details in.

Apply the intent of each principle through what the language offers, such as functions, modules, traits, protocols or closures. Never add classes or inheritance just to satisfy a principle.

### DRY

DRY is about knowledge, not text. Extract as soon as two places encode the same rule or fact, so that they must always change together. Don't wait for a third copy.

Code that only looks alike stays separate. To tell the difference, ask: if one copy changed, would the other have to change too? If not, they aren't duplicates.

### KISS

- Prefer fewer concepts, fewer layers and fewer indirections.
- Prefer plain functions and data over frameworks and patterns.
- Prefer the standard library over a new dependency.
- If two designs both satisfy the rules above, choose the one that's easier to explain.

## Writing code

1. **Read first.** Read the repo's architecture docs, if any, and the code around the change. Follow the established structure.
2. **Size the change.** It needs a design pass if it adds a module, boundary, dependency or pattern. Otherwise, do a quick check against the principles and go to step 4.
3. **Do the design pass.** State the structure and its main trade-off in a few lines, then carry on without waiting. Stop and ask first only for choices that are hard to reverse, such as a new external dependency, a public API or a stored data format.
4. **Build.** Improve only what the task touches.
5. **Report.** Flag design problems you noticed elsewhere, and any contradiction with the repo's docs, without changing them. If the task changed the architecture and an architecture doc exists, update that doc. Don't create one.

## Reviewing code

Follow these steps for code reviews and architecture audits.

1. **Confirm the target.** If the user didn't name one, ask what to review, such as the current changes, a module or the whole repo.
2. **Read first.** Read the repo's architecture docs, then review against the rules above, including the real-needs guard. Flagging speculative structure is as valid as flagging a missing boundary.
3. **Report the findings,** most severe first. Make no edits at this stage. Each finding gives:
   - the file and line
   - the principle broken
   - the concrete harm
   - the simplest fix
4. **Drop findings with no real harm.** If you can't name the harm, leave it out. If nothing survives, say so.
5. **Offer to apply the fixes.** Let the user choose which ones. Change code only after they say yes.
