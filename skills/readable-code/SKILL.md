---
name: readable-code
description: Writes clean, human-readable code in any programming language. It uses Allman braces in C, C++, C#, Java, PHP and Swift, puts a blank line around logic blocks such as if/else, loops, switch and try/catch, and follows each language's core guidelines. Use whenever writing, editing or implementing code, including new features, bug fixes and requested refactors. Not for code review, or for reformatting code the task doesn't touch.
---

# readable-code

Apply these rules to the code you write or change. Don't reformat anything else.

## Which rule wins

When rules conflict, the first match in this list wins:

1. **What the language requires.** Code must compile and keep its meaning.
2. **Enforced repo config.** If the repo enforces a style, follow it, even if it conflicts with the house rules. Tell the user which config overrode which rule.
3. **House rules.** Everything in this file.
4. **Language guidelines.** The language reference files, which never override house rules on layout.

A style is **enforced** when a formatter config, linter config, CI job or pre-commit hook sets it. Examples are `.clang-format`, `.prettierrc`, `eslint.config.*`, `.php-cs-fixer*`, `.swiftformat`, and Spotless or Checkstyle setup. An `.editorconfig` counts only if it sets brace style. Indent settings alone don't count.

## Steps

1. Look for enforced style config in the repo.
2. Read the reference for each language you're writing, from the table below.
3. Write the code using the rules below.
4. If the repo has a formatter, run it on the files you changed only.
5. Tell the user about any house rule that a repo config overrode.

## Allman braces

**Use Allman in C, C++, C#, Java, PHP and Swift.** Every other language keeps its normal style, including Go, Rust, JavaScript, TypeScript and Kotlin.

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

## Files with a different style

These cases apply when no style is enforced:

- **New functions and types:** use the house rules.
- **Rewriting over half of a function:** convert the whole function.
- **Smaller edits:** match the enclosing function, so no function has two styles.
- **Lines you aren't changing:** leave them alone.

## Language guidelines

Read only the files you need.

| Language | Reference | Allman |
| --- | --- | --- |
| C, C++ | [cpp.md](references/languages/cpp.md) | Yes |
| C# | [csharp.md](references/languages/csharp.md) | Yes |
| Java | [java.md](references/languages/java.md) | Yes |
| PHP | [php.md](references/languages/php.md) | Yes |
| Swift | [swift.md](references/languages/swift.md) | Yes |
| Go | [go.md](references/languages/go.md) | No |
| Kotlin | [kotlin.md](references/languages/kotlin.md) | No |
| Python | [python.md](references/languages/python.md) | No |
| Rust | [rust.md](references/languages/rust.md) | No |
| TypeScript, JavaScript | [typescript.md](references/languages/typescript.md) | No |
| Anything else | [generic.md](references/languages/generic.md) | No |

## Formatter configs

Add these to a repo only when the user asks. Each file says where it goes.

| Language | Asset |
| --- | --- |
| C, C++ | [clang-format](assets/clang-format) |
| C# | [editorconfig-csharp](assets/editorconfig-csharp) |
| Java | [eclipse-java-allman.xml](assets/eclipse-java-allman.xml), used with Spotless `eclipse().configFile(...)` |
| PHP | [php-cs-fixer.php](assets/php-cs-fixer.php) |
| Swift | [swiftformat](assets/swiftformat) |

These formatters enforce braces, but they can't add the blank lines around logic blocks. Those are up to you.
