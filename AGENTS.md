# liulab-runtime

How any agent works on this repo. `CLAUDE.md` is a symlink to this file, so edit this one.

The lab's environment manager: one pixi workspace that defines the environments the Liu Lab
analyses data in, and the container images built from them. It ships no importable code. The
thing easy to get wrong: `[tool.pixi.dependencies]` is the base layer of every environment
and every published image, so a tool for this repo's own upkeep goes in the `dev` feature.

## Restraint

Generalizable, lightweight, uncustomized — in that order, and ahead of thorough. Every gate,
lint rule and check is paid by everyone who works here afterwards. Before adding one, ask
whether it generalizes, what the total now is, and whether a narrower rule would do. A
measurement outranks a hypothesis.

## Toolchain

- **pixi** only. Never bare pip, uv, or conda. `pyproject.toml` holds the channels, features,
  environments and tasks.
- **Python 3.13**, declared by `requires-python` and the pixi pin, and nowhere else.
- **hatch-vcs**: the version is the newest git tag, CalVer `vYYYY.M.PATCH`. Never write a
  version by hand. Tags up to `2026.8.14` have no `v`.
- Platforms `osx-arm64`, `osx-64`, `linux-64`, and `linux-64-cuda`; channels conda-forge and
  bioconda. The reasons are comments in `pyproject.toml`.

```bash
pixi install              # build every environment
pixi shell -e align-rna   # enter one
pixi run <task>
```

## Layout

```text
pyproject.toml    the source of truth: dependencies, features, environments, tasks
Dockerfile        one image per environment; liulab-runtime.def wraps it for Apptainer
scripts/          check.sh (the gate), conformance.py, stack, update-env.sh, kernels
docs/             the published site; docs/adr/ and docs/agents/ are agent-facing
skills/           repo-local agent skills; `python skills/install.py --help`
GLOSSARY.md       the words this repo uses
```

## Environments

- `[tool.pixi.dependencies]` is the base layer. Keep `python` and `ipykernel` there, so every
  environment can back a Jupyter kernel, plus near-universal tools such as `htslib` and `pigz`.
- `[tool.pixi.feature.<name>]` is a named bundle; `[tool.pixi.environments]` combines them.
  To add an environment, add a feature, then list it under `environments`.
- Alignment is layered: `align-base` holds aligner-agnostic read processing, and `align-rna`
  and `align-dna` each add an aligner.
- Prefer conda packages. Use `pypi-dependencies` only for what conda lacks, such as the lab's
  own GitHub packages.
- A tool with no `osx-arm64` build, such as STAR, narrows its feature with `platforms = [...]`,
  as `align-rna` does. It still runs on Apple Silicon under Rosetta; `docs/index.md` has the
  steps.
- When the set of environments changes, update the tables in `README.md` and `docs/index.md`.

## Kernels and images

- Kernels are not registered at install: users run `pixi run register-kernels` once. Keep
  `scripts/register_all_kernels.sh` quiet and dependency-light.
- `Dockerfile` builds one image per entry in `docker-environments` (`pyproject.toml`), pushed
  as `ghcr.io/liuhlab/liulab-runtime:<env>`. The baked environment must be active on every
  entry into the container: read the ADR on it before touching `BASH_ENV`, `PATH` or
  `%environment`.

## The lab stack

`pixi run stack` runs one git command across the four sibling checkouts (`liulab-runtime`,
`seqforge`, `liulab-data`, `liulab-genome`) under one parent `src/`. It is a batch helper, not
a superproject: never nest them as submodules. A lab package change reaches this repo once it
is on that package's `main`; `pixi run update-env` then re-resolves the lock, on Linux.

## Gates

`pixi run check` must be green before you commit. It is `check-static`:

| Step | Tool |
| --- | --- |
| `lint`, `fmt-check` | ruff |
| `typecheck` | pyright on `scripts/` and `skills/` |
| `vale`, `markdownlint` | the writing rules |
| `conformance` | the repo still matches the template's rules |
| `hooks` | pre-commit: whitespace, file ends, YAML, TOML, merge markers, large files, shellcheck |

`check.sh` runs every step and reports **all** failures, so read to the bottom. The docs build,
`pixi run -e docs docs-build`, is not part of `check`; CI runs it as a step of its own. Install
the commit hooks once with `pixi run -- pre-commit install`.

Work on a branch and merge through a pull request. CI runs on pull requests only. A merge to
`main` publishes the site; a `v` tag builds and pushes the images.

**Release:** add a `CHANGELOG.md` entry headed with the next version, `YYYY.M.PATCH`, PATCH
counting from 0 each month. Once merged, tag `main` as `v<version>`. The tag sets the version
and publishes the pinned images.

## Writing rules

Three rules, enforced by vale: be concise; agent-facing documents have word caps; human-facing
prose avoids jargon and stays readable. Read `docs/agents/writing.md` before writing either kind.
The site is for end users, not developers: setup in `docs/index.md`, concepts in
`docs/background.md`.

A comment says why a line is surprising, and nothing more. Never record measurements, the
environment (hostnames, absolute paths, package versions), code restated in prose, or history.
A decision goes in an ADR, vocabulary in `GLOSSARY.md`, and an open question in an issue.

## Read next

| When | Read |
| --- | --- |
| Before changing anything | `GLOSSARY.md`, then any ADR covering the area |
| Writing anything | `docs/agents/writing.md` |
| Changing how an image activates its environment | `docs/adr/0001-baked-environment-active-on-every-entry.md` |
| Re-resolving `pixi.lock` | `docs/adr/0002-re-resolve-the-lock-on-linux.md` |

The issue tracker, triage labels and domain docs are the lab defaults, the page `/lab-setup`
points every agent at. A page of this repo's own under `docs/agents/` overrides only that one
default, so write one only where this repo differs.
