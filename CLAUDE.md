# CLAUDE.md

Guidance for working in this repository.

## What this is

`liulab-runtime` is **not** a Python library — it ships no importable
source code. It is a centralized **environment manager**: a single pixi
workspace that defines the reproducible environments the Liu Lab uses for
data analysis, aggregating the lab's own packages
(`liulab-data`, `liulab-genome`) with standard bioinformatics and
plotting tools.

The whole configuration lives in `pyproject.toml` under `[tool.pixi.*]`.

## Toolchain

Everything runs through **pixi** (https://pixi.sh). Do not use `pip`,
`conda`, or `venv` directly.

```bash
pixi install              # build all environments
pixi shell                # enter default env
pixi shell -e align-star  # enter a specific env
pixi run <task>           # run a defined task
```

## Repository layout

```
pyproject.toml            # the source of truth: channels, deps, features, envs, tasks
scripts/
  register_kernel.sh      # activation hook: registers active env as a Jupyter kernel
  register_all_kernels.sh # registers every env up front (`pixi run register-kernels`)
docs/                     # MkDocs site (index.md = getting started, background.md)
mkdocs.yml
.github/workflows/        # CI (docs build) + docs deploy
```

## How environments are structured

- `[tool.pixi.dependencies]` is the **base layer**, included in every
  environment. Keep `python` and `ipykernel` here so every env can back a
  Jupyter kernel.
- `[tool.pixi.feature.<name>]` defines a named bundle of extra packages.
- `[tool.pixi.environments]` combines features into an environment.

To add an environment: add a `feature`, then list it under
`environments`. Prefer conda packages (conda-forge / bioconda); use
`pypi-dependencies` only for things not on conda (e.g. GitHub-hosted lab
packages).

Some bioinformatics tools lack an `osx-arm64` build. When that happens,
narrow the feature with `platforms = [...]` (see `align-star`).

## Jupyter kernels

Kernels are registered automatically on **first activation** of each env
via the `scripts/register_kernel.sh` activation hook (pixi has no
install-time hook). The hook is idempotent — it uses a marker file under
`.pixi/`. Keep it quiet and dependency-free (POSIX `sh`).

## Conventions

- **Versioning:** date-based (CalVer), `YYYY.M.D`, set in
  `[project].version` and recorded in `CHANGELOG.md`.
- **Docs are for end users**, not developers — keep them concise and
  non-technical. Setup steps go in `docs/index.md`; conceptual
  explanation in `docs/background.md`.
- **Lint:** `pixi run lint` / `pixi run fmt` (ruff). `pre-commit` is
  configured; install once with `pixi run -- pre-commit install`.
- When you change available environments, update the tables in
  `README.md` and `docs/index.md` to match.
