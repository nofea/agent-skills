# C# / .NET

Tooling: **dotnet** SDK (latest LTS, pinned in `global.json`) · **dotnet format** · Roslyn analyzers with warnings as errors · **xUnit** · NuGet audit + `dotnet list package --vulnerable`.

## Init

```bash
dotnet new sln -n <Name>
dotnet new console   -o src/<Name>          # CLI;  library: classlib;  service: webapi
dotnet new xunit     -o tests/<Name>.Tests
dotnet sln add src/<Name> tests/<Name>.Tests
dotnet add tests/<Name>.Tests reference src/<Name>
dotnet new globaljson --sdk-version "$(dotnet --version)" --roll-forward latestFeature
dotnet new gitignore
dotnet new editorconfig       # merge: keep its C# rules, add the [*] basics from assets/editorconfig
```

In the merged `.editorconfig`, keep `csharp_new_line_before_open_brace = all` (Allman braces) and set `csharp_prefer_braces = true:warning`.

**Delete the template's sample test** (`UnitTest1.cs`). Trim `Program.cs` to a minimal entry point. The webapi template's WeatherForecast sample also goes; leave just the builder/app setup.

## Layout

```
src/<Name>/                 # project(s)
tests/<Name>.Tests/         # xUnit project, no tests yet
<Name>.sln(x)  global.json  Directory.Build.props  .editorconfig
```

- **CLI:** use `System.CommandLine` if the user wants subcommands, otherwise `args`.
- **Library:** set `<GenerateDocumentationFile>true</GenerateDocumentationFile>` and package metadata (`PackageId`, `Description`, `RepositoryUrl`, `PackageLicenseExpression`).
- **Service:** minimal APIs. Configuration from env (`appsettings.json` contains no secrets). Add `.env.example`.

## Directory.Build.props (repo root)

```xml
<Project>
  <PropertyGroup>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <AnalysisLevel>latest-recommended</AnalysisLevel>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
    <NuGetAudit>true</NuGetAudit>
    <NuGetAuditMode>all</NuGetAuditMode>
    <NuGetAuditLevel>low</NuGetAuditLevel>
  </PropertyGroup>
</Project>
```

With `TreatWarningsAsErrors`, NuGet audit warnings (NU1901–NU1904) fail the restore, so vulnerable packages break the build.

## Makefile recipes

| Target | Recipe |
| --- | --- |
| `setup` | `dotnet restore` |
| `build` | `dotnet build --no-restore` |
| `fmt` | `dotnet format` |
| `fmt-check` | `dotnet format --verify-no-changes` |
| `lint` | `dotnet build --no-incremental -c Release` (analyzers run during build, and warnings are errors) |
| `test` | `dotnet test` (on Microsoft.Testing.Platform, exit code 8 means zero tests ran: use `dotnet test \|\| [ $$? -eq 8 ]`) |
| `release` | `rm -rf out && dotnet publish src/<Name> -c Release -o out/release && mkdir -p out/symbols && find out/release -name '*.pdb' -exec mv -t out/symbols {} +` (library: `rm -rf out && dotnet pack -c Release -o out/release`) |
| `test-release` | `dotnet test -c Release` (with the same exit code 8 handling as `test`) |
| `security-deps` | `out=$$(dotnet list package --vulnerable --include-transitive 2>&1); echo "$$out"; ! grep -q "has the following vulnerable packages" <<<"$$out"` |
| `clean` | `dotnet clean && rm -rf out **/bin **/obj` |

`lint` stays in Release, because analyzers should check the configuration that ships.

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- `#if DEBUG` and `[Conditional("DEBUG")]` code, including `Debug.Assert`, is removed from Release. Don't put security checks there.
- Keep `TreatWarningsAsErrors` in every configuration, because it's what fails the build on vulnerable packages.
- **Artefacts:** `out/release/`. **Symbols:** `out/symbols/`.

## .gitignore

`dotnet new gitignore` output, plus `.devenv*/`, `devenv.local.nix`, `.env`, `docs/api/` and `out/`.

## Doxygen

| Placeholder | Value |
| --- | --- |
| `{{doxygen_input}}` | `src` |
| `{{doxygen_file_patterns}}` | `*.cs` |
| `{{doxygen_exclude_patterns}}` | `*/bin/* */obj/*` |
| `{{docs_check_args}}` | empty |

The `obj` exclusion matters, because the build writes generated `.cs` files there.

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

`{{devenv_languages}}`:
```nix
  languages.dotnet = {
    enable = true;
    package = pkgs.dotnet-sdk_10;   # match global.json
  };
```

## CI container

`ci/Containerfile`:
```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:<lts>
RUN apt-get update && apt-get install -y --no-install-recommends make git && rm -rf /var/lib/apt/lists/*
ENV HOME=/tmp NUGET_PACKAGES=/tmp/nuget DOTNET_CLI_TELEMETRY_OPTOUT=1
USER 65532:65532
```

Replace each `<version>` with the latest release. Check that `dotnet-sdk_10` is still the LTS, and match it to `global.json` and the `<lts>` images.

Dependabot ecosystem: `nuget`, and `docker` for `/ci`. Docker ignore extras: `**/bin **/obj`.

## Dockerfile (service)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:<lts> AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/<Name> -c Release -o /out && find /out -name '*.pdb' -delete

FROM mcr.microsoft.com/dotnet/aspnet:<lts>
WORKDIR /app
COPY --from=build /out .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "<Name>.dll"]
```
