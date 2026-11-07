# Unity

Tooling: **Unity Editor** · **Unity Test Framework** · **dotnet format**. The editor stays on the host, and devenv holds the other tools. CI runs in a [GameCI image](https://game.ci/docs/docker/docker-images/) with the user's own licence.

**None of this has been run.** Running it needs a Unity licence. Argument names come from Unity's manual for 6000.6, but treat every recipe as `unverified`, and tell the user so in the hand-off. Check the current docs and report what you confirmed.

## Licences

Ask which Unity plan the user has, before the file plan.

| Plan | CI | Status |
| --- | --- | --- |
| Pro, or Enterprise and Industry with a serial | `-serial` activation in batch mode | Confirmed from Unity's manual |
| Personal | **Decide with the user.** Unity's manual says Personal has no serial, activates through the Hub, and doesn't support manual activation. GameCI's docs still describe storing a Personal `.ulf` file as a secret | `unverified`, because the two sources conflict |

If Personal activation doesn't work in CI, `make ci-check` can't run the engine. Then CI runs only the checks that don't need the engine: `fmt-check` and the repo-wide scans. Tell the user that CI doesn't prove the game builds, and record it in `specs/architecture.md`.

Never write a licence, serial, email or password to the repo, an image or a log. They go in the CI's secrets. `-password` has to be passed as an argument, so never run these recipes with `set -x`.

## Init

Use Unity Hub or the editor's `-createProject <path>` if the editor is installed. Otherwise, write these by hand and open the project once in the editor:

`ProjectSettings/ProjectVersion.txt`:
```text
m_EditorVersion: <version>
```

`Packages/manifest.json`:
```json
{
  "dependencies": {
    "com.unity.test-framework": "<version>"
  }
}
```

In the editor, keep **Version Control** set to Visible Meta Files and **Asset Serialization** set to Force Text. Text scenes can be merged and scanned.

## Layout

```
Assets/Scripts/             # game code, with one .asmdef per area
Assets/Scenes/
Assets/Editor/BuildScript.cs
Assets/Tests/EditMode/      # tests with their own .asmdef
Assets/Tests/PlayMode/
Packages/  ProjectSettings/
```

Commit every `.meta` file, or references between assets break. Keep game rules in plain classes, so EditMode tests can run them without a scene.

## Build script

Unity has no command for building a player, so add one. `make release` fails until a scene is listed in Build Settings. Say so in the hand-off.

```csharp
/// <summary>Builds players from the command line.</summary>
public static class BuildScript
{
    /// <summary>Builds a development player.</summary>
    public static void Debug()
    {
        Build("out/debug/<Name>.x86_64", BuildOptions.Development);
    }

    /// <summary>Builds the player that ships.</summary>
    public static void Release()
    {
        Build("out/release/<Name>.x86_64", BuildOptions.None);
    }

    /// <summary>Builds a Linux player, and exits non-zero if the build fails.</summary>
    /// <param name="path">Output path.</param>
    /// <param name="options">Build options.</param>
    private static void Build(string path, BuildOptions options)
    {
        BuildPlayerOptions build = new()
        {
            scenes = EditorBuildSettings.scenes.Where(scene => scene.enabled).Select(scene => scene.path).ToArray(),
            locationPathName = path,
            target = BuildTarget.StandaloneLinux64,
            options = options,
        };

        BuildReport report = BuildPipeline.BuildPlayer(build);

        if (report.summary.result != BuildResult.Succeeded)
        {
            EditorApplication.Exit(1);
        }
    }
}
```

## Smoke test

The shipped build needs a [smoke test](../project-types.md#shipped-build-smoke-test). Add a small runtime class marked `[RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]`. If the command line contains `--smoke-test`, it waits a fixed number of frames, then calls `Application.Quit(0)`.

## Makefile recipes

Add `UNITY ?= $(UNITY_PATH)` through `{{extra_targets}}`. `{{ci_env}}` below sets `UNITY_PATH` to the CI image's own `unity-editor`.

| Target | Recipe |
| --- | --- |
| `setup` | `@test -z "$${UNITY_SERIAL:-}" \|\| "$(UNITY)" -quit -batchmode -nographics -serial "$$UNITY_SERIAL" -username "$$UNITY_EMAIL" -password "$$UNITY_PASSWORD" -logFile -` |
| `build` | `"$(UNITY)" -batchmode -nographics -quit -projectPath "$(CURDIR)" -executeMethod BuildScript.Debug -logFile -` |
| `fmt` | `dotnet format whitespace Assets --folder` |
| `fmt-check` | `dotnet format whitespace Assets --folder --verify-no-changes` |
| `lint` | `"$(UNITY)" -batchmode -nographics -quit -projectPath "$(CURDIR)" -logFile -` (fails on compile errors) |
| `test` | See below |
| `release` | `rm -rf out/release && "$(UNITY)" -batchmode -nographics -quit -projectPath "$(CURDIR)" -executeMethod BuildScript.Release -logFile -` |
| `test-release` | `timeout 120 out/release/<Name>.x86_64 -batchmode -nographics -logFile out/smoke.log --smoke-test` then `! grep -E 'Exception\|Error:' out/smoke.log` |
| `security-deps` | `@echo "Unity packages have no audit command. Review Packages/manifest.json when you update it."` |
| `clean` | `rm -rf out Library Temp Obj` |

`test` runs each mode. Leave out `-quit`, because Unity doesn't support it during test runs. Unity doesn't define test exit codes, so read the results file. With no test scripts, skip the run so the target passes:

```make
test: ## Run tests on the debug build (passes when no tests exist yet)
	@find Assets/Tests -name '*.cs' 2>/dev/null | grep -q . || { echo "no tests yet"; exit 0; }
	mkdir -p out/test-results
	"$(UNITY)" -batchmode -nographics -projectPath "$(CURDIR)" -runTests -testPlatform EditMode -testResults out/test-results/editmode.xml -logFile -
	"$(UNITY)" -batchmode -nographics -projectPath "$(CURDIR)" -runTests -testPlatform PlayMode -testResults out/test-results/playmode.xml -logFile -
	! grep -l 'result="Failed' out/test-results/*.xml
```

Add a target that returns the seat, and call it even when checks fail:

```make
unity-return: ## Return the CI licence seat
	@test -z "$${UNITY_SERIAL:-}" || "$(UNITY)" -quit -batchmode -nographics -returnlicense -logFile -
```

Change `ci-check` and `ci-release` to run through `bash -c 'make setup …; rc=$$?; make unity-return; exit $$rc'`.

`{{ci_env}}`: `-e UNITY_SERIAL -e UNITY_EMAIL -e UNITY_PASSWORD -e UNITY_PATH=unity-editor`

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- `DEVELOPMENT_BUILD` and `UNITY_EDITOR` code is compiled out of release players. Don't put security checks behind them.
- Use `[Conditional]` methods and `Debug.Assert` for internal invariants only.
- Don't call `Debug.Log` with secrets or personal data, because release players keep logging.
- Keep `Assets/Tests` assemblies set to test-only, so they don't ship.
- **Artefacts:** `out/release/`. **Symbols:** Unity writes a `<Name>_BackUpThisFolder_ButDontShipItWithYourGame` folder for IL2CPP builds. Move it to `out/symbols/`.

## .gitignore

`/[Ll]ibrary/ /[Tt]emp/ /[Oo]bj/ /[Bb]uild/ /[Bb]uilds/ /[Ll]ogs/ /[Uu]ser[Ss]ettings/ *.csproj *.sln .devenv*/ devenv.local.nix .env docs/api/ out/`

## .gitattributes

Use `gitattributes-media` plus `gitattributes-unity`. See [Binary assets](../project-types.md#binary-assets).

## Doxygen

| Placeholder | Value |
| --- | --- |
| `{{doxygen_input}}` | `Assets/Scripts` |
| `{{doxygen_file_patterns}}` | `*.cs` |
| `{{doxygen_exclude_patterns}}` | empty |
| `{{docs_check_args}}` | empty |

## Pre-commit local hook

```yaml
      - id: fmt-check
        name: dotnet format
        entry: make fmt-check
        language: system
        pass_filenames: false
        types: [c#]
```

## devenv

`{{devenv_languages}}`: the `languages.dotnet` block from [csharp.md](../languages/csharp.md#devenv), for `dotnet format` only. The editor comes from Unity Hub, not nixpkgs. Set `UNITY_PATH` in `devenv.local.nix`, which stays out of git, to the installed editor's binary.

## CI container

`ci/Containerfile`. GameCI tags look like `ubuntu-<editor>-<module>-<gameci>`, such as `ubuntu-<version>-linux-il2cpp-3`. Match the editor version in `ProjectVersion.txt`, and check Docker Hub for the tag.

```dockerfile
FROM docker.io/unityci/editor:<tag>
RUN apt-get update && apt-get install -y --no-install-recommends make && rm -rf /var/lib/apt/lists/*
ENV HOME=/tmp
```

Add the `dotnet` SDK for `fmt-check`, or run `fmt-check` in a separate job. GameCI has no macOS image, so macOS builds need a native runner. Pull requests from forks don't get secrets, so skip engine jobs for them.

Dependabot ecosystem: `docker` for `/ci`. Dependabot can't update Unity packages, so tell the user to update those by hand.

Scanner extras: `{{semgrepignore_extra}}` is `Library/`, `Temp/`, `Logs/` and `UserSettings/`. `{{trivy_skip_extra}}` is `--skip-dirs Library --skip-dirs Temp`.
