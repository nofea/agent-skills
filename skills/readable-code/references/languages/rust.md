# Rust

Source: [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/) and [The Rust Style Guide](https://doc.rust-lang.org/style-guide/). Use Clippy's defaults.

**Allman: no.** rustfmt's brace options are nightly-only, so keep the standard style. The blank-line rule still applies.

- **Naming:** `snake_case` for functions and variables, `PascalCase` for types and traits, `SCREAMING_SNAKE_CASE` for constants.
- **Errors:** return `Result` and propagate with `?`. Avoid `unwrap` and `expect` in library code.
- **Ownership:** borrow rather than clone, and accept `&str` and `&[T]` over `&String` and `&Vec<T>`.
- **Types:** use enums and newtypes so invalid states can't be represented. Use `match` for exhaustive handling.
- **Traits:** derive common traits such as `Debug`, `Clone` and `PartialEq` where they make sense.
- **Iterators:** prefer them when they read more clearly than index loops.
- **Unsafe:** keep `unsafe` minimal, and add a `// SAFETY:` comment to each block.
