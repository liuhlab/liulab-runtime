#!/usr/bin/env bash
# Register every environment as a Jupyter kernel in one go.
#
# Run this once after `pixi install` to make every environment available
# as a kernel in Jupyter (the docs tell users to do exactly that).
#
# The `docs` environment is skipped: it only builds the docs site and is
# never used as an analysis kernel.
#
# Usage:  pixi run register-kernels
set -euo pipefail

# Discover environments straight from pixi so this always matches
# pyproject.toml — no hard-coded env list to drift out of sync.
envs=$(pixi workspace environment list \
        | sed -n 's/^[[:space:]]*-[[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p')
if [ -z "$envs" ]; then
    echo "error: could not discover any environments from pixi" >&2
    echo "       run 'pixi install' first, then retry." >&2
    exit 1
fi

for env in $envs; do
    # The docs env only builds the site; it never backs an analysis kernel.
    if [ "$env" = "docs" ]; then
        continue
    fi
    echo "Registering kernel for: $env"
    # Some envs don't exist on every platform (e.g. the CUDA `ml-gpu` env is
    # linux-64 only, so it can't be solved on macOS). Skip an env that isn't
    # available here instead of aborting the whole run.
    if ! pixi run -e "$env" register-kernel; then
        echo "  skipped: '$env' is not available on this platform"
    fi
done

echo "Done. Open Jupyter Lab and pick a 'Python (liulab ...)' kernel."
