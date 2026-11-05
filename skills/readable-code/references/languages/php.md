# PHP

Source: [PER Coding Style](https://www.php-fig.org/per/coding-style/) (which extends PSR-12) and [PHP The Right Way](https://phptherightway.com/). Their brace rules for control structures don't apply here.

**Allman: yes.** The formatter is PHP-CS-Fixer, with the `braces_position` rule.

- **Types:** use `declare(strict_types=1);` and type all parameters, properties and returns.
- **Naming:** `PascalCase` for classes, `camelCase` for methods, `UPPER_SNAKE_CASE` for constants.
- **Autoloading:** follow PSR-4 with one class per file.
- **Comparison:** use `===` and `!==`.
- **Errors:** use exceptions, not error codes, and never use `@` to hide errors.
- **Security:** use prepared statements for SQL and escape output for its context.
