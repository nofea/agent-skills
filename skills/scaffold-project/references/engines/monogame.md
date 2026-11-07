# MonoGame

MonoGame is a C# framework, so start from [csharp.md](../languages/csharp.md) and apply the differences below. These recipes were run end to end with MonoGame 3.8.6.1 and the .NET 10 SDK. Check the current versions when you scaffold.

## Init

```bash
dotnet new install MonoGame.Templates.CSharp
dotnet new sln -n <Name>
dotnet new mgdesktopgl -o src/<Name>
dotnet new xunit -o tests/<Name>.Tests
dotnet sln add src/<Name> tests/<Name>.Tests
dotnet add tests/<Name>.Tests reference src/<Name>
dotnet new globaljson --sdk-version "$(dotnet --version)" --roll-forward latestFeature
dotnet new gitignore
dotnet new editorconfig       # merge as csharp.md describes
```

`mgdesktopgl` is the cross-platform desktop template, using SDL and OpenGL. Other templates cover mobile and Windows-only DirectX. Delete `UnitTest1.cs`. The template's `Game1.cs` is sample code, so trim it to the empty loop below.

## Layout

```
src/<Name>/                 # game: Program.cs, Game1.cs, Content/, .config/dotnet-tools.json
tests/<Name>.Tests/         # xUnit project, no tests yet
```

Keep game rules in plain classes that don't depend on `Game`, so tests can run without a window.

## Game class

The template doesn't build under `Directory.Build.props`, because `_spriteBatch` is set in `LoadContent`, after the constructor. Use `= null!` with a comment.

The shipped build needs a [smoke test](../project-types.md#shipped-build-smoke-test):

```csharp
private SpriteBatch _spriteBatch = null!; // Set in LoadContent, which the framework calls before Draw.

protected override void Update(GameTime gameTime)
{
    _frames++;

    if (_smokeTest && _frames >= SmokeTestFrames)
    {
        Exit();
    }

    base.Update(gameTime);
}
```

Pass the flag from `Program.cs` with `args.Contains("--smoke-test")`.

## Makefile recipes

Use the recipes in [csharp.md](../languages/csharp.md#makefile-recipes), except:

| Target | Recipe |
| --- | --- |
| `setup` | `dotnet restore && dotnet tool restore --tool-manifest src/<Name>/.config/dotnet-tools.json` |
| `release` | `rm -rf out && dotnet publish src/<Name> -c Release -r linux-x64 --self-contained -o out/release && mkdir -p out/symbols && find out/release -name '*.pdb' -exec mv -t out/symbols {} +` |
| `test-release` | `dotnet test -c Release` (with csharp.md's exit code 8 handling), then `xvfb-run -a timeout 60 out/release/<Name> --smoke-test` |

`setup` needs the tool manifest because the content build calls `mgcb` through it. Without it, a fresh container fails with `Run "dotnet tool restore"`.

Publish self-contained, because players won't have the .NET runtime installed. Add one `-r` build per platform.

## Effects and shaders

The shader compiler uses Windows-only DirectX tools. On Linux and macOS, building `.fx` effects needs WINE, according to MonoGame's docs. Add WINE to the CI container only if the project has effects. This setup is `unverified`, because the run above had none.

## Build profiles

Follow [build-profiles.md](../build-profiles.md) and csharp.md. **Artefacts:** `out/release/`. **Symbols:** `out/symbols/`.

## .gitattributes

Use `gitattributes-media`. See [Binary assets](../project-types.md#binary-assets).

## devenv

Add to `{{devenv_packages}}`: `SDL2 openal libGL`. Use csharp.md's `{{devenv_languages}}`, matching `global.json`.

## CI container

`ci/Containerfile`, on top of csharp.md's, with this `apt-get` line:

```dockerfile
RUN apt-get update && apt-get install -y --no-install-recommends make git xvfb xauth libgl1 libgl1-mesa-dri libglx-mesa0 libsdl2-2.0-0 libopenal1 && rm -rf /var/lib/apt/lists/*
```

`xvfb` gives the smoke test a virtual display, and Mesa renders it in software.

Dependabot ecosystem: `nuget`, and `docker` for `/ci`. Docker ignore extras: `**/bin **/obj`.

Scanner extras: `{{semgrepignore_extra}}` is `**/Content/bin/` and `**/Content/obj/`.
