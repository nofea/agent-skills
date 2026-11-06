# Other languages (generic fallback)

Use this for languages without a curated reference (Ruby, PHP, Elixir, Swift, Dart, Zig, Haskell, …). Apply the same principles with the language's **standard, community-default** tools. If you're unsure which tool is the default, ask the user rather than guessing.

## Pick, for each concern

| Concern | Choose | Examples |
| --- | --- | --- |
| Init / package manager | the official one | `bundle init`, `composer init`, `mix new`, `swift package init`, `dart create`, `zig init`, `cabal init` |
| Formatter | the official or near-universal one | rubocop -a / standardrb, php-cs-fixer, `mix format`, SwiftFormat, `dart format`, `zig fmt`, ormolu/fourmolu |
| Linter / type checker | the most adopted one, with security rules if available | rubocop + brakeman (Rails), phpstan/psalm, credo + sobelow (Phoenix), swiftlint, `dart analyze`, hlint |
| Tests | the default framework | rspec/minitest, phpunit/pest, ExUnit, XCTest/swift-testing, `dart test`, `zig build test`, hspec |
| Dependency audit | the ecosystem's advisory tool, otherwise `osv-scanner scan source -r .` | bundler-audit, `composer audit`, `mix deps.audit`/`mix hex.audit` |
| Dependabot ecosystem | if supported | bundler, composer, mix, swift, pub |

## Rules

- PHP: set php-cs-fixer's `braces_position` rule with `control_structures_opening_brace`, `functions_opening_brace` and `classes_opening_brace` all set to `next_line_unless_newline_at_signature_end`, and set `control_structure_continuation_position` to `next_line`, so code uses Allman braces.
- Swift: use SwiftFormat, with `--allman true` in `.swiftformat`, so code uses Allman braces. Apple's swift-format has no Allman option.
- Same Makefile verbs: `setup build fmt fmt-check lint test security-deps clean`. `build` can be a no-op with a comment for interpreted languages that have no build step.
- `test` must pass when there are no tests yet.
- Use the language's conventional layout (`lib/` + `spec/`, `src/` + `tests/`, `Sources/` + `Tests/` …). Don't invent one.
- Pin the language version the way the ecosystem does (`.ruby-version`, `composer.json` `require.php`, `.tool-versions`, `Package.swift` tools version).
- Write the toolchain, with install links, into CONTRIBUTING.md's Prerequisites. `doctor.sh generic` can't check it, so add `need <tool> <tool> --version` lines for the toolchain to the generated project's copy of `scripts/doctor.sh`.
- Tell the user, in the hand-off, which tool choices you made and that this language isn't one of the curated ones.

## Doxygen

Doxygen also reads PHP, Objective-C, Fortran, D and IDL. For these, set up the doc comment check as `SKILL.md` describes, with the language's source folder as `{{doxygen_input}}` and its extensions as `{{doxygen_file_patterns}}`. For PHP, use `*.php` and set `{{docs_check_args}}` to `--require-file-doc <source folder>`. Only PHP's setup has been tested, so run `make docs-check` on one undocumented function first to confirm it fails.

Skip this for any other language.
