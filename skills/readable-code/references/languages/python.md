# Python

Source: [PEP 8](https://peps.python.org/pep-0008/), [PEP 20](https://peps.python.org/pep-0020/) and [PEP 257](https://peps.python.org/pep-0257/).

**Allman: not applicable.** The blank-line rule still applies, and black and ruff keep those blank lines.

- **Naming:** `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants, and a leading `_` for internals.
- **Types:** add type hints to public functions.
- **Idioms:** use comprehensions when they stay simple, `enumerate` and `zip` over index loops, and `pathlib` for paths.
- **Comparison:** use `is None` for `None`.
- **Errors:** catch specific exceptions, never a bare `except:`.
- **Resources:** use `with`.
- **Arguments:** never use a mutable default argument.

## Doc comments

Use docstrings that start with `"""!`, so Doxygen reads the `@brief`, `@param`, `@return` and `@throws` tags. A plain docstring hides the tags from Doxygen. The docstring goes first inside the function, so `help()` and `__doc__` keep working.

Start each module with a docstring too, because Doxygen skips undocumented functions in a module without one. An empty `__init__.py` doesn't need one.

A function annotated `-> None` needs `@return None.`, or Doxygen reports a missing return. The exception is `__init__`, which must have no `@return`.

```python
"""!
@brief Order discount calculations.
"""


def apply_discount(total: int, percent: int) -> int:
    """!
    @brief Applies a percentage discount to an order total.
    @param total Order total in cents.
    @param percent Discount from 0 to 100.
    @return The discounted total in cents.
    @throws ValueError If percent is out of range.
    """
```
