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
| `build` | `dotnet build --no-restore -c Release` |
| `fmt` | `dotnet format` |
| `fmt-check` | `dotnet format --verify-no-changes` |
| `lint` | `dotnet build --no-incremental -c Release` (analyzers run during build, and warnings are errors) |
| `test` | `dotnet test -c Release` (on Microsoft.Testing.Platform, exit code 8 means zero tests ran: use `dotnet test -c Release \|\| [ $$? -eq 8 ]`) |
| `security-deps` | `out=$$(dotnet list package --vulnerable --include-transitive 2>&1); echo "$$out"; ! grep -q "has the following vulnerable packages" <<<"$$out"` |
| `clean` | `dotnet clean && rm -rf **/bin **/obj` |

## .gitignore

`dotnet new gitignore` output, plus `.env`.

## Pre-commit local hook

```yaml
      - id: fmt-check
        name: dotnet format
        entry: make fmt-check
        language: system
        pass_filenames: false
        types: [c#]
```

## CI setup steps

```yaml
      - uses: actions/setup-dotnet@<sha> # vX
        with:
          global-json-file: global.json
```

Dependabot ecosystem: `nuget`. Docker ignore extras: `**/bin **/obj`.

## Dockerfile (service)

```dockerfile
FROM mcr.microsoft.com/dotnet/sdk:<lts> AS build
WORKDIR /src
COPY . .
RUN dotnet publish src/<Name> -c Release -o /out

FROM mcr.microsoft.com/dotnet/aspnet:<lts>
WORKDIR /app
COPY --from=build /out .
USER $APP_UID
EXPOSE 8080
ENTRYPOINT ["dotnet", "<Name>.dll"]
```
