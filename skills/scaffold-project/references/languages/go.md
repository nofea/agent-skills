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
| `test` | `go test -race ./...` (passes with no test files; `-race` needs cgo and a C compiler) |
| `release` | `CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o bin/release/<name> ./cmd/<name>` (library: `go build -trimpath ./...`) |
| `test-release` | `CGO_ENABLED=0 go test -trimpath ./...` |
| `security-deps` | `govulncheck ./...` |
| `clean` | `rm -rf bin coverage.out` |

Each recipe goes tab-indented under its target.

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- Go has one build mode, so the profiles differ by flags only. `make test` adds the race detector, and `make release` uses the flags the Dockerfile uses.
- `-s -w` removes the symbol table and DWARF data. Panic stack traces still work, so Go has no symbols to retain.
- Drop `CGO_ENABLED=0` if the project needs cgo. The Dockerfile's final image must then include a C library, so `static-debian12` no longer fits.
- **Artefacts:** `bin/release/<name>`.

## .gitignore

`.devenv*/ devenv.local.nix bin/ coverage.out *.test .env`

## Pre-commit local hook

```yaml
      - id: lint
        name: gofmt + vet + golangci-lint
        entry: make lint
        language: system
        pass_filenames: false
        types: [go]
```

## devenv

`{{devenv_languages}}`:
```nix
  languages.go.enable = true;
```

`{{devenv_packages}}`: `golangci-lint` `govulncheck`

## CI container

`ci/Containerfile`:
```dockerfile
FROM docker.io/library/golang:1-bookworm      # pin to the go.mod minor, e.g. golang:1.25
ENV GOBIN=/usr/local/bin
RUN go install golang.org/x/vuln/cmd/govulncheck@<version> \
    && go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@<version>
ENV HOME=/tmp GOPATH=/tmp/go GOCACHE=/tmp/go-build
USER 65532:65532
```

Replace each `<version>` with the latest release.

Dependabot ecosystem: `gomod`, and `docker` for `/ci`. Docker ignore extras: `bin coverage.out`.

## Dockerfile (service)

```dockerfile
FROM docker.io/library/golang:1-bookworm AS build      # pin to the go.mod minor, e.g. golang:1.25
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -trimpath -ldflags="-s -w" -o /out/server ./cmd/server   # same flags as `make release`

FROM gcr.io/distroless/static-debian12:nonroot
COPY --from=build /out/server /server
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/server"]
```
