# liulab-runtime

Welcome! **liulab-runtime** is the Liu Lab's central place for managing
the software environments we use for data analysis.

Think of it as a shared toolbox. Rather than each person setting up
conda environments by hand (and getting slightly different versions of
everything), this repository defines a handful of ready-made
environments that everyone can install with a single command. Each one
bundles the lab's own packages together with the standard bioinformatics tools.

It is built on [pixi](https://pixi.sh), a modern, fast environment
manager. You don't need to know how pixi works to use it — just follow
the steps below. If you're curious about *what's going on under the
hood*, see [Background](background.md).

!!! info "Which platform should I use?"
    **Linux is the primary, fully-supported platform** — this is where
    nearly all real analysis runs (servers, clusters). **macOS** (both
    Intel and Apple Silicon) works for most environments and is great for
    development; note that a few aligners have no Apple Silicon build (see
    [Available environments](#available-environments)). **Windows is not
    supported** — install [WSL2](https://learn.microsoft.com/windows/wsl/install)
    and follow the Linux instructions inside it.

---

## Setup from scratch

### 1. Install pixi

pixi is a single program that manages everything else. Install it once
per computer.

```bash
curl -fsSL https://pixi.sh/install.sh | bash
```

(On Windows, run this *inside* a WSL2 Linux terminal — see the platform
note above.)

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
# Register the Jupyter kernels (run once)
pixi run register-kernels
```

This reads the recipe in `pyproject.toml`, downloads everything, and
sets up each environment. The first run can take a while; later
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
pixi shell -e align-rna
```

Not sure what's available? List every environment with:

```bash
pixi run envs        # shortcut for: pixi workspace environment list
```

!!! tip "Run one command without entering a shell"
    Use `pixi run` to execute a single command inside an environment:

    ```bash
    pixi run -e align-rna STAR --version
    ```

### 4. Use it in Jupyter

Because you ran `pixi run register-kernels`, every environment
shows up in Jupyter as its own **kernel** — e.g. **"Python (liulab
align-rna)"**.

Launch Jupyter Lab from the default environment and pick whichever kernel
you need from the kernel menu:

```bash
pixi run lab
```

If you add a new environment later, just run `pixi run register-kernels`
again to pick it up.

---

## Common tasks

| I want to...                          | Command                              |
| ------------------------------------- | ------------------------------------ |
| See all available environments        | `pixi run envs`                      |
| Enter the default environment         | `pixi shell`                         |
| Enter a specific environment          | `pixi shell -e align-rna`            |
| Launch Jupyter Lab                    | `pixi run lab`                       |
| Register all Jupyter kernels          | `pixi run register-kernels`          |
| Update to the latest package versions | `pixi update`                        |
| Run a single command in an env        | `pixi run -e <env> <command>`        |

---

## Available environments

| Environment  | Contents                                                            | Platforms |
| ------------ | ------------------------------------------------------------------- | --------- |
| `default`    | `liulab-data`, `liulab-genome`, Jupyter Lab, seaborn, pandas, numpy, samtools, bedtools | Linux, macOS |
| `align-base` | Aligner-agnostic read processing & QC: samtools, sambamba, fastqc, multiqc, repaq | Linux, macOS |
| `align-rna`  | RNA-seq aligners (on top of `align-base`): STAR, HISAT2, salmon, alevin-fry | Linux, Intel macOS |
| `docs`       | Tools for building this documentation site                         | Linux, macOS |

!!! warning "Apple Silicon & `align-rna`"
    STAR has no Apple Silicon (`osx-arm64`) build, so `align-rna` is
    available only on Linux and Intel macOS. On an M-series Mac, run it
    via a Linux container or on a cluster. The `align-base` toolkit works
    everywhere.

Need a new environment for a specific task? See
[Background → Adding your own environment](background.md#adding-your-own-environment).
