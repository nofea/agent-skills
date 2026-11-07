# Python

Tooling: **uv** (env, deps, build) · **ruff** (format + lint, including bandit `S` rules) · **mypy** (strict) · **pytest** · **pip-audit**. Python version: the latest stable release, pinned in `.python-version`.

## Init

```bash
uv init --package --name <name> .     # CLI / service / app (src layout, [project.scripts])
uv init --lib --name <name> .         # library
uv add --dev ruff mypy pytest pytest-cov pip-audit
```

`uv init` writes a minimal `main()`. Keep it as the entry point. With no uv, write `pyproject.toml` by hand using the same structure.

## Layout

```
src/<pkg>/__init__.py       # package; CLI: __main__.py + cli.py (argparse)
tests/                      # empty, with conftest.py only if needed
pyproject.toml  uv.lock  .python-version
```

- **CLI:** argparse (stdlib) unless the user wants typer/click. Entry point goes in `[project.scripts] <name> = "<pkg>.cli:main"`.
- **Library:** add the `py.typed` marker and export the public API via `__all__`.
- **Service:** `uv add fastapi uvicorn[standard]` (or the user's choice). Add `src/<pkg>/app.py`, `config.py` (env via pydantic-settings or `os.environ`) and `.env.example`.

## Config (append to pyproject.toml)

```toml
[tool.ruff]
line-length = 100
src = ["src", "tests"]

[tool.ruff.lint]
select = ["E", "W", "F", "I", "B", "UP", "S", "SIM", "N", "RUF", "PTH"]

[tool.ruff.lint.per-file-ignores]
"tests/**" = ["S101"]

[tool.mypy]
strict = true
files = ["src"]

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-ra"
```

## Makefile recipes

| Target | Recipe |
| --- | --- |
| `setup` | `uv sync` |
| `build` | `uv build` |
| `fmt` | `uv run ruff format . && uv run ruff check --fix .` |
| `fmt-check` | `uv run ruff format --check .` |
| `lint` | `uv run ruff check . && uv run mypy` |
| `test` | `uv run pytest \|\| [ $$? -eq 5 ]` (exit 5 = no tests collected) |
| `release` | `rm -rf dist && uv build` |
| `test-release` | `$(MAKE) test` (Python has no separate release compile) |
| `security-deps` | `uv run pip-audit --skip-editable` |
| `clean` | `rm -rf dist build .pytest_cache .mypy_cache .ruff_cache` |

Each recipe goes tab-indented under its target. Join multi-step recipes with `&&`, or put each step on its own line.

## Build profiles

Follow [build-profiles.md](../build-profiles.md).

- `python -O` removes `assert` statements. Ruff's `S101` rule flags them outside `tests/`, so keep it on, and don't suppress it for a security check.
- Services ship through the Dockerfile rather than the wheel, so for them `make release` proves packaging only.
- **Artefacts:** `dist/`.

## .gitignore

`.devenv*/ devenv.local.nix .venv/ __pycache__/ *.py[cod] dist/ build/ *.egg-info/ .mypy_cache/ .ruff_cache/ .pytest_cache/ .coverage htmlcov/ docs/api/ .env`

## Doxygen

| Placeholder | Value |
| --- | --- |
| `{{doxygen_input}}` | `src` |
| `{{doxygen_file_patterns}}` | `*.py` |
| `{{doxygen_exclude_patterns}}` | `*/__pycache__/*` |
| `{{docs_check_args}}` | `--require-file-doc src` |

Docstrings must start with `"""!` and use `@brief`, `@param`, `@return` and `@throws`, or the check can't read the tags. Each module needs a docstring. Functions annotated `-> None` need `@return None.`, except `__init__`, which must have no `@return`.

## Pre-commit local hook

```yaml
      - id: lint
        name: ruff format check + lint + mypy
        entry: make lint
        language: system
        pass_filenames: false
        types: [python]
```

## devenv

`{{devenv_languages}}`:
```nix
  languages.python = {
    enable = true;
    package = pkgs.python313;   # match .python-version
    uv.enable = true;
  };
```

## CI container

`ci/Containerfile`:
```dockerfile
FROM docker.io/library/python:3.13-slim
COPY --from=ghcr.io/astral-sh/uv:<version> /uv /usr/local/bin/uv
RUN apt-get update && apt-get install -y --no-install-recommends make git && rm -rf /var/lib/apt/lists/*
ENV HOME=/tmp UV_CACHE_DIR=/tmp/uv
USER 65532:65532
```

Replace each `<version>` with the latest release. Match the Python tag to `.python-version`. Keep this tag, `.python-version` and the `package` in `devenv.nix` on the same version. devenv stops uv from downloading Python, so a mismatch fails every target.

Dependabot ecosystem: `uv`, and `docker` for `/ci`. Docker ignore extras: `.venv __pycache__ .mypy_cache .ruff_cache .pytest_cache dist`.

## Dockerfile (service)

```dockerfile
FROM docker.io/library/python:3.13-slim AS build
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
WORKDIR /app
ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project
COPY src ./src
RUN uv sync --frozen --no-dev

FROM docker.io/library/python:3.13-slim
RUN useradd --create-home --uid 10001 app
WORKDIR /app
COPY --from=build --chown=app /app /app
ENV PATH="/app/.venv/bin:$PATH"
USER app
EXPOSE 8000
CMD ["uvicorn", "<pkg>.app:app", "--host", "0.0.0.0", "--port", "8000"]
```

Match the Python tag to `.python-version`, and pin the uv image to a version rather than `latest`.
