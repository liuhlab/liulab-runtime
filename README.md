# liulab-runtime

[![Documentation](https://img.shields.io/badge/docs-liuhlab.github.io-teal)](https://liuhlab.github.io/liulab-runtime/)

The Liu Lab's **one-stop environment manager** for data analysis.

Instead of every project juggling its own conda environments, this
repository uses [pixi](https://pixi.sh) to provide a small set of
ready-made, reproducible environments — bundling the lab's [own packages](https://github.com/orgs/liuhlab/repositories) together with
common tools and packages. Full setup and background guides live in the
**[documentation](https://liuhlab.github.io/liulab-runtime/)**.

## Quick start

```bash
# 1. Install pixi (once per machine)
curl -fsSL https://pixi.sh/install.sh | bash

# 2. Get this repo and install the environments
git clone https://github.com/liuhlab/liulab-runtime.git
cd liulab-runtime
pixi install

# 3. Register every environment as a Jupyter kernel (run once)
pixi run register-kernels

# 4. Drop into the default analysis environment
pixi shell

# 5. ...or launch Jupyter Lab
pixi run lab
```

> **Platforms:** Linux is the primary, fully-supported platform. macOS
> (Intel & Apple Silicon) works for most environments. Windows is not
> supported — use WSL2.

## Available environments

| Environment  | What it's for                                                          |
| ------------ | --------------------------------------------------------------------- |
| `default`    | Everyday analysis: lab packages, Jupyter, plotting, samtools, bedtools |
| `align-base` | Aligner-agnostic read processing & QC (samtools, sambamba, fastqc, multiqc, repaq) |
| `align-rna`  | RNA-seq alignment: STAR, HISAT2, salmon, alevin-fry (Linux & Intel macOS) |

Enter a specific one with `pixi shell -e align-rna`.
