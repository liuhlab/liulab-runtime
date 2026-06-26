# liulab-runtime

Welcome! **liulab-runtime** is the Liu Lab's central place for managing
the software environments we use for data analysis.

Think of it as a shared toolbox. Rather than each person setting up
conda environments by hand (and getting slightly different versions of
everything), this repository defines a handful of ready-made
environments that everyone can install with a single command. Each one
bundles the lab's own packages together with the standard bioinformatics
and plotting tools.

It is built on [pixi](https://pixi.sh), a modern, fast environment
manager. You don't need to know how pixi works to use it — just follow
the steps below. If you're curious about *what's going on under the
hood*, see [Background](background.md).

---

## Setup from scratch

### 1. Install pixi

pixi is a single program that manages everything else. Install it once
per computer.

=== "macOS / Linux"

    ```bash
    curl -fsSL https://pixi.sh/install.sh | bash
    ```

=== "Windows (PowerShell)"

    ```powershell
    iwr -useb https://pixi.sh/install.ps1 | iex
    ```

Close and reopen your terminal afterwards so the `pixi` command is
available. Check it worked:

```bash
pixi --version
```

### 2. Install the runtime

Clone this repository and let pixi build the environments:

```bash
git clone https://github.com/liuhlab/liulab-runtime.git
cd liulab-runtime
pixi install
```

This reads the recipe in `pyproject.toml`, downloads everything, and
sets up each environment. The first run can take a few minutes; later
runs are fast because pixi caches what it downloads.

### 3. Activate an environment

To start working, "enter" an environment. This puts all of its tools on
your path:

```bash
pixi shell          # enters the default analysis environment
```

You're now in a shell where `python`, `jupyter`, `samtools`, and the lab
packages are all available. Type `exit` to leave.

To enter a different environment, name it:

```bash
pixi shell -e align-star
```

!!! tip "Run one command without entering a shell"
    Use `pixi run` to execute a single command inside an environment:

    ```bash
    pixi run lab                    # launch Jupyter Lab
    pixi run -e align-star STAR --version
    ```

### 4. Use it in Jupyter

Every environment registers itself as a **Jupyter kernel** the first
time you enter it. So after you've run `pixi shell -e align-star` once,
a kernel called **"Python (liulab align-star)"** appears in Jupyter.

Launch Jupyter Lab from the default environment and pick whichever kernel
you need from the kernel menu:

```bash
pixi run lab
```

Want to register every kernel up front, without entering each
environment? Run:

```bash
pixi run register-kernels
```

---

## Common tasks

| I want to...                          | Command                              |
| ------------------------------------- | ------------------------------------ |
| See all available environments        | `pixi run envs`                      |
| Enter the default environment         | `pixi shell`                         |
| Enter a specific environment          | `pixi shell -e align-star`           |
| Launch Jupyter Lab                    | `pixi run lab`                       |
| Register all Jupyter kernels          | `pixi run register-kernels`          |
| Update to the latest package versions | `pixi update`                        |
| Run a single command in an env        | `pixi run -e <env> <command>`        |

---

## Available environments

| Environment  | Contents                                                            |
| ------------ | ------------------------------------------------------------------- |
| `default`    | `liulab-data`, `liulab-genome`, Jupyter Lab, seaborn, pandas, numpy, samtools, bedtools |
| `align-star` | STAR aligner, samtools                                              |
| `docs`       | Tools for building this documentation site                         |

Need a new environment for a specific task? See
[Background → Adding your own environment](background.md#adding-your-own-environment).
