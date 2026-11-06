# Go

Source: [Effective Go](https://go.dev/doc/effective_go) and [Go Code Review Comments](https://go.dev/wiki/CodeReviewComments).

**Allman: no.** It doesn't compile, because Go inserts a semicolon at the end of the line. gofmt is required. The blank-line rule still applies, and gofmt keeps those blank lines. That includes a blank line before `if err != nil`.

- **Naming:** use `MixedCaps`, with an exported name starting in a capital. Keep names short, with short package names that don't repeat in identifiers.
- **Errors:** return errors as values and handle each one. Wrap with `fmt.Errorf("doing x: %w", err)`, and don't panic for normal failures.
- **Interfaces:** define small ones where they're used. Accept interfaces and return concrete types.
- **Concurrency:** pass `context.Context` as the first parameter, and make sure every goroutine can stop.
- **Cleanup:** use `defer`.
- **Control flow:** handle errors first and return early, keeping the normal path unindented.

## Doc comments

Doxygen can't read Go, so use GoDoc comments. Start with the function's name, and cover parameters, the return value and errors in prose. There are no tags.

```go
// ApplyDiscount returns total, in cents, reduced by percent, which must be from 0 to 100.
// It returns an error if percent is out of range.
func ApplyDiscount(total, percent int) (int, error) {
```
