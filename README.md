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
| `align-rna`  | RNA-seq alignment: STAR (Linux & Intel macOS) |
| `align-dna`  | DNA-seq alignment: chromap |
| `ml`         | PyTorch + scvi-tools + scanpy for single-cell / ML; runs on CPU, and on the Apple GPU (MPS) on Apple Silicon |
| `ml-gpu`     | Same stack on an NVIDIA CUDA GPU (Linux only) |

Enter a specific one with `pixi shell -e align-rna`.

## Containers

Each environment ships as its **own** container image — pull only the one
you need. Images are published per env as `ghcr.io/liuhlab/liulab-runtime:<env>`
(e.g. `:align-rna`, `:align-dna`, `:ml`, `:ml-gpu`).

```bash
# Docker — pull and run a single-env image (env is baked in)
docker pull ghcr.io/liuhlab/liulab-runtime:align-rna
docker run --rm ghcr.io/liuhlab/liulab-runtime:align-rna STAR --version

# GPU image needs the host driver: add --gpus all (Docker) / --nv (Singularity)
docker run --rm --gpus all ghcr.io/liuhlab/liulab-runtime:ml-gpu \
  python -c "import torch; print(torch.cuda.is_available())"

# Singularity / Apptainer
singularity pull docker://ghcr.io/liuhlab/liulab-runtime:align-rna
singularity run liulab-runtime_align-rna.sif STAR --version

# Build one locally instead of pulling
docker build --build-arg PIXI_ENV=align-rna -t liulab-runtime:align-rna .
```

Which envs are published is the `docker-environments` list in
`pyproject.toml`. Images are **amd64-only** (no `linux-aarch64` platform); on
Apple Silicon, build/run with `--platform=linux/amd64`. Full instructions:
**[Containers guide](https://liuhlab.github.io/liulab-runtime/containers/)**.
