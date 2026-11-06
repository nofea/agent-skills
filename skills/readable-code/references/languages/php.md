# PHP

Source: [PER Coding Style](https://www.php-fig.org/per/coding-style/) (which extends PSR-12) and [PHP The Right Way](https://phptherightway.com/). Their brace rules for control structures don't apply here.

**Allman: yes.** The formatter is PHP-CS-Fixer, with the `braces_position` rule.

- **Types:** use `declare(strict_types=1);` and type all parameters, properties and returns.
- **Naming:** `PascalCase` for classes, `camelCase` for methods, `UPPER_SNAKE_CASE` for constants.
- **Autoloading:** follow PSR-4 with one class per file.
- **Comparison:** use `===` and `!==`.
- **Errors:** use exceptions, not error codes, and never use `@` to hide errors.
- **Security:** use prepared statements for SQL and escape output for its context.

## Doc comments

Use PHPDoc, with `@param`, `@return` and `@throws`. Doxygen reads it as is. Add a bare `@file` comment at the top of each file, because Doxygen skips undocumented global functions in a file without one.

```php
/**
 * Applies a percentage discount to an order total.
 *
 * @param int $total Order total in cents.
 * @param int $percent Discount from 0 to 100.
 * @return int The discounted total in cents.
 * @throws InvalidArgumentException If percent is out of range.
 */
function applyDiscount(int $total, int $percent): int
```
