# TypeScript / Node

Tooling: **pnpm** · **tsc** (strict) · **Biome** (format + lint) · **Vitest** · **pnpm audit**. Node: the current Active LTS, pinned in `engines` and `.nvmrc`. pnpm is pinned in `packageManager` via corepack.

## Init

```bash
pnpm init
corepack use pnpm@latest            # writes "packageManager"
pnpm add -D typescript @types/node @biomejs/biome vitest
pnpm exec biome init                # biome.json
```

**Web app:** use the framework's create command instead (see [project-types.md](../project-types.md)), then add Biome/Vitest if the template doesn't have them.

## Layout

```
src/index.ts          # must exist, or tsc fails with "No inputs were found"; `export {};` is enough
tests/                # *.test.ts
package.json  pnpm-lock.yaml  tsconfig.json  biome.json  .nvmrc
```

- `package.json`: `"type": "module"`, `"engines": {"node": ">=<lts>"}`.
- **CLI:** `src/cli.ts` with a `#!/usr/bin/env node` shebang. Arguments via `node:util` `parseArgs` (stdlib) unless the user wants commander. Add `"bin": {"<name>": "dist/cli.js"}`.
- **Library:** `"exports": {".": {"types": "./dist/index.d.ts", "import": "./dist/index.js"}}`, `"files": ["dist"]`, and `declaration: true`.
- **Service:** `pnpm add fastify` (or hono, or the user's choice). Add `src/server.ts`, `src/config.ts` (env) and `.env.example`.

## tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2023", "module": "NodeNext", "moduleResolution": "NodeNext",
    "strict": true, "noUncheckedIndexedAccess": true, "exactOptionalPropertyTypes": true,
    "outDir": "dist", "rootDir": "src", "declaration": true, "sourceMap": true,
    "skipLibCheck": true, "verbatimModuleSyntax": true
  },
  "include": ["src"]
}
```

In `biome.json`, set `"vcs": {"enabled": true, "clientKind": "git", "useIgnoreFile": true}` so `dist/` and `node_modules/` are skipped.

## package.json scripts + Makefile recipes

Keep the scripts as the native interface. The Makefile calls them.

```json
"scripts": {
  "build": "tsc -p .",
  "build:release": "rm -rf dist && tsc -p tsconfig.release.json",
  "fmt": "biome check --write .",
  "fmt:check": "biome format .",
  "lint": "biome lint . && tsc -p . --noEmit",
  "test": "vitest run --passWithNoTests"
}
```

| Target | Recipe |
| --- | --- |
| `setup` | `pnpm install` |
| `build` | `pnpm run build` |
| `fmt` | `pnpm run fmt` |
| `fmt-check` | `pnpm run fmt:check` |
| `lint` | `pnpm run lint` |
| `test` | `pnpm run test` |
| `release` | `NODE_ENV=production pnpm run build:release` |
| `test-release` | `$(MAKE) test` (vitest runs the source, and `tsc` has no release-only behaviour) |
| `security-deps` | `pnpm audit --audit-level high` |
| `clean` | `rm -rf dist coverage` |

Each recipe goes tab-indented under its target. Join multi-step recipes with `&&`, or put each step on its own line.

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

`tsconfig.release.json`:
```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": { "sourceMap": false }
}
```

- `build:release` deletes `dist/` first, so no source maps are left from an earlier debug build.
- **Web apps:** point `build:release` at the framework's production build, such as `vite build`. Leave its source map option off, or upload maps only to the error tracker.
- Don't branch security behaviour on `NODE_ENV`, because it's only an environment variable.
- **Artefacts:** `dist/`.

## .gitignore

`.devenv*/ devenv.local.nix node_modules/ dist/ coverage/ *.tsbuildinfo .env`

## Pre-commit local hook

```yaml
      - id: lint
        name: biome + tsc
        entry: make lint
        language: system
        pass_filenames: false
        types_or: [ts, tsx, javascript, json]
```

## devenv

`{{devenv_languages}}`:
```nix
  languages.javascript = {
    enable = true;
    pnpm.enable = true;
  };
  languages.typescript.enable = true;
```

## CI container

`ci/Containerfile`:
```dockerfile
FROM docker.io/library/node:24-slim
RUN apt-get update && apt-get install -y --no-install-recommends make git && rm -rf /var/lib/apt/lists/*
RUN corepack enable
ENV HOME=/tmp COREPACK_ENABLE_DOWNLOAD_PROMPT=0
USER 65532:65532
```

Replace each `<version>` with the latest release.

pnpm uses `--frozen-lockfile` automatically when `CI=true`. Dependabot ecosystem: `npm` (it handles pnpm lockfiles), and `docker` for `/ci`. Docker ignore extras: `node_modules dist coverage`.

## Dockerfile (service)

```dockerfile
FROM docker.io/library/node:24-slim AS build
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY tsconfig.json tsconfig.release.json ./
COPY src ./src
RUN NODE_ENV=production pnpm run build:release && pnpm prune --prod

FROM docker.io/library/node:24-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build --chown=node /app/node_modules ./node_modules
COPY --from=build --chown=node /app/dist ./dist
COPY package.json ./
USER node
EXPOSE 3000
CMD ["node", "dist/server.js"]
```

Use the Node tag that matches `.nvmrc`.
