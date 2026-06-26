#!/usr/bin/env bash
# Register every environment as a Jupyter kernel in one go.
#
# Run this once after `pixi install` to make every environment available
# as a kernel in Jupyter (the docs tell users to do exactly that).
#
# Usage:  pixi run register-kernels
set -euo pipefail

# Discover environments straight from pixi so this stays in sync with
# pyproject.toml. Falls back to the known list if parsing is unavailable.
if envs=$(pixi workspace environment list 2>/dev/null \
        | sed -n 's/^[[:space:]]*-[[:space:]]*\([A-Za-z0-9_-]*\).*/\1/p'); then
    [ -z "$envs" ] && envs="default align-rna align-dna"
else
    envs="default align-rna align-dna"
fi

for env in $envs; do
    echo "Registering kernel for: $env"
    pixi run -e "$env" register-kernel
done

echo "Done. Open Jupyter Lab and pick a 'Python (liulab ...)' kernel."
