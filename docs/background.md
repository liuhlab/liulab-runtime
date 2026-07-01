# Background

This page explains the tools behind **liulab-runtime** and how the
pieces fit together. You don't need any of this to use the package — but
it helps to know what's happening when something goes wrong, or when you
want to add your own environment.

## What is PyPI?

**PyPI** (the Python Package Index) is the official home for Python
libraries — it's what `pip install` downloads from. Almost any pure-Python
package you can think of lives there.

The catch: PyPI is Python-only. It doesn't handle compiled command-line
tools like `samtools` or `STAR`, and it doesn't manage non-Python
dependencies. That's where conda comes in.

In this project we use **both**: conda (via pixi) for tools and most
libraries, and PyPI for a few Python packages that aren't on conda —
including the lab's own packages, which pixi installs straight from
GitHub.

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
  packages from pypi or straight from GitHub.

So: conda/bioconda provide the *packages*; pixi is the *manager* that
assembles them into tidy, reproducible environments.

## How this package is organized

Everything is declared in `pyproject.toml`, in three layers:

1. **Base layer** (`[tool.pixi.dependencies]`) — included in *every*
   environment. We put `python` and `ipykernel` here so any environment
   can act as a Jupyter kernel.

2. **Features** (`[tool.pixi.feature.<name>]`) — named bundles of extra
   packages. For example, the `align-rna` feature adds RNA-seq aligners.

3. **Environments** (`[tool.pixi.environments]`) — recipes that combine
   features. The `default` environment combines the analysis, dev, and
   docs features; `align-rna` is the base layer plus the `align-base`
   (shared read-processing) and `align-rna` (aligners) features.

This is why environments share their common pieces but stay small and
focused.

## Adding a package that lives only on GitHub

Some lab packages are still in development and aren't published on conda
or PyPI yet — they exist only as a GitHub repository. pixi can install
these directly from GitHub as a **PyPI (git) dependency**.

That's exactly how `liulab-data` and `liulab-genome` are wired in. Because
they're used nearly everywhere, they live in a shared `lab` feature that
every environment except `docs` includes:

```toml
[tool.pixi.feature.lab.pypi-dependencies]
liulab-data = { git = "https://github.com/liuhlab/liulab-data.git" }
liulab-genome = { git = "https://github.com/liuhlab/liulab-genome.git" }
```

To add another, drop a line in the relevant feature's
`pypi-dependencies` table. You can pin to a specific branch, tag, or
commit so everyone gets the same code:

```toml
[tool.pixi.feature.analysis.pypi-dependencies]
# latest on the default branch
my-pkg = { git = "https://github.com/liuhlab/my-pkg.git" }
# pin to a branch / tag / commit
my-pkg = { git = "https://github.com/liuhlab/my-pkg.git", branch = "dev" }
my-pkg = { git = "https://github.com/liuhlab/my-pkg.git", tag = "v0.2.0" }
my-pkg = { git = "https://github.com/liuhlab/my-pkg.git", rev = "a1b2c3d" }
```

Then run `pixi install` to fetch and build it.

!!! note "A couple of requirements"
    - The repository must be **pip-installable** — i.e. it has a
      `pyproject.toml` (or `setup.py`) at its root.
    - For a **private** repo, make sure your machine can already clone it
      (e.g. via an SSH key or a cached GitHub credential); pixi uses your
      normal git access.



## How Jupyter kernels are registered

We want every environment to be usable as a kernel inside Jupyter, so you
can switch between them in a notebook.

The `pixi run register-kernels` command (which you run once, right after
`pixi install`) walks through every environment and registers it as a
Jupyter kernel. So `align-rna` becomes a kernel named **"Python (liulab
align-rna)"**, and so on.

It's safe to run again at any time — for instance after you add a new
environment.

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
gets Python too. Run `pixi run register-kernels` afterwards to add it as a
Jupyter kernel.

## How to contribute to this repository

Changes go through a simple branch-and-merge flow:

1. **Create a branch** for your work:

    ```bash
    git switch -c my-new-env
    ```

2. **Make your change** — usually editing `pyproject.toml` to add a
   feature or environment — and check it solves:

    ```bash
    pixi install
    ```

3. **Commit and push** your branch, then open a pull request on GitHub.

4. **Merge to `main`** once it's reviewed and the change has matured.
   Merging to `main` automatically rebuilds and publishes the docs.

When you change the available environments, update the tables in
`README.md` and `docs/index.md` so they stay accurate.

## Versioning

This package uses **date-based (CalVer) versioning**: the version number
is the date of release, e.g. `2026.6.25`. There's no API to keep stable
here — it's an environment definition — so the date simply tells you how
recent your copy is.
