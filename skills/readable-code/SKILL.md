---
name: readable-code
description: Writes clean, human-readable code in any programming language. It uses Allman braces in C, C++, C#, Java, PHP and Swift, puts a blank line around logic blocks such as if/else, loops, switch and try/catch, adds a Doxygen-style doc comment to every function and type, keeps inline comments to logic the code can't explain alone, and follows each language's core guidelines. Use whenever writing, editing or implementing code, including new features, bug fixes and requested refactors. Not for code review, or for reformatting code the task doesn't touch.
---

# readable-code

Apply these rules to the code you write or change. Don't reformat anything else.

## Which rule wins

When rules conflict, the first match in this list wins:

1. **What the language requires.** Code must compile and keep its meaning. In a game project, this includes what the engine's tooling requires, such as Unreal's type prefixes and macros.
2. **Enforced repo config.** If the repo enforces a style, follow it, even if it conflicts with the house rules. Tell the user which config overrode which rule.
3. **House rules.** Everything in this file.
4. **Language guidelines.** The language reference files, which never override house rules on layout.

A style is **enforced** when a formatter config, linter config, CI job or pre-commit hook sets it. Examples are `.clang-format`, `.prettierrc`, `eslint.config.*`, `.php-cs-fixer*`, `.swiftformat`, Spotless or Checkstyle setup, and doc comment lint rules such as `pydocstyle` or ruff's `D` rules. An `.editorconfig` counts only if it sets brace style. Indent settings alone don't count.

## Steps

1. Look for enforced style config in the repo.
2. Read the reference for each language you're writing, from the table below. In a game project, also read [engines.md](references/engines.md).
3. Write the code using the rules below, including a doc comment on each function and type you write or change.
4. If the repo has a formatter, run it on the files you changed only. If it has `make docs-check`, run that too.
5. Tell the user about any house rule that a repo config overrode.

## Allman braces

**Use Allman in C, C++, C#, Java, PHP and Swift.** Every other language keeps its normal style, including Go, Rust, JavaScript, TypeScript, Kotlin and GDScript.

- Put the opening and closing brace each on its own line, for functions, types, namespaces and control flow.
- Put `else`, `catch` and `finally` on their own line after the closing brace. The `while` of a `do` loop stays on the closing brace's line.
- Keep array and object initialisers and short inline lambdas on one line. A lambda with a multi-line body uses Allman.
- Always use braces in these languages, even for a single-statement body or guard.

## Blank lines

**In every language**, put one blank line before and after each logic block. Logic blocks are `if`/`else`, `for`, `while`, `do`, `switch`/`match`, `try`/`catch`, and scoped blocks such as `with`, `using` and `lock`. Short guards count.

- No blank line right after an opening brace or right before a closing brace. In languages without braces, none right after a line ending in `:` or `do`.
- One blank line between two adjacent blocks.
- `else`, `catch` and `finally` stay attached to their block, with no blank line between them.
- A comment that describes a block sits directly above it, after the blank line.
- `case` arms need no blank lines between them.
- This rule beats language idiom. In Go, `x, err := f()` gets a blank line before `if err != nil`.

```csharp
int Process(int count)
{
    if (count == 0)
    {
        return 0;
    }

    int total = 0;

    for (int i = 0; i < count; i++)
    {
        if (i % 2 == 0)
        {
            total += i;
        }
        else
        {
            total -= i;
        }
    }

    return total;
}
```

```python
def process(count):
    if count == 0:
        return 0

    total = 0

    for i in range(count):
        if i % 2 == 0:
            total += i
        else:
            total -= i

    return total
```

## Comments and documentation

Doc comments and inline comments follow separate rules. Doc comments are required. Inline comments are the exception.

### Doc comments

**Add a doc comment to every named function and method, and to every class, struct, interface and enum.** That includes private functions, constructors, overrides, engine callbacks such as `Update()` and `_process()`, and one-line getters. Anonymous lambdas, closures and test functions don't need one.

Each function's doc comment covers all of these, even when they look obvious:

- a one-line brief
- every parameter
- the return value, unless the function returns nothing
- every error it deliberately throws

Put the doc comment directly before the definition, with these exceptions:

- **Python:** the docstring goes first inside the function.
- **C and C++:** document a function declared in a header at that declaration, not at its definition.

Use the format from the language reference. C and C++ use Doxygen tags, Java, C#, PHP and Python use a native form that Doxygen also reads, and every other language uses its own doc format.

Files need a doc comment too in the languages where Doxygen skips global functions without one: `@file` in C, C++ and PHP, and a module docstring in Python.

```cpp
/**
 * @brief Applies a percentage discount to an order total.
 * @param total Order total in cents.
 * @param percent Discount from 0 to 100.
 * @return The discounted total in cents.
 * @throws std::invalid_argument If percent is out of range.
 */
int ApplyDiscount(int total, int percent);
```

### Inline comments

**Add an inline comment only where the logic is complex, or where reading the code isn't enough to understand it.** Explain why the code does something, not what it does. Good reasons are a non-obvious algorithm, a workaround and what it works around, or a constraint from outside the code.

Don't restate the code, label sections or leave commented-out code. If a clearer name would remove the need for a comment, rename instead.

## Files with a different style

These cases apply when no style is enforced:

- **New functions and types:** use the house rules.
- **Rewriting over half of a function:** convert the whole function.
- **Smaller edits:** match the enclosing function, so no function has two styles.
- **Lines you aren't changing:** leave them alone.
- **Doc comments:** add them to the functions you write or change. Leave other functions undocumented.

## Language guidelines

Read only the files you need.

| Language | Reference | Allman |
| --- | --- | --- |
| C, C++ | [cpp.md](references/languages/cpp.md) | Yes |
| C# | [csharp.md](references/languages/csharp.md) | Yes |
| Java | [java.md](references/languages/java.md) | Yes |
| PHP | [php.md](references/languages/php.md) | Yes |
| Swift | [swift.md](references/languages/swift.md) | Yes |
| GDScript | [gdscript.md](references/languages/gdscript.md) | No |
| Go | [go.md](references/languages/go.md) | No |
| Kotlin | [kotlin.md](references/languages/kotlin.md) | No |
| Python | [python.md](references/languages/python.md) | No |
| Rust | [rust.md](references/languages/rust.md) | No |
| TypeScript, JavaScript | [typescript.md](references/languages/typescript.md) | No |
| Anything else | [generic.md](references/languages/generic.md) | No |

These rules cover text only. Don't edit visual scripts or other binary assets, such as Unreal Blueprints. If your work depends on one, say that you didn't read it.

## Formatter configs

Add these to a repo only when the user asks. Each file says where it goes.

| Language | Asset |
| --- | --- |
| C, C++ | [clang-format](assets/clang-format) |
| Unreal C++ | [clang-format-unreal](assets/clang-format-unreal) |
| C# | [editorconfig-csharp](assets/editorconfig-csharp) |
| Java | [eclipse-java-allman.xml](assets/eclipse-java-allman.xml), used with Spotless `eclipse().configFile(...)` |
| PHP | [php-cs-fixer.php](assets/php-cs-fixer.php) |
| Swift | [swiftformat](assets/swiftformat) |

GDScript needs no asset, because `gdformat`'s defaults follow the style guide. These formatters enforce braces, but they can't add the blank lines around logic blocks. Those are up to you.
