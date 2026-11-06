# C / C++

Tooling: **CMake** (presets) + **Ninja** · **clang-format** · **clang-tidy** + compiler warnings as errors · **CTest** + **GoogleTest** (C: CTest only, unless the user wants a framework) · **osv-scanner**. Standard: C++20, or C17 for C.

## Init

There's no init tool, so write the files by hand.

## Layout

```
src/main.cpp              # executable: `int main() { return 0; }`
include/<name>/<name>.hpp # library public headers
src/<name>.cpp            # library sources (one minimal file, so the target builds)
tests/CMakeLists.txt      # GoogleTest via FetchContent; no test files yet
CMakeLists.txt  CMakePresets.json  .clang-format  .clang-tidy
```

- **CLI:** parse `argv` by hand, or use CLI11 if the user wants it (via FetchContent or vcpkg).
- **Library:** use `add_library(<name>)` with `target_include_directories(<name> PUBLIC include)`. Add an install/export setup only if asked.
- **Service:** ask which HTTP library to use (cpp-httplib, Drogon, Boost.Beast). There's no default.
- **Dependencies:** a vcpkg manifest (`vcpkg.json`) if the user wants a package manager. Otherwise FetchContent pinned to tags.

## CMakeLists.txt (root)

```cmake
cmake_minimum_required(VERSION 3.25)
project(<name> VERSION 0.1.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(<name> src/main.cpp)          # or add_library(...)
target_compile_options(<name> PRIVATE
  $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic -Werror>
  $<$<CXX_COMPILER_ID:MSVC>:/W4 /WX>)

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
```

`tests/CMakeLists.txt`: `FetchContent_Declare(googletest URL https://github.com/google/googletest/archive/refs/tags/v<latest>.tar.gz)`, `FetchContent_MakeAvailable(googletest)`, `include(GoogleTest)`. Add test executables later with `gtest_discover_tests`.

`CMakePresets.json`: a `dev` configure preset (Ninja, `Debug`, `binaryDir: build/dev`), a `release` preset, matching build presets, and a `dev` test preset with `"output": {"outputOnFailure": true}`.

`.clang-format` (Allman braces; short lambdas and initialisers stay on one line):
```yaml
BasedOnStyle: Google
BreakBeforeBraces: Allman
AllowShortBlocksOnASingleLine: Never
AllowShortCaseLabelsOnASingleLine: false
AllowShortFunctionsOnASingleLine: None
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false
AllowShortLambdasOnASingleLine: All
```

`.clang-tidy`:
```yaml
Checks: "-*,bugprone-*,cert-*,clang-analyzer-*,concurrency-*,cppcoreguidelines-*,modernize-*,performance-*,portability-*,readability-*,-modernize-use-trailing-return-type,-readability-magic-numbers,-cppcoreguidelines-avoid-magic-numbers"
WarningsAsErrors: "*"
HeaderFilterRegex: "(src|include)/.*"
```

## Makefile recipes

Define `SRC := $(shell find src include tests -name '*.[ch]' -o -name '*.[ch]pp' -o -name '*.cc' 2>/dev/null)` near the top.

| Target | Recipe |
| --- | --- |
| `setup` | `cmake --preset dev` |
| `build` | `cmake --build --preset dev` |
| `fmt` | `clang-format -i $(SRC)` |
| `fmt-check` | `clang-format --dry-run --Werror $(SRC)` |
| `lint` | `cmake --preset dev >/dev/null && clang-tidy -p build/dev $(filter %.c %.cpp %.cc,$(SRC))` |
| `test` | `cmake --build --preset dev && ctest --preset dev` (no tests means "No tests were found", exit 0) |
| `security-deps` | `osv-scanner scan source -r .` (checks lockfiles such as `conan.lock`/`vcpkg.json` and git submodules; with neither, it has little to check, so say so in CONTRIBUTING.md) |
| `clean` | `rm -rf build` |

## .gitignore

`build/ .cache/ compile_commands.json docs/api/ .env`

## Doxygen

| Placeholder | Value |
| --- | --- |
| `{{doxygen_input}}` | `src include` |
| `{{doxygen_file_patterns}}` | `*.c *.cc *.cpp *.h *.hpp` |
| `{{doxygen_exclude_patterns}}` | `*/build/*` |
| `{{docs_check_args}}` | `--require-file-doc src include` |

Every file needs a `@file` comment, including the entry point.

## Pre-commit local hook

```yaml
      - id: fmt-check
        name: clang-format
        entry: make fmt-check
        language: system
        pass_filenames: false
        types_or: [c, c++]
```

## CI setup steps

```yaml
      - run: sudo apt-get update && sudo apt-get install -y ninja-build clang-format clang-tidy
      - uses: actions/setup-go@<sha> # vX   (only to install osv-scanner)
      - run: go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest
```

Dependabot ecosystem: `gitsubmodule` if submodules are used. There's none for plain CMake/FetchContent, so mention that the FetchContent pins need manual updates. Docker ignore extras: `build`.

## Dockerfile (service)

```dockerfile
FROM gcc:14 AS build
RUN apt-get update && apt-get install -y --no-install-recommends cmake ninja-build && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN cmake --preset release -DBUILD_TESTING=OFF && cmake --build --preset release

FROM gcr.io/distroless/cc-debian12:nonroot
COPY --from=build /src/build/release/<name> /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```
