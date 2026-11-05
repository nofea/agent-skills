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
| `security-deps` | `pnpm audit --audit-level high` |
| `clean` | `rm -rf dist coverage` |

Each recipe goes tab-indented under its target. Join multi-step recipes with `&&`, or put each step on its own line.

## .gitignore

`node_modules/ dist/ coverage/ *.tsbuildinfo .env`

## Pre-commit local hook

```yaml
      - id: lint
        name: biome + tsc
        entry: make lint
        language: system
        pass_filenames: false
        types_or: [ts, tsx, javascript, json]
```

## CI setup steps

```yaml
      - uses: pnpm/action-setup@<sha> # vX   (reads packageManager)
      - uses: actions/setup-node@<sha> # vX
        with:
          node-version-file: .nvmrc
          cache: pnpm
```

pnpm uses `--frozen-lockfile` automatically when `CI=true`. Dependabot ecosystem: `npm` (it handles pnpm lockfiles). Docker ignore extras: `node_modules dist coverage`.

## Dockerfile (service)

```dockerfile
FROM node:24-slim AS build
RUN corepack enable
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
COPY tsconfig.json ./
COPY src ./src
RUN pnpm run build && pnpm prune --prod

FROM node:24-slim
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
