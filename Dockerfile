# syntax=docker/dockerfile:1
# ======================================================================
#  liulab-runtime container — ONE image per environment
#
#  Each image ships a single pixi environment, selected at build time with
#  `--build-arg PIXI_ENV=<env>`. Published to GHCR as one tag per env
#  (`ghcr.io/liuhlab/liulab-runtime:<env>`); the set of envs to publish is
#  the `docker-environments` list in pyproject.toml, driven by the Docker
#  workflow. Build one locally with:
#      docker build --build-arg PIXI_ENV=align-rna -t liulab-runtime:align-rna .
#
#  The base layers (pixi image + git + the manifest COPY) are identical for
#  every env, so GHCR stores them once and per-env pulls share them; only the
#  `pixi install -e <env>` layer differs.
#
#  IMPORTANT: the workspace only defines a linux-64 platform (no
#  linux-aarch64), so these images are amd64-only. On Apple Silicon build
#  and run them with `--platform=linux/amd64` (emulated).
#
#  Single-stage on purpose. pixi hardlinks each package from its cache into
#  the environment; a BuildKit `--mount=type=cache` or a multi-stage
#  `COPY --from=build` would put the cache on another filesystem / force a
#  materialise and break those links. Instead we keep the cache next to the
#  env and delete it in the SAME RUN as the install, so the cache bytes never
#  land in a committed layer while the env stays intact.
# ======================================================================

# amd64-only (no linux-aarch64 platform). Declared as an ARG so it isn't
# a hardcoded FROM --platform constant (which BuildKit flags as a lint
# warning); override at build time only if you know what you're doing.
ARG BUILD_PLATFORM=linux/amd64
FROM --platform=${BUILD_PLATFORM} ghcr.io/prefix-dev/pixi:latest

# Which environment this image contains. Overridden per build by the Docker
# workflow (one build per entry in pyproject's `docker-environments`).
ARG PIXI_ENV=default

# git is needed to resolve the lab's GitHub-hosted pypi dependencies
# (liulab-data, liulab-genome) during install, and is kept for users who
# want to `pixi update`/`pixi add` inside the container.
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Manifest first so the heavy install layer caches across source-only
# changes.
COPY pyproject.toml pixi.lock ./

# One RUN does everything that must share a layer with the install:
#   1. build just this env exactly as pinned (--locked, no cache mount so
#      pixi can hardlink from the cache);
#   2. generate the env's activation script;
#   3. smoke-test the env (--frozen: run as-is, never re-solve). GPU builds
#      only `import torch` — the builder has no GPU, so we never call
#      torch.cuda.is_available() here;
#   4. strip runtime-useless files (static archives, bytecode, JS source
#      maps, man/doc/info pages, prefix C headers);
#   5. delete pixi's package cache + apt/pip leftovers.
# Steps 4-5 only reclaim space because they happen in THIS layer.
# CONDA_OVERRIDE_CUDA lets a GPU-less builder (CI runner, a laptop) resolve and
# install the CUDA `ml-gpu` env: with no NVIDIA driver present the `__cuda`
# virtual package is absent, so pixi would consider `ml-gpu` unavailable and
# refuse it. This is build-time only (never an `ENV`), so at runtime the
# container still detects the real host driver via `--gpus`/`--nv`. Harmless for
# CPU envs — nothing there requests `__cuda`.
RUN set -eux; \
    export CONDA_OVERRIDE_CUDA=12; \
    pixi install --locked -e "$PIXI_ENV"; \
    pixi shell-hook -e "$PIXI_ENV" -s bash > "/app/.pixi/activate-$PIXI_ENV.sh" || true; \
    echo "== env size after install:"; du -sh "/app/.pixi/envs/$PIXI_ENV"; \
    case "$PIXI_ENV" in \
        align-rna) pixi run --frozen -e "$PIXI_ENV" STAR --version ;; \
        align-dna) pixi run --frozen -e "$PIXI_ENV" chromap --version ;; \
        ml|ml-gpu) pixi run --frozen -e "$PIXI_ENV" python -c "import torch, scvi, scanpy, anndata" ;; \
        default)   pixi run --frozen -e "$PIXI_ENV" python -c "import pandas, numpy, seaborn, jupyterlab" ;; \
        docs)      pixi run --frozen -e "$PIXI_ENV" mkdocs --version ;; \
        *)         pixi run --frozen -e "$PIXI_ENV" python -c "import sys; print(sys.version)" ;; \
    esac; \
    find /app/.pixi/envs -depth -type d -name '__pycache__' -exec rm -rf {} + ; \
    find /app/.pixi/envs -type f \( -name '*.pyc' -o -name '*.a' -o -name '*.js.map' \) -delete ; \
    find /app/.pixi/envs -depth -type d \( -name man -o -name doc -o -name info \) \
        -path '*/share/*' -exec rm -rf {} + ; \
    for env in /app/.pixi/envs/*/; do rm -rf "${env}include"; done ; \
    rm -rf /root/.cache /app/.pixi/.cache 2>/dev/null || true; \
    echo "== env size after strip:"; du -sh "/app/.pixi/envs/$PIXI_ENV"; \
    echo "== total /app/.pixi:"; du -sh /app/.pixi

# Bring in the rest of the repo (scripts, docs, entrypoint sources).
COPY . .

# Bake the built env in so the entrypoint defaults to it (no need to set
# LIULAB_ENV at runtime). Persist it as a real ENV so `docker run` inherits it.
ENV LIULAB_ENV=${PIXI_ENV}

# Activate the baked env for EVERY entry, not just the entrypoint/runscript.
# Workflow engines and `docker exec … bash -c "…"` (what Snakemake's
# `container:` runs) invoke a non-interactive bash, which sources $BASH_ENV at
# startup — point it at the env's generated activation script so the env's
# tools (e.g. STAR) are on PATH with no per-caller setup. This also runs the
# conda activate.d hooks, so it's faithful where a bare PATH is not.
ENV BASH_ENV=/app/.pixi/activate-${PIXI_ENV}.sh
# Baseline for a direct `docker run <image> <cmd>` that never goes through a
# shell (so $BASH_ENV isn't consulted). Less complete than sourcing the script
# above — it skips activate.d — but enough to find the env's binaries.
ENV PATH="/app/.pixi/envs/${PIXI_ENV}/bin:${PATH}"

# Jupyter Lab (available in every env) listens here when launched.
EXPOSE 8888

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default: drop into this image's environment shell. Run a one-off command
# instead by appending it, e.g. `docker run ...:align-rna STAR --version`.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["pixi", "shell"]
