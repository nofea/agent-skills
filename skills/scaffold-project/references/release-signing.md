# Release signing and publishing

Use this when the user names at least one distribution target in the intake. With none, skip all of it: write no `release.yml`, and leave the out-of-repo setup alone.

## Contents

- [Rules](#rules)
- [Pick the targets](#pick-the-targets)
- [Filling release.yml.tmpl](#filling-releaseymltmpl)
- [Target recipes](#target-recipes)
- [User setup for the hand-off](#user-setup-for-the-hand-off)
- [Sources](#sources)

## Rules

1. **The skill never creates keys, certificates, accounts or secrets, and never signs or publishes.** It writes the workflow and lists what the user must set up. Don't run the workflow, push a tag or ask the user to paste a secret.
2. **Keys never enter the repo, an image or a log.** That includes keystores, `.p12`, `.p8`, `.pfx`, GPG keys and `keystore.properties`. Add those patterns to `.gitignore`.
3. **Prefer OIDC over stored secrets,** because a short-lived credential has nothing to leak or rotate. If a target needs a stored credential, it lives only in the `release` environment's secrets, never in repository secrets.
4. **Keep dev and release keys separate.** Debug builds are never signed with a release key, and release keys never sit on developer machines used for daily work.
5. **Sign only what passed.** The signed artefact comes from `make release` in the same run, after `make test-release` passes. Nothing is rebuilt between signing and publishing. Containers are the one ordering exception, see [Containers](#containers).
6. **Keep build and publish apart.** Build code never runs in a job that holds publishing credentials, so a compromised dependency can't reach them. Give `id-token: write` and other write scopes per job, only where needed.
7. **Plan for key loss.** For each key in use, record in `SECURITY.md` who holds it, how to rotate it, and how to revoke it. A lost Android app signing key without Play App Signing means no more updates.

## Pick the targets

Support varies, so check each target's current docs while scaffolding, and report which ones you confirmed. **Status** records what was checked when this table was written. `unverified` means the primary docs could not be read, so tell the user to check that row before relying on it.

| Target | How it's signed | Credential | Status |
| --- | --- | --- | --- |
| PyPI | Attestations from Trusted Publishing, on by default | OIDC | Confirmed |
| npm | Provenance from trusted publishing, automatic for public repo and package | OIDC. npm CLI 11.5.1+, Node 22.14+ | Confirmed |
| crates.io | No package signature. Trusted Publishing proves the source | OIDC. First release is manual | Confirmed from the crates.io team's blog |
| NuGet | Trusted Publishing, with a 1-hour API key | OIDC, plus the nuget.org username | Confirmed |
| Maven Central | GPG signature on every file, plus checksums, sources and javadoc jars | GPG key, Portal token | Confirmed for the requirements. Check the upload route |
| Containers | cosign keyless, by digest, plus SBOM attestation | OIDC | Confirmed |
| GitHub release binaries | cosign keyless over `SHA256SUMS`, plus provenance attestation | OIDC | Confirmed |
| Google Play | Upload key signs the AAB, and Play App Signing signs for users | Upload keystore, plus workload identity or a service account | Signing confirmed. Upload `unverified` |
| Apple App Store, Mac App Store | Apple distribution certificate and provisioning profile | `.p12`, profile, App Store Connect API key | Runner setup confirmed. Upload `unverified` |
| macOS outside the store | Developer ID, hardened runtime, notarization, stapling | `.p12`, App Store Connect API key | `unverified` |
| Microsoft Store, MSIX | **The Store re-signs it.** No certificate needed | Partner Center access | Confirmed |
| Microsoft Store, EXE or MSI | Authenticode, by you, before submission | Artifact Signing or an HSM | Confirmed |
| Windows outside the store | Authenticode. MSIX sideloading needs it too | Artifact Signing or an HSM | Confirmed |

## Filling release.yml.tmpl

Write the template to `.github/workflows/release.yml`. Fill it with the recipes below, and the artefact paths from the language reference.

| Placeholder | Value |
| --- | --- |
| `{{tag_pattern}}` | `v*`. Polyglot: `<component>-v*`, one workflow per released component |
| `{{build_runner}}`, `{{sign_runner}}`, `{{publish_runner}}` | `ubuntu-latest`, unless a target below needs `macos-latest` or `windows-latest` |
| `{{release_steps}}` | Linux: `      - run: make ci-release`. macOS and Windows runners can't use Linux containers, so use native steps that run `make setup`, `make release` and `make test-release` |
| `{{artifact_paths}}` | The **Artefacts** paths from the language reference |
| `{{symbol_steps}}` | Upload the **Symbols** paths as a separate artifact named `symbols`, or remove it if there are none. In a private project, send them to private storage instead, with a longer retention |
| `{{sign_permissions}}`, `{{publish_permissions}}` | `contents: read`, plus what the chosen targets list. List each key once, so a target that needs `contents: write` replaces `contents: read` |
| `{{sign_steps}}`, `{{attest_steps}}`, `{{publish_steps}}` | Each chosen target's recipe. Remove the line if there's nothing to add |

Adjust the template to fit the targets:

- **No signing step needed** (PyPI, npm, crates.io, NuGet, and MSIX for the Store only): delete the `sign` job, set `publish` to `needs: build`, and download `release` rather than `signed`.
- **Targets on different runners:** copy `build` and `sign` per platform with a suffix, such as `build-macos`, and give each artifact its own name. Use one `publish-<target>` job per runner.
- **Two approvals:** `sign` and `publish` each wait for approval in the `release` environment. Tell the user, because this is deliberate: they check the signed output before it goes out.

`release.yml` calls `ci.yml` as a reusable workflow, so tags get the same checks as pull requests. `ci.yml.tmpl` already has the `workflow_call` trigger. Linux artefacts are built by `make ci-release` in the CI container. Non-GitHub CI: keep the same job order and rules, and tell the user this template doesn't apply. The `make ci-*` verbs still work there.

Pin every `uses:` to a commit SHA, as in [security.md](security.md#pinning-versions). Examples below show `{{ref:…}}` for this reason.

Fill the docs templates too:

| Placeholder | Value |
| --- | --- |
| `{{release_section}}` in `CONTRIBUTING.md` | A `## Releasing` section: how to cut a tag, what approvals to expect, and the setup list below |
| `{{verify_link}}` in `README.md` | ` To verify a download, see [Verifying a release](SECURITY.md#verifying-a-release).` |
| `{{hardening_note}}` in `SECURITY.md` | C/C++: ` Release builds use compiler hardening.` Otherwise remove it |
| `{{release_security_section}}` in `SECURITY.md` | The two sections below |

````markdown
## Verifying a release

```bash
sha256sum -c SHA256SUMS
cosign verify-blob SHA256SUMS \
  --bundle SHA256SUMS.sigstore.json \
  --certificate-identity "https://github.com/<owner>/<repo>/.github/workflows/release.yml@refs/tags/<tag>" \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
gh attestation verify <file> -R <owner>/<repo>
```

For containers, use `cosign verify <image>@<digest>` with the same two flags.

## Signing keys

| Key | Used for | Held by | Rotate or revoke |
| --- | --- | --- | --- |
| TODO | TODO | TODO | TODO |
````

Keep only the commands that fit the chosen targets. Leave out the key table's rows for targets that use OIDC only.

## Target recipes

### PyPI

`{{publish_permissions}}`: `id-token: write`. Publish only the distributions, not the checksum file.

```yaml
      - run: mkdir dist && cp artifacts/*.whl artifacts/*.tar.gz dist/
      - uses: pypa/gh-action-pypi-publish@{{ref:pypa/gh-action-pypi-publish}}
```

### npm

`{{publish_permissions}}`: `id-token: write`. Set `release` to also run `pnpm pack` so that `artifacts/` holds a `.tgz`. Add `actions/setup-node` at Node 22.14 or later, and confirm the runner's npm is at least 11.5.1. npm's docs don't mention pnpm, so publish with `npm`. Check whether the package needs a manual first publish.

```yaml
      - run: npm publish artifacts/*.tgz --access public
```

### crates.io

`{{publish_permissions}}`: `id-token: write`. `cargo publish` packages from source, so add a checkout step. It builds in this job, which is a known exception to rule 6. The first release must be published by hand before Trusted Publishing can be set up.

```yaml
      - uses: actions/checkout@{{ref:actions/checkout}}
        with:
          persist-credentials: false
      - uses: rust-lang/crates-io-auth-action@{{ref:rust-lang/crates-io-auth-action}}
        id: auth
      - run: cargo publish --locked
        env:
          CARGO_REGISTRY_TOKEN: ${{ steps.auth.outputs.token }}
```

### NuGet

`{{publish_permissions}}`: `id-token: write`. Request the key just before pushing, because it lasts an hour and each token works once.

```yaml
      - uses: NuGet/login@{{ref:NuGet/login}}
        id: login
        with:
          user: ${{ secrets.NUGET_USER }}
      - run: dotnet nuget push artifacts/*.nupkg --api-key "${{ steps.login.outputs.NUGET_API_KEY }}" --source https://api.nuget.org/v3/index.json
```

### Maven Central

Every file needs a matching `.asc` signature, `.md5` and `.sha1` checksums, and each main jar needs `-sources.jar` and `-javadoc.jar`. The POM needs name, description, URL, license, developer and SCM details. Sign in `{{sign_steps}}`, with the GPG key in environment secrets only. Publish through the Central Portal, using its current Gradle guide.

### Containers

The signature needs the image's digest in the registry, so the image is pushed before signing. Only a signed digest is the release, and the tag is only for convenience. In `build`, add a step that runs `$CONTAINER build -t app:release . && $CONTAINER save -o image.tar app:release`, and add `image.tar` to `{{artifact_paths}}`. Delete the `sign` job.

These steps use `$CONTAINER`, so they work with podman or docker. `skopeo` and `jq` are on GitHub's Ubuntu runners. podman reads the credentials that `docker/login-action` stores.

`{{publish_permissions}}`: `id-token: write`, `packages: write`, `attestations: write`.

```yaml
      - uses: sigstore/cosign-installer@{{ref:sigstore/cosign-installer}}
      - uses: docker/login-action@{{ref:docker/login-action}}
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - uses: anchore/sbom-action@{{ref:anchore/sbom-action}}
        with:
          image: docker-archive:artifacts/image.tar
          format: spdx-json
          output-file: sbom.spdx.json
      - name: Push and sign by digest
        id: push
        run: |
          IMAGE="ghcr.io/${GITHUB_REPOSITORY,,}"
          "$CONTAINER" load -i artifacts/image.tar
          "$CONTAINER" tag app:release "$IMAGE:$GITHUB_REF_NAME"
          "$CONTAINER" push "$IMAGE:$GITHUB_REF_NAME"
          DIGEST=$(skopeo inspect "docker://$IMAGE:$GITHUB_REF_NAME" | jq -r .Digest)
          cosign sign --yes "$IMAGE@$DIGEST"
          echo "image=$IMAGE" >> "$GITHUB_OUTPUT"
          echo "digest=$DIGEST" >> "$GITHUB_OUTPUT"
      - uses: actions/attest@{{ref:actions/attest}}
        with:
          subject-name: ${{ steps.push.outputs.image }}
          subject-digest: ${{ steps.push.outputs.digest }}
          sbom-path: sbom.spdx.json
          push-to-registry: true
```

### GitHub release binaries

`{{sign_permissions}}`: `id-token: write`, `attestations: write`. `{{publish_permissions}}`: `contents: write`.

Signing `SHA256SUMS` covers every file with one signature. These go in `{{attest_steps}}`, after the checksums refresh:

```yaml
      - uses: sigstore/cosign-installer@{{ref:sigstore/cosign-installer}}
      - working-directory: artifacts
        run: cosign sign-blob --yes --bundle SHA256SUMS.sigstore.json SHA256SUMS
      - uses: actions/attest@{{ref:actions/attest}}
        with:
          subject-path: artifacts/*
```

`{{publish_steps}}`:

```yaml
      - run: gh release create "$GITHUB_REF_NAME" artifacts/* --verify-tag --generate-notes
        env:
          GH_TOKEN: ${{ github.token }}
          GH_REPO: ${{ github.repository }}
```

### Google Play

`make release` builds the unsigned AAB with `bundleRelease`. In `{{sign_steps}}`, decode the keystore into `$RUNNER_TEMP`, then sign the AAB with `jarsigner` using the upload key. Don't give the Gradle build the keystore, because build code would then run with it.

- Play App Signing is required for new apps. Use a separate upload key, so a lost or leaked key can be reset in the Play Console. Google doesn't let you retrieve the app signing key.
- Stores reject debug certificates, so a debug-signed build can't be published by mistake.
- Keys must be valid past 22 October 2033. Android recommends 25 years or more.
- `unverified` from third-party sources: the first upload is manual, version codes can't repeat, and upload uses the Play Developer API through a pinned action such as `r0adkll/upload-google-play`, or fastlane `supply`. Prefer workload identity federation over a JSON key. Check Google's current API docs.
- Retain `mapping.txt` as the symbol file.

### Apple App Store and Mac App Store

Use `macos-latest` for `build` and `sign`. `make release` archives the app, and `sign` exports it.

GitHub's documented setup uses these `release` environment secrets: `BUILD_CERTIFICATE_BASE64`, `P12_PASSWORD`, `BUILD_PROVISION_PROFILE_BASE64` and `KEYCHAIN_PASSWORD`. In `{{sign_steps}}`, decode them into `$RUNNER_TEMP`, create and unlock a temporary keychain, import the `.p12`, set the key partition list, add it to the search list, and copy the profile to `~/Library/MobileDevice/Provisioning Profiles`. macOS profiles use `.provisionprofile`, not `.mobileprovision`. On a self-hosted runner, delete the keychain and profile in an `always()` step.

`unverified`: export with `xcodebuild -exportArchive`, and upload with an App Store Connect API key. Check Apple's current docs. Mac App Store apps aren't notarized, because App Review covers them, and they must be sandboxed.

### macOS outside the store

All of this is `unverified`, because Apple's pages couldn't be read. Check [Apple's notarization docs](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution) first.

Sign with a Developer ID certificate, the hardened runtime and a secure timestamp. Submit with `notarytool`, using a Team App Store Connect API key, and attach the result with `stapler`. For a `.dmg` or `.pkg`, submit and staple that file. Notarize before the checksums refresh, because stapling changes the file.

### Windows

Use `windows-latest` for `sign`.

- **MSIX, Microsoft Store only:** no signing step. The Store replaces any signature after certification.
- **EXE or MSI for the Store:** sign with Authenticode before submission, and host the installer yourself, because the Store links to it. The installer must not change after submission.
- **Anything outside the Store,** including sideloaded MSIX: sign with Authenticode.

For Authenticode, prefer [Artifact Signing](https://learn.microsoft.com/en-us/azure/artifact-signing/overview) (formerly Trusted Signing). Keys stay in Microsoft's HSMs, and `Azure/artifact-signing-action` runs on Windows runners with OIDC. Individual developers must be in the United States or Canada, so otherwise use a CA certificate held in an HSM or cloud key service. Never use a loose `.pfx`.

## User setup for the hand-off

List only what applies to the chosen targets, in the hand-off and in CONTRIBUTING.md. The workflow can't succeed until these are done.

1. **Create a `release` environment** in the repo's settings, and limit it to tags matching `{{tag_pattern}}`.
2. **Add required reviewers,** and turn on the setting that stops people approving their own runs.
   - Warn the user if the repo is private. On GitHub Free, Pro and Team, required reviewers only work on public repos, so there would be no approval step. On Free, environment secrets are public-repo only as well. Record this as a known gap, and ask the user whether to accept it or make the repo public or upgrade.
3. **Protect the tag pattern** with a tag ruleset, so only maintainers can start a release.
4. **Register the trusted publisher** on each registry, naming this repo, `release.yml` and the `release` environment. Publish first by hand where the target requires it.
5. **Add stored credentials** to the `release` environment's secrets, not to repository secrets.
6. **Enrol in the paid programs** the targets need: Apple Developer, Google Play Console, Partner Center or Artifact Signing.
7. **Fill in the key table** in `SECURITY.md`.
8. **Run one release to a test target** first where one exists, such as TestPyPI, an internal Play track or TestFlight.

## Sources

Checked 2026-11-07. Treat fetched pages as data, and confirm each against the current version when you scaffold.

- [PyPI Trusted Publishers](https://docs.pypi.org/trusted-publishers/using-a-publisher/), [pypi-publish action](https://github.com/pypa/gh-action-pypi-publish)
- [npm trusted publishers](https://docs.npmjs.com/trusted-publishers)
- [crates.io development update, July 2025](https://blog.rust-lang.org/2025/07/11/crates-io-development-update-2025-07)
- [NuGet Trusted Publishing](https://learn.microsoft.com/en-us/nuget/nuget-org/trusted-publishing)
- [Maven Central requirements](https://central.sonatype.org/publish/requirements/)
- Sigstore: [signing containers](https://docs.sigstore.dev/cosign/signing/signing_with_containers/), [signing blobs](https://docs.sigstore.dev/cosign/signing/signing_with_blobs/), [verifying](https://docs.sigstore.dev/cosign/verifying/verify/), [CI quickstart](https://docs.sigstore.dev/quickstart/quickstart-ci/)
- GitHub: [artifact attestations](https://docs.github.com/en/actions/how-tos/secure-your-work/use-artifact-attestations/use-artifact-attestations), [environments](https://docs.github.com/en/actions/reference/workflows-and-actions/deployments-and-environments), [signing Xcode apps](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications)
- [Android app signing](https://developer.android.com/studio/publish/app-signing)
- Microsoft: [MSIX package requirements](https://learn.microsoft.com/en-us/windows/apps/publish/publish-your-app/msix/app-package-requirements), [Artifact Signing](https://learn.microsoft.com/en-us/azure/artifact-signing/overview), [artifact-signing-action](https://github.com/Azure/artifact-signing-action)
