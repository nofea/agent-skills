# Kotlin

Source: [Kotlin coding conventions](https://kotlinlang.org/docs/coding-conventions.html).

**Allman: no.** Keep the standard style, which ktlint enforces. The blank-line rule still applies.

- **Naming:** `PascalCase` for types, `camelCase` for functions and properties, `UPPER_SNAKE_CASE` for constants.
- **Immutability:** prefer `val` and read-only collections.
- **Nulls:** use nullable types, `?.`, `?:` and `let`. Avoid `!!`.
- **Data:** use data classes for plain data and sealed types for closed sets of cases.
- **Expressions:** use `when`, and expression bodies for short functions.
- **Coroutines:** use structured concurrency, and don't use `GlobalScope`.
- **Errors:** use exceptions for failures, and nullable or sealed results for expected absence.

## Doc comments

Doxygen can't read Kotlin, so use KDoc, with `@param`, `@return` and `@throws`.

```kotlin
/**
 * Applies a percentage discount to an order total.
 *
 * @param total order total in cents
 * @param percent discount from 0 to 100
 * @return the discounted total in cents
 * @throws IllegalArgumentException if percent is out of range
 */
fun applyDiscount(total: Int, percent: Int): Int {
```
