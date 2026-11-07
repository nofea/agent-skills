# Principles

Each principle below has the rule, its warning signs, a short pseudocode example and what over-applying it looks like. The examples show the shape of a change, not a required style. Use your language's own idioms, and remember the real-needs guard in [SKILL.md](../SKILL.md#which-rule-wins).

## Contents

- [Single responsibility](#single-responsibility)
- [Open/closed](#openclosed)
- [Liskov substitution](#liskov-substitution)
- [Interface segregation](#interface-segregation)
- [Dependency inversion](#dependency-inversion)
- [DRY](#dry)
- [KISS](#kiss)
- [Game code](#game-code)

## Single responsibility

**Rule:** Give each function, type and module one reason to change. A reason to change usually maps to one concern or one group of people asking for changes.

**Warning signs:**

- The name needs "and", or a vague word such as "manager", "utils" or "helper".
- Unrelated changes keep landing in the same place.
- A test for one behaviour has to set up something unrelated.

**Before:**

```text
function create_invoice(order):
    total = sum of order.lines
    html = render invoice template with total
    write html to disk
    send email with html
```

**After:**

```text
function invoice_total(order):
    return sum of order.lines

function render_invoice(order, total):
    return render invoice template with total

function create_invoice(order):
    total = invoice_total(order)
    html = render_invoice(order, total)
    write html to disk
    send email with html
```

**Without classes:** The rule applies to functions, modules and packages just the same.

**Overdone:** Splitting a short, cohesive function into many one-line pieces that the reader must follow around. If the parts always change together, they're one responsibility.

## Open/closed

**Rule:** When variation already exists, add new behaviour by adding code, not by editing a growing conditional that several places depend on.

**Warning signs:**

- Each new case means editing the same conditional.
- The same set of cases is checked in more than one place.

**Before:**

```text
function shipping_cost(order):
    if order.method == "standard": return standard rate
    if order.method == "express": return express rate
    if order.method == "freight": return freight rate
```

**After:**

```text
shipping_rates = {
    "standard": standard_rate,
    "express": express_rate,
    "freight": freight_rate,
}

function shipping_cost(order):
    return shipping_rates[order.method](order)
```

**Without classes:** Use a lookup table of functions, pattern matching over a closed set of cases, traits or protocols. In some languages, an exhaustive match is the better choice, because the compiler then finds every place a new case must be handled.

**Overdone:** Adding a plugin system or strategy type when only one behaviour exists. A single `if` with two stable branches is fine.

## Liskov substitution

**Rule:** Anything that claims to fulfil a contract must honour all of it. Callers shouldn't need to know which implementation they have.

**Warning signs:**

- Callers check the concrete type before using a value.
- An implementation throws "not supported" for part of its contract.
- An implementation accepts less, or returns less, than the contract promises.

**Before:**

```text
contract Storage:
    read(key)
    write(key, value)

ReadOnlyStorage implements Storage:
    read(key): return value
    write(key, value): fail "not supported"
```

**After:**

```text
contract Reader:
    read(key)

contract Writer:
    write(key, value)

ReadOnlyStorage implements Reader:
    read(key): return value
```

**Without classes:** The contract is whatever callers rely on: a function's signature and its documented behaviour, a trait, a protocol or a duck-typed shape. A replacement function must honour it too, including its errors and edge cases.

**Overdone:** Designing elaborate contract hierarchies up front. Define a contract when two real implementations need one.

## Interface segregation

**Rule:** Make callers depend only on what they use.

**Warning signs:**

- Callers use a small part of a large interface.
- Test doubles need many stubs that the test never calls.
- A change to an unused method forces callers to change.

**Before:**

```text
function send_receipt(user_record, order):
    email(user_record.email, order)
```

Here, `user_record` carries the user's password hash, address and payment details, none of which `send_receipt` needs.

**After:**

```text
function send_receipt(email_address, order):
    email(email_address, order)
```

**Without classes:** Pass narrower arguments, export smaller module surfaces, or use small traits or protocols.

**Overdone:** Creating a separate one-method interface for every caller. Split only when callers really need different subsets.

## Dependency inversion

**Rule:** Keep business rules independent of I/O and infrastructure details. Pass those details in, so the rules don't reach out for them.

**Warning signs:**

- A business rule can't be tested without a database, network or clock.
- Replacing an infrastructure detail means editing business rules.

**Before:**

```text
function is_overdue(invoice):
    return database_connection.now() > invoice.due_date
```

**After:**

```text
function is_overdue(invoice, now):
    return now > invoice.due_date
```

**Without classes:** Passing a value or a function as an argument is often all you need. A dependency injection container is rarely necessary.

**Overdone:** Adding an interface for every dependency, each with a single implementation and no testing need. Stable dependencies, such as the standard library, can be used directly.

## DRY

**Rule:** Every piece of knowledge has one authoritative place. Extract as soon as two places encode the same rule or fact, so that they must always change together.

**Warning signs:**

- A change to one rule means finding and editing several places.
- The same constant, validation or business rule appears in more than one file.
- A bug fix had to be applied twice.

**Before:**

```text
function can_checkout(user):
    return user.age >= 18

function can_register(user):
    return user.age >= 18
```

If both depend on one legal adult age, it's one fact:

**After:**

```text
LEGAL_ADULT_AGE = 18

function is_adult(user):
    return user.age >= LEGAL_ADULT_AGE
```

**Overdone:** Merging code that only looks alike. If checkout's age limit could change without registration's limit changing, they're two facts that happen to share a value, so keep them separate. Flags added to a shared function so it can serve different callers are a sign that it merged unrelated things.

## KISS

**Rule:** Prefer the design with the fewest concepts, layers and indirections that still satisfies the rules above.

**Warning signs:**

- A pattern or layer has only one use and adds nothing today.
- Following one behaviour means jumping through several files.
- The design takes longer to explain than the problem.
- A new dependency replaces a few lines of plain code.

**Before:**

```text
contract GreetingStrategy:
    greet(name)

DefaultGreetingStrategy implements GreetingStrategy:
    greet(name): return "Hello, " + name

GreetingStrategyFactory:
    create(): return new DefaultGreetingStrategy

greeting = GreetingStrategyFactory.create().greet(name)
```

**After:**

```text
function greet(name):
    return "Hello, " + name
```

**Overdone:** Using simplicity as a reason to ignore a real problem. SOLID and DRY rank above KISS, so a concrete violation still gets fixed, in the simplest way that fixes it.

## Game code

**Rule:** The same principles apply. A game adds a hard limit, which is the time each frame gets, and an engine that already owns the main loop and object model.

**Warning signs:**

- A `GameManager` or similar type that everything talks to.
- Game rules that can only run with a scene, a window or the engine loaded.
- Allocations in per-frame code that show up in a profiler as stutter.
- The same balance number written in code and in a data file.
- Pooling, job systems or a custom ECS with no profiler result behind them.

**Before:**

```text
class Player extends EngineNode:
    on_hit(amount):
        health = health - max(amount - armor, 0)
        if health <= 0: play death animation
```

**After:**

```text
function damage_taken(amount, armor):
    return max(amount - armor, 0)

class Player extends EngineNode:
    on_hit(amount):
        health = health - damage_taken(amount, armor)
        if health <= 0: play death animation
```

The rule now runs in a test without the engine, and the engine class stays in charge of the scene.

**Performance:** measure before you restructure, on the target hardware and with a release build, because debug builds mislead. Fix the worst result first. Record the measurement next to the change, so it's clear why the structure exists.

**Engine patterns:** use what the engine gives you, such as scenes, components, signals or systems, before writing your own. A second object model on top of the engine doubles what readers must learn.

**Overdone:** Wrapping every engine call behind your own interface, in case the engine changes. Engine choice is hard to reverse whatever you do, so isolate the rules worth testing and leave the rest as plain engine code.
