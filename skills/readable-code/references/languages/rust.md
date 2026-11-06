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

## Doc comments

Doxygen can't read Rust, so use rustdoc `///` comments, with `# Arguments`, `# Returns` and `# Errors` sections. Add `# Panics` if the function can panic.

```rust
/// Applies a percentage discount to an order total.
///
/// # Arguments
///
/// * `total` - Order total in cents.
/// * `percent` - Discount from 0 to 100.
///
/// # Returns
///
/// The discounted total in cents.
///
/// # Errors
///
/// Returns `DiscountError` if `percent` is out of range.
pub fn apply_discount(total: u32, percent: u32) -> Result<u32, DiscountError> {
```
