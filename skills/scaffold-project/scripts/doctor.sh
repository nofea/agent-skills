#!/usr/bin/env bash
# Check that the tools a scaffolded project needs are installed.
# Usage: doctor.sh [python] [typescript] [go] [rust] [java-kotlin] [csharp] [cpp] [godot] [unity] [unreal] [generic] [doxygen] [git-lfs] [signing]
# Exits 1 if any required tool is missing. Optional tools are only reported.
# The scaffold-project skill copies this script into generated projects as scripts/doctor.sh.
set -uo pipefail

missing=0

have() {
  # have <label> <command...>: true if the command runs successfully
  local label="$1"; shift
  if "$@" >/dev/null 2>&1; then
    printf '  ok       %s\n' "$label"
    return 0
  fi
  return 1
}

need() { # need <label> <command...>
  local label="$1"
  if ! have "$@"; then
    printf '  MISSING  %s\n' "$label"
    missing=1
  fi
}

want() { # want <label> <command...>: optional
  local label="$1"
  if ! have "$@"; then
    printf '  optional %s (not found)\n' "$label"
  fi
}

echo "Shared tools:"
need make        make --version
need pre-commit  pre-commit --version
need gitleaks    gitleaks version
need trivy       trivy --version
want devenv      devenv version

# Containers run CI and semgrep. Either engine works.
if ! have podman podman --version && ! have docker docker --version; then
  printf '  MISSING  podman or docker\n'
  missing=1
fi

for lang in "$@"; do
  echo "$lang:"
  case "$lang" in
    python)
      need uv uv --version ;;
    typescript|ts|node)
      need node node --version
      need pnpm pnpm --version ;;
    go)
      need go go version
      need golangci-lint golangci-lint --version
      need govulncheck govulncheck -version ;;
    rust)
      need cargo cargo --version
      need rustfmt rustfmt --version
      need clippy cargo clippy --version
      need cargo-deny cargo deny --version ;;
    java-kotlin|java|kotlin)
      need java java -version
      want gradle gradle --version   # the Gradle wrapper (./gradlew) is used once generated
      ;;
    csharp|dotnet)
      need dotnet dotnet --version ;;
    cpp|c)
      need cmake cmake --version
      need ninja ninja --version
      need clang-format clang-format --version
      need clang-tidy clang-tidy --version
      need osv-scanner osv-scanner --version ;;
    godot|gdscript)
      need godot godot --version
      need gdformat gdformat --version
      need gdlint gdlint --version ;;
    unity)
      # The editor stays on the host, because it's licensed and isn't in nixpkgs.
      need dotnet dotnet --version
      need "Unity editor (UNITY_PATH)" test -x "${UNITY_PATH:-}" ;;
    unreal)
      # The engine stays on the host, because it's licensed and isn't in nixpkgs.
      need clang-format clang-format --version
      need "Unreal Engine (UE_ROOT)" test -x "${UE_ROOT:-}/Engine/Build/BatchFiles/RunUAT.sh" ;;
    git-lfs)
      need git-lfs git lfs version ;;
    doxygen)
      need doxygen doxygen --version ;;
    signing)
      want cosign cosign version ;;   # CI installs its own copy; this is for verifying releases locally
    generic)
      echo "  (check the toolchain listed in CONTRIBUTING.md by hand)" ;;
    *)
      echo "  unknown language '$lang': skipped" ;;
  esac
done

if (( missing )); then
  echo
  echo "Some required tools are missing. Run 'devenv shell' first, or see CONTRIBUTING.md (Prerequisites)."
  exit 1
fi
echo
echo "All required tools found."
