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

set(CMAKE_POSITION_INDEPENDENT_CODE ON)
include(CheckPIESupported)
check_pie_supported()

option(WARNINGS_AS_ERRORS "Fail on warnings (dev preset)" OFF)
option(SANITIZE "ASan and UBSan (dev preset)" OFF)
option(HARDEN "Exploit hardening (release preset)" OFF)

add_library(project_options INTERFACE)
target_compile_options(project_options INTERFACE
  $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Wall -Wextra -Wpedantic>
  $<$<CXX_COMPILER_ID:MSVC>:/W4>)

if(WARNINGS_AS_ERRORS)
  target_compile_options(project_options INTERFACE
    $<$<CXX_COMPILER_ID:GNU,Clang,AppleClang>:-Werror>
    $<$<CXX_COMPILER_ID:MSVC>:/WX>)
endif()

if(SANITIZE AND NOT MSVC)
  target_compile_options(project_options INTERFACE
    -fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer -U_FORTIFY_SOURCE)
  target_link_options(project_options INTERFACE -fsanitize=address,undefined)
endif()

if(HARDEN AND CMAKE_SYSTEM_NAME STREQUAL "Linux" AND NOT MSVC)
  target_compile_options(project_options INTERFACE
    -U_FORTIFY_SOURCE -D_FORTIFY_SOURCE=3
    -D_GLIBCXX_ASSERTIONS -D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_FAST
    -fstack-protector-strong -fstack-clash-protection
    -ftrivial-auto-var-init=zero
    -fno-delete-null-pointer-checks -fno-strict-overflow -fno-strict-aliasing
    -ffile-prefix-map=${CMAKE_SOURCE_DIR}=.)
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
    target_compile_options(project_options INTERFACE -fcf-protection=full)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64")
    target_compile_options(project_options INTERFACE -mbranch-protection=standard)
  endif()
  target_link_options(project_options INTERFACE
    -Wl,-z,relro -Wl,-z,now -Wl,-z,noexecstack -Wl,--as-needed)
endif()

add_executable(<name> src/main.cpp)          # or add_library(...)
target_link_libraries(<name> PRIVATE project_options)

if(HARDEN AND CMAKE_SYSTEM_NAME STREQUAL "Linux")  # executables and shared libraries only
  add_custom_command(TARGET <name> POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} --only-keep-debug $<TARGET_FILE:<name>> $<TARGET_FILE:<name>>.debug
    COMMAND ${CMAKE_STRIP} --strip-debug --strip-unneeded $<TARGET_FILE:<name>>
    COMMAND ${CMAKE_OBJCOPY} --add-gnu-debuglink=$<TARGET_FILE:<name>>.debug $<TARGET_FILE:<name>>)
endif()

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
```

`tests/CMakeLists.txt`: `FetchContent_Declare(googletest URL https://github.com/google/googletest/archive/refs/tags/v<latest>.tar.gz)`, `FetchContent_MakeAvailable(googletest)`, `include(GoogleTest)`. Add test executables later with `gtest_discover_tests`.

Test executables link `project_options` too, so they get the same flags as the code they test.

`CMakePresets.json`:

```json
{
  "version": 6,
  "configurePresets": [
    {
      "name": "dev", "generator": "Ninja", "binaryDir": "build/dev",
      "cacheVariables": {"CMAKE_BUILD_TYPE": "Debug", "WARNINGS_AS_ERRORS": "ON", "SANITIZE": "ON"}
    },
    {
      "name": "release", "generator": "Ninja", "binaryDir": "build/release",
      "cacheVariables": {"CMAKE_BUILD_TYPE": "RelWithDebInfo", "HARDEN": "ON"}
    }
  ],
  "buildPresets": [
    {"name": "dev", "configurePreset": "dev"},
    {"name": "release", "configurePreset": "release"}
  ],
  "testPresets": [
    {"name": "dev", "configurePreset": "dev", "output": {"outputOnFailure": true}},
    {"name": "release", "configurePreset": "release", "output": {"outputOnFailure": true}}
  ]
}
```

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- **`release`** uses `RelWithDebInfo`, not `Release`. It gives `-O2 -g -DNDEBUG`. The guide below recommends `-O2`, and `-g` provides the symbols that the post-build step moves into `<name>.debug`.
- **Hardening** comes from the [OpenSSF Compiler Options Hardening Guide](https://best.openssf.org/Compiler-Hardening-Guides/Compiler-Options-Hardening-Guide-for-C-and-C++.html) (2026-08-20 edition). Check the current edition when scaffolding, and report which one you used. `_FORTIFY_SOURCE=3` needs GCC 12 or Clang 9.
- **Left out on purpose:** `-Wl,-z,nodlopen` breaks plugin loading, `-fstrict-flex-arrays=3` rejects older flexible array code, and `-fzero-call-used-regs` needs Clang 16. Add them if the project allows.
- **Linux only.** When a project targets macOS or Windows, add those platforms' equivalents from the same guide or the platform's docs, and say so in the hand-off.
- **CET:** `-fcf-protection=full` adds the instructions, but the binary is only marked for IBT and shadow stacks if every linked object is. Debian's startup files aren't, so builds in the CI container carry no CET note. Don't report CET as active without checking `readelf -n`.
- **Sanitizers** run in `dev`. The guide advises against combining them with `_FORTIFY_SOURCE`, so `SANITIZE` turns it off.
- **`-Werror` is `dev` only,** because the guide says not to use it in distributed source.
- **Artefacts:** `build/release/<name>`. **Symbols:** `build/release/<name>.debug`.

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
| `release` | `cmake --preset release && cmake --build --preset release` |
| `test-release` | `cmake --preset release && cmake --build --preset release && ctest --preset release` |
| `security-deps` | `osv-scanner scan source -r .` (checks lockfiles such as `conan.lock`/`vcpkg.json` and git submodules; with neither, it has little to check, so say so in CONTRIBUTING.md) |
| `clean` | `rm -rf build` |

## .gitignore

`.devenv*/ devenv.local.nix build/ .cache/ compile_commands.json docs/api/ .env`

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

## devenv

`{{devenv_languages}}`:
```nix
  languages.cplusplus.enable = true;
```

`{{devenv_packages}}`: `cmake` `ninja` `clang-tools` `binutils` `osv-scanner`

## CI container

`ci/Containerfile`:
```dockerfile
FROM docker.io/library/gcc:14
RUN apt-get update && apt-get install -y --no-install-recommends cmake ninja-build clang-format clang-tidy \
    && rm -rf /var/lib/apt/lists/*
ADD --chmod=755 https://github.com/google/osv-scanner/releases/download/<version>/osv-scanner_linux_amd64 /usr/local/bin/osv-scanner
ENV HOME=/tmp
USER 65532:65532
```

Replace each `<version>` with the latest release. Keep the distroless image on the same Debian release as the build image, because a binary built against a newer glibc may not start on an older one. devenv's compiler is Clang through a Nix wrapper that adds its own hardening flags. CI's is GCC with only the project's flags, so `make ci-check` is what proves the build. A binary built in devenv links to `/nix/store`, so it can't ship.

Dependabot ecosystem: `gitsubmodule` if submodules are used, and `docker` for `/ci`. There's none for plain CMake/FetchContent, so mention that the FetchContent pins need manual updates. Docker ignore extras: `build`.

## Dockerfile (service)

```dockerfile
FROM docker.io/library/gcc:14 AS build
RUN apt-get update && apt-get install -y --no-install-recommends cmake ninja-build && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN cmake --preset release -DBUILD_TESTING=OFF && cmake --build --preset release

FROM gcr.io/distroless/cc-debian13:nonroot
COPY --from=build /src/build/release/<name> /app
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/app"]
```
