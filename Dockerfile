# syntax=docker/dockerfile:1
# ======================================================================
#  liulab-runtime container
#
#  Ships every pixi environment (default, align-rna, align-dna,
#  single-cell) inside one image. Users pick an environment at runtime
#  with `pixi shell -e <env>` or `pixi run -e <env> <cmd>`.
#
#  IMPORTANT: the workspace only defines a linux-64 platform (no
#  linux-aarch64), so this image is amd64-only. On Apple Silicon build
#  and run it with `--platform=linux/amd64` (emulated).
#
#  Single-stage on purpose. pixi HARDLINKS each package from its cache
#  into every environment, so the four envs share one physical copy of
#  python/numpy/samtools/etc. Two things would silently break that
#  dedup, so we avoid both:
#    * a BuildKit `--mount=type=cache` for the cache puts it on a
#      separate filesystem -> hardlinks can't span filesystems -> pixi
#      falls back to full copies (4x the shared packages).
#    * a multi-stage `COPY --from=build` that leaves the cache behind
#      forces the copied tree to be materialised, breaking the links.
#  Instead we keep the cache next to the envs and delete it in the SAME
#  RUN as the install: the cache's bytes never land in a committed layer,
#  while the env-to-env hardlinks survive (so the dedup is preserved).
# ======================================================================

# amd64-only (no linux-aarch64 platform). Declared as an ARG so it isn't
# a hardcoded FROM --platform constant (which BuildKit flags as a lint
# warning); override at build time only if you know what you're doing.
ARG BUILD_PLATFORM=linux/amd64
FROM --platform=${BUILD_PLATFORM} ghcr.io/prefix-dev/pixi:latest

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
#   1. build every env exactly as pinned (--locked, no cache mount so
#      pixi can hardlink across envs);
#   2. generate per-env activation scripts;
#   3. smoke-test all four envs (--frozen: run as-is, never re-solve);
#   4. strip runtime-useless files (static archives, bytecode, JS source
#      maps, man/doc/info pages, prefix C headers);
#   5. delete pixi's package cache + apt/pip leftovers.
# Steps 4-5 only reclaim space because they happen in THIS layer.
RUN set -eux; \
    pixi install --locked --all; \
    for env in default align-rna align-dna single-cell; do \
        pixi shell-hook -e "$env" -s bash > "/app/.pixi/activate-$env.sh" || true; \
    done; \
    echo "== envs size after install (deduped on disk):"; du -sh /app/.pixi/envs; \
    pixi run --frozen -e default     python -c "import pandas, numpy, gffutils, seaborn, jupyterlab"; \
    pixi run --frozen -e single-cell python -c "import scanpy, anndata, leidenalg"; \
    pixi run --frozen -e align-dna   chromap --version; \
    pixi run --frozen -e align-rna   STAR --version; \
    find /app/.pixi/envs -depth -type d -name '__pycache__' -exec rm -rf {} + ; \
    find /app/.pixi/envs -type f \( -name '*.pyc' -o -name '*.a' -o -name '*.js.map' \) -delete ; \
    find /app/.pixi/envs -depth -type d \( -name man -o -name doc -o -name info \) \
        -path '*/share/*' -exec rm -rf {} + ; \
    for env in /app/.pixi/envs/*/; do rm -rf "${env}include"; done ; \
    rm -rf /root/.cache /app/.pixi/.cache 2>/dev/null || true; \
    echo "== envs size after strip:"; du -sh /app/.pixi/envs; \
    echo "== total /app/.pixi:"; du -sh /app/.pixi

# Bring in the rest of the repo (scripts, docs, entrypoint sources).
COPY . .

# Jupyter Lab (in the default env) listens here when launched.
EXPOSE 8888

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default: drop into the default analysis environment's shell.
# Override the env with `pixi run -e <env> <cmd>` as the container command.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["pixi", "shell"]
