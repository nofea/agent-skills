# Go

Tooling: **go** toolchain · **gofmt** · **go vet** + **golangci-lint v2** (with gosec) · **go test** · **govulncheck**. The Go version is the latest stable, set in the `go` directive of `go.mod`.

## Init

```bash
go mod init github.com/<owner>/<name>      # or the module path the user gives
```

## Layout

Don't create `pkg/` or other speculative folders. Add them when there's code for them.

```
cmd/<name>/main.go     # CLI / service entry; `package main` + empty `func main() {}`
internal/              # private packages (add as needed)
<name>.go / doc.go     # library: package at the module root, doc.go with a package comment
go.mod  .golangci.yml
```

- **CLI:** use the `flag` package (stdlib) unless the user wants cobra.
- **Library:** the public API lives at the root package. Put helpers in `internal/`.
- **Service:** `cmd/server/main.go` and `internal/{httpapi,config}` using `net/http` (the Go 1.22+ router handles method and path patterns). Add `.env.example`.

## .golangci.yml

```yaml
version: "2"
linters:
  default: standard
  enable: [gosec, errorlint, bodyclose, misspell, revive, unconvert, gocritic]
formatters:
  enable: [gofmt, goimports]
```

## Makefile recipes

| Target | Recipe |
| --- | --- |
| `setup` | `go mod download` |
| `build` | `go build ./...` (CLI/service: also `go build -o bin/<name> ./cmd/<name>`) |
| `fmt` | `gofmt -w .` |
| `fmt-check` | `out=$$(gofmt -l .); if [ -n "$$out" ]; then echo "$$out"; exit 1; fi` |
| `lint` | `go vet ./... && golangci-lint run` |
| `test` | `go test ./...` (passes with no test files) |
| `security-deps` | `govulncheck ./...` |
| `clean` | `rm -rf bin coverage.out` |

Each recipe goes tab-indented under its target.

## .gitignore

`bin/ coverage.out *.test .env`

## Pre-commit local hook

```yaml
      - id: lint
        name: gofmt + vet + golangci-lint
        entry: make lint
        language: system
        pass_filenames: false
        types: [go]
```

## CI setup steps

```yaml
      - uses: actions/setup-go@<sha> # vX
        with:
          go-version-file: go.mod
      - uses: golangci/golangci-lint-action@<sha> # vX   (installs and runs golangci-lint)
        with:
          version: latest
      - run: go install golang.org/x/vuln/cmd/govulncheck@latest
```

`make lint` runs golangci-lint again. That's harmless, or you can leave out the action and install the binary instead. In CI, run `go test -race ./...` as well.

Dependabot ecosystem: `gomod`. Docker ignore extras: `bin coverage.out`.

## Dockerfile (service)

```dockerfile
FROM golang:1-bookworm AS build      # pin to the go.mod minor, e.g. golang:1.25
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/server /server
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```
