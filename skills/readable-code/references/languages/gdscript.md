# GDScript

Source: [GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).

**Allman: no.** GDScript has no braces. The formatter is `gdformat` from gdtoolkit, and the linter is `gdlint`. gdformat keeps the house blank lines around logic blocks. Leave two blank lines around functions, as the style guide asks.

- **Indentation:** tabs. Continuation lines for function calls get two levels, and those for arrays, dictionaries and enums get one.
- **Naming:** `snake_case` for files, functions and variables, `PascalCase` for classes and nodes, `CONSTANT_CASE` for constants and enum members, and singular `PascalCase` for enums. A file holding a named class uses that name, so `YAMLParser` lives in `yaml_parser.gd`.
- **Private and virtual members:** start them with one underscore.
- **Signals:** `snake_case`, in the past tense, such as `door_opened`.
- **Types:** declare them, with `var health: int` and `-> void`. Use `:=` only when the type is clear from the same line. `as` gives `null` on a mismatch, so check the result.
- **Order:** annotations, `class_name`, `extends`, the doc comment, signals, enums, constants, static variables, `@export` variables, other variables, `@onready` variables, then methods. Built-in virtual methods come first, in the order `_init`, `_enter_tree`, `_ready`, `_process`, `_physics_process`.
- **Lines:** keep them under 100 characters.

## Doc comments

Use `##` lines directly above the member. GDScript has no parameter or return tags, so cover those in the text, with `[param name]` for parameters. Doxygen can't read GDScript, so nothing checks these automatically.

```gdscript
## Applies a percentage discount to an order total.
## [param total] is the order total in cents.
## [param percent] is the discount from 0 to 100.
## Returns the discounted total in cents.
func apply_discount(total: int, percent: int) -> int:
	return total - total * percent / 100
```
