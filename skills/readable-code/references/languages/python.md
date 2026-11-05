# Python

Source: [PEP 8](https://peps.python.org/pep-0008/), [PEP 20](https://peps.python.org/pep-0020/) and [PEP 257](https://peps.python.org/pep-0257/).

**Allman: not applicable.** The blank-line rule still applies, and black and ruff keep those blank lines.

- **Naming:** `snake_case` for functions and variables, `PascalCase` for classes, `UPPER_SNAKE_CASE` for constants, and a leading `_` for internals.
- **Types:** add type hints to public functions.
- **Docstrings:** add them to public modules, classes and functions.
- **Idioms:** use comprehensions when they stay simple, `enumerate` and `zip` over index loops, and `pathlib` for paths.
- **Comparison:** use `is None` for `None`.
- **Errors:** catch specific exceptions, never a bare `except:`.
- **Resources:** use `with`.
- **Arguments:** never use a mutable default argument.
