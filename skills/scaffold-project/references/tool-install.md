# Installing tools

Always **ask** before installing. Offer the command for the user's platform, run it only after a yes, and then run `doctor.sh` again. Prefer user-level installs (pipx, `~/.local/bin`, rustup, `go install`) over `sudo`.

Detect the platform with `uname -s`. On Linux, check `/etc/os-release` (`ID`, `ID_LIKE`) and which of `brew`, `apt-get`, `dnf`, `pacman` exists.

## Toolchains

| Tool | macOS | Debian/Ubuntu | Fedora | Any (official installer) |
| --- | --- | --- | --- | --- |
| uv | `brew install uv` | — | `sudo dnf install uv` | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| node + pnpm | `brew install node pnpm` | `sudo apt-get install nodejs npm` then `corepack enable pnpm` | `sudo dnf install nodejs` then `corepack enable pnpm` | https://nodejs.org, then `corepack enable pnpm` |
| go | `brew install go` | `sudo apt-get install golang` (often old, prefer go.dev tarball) | `sudo dnf install golang` | https://go.dev/dl |
| rust | — | — | — | `curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \| sh` |
| JDK 21 + Gradle | `brew install openjdk@21 gradle` | `sudo apt-get install openjdk-21-jdk` | `sudo dnf install java-21-openjdk-devel` | sdkman: `sdk install java 21-tem && sdk install gradle` |
| .NET SDK | `brew install --cask dotnet-sdk` | Microsoft package feed / `sudo apt-get install dotnet-sdk-8.0` | `sudo dnf install dotnet-sdk-8.0` | https://dot.net/v1/dotnet-install.sh |
| cmake, ninja, clang tools | `brew install cmake ninja llvm` | `sudo apt-get install cmake ninja-build clang-format clang-tidy` | `sudo dnf install cmake ninja-build clang-tools-extra` | — |

Use the newest LTS or stable version available. Write the version into the project (`.python-version`, `engines`/`.nvmrc`, `go` directive, `rust-toolchain.toml`, toolchain in Gradle, `global.json`, CMake minimum).

## Shared tools

| Tool | macOS | Linux | Also |
| --- | --- | --- | --- |
| make | Xcode CLT (`xcode-select --install`) | `build-essential` / `make` package | — |
| pre-commit | `brew install pre-commit` | `pipx install pre-commit` or `uv tool install pre-commit` | — |
| gitleaks | `brew install gitleaks` | release binary from github.com/gitleaks/gitleaks/releases into `~/.local/bin` | `go install github.com/zricethezav/gitleaks/v8@latest` |
| semgrep | `brew install semgrep` | `pipx install semgrep` or `uv tool install semgrep` | — |
| trivy | `brew install trivy` | `sudo dnf install trivy` / apt repo from trivy.dev docs / install script `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh \| sh -s -- -b ~/.local/bin` | — |
| osv-scanner (C/C++) | `brew install osv-scanner` | release binary | `go install github.com/google/osv-scanner/v2/cmd/osv-scanner@latest` |

## Language-specific extras

| Tool | Install |
| --- | --- |
| golangci-lint | `brew install golangci-lint`, or the official install script (the docs advise against `go install`) |
| govulncheck | `go install golang.org/x/vuln/cmd/govulncheck@latest` |
| cargo-deny | `cargo install --locked cargo-deny` |
| pip-audit, ruff, mypy, pytest | project dev dependencies via `uv add --dev`, so there's no global install |
| biome, vitest, typescript | project dev dependencies via `pnpm add -D` |

If the user declines an install, carry on. Write the files by hand where an init command would have made them. The affected make targets will fail with "command not found" until the tool is installed. Say so in the hand-off.
