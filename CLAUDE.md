# CLAUDE.md

Guidance for working in this repository.

## What this is

`liulab-runtime` is **not** a Python library — it ships no importable
source code. It is a centralized **environment manager**: a single pixi
workspace that defines the reproducible environments the Liu Lab uses for
data analysis, aggregating the lab's own packages with standard conda and
pypi tools.

The whole configuration lives in `pyproject.toml` under `[tool.pixi.*]`.

## Toolchain

Everything runs through **pixi** (https://pixi.sh). Do not use `pip`,
`conda`, or `venv` directly.

```bash
pixi install              # build all environments
pixi shell                # enter default env
pixi shell -e align-rna   # enter a specific env
pixi run <task>           # run a defined task
```

## Repository layout

```
pyproject.toml            # the source of truth: channels, deps, features, envs, tasks
scripts/                  # register_all_kernels.sh (kernels); stack (cross-repo git helper)
docs/                     # MkDocs site (index.md = getting started, background.md)
mkdocs.yml
.github/workflows/        # CI (docs build) + docs deploy
```

## How environments are structured

- `[tool.pixi.dependencies]` is the **base layer**, included in every
  environment. Keep `python` + `ipykernel` (so every env can back a
  Jupyter kernel) and near-universal tools (`htslib`, `pigz`) here.
- `[tool.pixi.feature.<name>]` defines a named bundle of extra packages.
- `[tool.pixi.environments]` combines features into an environment.

Alignment envs are layered: `align-base` holds aligner-agnostic,
shared read-processing tools; aligner envs like `align-rna` add the
aligners on top of `align-base`.

To add an environment: add a `feature`, then list it under
`environments`. Prefer conda packages (conda-forge / bioconda); use
`pypi-dependencies` only for things not on conda (e.g. GitHub-hosted lab
packages).

Some bioinformatics tools lack an `osx-arm64` build (e.g. STAR). When
that happens, narrow the feature with `platforms = [...]` (see
`align-rna`).

## Jupyter kernels

Kernels are **not** auto-registered. Users run `pixi run register-kernels`
once after `pixi install` (documented in `docs/index.md`); pixi has no
install-time hook. The task loops over every environment running the
per-env `register-kernel` task. Keep `scripts/register_all_kernels.sh`
quiet and dependency-light (POSIX-ish bash).

## Container images

`Dockerfile` builds **one image per env** (`--build-arg PIXI_ENV=<env>`,
published as `ghcr.io/liuhlab/liulab-runtime:<env>`); `liulab-runtime.def`
bootstraps the same GHCR image for Singularity/Apptainer. The published
list is `docker-environments` in `pyproject.toml`.

The baked env must stay active on **every** entry, not just the
entrypoint/runscript — workflow engines (Snakemake/Nextflow `container:`)
and `docker/apptainer exec … bash -c "…"` bypass those. Activation is
carried by, and these must stay in sync:

- `Dockerfile`: `BASH_ENV=/app/.pixi/activate-$PIXI_ENV.sh` (sourced by
  non-interactive `bash -c`) + a baseline `PATH` prepend of the env `bin/`.
- `liulab-runtime.def`: `%environment` sources the same generated script
  (apptainer runs it on both `run` and `exec`).

Prefer sourcing the generated `activate-<env>.sh` over a bare `PATH` edit —
it also runs the conda `activate.d` hooks (glib/proj/GDAL/…). Don't remove
these hooks; `apptainer exec <sif> <tool>` must work with no caller setup.

## Developing across the lab stack

This repo pins the lab's own packages (`seqforge`, `liulab-data`,
`liulab-genome`) by git URL, so it's also the place to coordinate their
checkouts during development. `scripts/stack` — exposed as `pixi run stack`
— fans one git command across the four sibling checkouts (`liulab-runtime`,
`seqforge`, `liulab-data`, `liulab-genome`) that live side by side under a
common parent `src/` dir. Commands: `status`, `sync`, `pull`, `push`,
`branch <name>`, `switch <name>`, `run <cmd...>`. A sibling that isn't
checked out is skipped, not an error.

It's a **batch helper, not a superproject**: the four repos stay
independent (own remotes, branches, CI) and no submodule pointers are
tracked — never nest them as submodules. A pinned dependency change reaches
this env only after it lands on that package's `main`: commit + push it in
its own repo (`stack push` helps), then `pixi update <package>` here. For
cross-repo editing, open the editor at the parent `src/` dir so all four
repos are under one working root.

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
