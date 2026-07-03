# Containers (Docker & Singularity)

Prefer not to install pixi at all? The whole runtime — **every**
environment — ships as a single container image. This is handy on shared
servers and HPC clusters, or anywhere you want a guaranteed-identical
setup. It's especially useful on **older Linux systems** (e.g. CentOS 7),
where a direct `pixi install` can be hard or impossible because the host
is too old: the container carries its own modern userspace, so it only
needs a compatible kernel — not an up-to-date OS.

!!! warning "amd64 only"
    The runtime defines a `linux-64` platform but no `linux-aarch64`
    one, so the image is **amd64-only**. On an Apple Silicon Mac it runs
    emulated — add `--platform=linux/amd64` to your `docker` commands.

---

## Docker

### Build

```bash
git clone https://github.com/liuhlab/liulab-runtime.git
cd liulab-runtime
docker build -t liulab-runtime:latest .
```

The first build solves and downloads every environment, so it takes a
while; later builds reuse the cache.

### Use

```bash
# Interactive shell in the default analysis environment
docker run --rm -it liulab-runtime

# Pick a different environment for the shell
docker run --rm -it -e LIULAB_ENV=align-rna liulab-runtime

# Run a single command in a specific environment
docker run --rm liulab-runtime pixi run -e align-rna STAR --version

# List all environments
docker run --rm liulab-runtime pixi run envs

# Work on your own data (mount a host folder)
docker run --rm -it -v "$PWD/data:/data" liulab-runtime

# Jupyter Lab — then open http://localhost:8888
docker run --rm -it -p 8888:8888 -v "$PWD:/data" liulab-runtime \
  pixi run lab --ip=0.0.0.0 --no-browser --allow-root
```

Inside the container, switch environments the usual way:
`pixi shell -e ml` or `pixi run -e align-dna <command>`.

---

## Singularity / Apptainer

Most clusters use Singularity (Apptainer) instead of Docker. Pull the
same public image straight from GHCR — no Docker, no root needed.

### Build

```bash
# `pull` converts the image into a single .sif file, named after the tag.
singularity pull docker://ghcr.io/liuhlab/liulab-runtime:latest
#  -> liulab-runtime_latest.sif
```

(Or build from the bundled definition file instead:
`singularity build liulab-runtime_latest.sif liulab-runtime.def`.)

### Use

```bash
# Run a command in an environment (set LIULAB_ENV to choose; default: default)
LIULAB_ENV=align-dna singularity run liulab-runtime_latest.sif chromap --version

# Or call pixi directly
singularity exec liulab-runtime_latest.sif pixi run -e ml python -c "import scanpy"

# Interactive shell, then activate an environment
singularity shell liulab-runtime_latest.sif
#   inside:  pixi shell -e align-rna

# Jupyter Lab on a compute node
singularity exec liulab-runtime_latest.sif pixi run lab --ip=0.0.0.0 --no-browser
```

!!! tip "Read-only image"
    A `.sif` is read-only. Run analyses against the environments baked
    into the image and keep your *data* on bind mounts — don't try to
    `pixi install`/`pixi update` inside a running container.
