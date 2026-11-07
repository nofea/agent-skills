# Unreal Engine

Tooling: **Unreal Engine** · **RunUAT** · **Automation tests** · **clang-format**. The editor stays on the host, and devenv holds the other tools. CI runs in Epic's container image with the user's own access.

**None of this has been run.** Running it needs a GitHub account linked to Epic. Epic's docs confirm `BuildCookRun`, `-project`, `-clientconfig`, `Automation RunTest` and `-ReportExportPath`. Other flags come from community examples, so treat every recipe as `unverified`, and tell the user so in the hand-off. Check `RunUAT BuildCookRun -help` and report what you confirmed.

## Access and licence

- Epic's images are at `ghcr.io/epicgames/unreal-engine`. Pulling them needs a GitHub account linked to an Epic account, and a token with `read:packages`.
- **Keep images private.** The EULA lets you share Engine Code only with people licensed for the same version, and development images contain the engine. Whether the EULA forbids every public image is `unverified`, but the safe rule is simple: never push a derived image to a public registry.
- Read the current EULA's royalty and notice terms. Have the user check them, because this skill can't confirm them.

## Init

Create the project from the editor if it's installed. Otherwise, write these by hand:

- `<Name>.uproject`, with `FileVersion`, `EngineAssociation` and one `Runtime` module
- `Source/<Name>.Target.cs` with `Type = TargetType.Game`
- `Source/<Name>Editor.Target.cs` with `Type = TargetType.Editor`
- `Source/<Name>/<Name>.Build.cs`, plus the module's `.h` and `.cpp` using `IMPLEMENT_PRIMARY_GAME_MODULE`
- `Config/DefaultEngine.ini`

Use `.clang-format` from readable-code's `clang-format-unreal`, if readable-code is installed.

## Layout

```
<Name>.uproject
Config/                     # text settings, committed
Content/                    # .uasset and .umap files, in LFS
Source/<Name>/              # game module
Source/<Name>Tests/         # test module, editor-only
```

Keep logic in C++ modules. Blueprints are binary, so agents can't read or review them.

## Smoke test

The shipped build needs a [smoke test](../project-types.md#shipped-build-smoke-test). Shipping strips console commands, so `-ExecCmds` doesn't work there. In the game instance's `Init`, check `FParse::Param(FCommandLine::Get(), TEXT("SmokeTest"))`, wait for a fixed number of ticks, then call `FPlatformMisc::RequestExit(false)`.

Automation tests don't run against Shipping. Epic's **Test** configuration is the same as Shipping with some tools left in, so it's the nearest place to run them if the user wants more than the smoke test.

## Makefile recipes

Set these through `{{extra_targets}}`. `UE_ROOT` is the engine folder:

```make
UAT = "$(UE_ROOT)/Engine/Build/BatchFiles/RunUAT.sh"
UE_FLAGS = BuildCookRun -project="$(CURDIR)/<Name>.uproject" -noP4 -platform=Linux -build -cook -stage -pak -unattended
UE_EDITOR = "$(UE_ROOT)/Engine/Binaries/Linux/UnrealEditor-Cmd"
```

| Target | Recipe |
| --- | --- |
| `setup` | `@test -n "$(UE_ROOT)"` |
| `build` | `$(UAT) $(UE_FLAGS) -clientconfig=Development -archive -archivedirectory="$(CURDIR)/out/debug"` |
| `fmt` | `find Source -name '*.h' -o -name '*.cpp' \| xargs -r clang-format -i` |
| `fmt-check` | `find Source -name '*.h' -o -name '*.cpp' \| xargs -r clang-format --dry-run --Werror` |
| `lint` | `@echo "The Unreal compiler checks code in make build."` |
| `test` | See below |
| `release` | `rm -rf out/release && $(UAT) $(UE_FLAGS) -clientconfig=Shipping -archive -archivedirectory="$(CURDIR)/out/release"` |
| `test-release` | `timeout 300 out/release/Linux/<Name>.sh -nullrhi -SmokeTest` |
| `security-deps` | `@echo "Unreal plugins have no audit command. Review Plugins/ when you update them."` |
| `clean` | `rm -rf out Binaries Intermediate Saved DerivedData` |

Exit codes aren't reliable for Automation tests, according to community reports, so read the report. With no tests, skip the run so the target passes:

```make
test: ## Run tests on the debug build (passes when no tests exist yet)
	@grep -rlE 'IMPLEMENT_[A-Z_]*AUTOMATION_TEST|TEST_CLASS' Source 2>/dev/null | grep -q . || { echo "no tests yet"; exit 0; }
	$(UE_EDITOR) "$(CURDIR)/<Name>.uproject" -ExecCmds="Automation RunTest Project;Quit" -unattended -nullrhi -nopause -ReportExportPath="$(CURDIR)/out/test-report"
	grep -q '"failed": 0' out/test-report/index.json
```

Confirm the report's field name on the first run.

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- `Development` is the debug profile, and `Shipping` is the release profile.
- `check()` and `ensure()` macros are removed from Shipping, depending on the settings. Don't put security checks in them.
- Guard developer tools with `#if !UE_BUILD_SHIPPING`.
- `UFUNCTION(Exec)` and console commands are a debug surface, so keep them out of Shipping.
- **Artefacts:** `out/release/Linux/`. **Symbols:** `.sym` and `.debug` files. Move them to `out/symbols/`, and confirm the names on the first build.

## .gitignore

`Binaries/ Intermediate/ Saved/ DerivedData/ .vs/ *.sln .devenv*/ devenv.local.nix .env docs/api/ out/`

## .gitattributes

Use `gitattributes-media` plus `gitattributes-unreal`. See [Binary assets](../project-types.md#binary-assets). Binary assets can't be merged. Tell the user to turn on LFS file locking, and that large teams often choose Perforce, which this scaffold doesn't set up.

## Doxygen

| Placeholder | Value |
| --- | --- |
| `{{doxygen_input}}` | `Source` |
| `{{doxygen_file_patterns}}` | `*.h` |
| `{{doxygen_exclude_patterns}}` | `*/Intermediate/*` |
| `{{docs_check_args}}` | `--report-only` |

Unreal's macros, such as `UCLASS()` and `GENERATED_BODY()`, can confuse Doxygen. Keep `--report-only` until the output looks right.

## Pre-commit local hook

```yaml
      - id: fmt-check
        name: clang-format
        entry: make fmt-check
        language: system
        pass_filenames: false
        types_or: [c++]
```

## devenv

`{{devenv_packages}}`: `clang-tools`

`{{devenv_languages}}` stays empty. The engine comes from the Epic launcher or a source build, not nixpkgs. Set `UE_ROOT` in `devenv.local.nix`, which stays out of git.

## CI container

`ci/Containerfile`. Check Epic's containers guide for the current `dev-<version>` tag:

```dockerfile
FROM ghcr.io/epicgames/unreal-engine:dev-<version>
ENV UE_ROOT=/home/ue4/UnrealEngine
```

Confirm that the image has `make`, and check the engine path, which is `unverified`. Log in first with `$(CONTAINER) login ghcr.io`. In GitHub Actions, use a stored token with `read:packages`, in repository secrets, because `GITHUB_TOKEN` can't read Epic's packages.

These images are tens of GB, which can overflow GitHub-hosted runners. Tell the user they may need a self-hosted runner, still running the same container. Secrets aren't available to pull requests from forks, so skip engine jobs for them.

Dependabot ecosystem: `docker` for `/ci`, if Dependabot can reach the registry. Dependabot can't update plugins, so tell the user to update those by hand.

Scanner extras: `{{semgrepignore_extra}}` is `Binaries/`, `Intermediate/`, `Saved/` and `DerivedData/`. `{{trivy_skip_extra}}` is `--skip-dirs Binaries --skip-dirs Intermediate --skip-dirs Saved --skip-dirs DerivedData`.
