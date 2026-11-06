# Security scanning

Four layers. Each one runs locally (`make security-*`) and in CI. Secrets are also caught at commit time.

| Layer | Tool | Local | Pre-commit | CI |
| --- | --- | --- | --- | --- |
| Secrets | gitleaks | `make security-secrets` (`gitleaks dir`) | `gitleaks` hook (staged changes) | Docker image, `gitleaks git` (full history) |
| SAST | semgrep | `make security-sast` | — (too slow) | Docker image `semgrep/semgrep` |
| Dependencies | language-native audit | `make security-deps` | — | inside each check job (`make security-deps`) |
| Filesystem / IaC / containers | trivy | `make security-fs` | — | `aquasecurity/trivy-action` fs, plus image scan for services |
| Updates | Dependabot | — | — | `.github/dependabot.yml` |

Language security linters (bandit rules in ruff, gosec in golangci-lint, clippy, Roslyn security analyzers) run as part of `make lint`, not `make security`.

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
- `{{gitleaks_version}}`, `{{semgrep_version}}`: the latest release tags (for example `v8.28.0`, `1.140.0`). Look them up with `git ls-remote --tags` on `github.com/gitleaks/gitleaks` and `github.com/semgrep/semgrep`.
- `{{gitleaks_rev}}`, `{{pre_commit_hooks_rev}}`: the latest tags of those repos. After the user runs `pre-commit install`, `pre-commit autoupdate` can refresh them.

If the network is unavailable, use the latest major tag you know (`@v5`), and tell the user in the hand-off that the pins need resolving.

### `{{check_jobs}}` in `ci.yml.tmpl`

One job per component, or a single `check` job for single-language repos:

```yaml
  check:
    name: Lint, build, test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@<sha> # vX
      # language setup steps from references/languages/<lang>.md
      - run: make setup
      - run: sudo apt-get update && sudo apt-get install -y doxygen   # Doxygen languages only
      - run: make lint
      - run: make docs-check                                          # Doxygen languages only
      - run: make build
      - run: make test
      - run: make security-deps
```

For polyglot repos, give each component its own job and add `working-directory: apps/<name>` under `defaults.run`.

### `{{image_scan_steps}}` (web services only)

```yaml
      - name: Build image
        run: docker build -t app:ci .            # or -f apps/<name>/Dockerfile apps/<name>
      - name: Image scan (trivy)
        uses: aquasecurity/trivy-action@<sha> # vX
        with:
          scan-type: image
          image-ref: app:ci
          severity: HIGH,CRITICAL
          exit-code: "1"
          ignore-unfixed: true
```

For services, also add these Makefile targets (via `{{extra_targets}}`), and add `security-image` to the `security` prerequisites:

```make
.PHONY: docker-build security-image
docker-build: ## Build the container image
	docker build -t {{project_name}}:dev .

security-image: docker-build ## Scan the container image (trivy)
	trivy image --severity HIGH,CRITICAL --ignore-unfixed --exit-code 1 --quiet {{project_name}}:dev
```

### Dependabot `{{ecosystems}}`

One block per language and component directory (the ecosystem names are in each language reference), plus `docker` for services:

```yaml
  - package-ecosystem: pip        # uv projects: use "uv"
    directory: /                  # or /apps/<name>
    schedule:
      interval: weekly
```

## Handling findings

- During the scaffold's own verification, findings in **generated** files must be fixed. Findings in **existing** code are reported to the user, not fixed.
- Suppress a false positive in the narrowest place possible: an inline `nosemgrep: <rule-id>` or `gitleaks:allow` comment, a `.gitleaks.toml` allowlist entry, or a `.trivyignore` with the CVE and a reason. Always add a comment saying why.
