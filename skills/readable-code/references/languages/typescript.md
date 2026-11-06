# TypeScript / JavaScript

Source: the [TypeScript Handbook](https://www.typescriptlang.org/docs/handbook/) and [typescript-eslint recommended rules](https://typescript-eslint.io/rules/?=recommended).

**Allman: no.** Prettier has no brace option, so keep the standard style. The blank-line rule still applies, and Prettier keeps those blank lines.

- **Naming:** `camelCase` for functions and variables, `PascalCase` for types, classes and components.
- **Types:** use `strict` mode. Avoid `any`, and use `unknown` and narrowing instead. Prefer unions over enums for string sets.
- **Variables:** use `const` by default, then `let`. Never `var`.
- **Comparison:** use `===` and `!==`.
- **Absent values:** use `?.` and `??`.
- **Async:** use `async`/`await` and handle every promise.
- **Errors:** throw `Error` objects, and treat caught values as `unknown`.
- **Modules:** use ES modules and named exports.

## Doc comments

Doxygen can't read TypeScript or modern JavaScript, so use TSDoc, with `@param`, `@returns` and `@throws`.

```typescript
/**
 * Applies a percentage discount to an order total.
 *
 * @param total - Order total in cents.
 * @param percent - Discount from 0 to 100.
 * @returns The discounted total in cents.
 * @throws RangeError if percent is out of range.
 */
function applyDiscount(total: number, percent: number): number {
```
