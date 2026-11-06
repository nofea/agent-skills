# C / C++

Source: [C++ Core Guidelines](https://isocpp.github.io/CppCoreGuidelines/CppCoreGuidelines). For C, use the [SEI CERT C Coding Standard](https://wiki.sei.cmu.edu/confluence/display/c).

**Allman: yes.** The formatter is clang-format, with `BreakBeforeBraces: Allman`.

- **Resources:** tie them to object lifetimes (RAII). Avoid naked `new` and `delete`, and prefer `std::unique_ptr`, then `std::shared_ptr` when ownership is really shared.
- **Interfaces:** make them explicit and strongly typed. Use `std::span` or `std::string_view` for non-owning ranges, and references when null isn't valid.
- **Immutability:** use `const` by default and `constexpr` where possible.
- **Initialisation:** always initialise variables, and declare them as late as you can.
- **Types:** use `enum class` over plain enums, and C++ casts over C casts. Use `nullptr`, never `NULL` or `0`.
- **Classes:** follow the rule of zero. If you define one special member, define or delete them all.
- **Errors:** throw exceptions for errors that can't be handled locally, unless the project bans them. Never ignore a return code.
- **Naming:** use the project's convention. Otherwise use `snake_case` for functions and variables and `PascalCase` for types. Keep each file's naming consistent.
- **C:** check every allocation and return value, use one clear cleanup path, and use bounded string functions.

## Doc comments

Use Doxygen `/** */` blocks with `@brief`, `@param`, `@return` and `@throws`. Start each file with a bare `@file` comment, because Doxygen skips undocumented global functions in a file without one.

```cpp
/**
 * @file
 * @brief Order discount calculations.
 */

/**
 * @brief Applies a percentage discount to an order total.
 * @param total Order total in cents.
 * @param percent Discount from 0 to 100.
 * @return The discounted total in cents.
 */
int ApplyDiscount(int total, int percent);
```
