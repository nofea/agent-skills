# Java / Kotlin

Tooling: **Gradle** (Kotlin DSL, wrapper committed) · **Spotless** (Eclipse formatter with an Allman profile / ktlint) · lint: `javac -Xlint:all -Werror` + **PMD** for Java, **detekt** for Kotlin · **JUnit 5** · **OWASP dependency-check**. JDK: the latest LTS, set through a Gradle toolchain.

## Init

```bash
gradle init --type java-application --dsl kotlin --test-framework junit-jupiter \
  --project-name <name> --package <group.name> --java-version 21 --no-split-project --use-defaults
# kotlin: --type kotlin-application | kotlin-library ; java library: --type java-library
```

`gradle init` writes sample code and a sample test. Keep the minimal main class (or library class), but trim it to an empty `main` or an empty class, and **delete the generated sample test**. The user chose to start with no sample tests. With no Gradle, write `settings.gradle.kts`, `build.gradle.kts` and `gradle/libs.versions.toml` by hand, and tell the user to run `gradle wrapper` once Gradle is installed.

## Layout

```
app/ (or lib/)                       # Gradle subproject created by init
  src/main/{java|kotlin}/<pkg path>/
  src/test/{java|kotlin}/<pkg path>/ # empty
  build.gradle.kts
gradle/libs.versions.toml            # version catalog
gradlew  gradlew.bat  gradle/wrapper/
settings.gradle.kts
```

- **CLI:** use `application { mainClass = … }`. Use picocli if the user wants subcommands. Otherwise plain `args`.
- **Library:** use the `java-library` plugin, with `api` vs `implementation` dependencies chosen deliberately. Add `maven-publish` only if asked.
- **Service:** Spring Boot (start.spring.io settings: Gradle-Kotlin, Java 21, Web, Actuator), or Ktor for Kotlin, or the user's choice. If using Spring, generate with `curl https://start.spring.io/starter.zip -d type=gradle-project-kotlin …` and then apply this setup.

## Build config (add to the subproject's `build.gradle.kts`)

```kotlin
plugins {
    id("com.diffplug.spotless") version "<latest>"
    id("org.owasp.dependencycheck") version "<latest>"
    pmd                                     // Java; Kotlin: id("io.gitlab.arturbosch.detekt") version "<latest>"
}
java { toolchain { languageVersion = JavaLanguageVersion.of(21) } }
tasks.withType<JavaCompile>().configureEach { options.compilerArgs.addAll(listOf("-Xlint:all", "-Werror")) }
spotless {
    java { eclipse().configFile(rootProject.file("config/eclipse-java-allman.xml")) }   // Kotlin: kotlin { ktlint() } ; kotlinGradle { ktlint() }
}
pmd { isConsoleOutput = true; ruleSetFiles = files(); ruleSets = listOf("category/java/bestpractices.xml", "category/java/errorprone.xml", "category/java/security.xml") }
dependencyCheck { failBuildOnCVSS = 7.0f; nvd { apiKey = System.getenv("NVD_API_KEY") } }
tasks.test {
    useJUnitPlatform()
    failOnNoDiscoveredTests = false         // Gradle 9+: don't fail while there are no tests yet
}
```

Java formatting uses Allman braces, which google-java-format can't produce. Copy `assets/eclipse-java-allman.xml` to `config/eclipse-java-allman.xml`. Kotlin stays on ktlint's standard style. Put plugin versions in `gradle/libs.versions.toml`. Look them up on the Gradle Plugin Portal. OWASP dependency-check needs an **NVD API key** (free from nvd.nist.gov). Without one, the first run takes a very long time. Document `NVD_API_KEY` in CONTRIBUTING.md, and add it as a CI secret.

## Makefile recipes

| Target | Recipe |
| --- | --- |
| `setup` | `./gradlew --version` (the wrapper downloads Gradle; dependencies resolve on build) |
| `build` | `./gradlew assemble` |
| `fmt` | `./gradlew spotlessApply` |
| `fmt-check` | `./gradlew spotlessCheck` |
| `lint` | `./gradlew pmdMain` (Kotlin: `./gradlew detekt`) |
| `test` | `./gradlew test` |
| `release` | `./gradlew assemble` (Android: `./gradlew bundleRelease`) |
| `test-release` | `$(MAKE) test` (the JVM has no separate release compile; Android: `./gradlew testReleaseUnitTest`) |
| `security-deps` | `./gradlew dependencyCheckAnalyze` |
| `clean` | `./gradlew clean` |

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- JVM `assert` is off unless the JVM runs with `-ea`, so it never protects production. Use a normal check for anything security-related.
- **Android:** the `debug` and `release` build types are separate. Shrinking with R8 produces `mapping.txt`, which is the symbol file to retain. Set `debuggable` to false for release.
- **Artefacts:** `build/libs/` or `build/distributions/` (Android: `build/outputs/bundle/release/`).

## .gitignore

`.devenv*/ devenv.local.nix .gradle/ build/ out/ .kotlin/ *.class .idea/ *.iml docs/api/ .env`. **Commit** `gradle/wrapper/gradle-wrapper.jar`.

## Doxygen

| Placeholder | Value |
| --- | --- |
| `{{doxygen_input}}` | `app/src/main/java` (or `lib/src/main/java`) |
| `{{doxygen_file_patterns}}` | `*.java` |
| `{{doxygen_exclude_patterns}}` | `*/build/*` |
| `{{docs_check_args}}` | empty |

Java only. Doxygen can't read Kotlin, so a Kotlin project skips this section and a mixed project checks only its Java code.

## Pre-commit local hook

```yaml
      - id: fmt-check
        name: spotless check
        entry: make fmt-check
        language: system
        pass_filenames: false
        types_or: [java, kotlin]
```

Lint runs in CI rather than pre-commit, because starting Gradle is slow.

## devenv

`{{devenv_languages}}`:
```nix
  languages.java = {
    enable = true;
    jdk.package = pkgs.jdk21;
    gradle.enable = true;
  };
```

## CI container

`ci/Containerfile`:
```dockerfile
FROM docker.io/library/eclipse-temurin:21-jdk
RUN apt-get update && apt-get install -y --no-install-recommends make git && rm -rf /var/lib/apt/lists/*
ENV HOME=/tmp GRADLE_USER_HOME=/tmp/gradle
USER 65532:65532
```

Replace each `<version>` with the latest release. Set `{{ci_env}}` to `-e NVD_API_KEY` in the Makefile, and add `NVD_API_KEY: ${{ secrets.NVD_API_KEY }}` to the job's `env` in `ci.yml`.

Dependabot ecosystem: `gradle`, and `docker` for `/ci`. Docker ignore extras: `.gradle build out`.

## Dockerfile (service)

```dockerfile
FROM docker.io/library/eclipse-temurin:21-jdk AS build
WORKDIR /src
COPY . .
RUN ./gradlew --no-daemon :app:installDist

FROM docker.io/library/eclipse-temurin:21-jre
RUN useradd --uid 10001 --create-home app
COPY --from=build /src/app/build/install/app /opt/app
USER app
EXPOSE 8080
ENTRYPOINT ["/opt/app/bin/app"]
```

For Spring Boot, use `bootJar` and `java -jar` instead.
