# Swift

Source: [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/).

**Allman: yes.** The formatter is SwiftFormat with `--allman true`. Apple's swift-format has no Allman option.

- **Naming:** `PascalCase` for types and protocols, `camelCase` for everything else. Name for clarity at the call site, so calls read like English phrases.
- **Immutability:** prefer `let`, and prefer value types (`struct`, `enum`) unless you need identity.
- **Optionals:** use `guard let`, `if let` and `??`. Avoid `!` and `try!`.
- **Errors:** use `throws` for recoverable failures.
- **Access:** use the narrowest access level that works.
- **Concurrency:** use `async`/`await` and actors over manual locks.
- **Closures:** a single-line closure may stay on one line.

## Doc comments

Doxygen can't read Swift, so use `///` markup, with `- Parameter`, `- Returns` and `- Throws`.

```swift
/// Applies a percentage discount to an order total.
///
/// - Parameter total: Order total in cents.
/// - Parameter percent: Discount from 0 to 100.
/// - Returns: The discounted total in cents.
/// - Throws: `DiscountError` if percent is out of range.
func applyDiscount(total: Int, percent: Int) throws -> Int
```
