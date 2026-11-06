# Java

Source: *Effective Java* (Joshua Bloch) and the naming and programming rules in the [Google Java Style Guide](https://google.github.io/styleguide/javaguide.html). Its brace rules don't apply here.

**Allman: yes.** google-java-format can't produce it, so use Spotless with the Eclipse formatter profile.

- **Naming:** `PascalCase` for types, `camelCase` for methods and fields, `UPPER_SNAKE_CASE` for constants, and lowercase packages.
- **Immutability:** make fields `final` and classes immutable where you can. Use records for plain data.
- **Design:** prefer composition to inheritance, and depend on interfaces such as `List` rather than `ArrayList`.
- **Nulls:** return empty collections rather than null, and use `Optional` for return values that may be absent, not for fields or parameters.
- **Errors:** throw specific exceptions, and never swallow one with an empty `catch`.
- **Resources:** use try-with-resources.
- **Generics:** avoid raw types.
- **Overrides:** use `@Override`, and implement `hashCode` whenever you implement `equals`.

## Doc comments

Use Javadoc, with a first sentence as the brief, then `@param`, `@return` and `@throws`. Doxygen reads it as is.

```java
/**
 * Applies a percentage discount to an order total.
 *
 * @param total order total in cents
 * @param percent discount from 0 to 100
 * @return the discounted total in cents
 * @throws IllegalArgumentException if percent is out of range
 */
public int applyDiscount(int total, int percent)
```
