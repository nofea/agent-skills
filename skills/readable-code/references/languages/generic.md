# Other languages

**Allman: no.** Keep the language's normal style. The blank-line rule still applies.

Find the language's official or most widely used style guide, and follow it for anything the house rules don't cover. If its formatter exists, use it. Examples are [Ruby Style Guide](https://rubystyle.guide/), `mix format` for Elixir, `dart format`, `zig fmt`, and the [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html).

These apply everywhere:

- Name things for what they mean, and use the language's naming convention.
- Keep functions short, with one job.
- Handle errors explicitly.
- Prefer early returns to deep nesting.
- Use the language's standard idioms over ones borrowed from elsewhere.

## Doc comments

Use the language's standard doc comment format, covering the content the house rules require. If the language has none but Doxygen supports it, use Doxygen tags.
