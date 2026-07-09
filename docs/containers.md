# Containers (Docker & Singularity)

Prefer not to install pixi at all? Each environment ships as its **own**
container image, so you pull only the one you need. This is handy on shared
servers and HPC clusters, or anywhere you want a guaranteed-identical setup.
It's especially useful on **older Linux systems** (e.g. CentOS 7), where a
direct `pixi install` can be hard or impossible because the host is too old:
the container carries its own modern userspace, so it only needs a compatible
kernel — not an up-to-date OS.

Images are published to GHCR, one tag per environment:

| Image | Contains |
| ----- | -------- |
| `ghcr.io/liuhlab/liulab-runtime:align-rna` | RNA-seq alignment (STAR + QC) |
| `ghcr.io/liuhlab/liulab-runtime:align-dna` | DNA-seq alignment (chromap + QC) |
| `ghcr.io/liuhlab/liulab-runtime:ml`        | PyTorch (CPU/MPS) + scvi-tools + scanpy |
| `ghcr.io/liuhlab/liulab-runtime:ml-gpu`    | The ML stack built against an NVIDIA CUDA GPU |

Each image holds a **single** environment (baked in — no need to pick one at
runtime). A moving `:<env>` tag tracks the latest build; released versions are
also pinned as `:<env>-<version>` (e.g. `:align-rna-2026.7.3`). Which envs are
published is the `docker-environments` list in `pyproject.toml`.

!!! warning "amd64 only"
    The runtime defines a `linux-64` platform but no `linux-aarch64` one, so
    the images are **amd64-only**. On an Apple Silicon Mac they run emulated —
    add `--platform=linux/amd64` to your `docker` commands.

---

## Docker

### Pull & run

```bash
# Pull the env you need
docker pull ghcr.io/liuhlab/liulab-runtime:align-rna

# Run a command in it (the env is baked in — no -e needed)
docker run --rm ghcr.io/liuhlab/liulab-runtime:align-rna STAR --version

# Interactive shell
docker run --rm -it ghcr.io/liuhlab/liulab-runtime:ml

# Work on your own data (mount a host folder)
docker run --rm -it -v "$PWD/data:/data" ghcr.io/liuhlab/liulab-runtime:align-dna

# Jupyter Lab — then open http://localhost:8888
docker run --rm -it -p 8888:8888 -v "$PWD:/data" ghcr.io/liuhlab/liulab-runtime:ml \
  pixi run lab --ip=0.0.0.0 --no-browser --allow-root
```

### GPU (`ml-gpu`)

The `ml-gpu` image needs the **host NVIDIA driver** injected at runtime — the
conda `pytorch-gpu` build bundles the CUDA runtime libraries itself, so no CUDA
base image is required, only a compatible driver (CUDA ≥ 12.0; the build runs
on 12.6 nodes thanks to CUDA 12 minor-version compatibility).

```bash
docker run --rm --gpus all ghcr.io/liuhlab/liulab-runtime:ml-gpu \
  python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"
```

### Build locally

```bash
git clone https://github.com/liuhlab/liulab-runtime.git
cd liulab-runtime
# Pick the env with --build-arg PIXI_ENV
docker build --build-arg PIXI_ENV=align-rna -t liulab-runtime:align-rna .
# The ml-gpu image builds on any amd64 machine — no GPU needed at build time
docker build --build-arg PIXI_ENV=ml-gpu -t liulab-runtime:ml-gpu .
```

!!! note "Building `ml-gpu` without a GPU"
    A GPU is only needed to *run* `ml-gpu`, not to build it — the build just
    downloads the CUDA packages. The Dockerfile sets `CONDA_OVERRIDE_CUDA` at
    build time so the CUDA env resolves on a GPU-less builder (CI, a laptop). On
    an **Intel** Mac this builds at native speed (it's already `linux/amd64`); on
    Apple Silicon it works but is emulated and slow. You can't test the GPU on a
    Mac — validate that on an NVIDIA node with `--nv` / `--gpus all`.

---

## Singularity / Apptainer

Most clusters use Singularity (Apptainer) instead of Docker. Pull the same
public per-env image straight from GHCR — no Docker, no root needed.

!!! tip "On the lab's IRCBC cluster?"
    This page stays general (any machine or cluster). Lab members working on
    IRCBC should follow the [IRCBC HPC](inhouse/ircbc.md) in-house tutorial
    instead — it covers the exact cluster workflow end to end: SSH setup, the
    shared image, and JupyterLab over a tunnel.

### Pull

```bash
# `pull` converts the image into a single .sif, named after the tag.
singularity pull docker://ghcr.io/liuhlab/liulab-runtime:align-rna
#  -> liulab-runtime_align-rna.sif
```

(Or build from the bundled definition file, choosing the env with a build arg:
`singularity build --build-arg ENV=align-rna liulab-runtime_align-rna.sif liulab-runtime.def`.)

### Use

```bash
# Run a command in the image's environment (via `singularity run`, which
# activates the baked env — don't prefix with `pixi run`)
singularity run liulab-runtime_align-dna.sif chromap --version
singularity run liulab-runtime_ml.sif python -c "import scanpy"

# Interactive shell
singularity shell liulab-runtime_align-rna.sif
#   inside:  pixi shell -e "$LIULAB_ENV"

# GPU image — add --nv so the host driver is visible
singularity run --nv liulab-runtime_ml-gpu.sif \
  python -c "import torch; print(torch.cuda.is_available(), torch.cuda.get_device_name(0))"

# Jupyter Lab on a compute node
singularity run liulab-runtime_ml.sif lab --ip=0.0.0.0 --no-browser
```

!!! tip "Read-only image"
    A `.sif` is read-only, and each image carries just one environment. Run
    analyses against the baked-in env and keep your *data* on bind mounts —
    don't try to `pixi install`/`pixi update` inside a running container. Need a
    different environment? Pull its image tag.
