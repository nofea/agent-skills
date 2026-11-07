# Security scanning

Four layers. Each one runs locally (`make security-*`) and in CI. Secrets are also caught at commit time. In CI, every scan runs in a pinned container through `make ci-security`, so the same command works under podman or docker, here and on the CI server.

| Layer | Tool | Local | Pre-commit | CI |
| --- | --- | --- | --- | --- |
| Secrets | gitleaks | `make security-secrets` (`gitleaks dir`) | `gitleaks` hook (staged changes) | `make ci-security`: container, `gitleaks git` (full history) |
| SAST | semgrep | `make security-sast` (container) | — (too slow) | `make ci-security`: container |
| Dependencies | language-native audit | `make security-deps` | — | inside `make ci-check` |
| Filesystem / IaC / containers | trivy | `make security-fs` | — | `make ci-security`: container, plus `make security-image` for services |
| Updates | Dependabot | — | — | `.github/dependabot.yml` |

Language security linters (bandit rules in ruff, gosec in golangci-lint, clippy, Roslyn security analyzers) run as part of `make lint`, not `make security`.

Scanners check source and dependencies, not what the build produces. For that, see [build-profiles.md](build-profiles.md), which covers hardening and testing the release build, and [release-signing.md](release-signing.md), which covers signing and publishing it.

## Filling the templates

Placeholders are `{{name}}` (no spaces). **Leave GitHub expressions such as `${{ github.ref }}` exactly as they are.**

### Pinning versions

Supply-chain attacks through hijacked action tags and hook revisions are real, so pin everything:

- `uses: owner/action@{{ref:owner/action}}`: resolve the action's latest release tag and pin it to the full commit SHA, with the tag as a comment:
  ```bash
  git ls-remote --tags https://github.com/actions/checkout | grep -v '\^{}' | sort -t/ -k3 -V | tail -1
  # for annotated tags, use the peeled "^{}" line's SHA
  ```
  Result: `uses: actions/checkout@<40-char-sha> # v5.0.0`. Dependabot (github-actions ecosystem) keeps these updated.
- `{{gitleaks_version}}`, `{{semgrep_version}}`, `{{trivy_version}}`: the latest release tags (for example `v8.28.0`, `1.140.0`, `0.68.0`). Look them up with `git ls-remote --tags` on `github.com/gitleaks/gitleaks`, `github.com/semgrep/semgrep` and `github.com/aquasecurity/trivy`. The trivy image tag has no `v`. These same pins are used in the Makefile.
- Base images in `ci/Containerfile`: pin to a version tag, and let Dependabot's `docker` ecosystem update it.
- Write every image name in full, with its registry, such as `docker.io/library/gcc:14`. podman refuses short names when there's no terminal, so `gcc:14` fails on a CI server. Docker accepts both forms.
- `devenv.lock` pins the dev environment. Commit it.
- `{{gitleaks_rev}}`, `{{pre_commit_hooks_rev}}`: the latest tags of those repos. After the user runs `pre-commit install`, `pre-commit autoupdate` can refresh them.

Game engines have generated folders that scanners shouldn't crawl. Each [engine reference](project-types.md#game) gives `{{semgrepignore_extra}}` and `{{trivy_skip_extra}}`. For anything else, leave both empty and remove the placeholder.

If the network is unavailable, use the latest major tag you know (`@v5`), and tell the user in the hand-off that the pins need resolving.

### `{{check_jobs}}` in `ci.yml.tmpl`

One job per component, or a single `check` job for single-language repos:

```yaml
  check:
    name: Lint, build, test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha> # vX
        with:
          persist-credentials: false
      - run: make ci-check
```

Everything the job needs is in `ci/Containerfile`, written from the language reference's **CI container** section. In Doxygen languages, add `doxygen` to its `apt-get install` line.

macOS and Windows builds can't run in Linux containers. Give those jobs native steps, and keep them on the same `make` verbs.

#### CI image speed

The CI image is rebuilt on every run, which is slow if a step compiles a tool, such as `cargo-deny`. To speed it up, push the image to a registry and set `CI_IMAGE` to its pinned digest.

For polyglot repos, give each component its own job and add `working-directory: apps/<name>` under `defaults.run`.

### `{{image_scan_steps}}` (web services only)

```yaml
      - run: make security-image
```

For services, also add these Makefile targets (via `{{extra_targets}}`), and add `security-image` to the `security` prerequisites:

```make
.PHONY: image-build security-image
image-build: ## Build the container image
	$(CONTAINER) build -t {{project_name}}:dev .

security-image: image-build ## Scan the container image (trivy)
	$(CONTAINER) save -o .image-scan.tar {{project_name}}:dev
	rc=0; $(TRIVY) image --input /src/.image-scan.tar --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --quiet || rc=$$?; rm -f .image-scan.tar; exit $$rc
```

Add `.image-scan.tar` to `.gitignore` and `.dockerignore`.

A fresh scaffold can fail this scan on a CVE in the base image, when a newer image fixes it. That's the scan working. Move to the newer base image, as the scaffold's verification step requires, rather than suppressing the finding.

### Dependabot `{{ecosystems}}`

One block per language and component directory (the ecosystem names are in each language reference), plus `docker` for `/ci` and for services:

```yaml
  - package-ecosystem: pip        # uv projects: use "uv"
    directory: /                  # or /apps/<name>
    schedule:
      interval: weekly
```

## Handling findings

- During the scaffold's own verification, findings in **generated** files must be fixed. Findings in **existing** code are reported to the user, not fixed.
- Suppress a false positive in the narrowest place possible: an inline `nosemgrep: <rule-id>` or `gitleaks:allow` comment, a `.gitleaks.toml` allowlist entry, or a `.trivyignore` with the CVE and a reason. Always add a comment saying why.
