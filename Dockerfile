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
# ======================================================================

# ---- Stage 1: build every environment from the lock file -------------
FROM --platform=linux/amd64 ghcr.io/prefix-dev/pixi:latest AS build

# git is needed to resolve the lab's GitHub-hosted pypi dependencies
# (liulab-data, liulab-genome) during `pixi install`.
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only what the solve needs first, so this layer caches across
# source-only changes.
COPY pyproject.toml pixi.lock ./

# Build EVERY environment exactly as pinned in pixi.lock.
# --locked fails loudly if pyproject.toml and pixi.lock disagree.
RUN --mount=type=cache,target=/root/.cache/rattler \
    pixi install --locked --all

# Bring in the rest of the repo (scripts, docs, etc.).
COPY . .

# Generate per-env activation scripts so the runtime stage can source
# them without re-solving. (Optional convenience; see entrypoint.)
RUN for env in default align-rna align-dna single-cell; do \
        pixi shell-hook -e "$env" -s bash > "/app/.pixi/activate-$env.sh" || true; \
    done

# Smoke-test every environment BEFORE stripping, so a green build proves
# the envs actually work. --frozen runs them as-is (never re-solving or
# re-downloading, which would undo the cleanup below).
RUN set -eux; \
    pixi run --frozen -e default     python -c "import pandas, numpy, gffutils, seaborn, jupyterlab"; \
    pixi run --frozen -e single-cell python -c "import scanpy, anndata, leidenalg"; \
    pixi run --frozen -e align-dna   chromap --version; \
    pixi run --frozen -e align-rna   STAR --version

# Shrink the image: drop files that no tool needs at RUNTIME. Static
# archives (*.a) are link-time only; *.pyc/__pycache__ regenerate on
# demand; JS source maps are browser-debug only; man/doc/info pages and
# prefix-level C headers are dev artifacts. Also clear pixi's solve/
# download caches (not needed once envs are built). Done LAST so nothing
# downstream re-creates the deleted files.
RUN set -eux; \
    find /app/.pixi/envs -depth -type d -name '__pycache__' -exec rm -rf {} + ; \
    find /app/.pixi/envs -type f \( -name '*.pyc' -o -name '*.a' -o -name '*.js.map' \) -delete ; \
    find /app/.pixi/envs -depth -type d \( -name man -o -name doc -o -name info \) \
        -path '*/share/*' -exec rm -rf {} + ; \
    for env in /app/.pixi/envs/*/; do rm -rf "${env}include"; done ; \
    rm -rf /root/.cache/* /app/.pixi/.cache 2>/dev/null || true

# ---- Stage 2: lean runtime image -------------------------------------
FROM --platform=linux/amd64 ghcr.io/prefix-dev/pixi:latest AS runtime

# git kept at runtime too in case users `pixi update`/`pixi add` live.
RUN apt-get update && apt-get install -y --no-install-recommends git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the fully-solved workspace (the heavy .pixi/ envs + sources).
COPY --from=build /app /app

# Jupyter Lab (in the default env) listens here when launched.
EXPOSE 8888

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Default: drop into the default analysis environment's shell.
# Override the env with `pixi run -e <env> <cmd>` as the container command.
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["pixi", "shell"]
