# Background

This page explains the tools behind **liulab-runtime** and how the
pieces fit together. You don't need any of this to use the package — but
it helps to know what's happening when something goes wrong, or when you
want to add your own environment.

## What is conda?

A lot of scientific software isn't pure Python. Tools like `samtools` or
`STAR` are compiled programs; others depend on specific system libraries.
Installing all of that by hand is painful and easy to get wrong.

**Conda** solves this. It's a *package manager* that installs not just
Python libraries but also compiled tools and their dependencies, all
isolated inside an **environment** — a self-contained folder that won't
interfere with the rest of your system. You can have several
environments side by side, each with different versions of things.

Conda installs packages from **channels** (online package
repositories).

## What is bioconda?

**Bioconda** is a community-run conda channel dedicated to
bioinformatics software. Tools like `samtools`, `bedtools`, `STAR`,
`bwa`, and thousands of others are published there.

Alongside it is **conda-forge**, a large general-purpose channel that
provides Python, NumPy, pandas, and most everything else.

Together, conda-forge + bioconda cover almost everything a
bioinformatics project needs. This package pulls from both.

## What is pixi?

**pixi** is a newer, faster tool that uses the *same* conda packages and
channels (conda-forge, bioconda), but is much nicer to work with:

- **One project file.** All environments are described in
  `pyproject.toml`. No manual `conda create` commands to remember.
- **Reproducible.** pixi writes a lock file (`pixi.lock`) recording the
  exact versions of everything, so every lab member gets an identical
  setup.
- **Fast.** Installs and resolves dependencies far quicker than classic
  conda.
- **Mixes conda and PyPI.** It can install conda packages *and* Python
  packages straight from GitHub (which is how we pull in the lab's own
  `liulab-data` and `liulab-genome`).

So: conda/bioconda provide the *packages*; pixi is the *manager* that
assembles them into tidy, reproducible environments.

## How this package is organized

Everything is declared in `pyproject.toml`, in three layers:

1. **Base layer** (`[tool.pixi.dependencies]`) — included in *every*
   environment. We put `python` and `ipykernel` here so any environment
   can act as a Jupyter kernel.

2. **Features** (`[tool.pixi.feature.<name>]`) — named bundles of extra
   packages. For example, the `align-star` feature adds the STAR aligner.

3. **Environments** (`[tool.pixi.environments]`) — recipes that combine
   features. The `default` environment combines the analysis, dev, and
   docs features; `align-star` is the base layer plus the `align-star`
   feature.

This is why environments share their common pieces but stay small and
focused.

## How Jupyter kernels are registered

We want every environment to be usable as a kernel inside Jupyter,
ideally without anyone having to remember an extra step.

pixi runs an **activation script** every time you enter an environment.
Ours ([`scripts/register_kernel.sh`](https://github.com/liuhlab/liulab-runtime/blob/main/scripts/register_kernel.sh))
registers the current environment as a Jupyter kernel the first time you
enter it, then records a marker file so it doesn't repeat the work.

The result: the first time you run `pixi shell -e align-star`, a kernel
named **"Python (liulab align-star)"** shows up in Jupyter Lab.

!!! note "Why not at install time?"
    pixi doesn't run a hook at `pixi install` time, so we register on
    *first activation* instead. In practice that's the same moment for
    you — the first time you actually use an environment. If you'd rather
    register everything up front, run `pixi run register-kernels`.

## Adding your own environment

Say you want an environment for variant calling with `bcftools`. Add a
feature and an environment to `pyproject.toml`:

```toml
[tool.pixi.feature.variants.dependencies]
bcftools = "*"

[tool.pixi.environments]
variants = { features = ["variants"] }
```

Then install it and you're done:

```bash
pixi install
pixi shell -e variants
```

Because the base layer is in every environment, `variants` automatically
gets Python and an auto-registered Jupyter kernel too.

## Versioning

This package uses **date-based (CalVer) versioning**: the version number
is the date of release, e.g. `2026.6.25`. There's no API to keep stable
here — it's an environment definition — so the date simply tells you how
recent your copy is.
