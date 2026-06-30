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
