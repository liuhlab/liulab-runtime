#!/usr/bin/env sh
# Registers the active pixi environment as a Jupyter kernel.
#
# pixi sources this on every environment activation (`pixi shell` /
# `pixi run`). It does real work only the first time you enter a given
# environment: after that a marker file makes it a fast no-op.
#
# Result: the first time you activate, say, the `align_star` env, a
# kernel named "Python (liulab align_star)" appears in Jupyter Lab.

env_name="${PIXI_ENVIRONMENT_NAME:-default}"
root="${PIXI_PROJECT_ROOT:-.}"
marker="${root}/.pixi/.kernel-registered-${env_name}"

if [ ! -f "$marker" ]; then
    if python -m ipykernel install --user \
        --name "liulab-${env_name}" \
        --display-name "Python (liulab ${env_name})" >/dev/null 2>&1; then
        mkdir -p "${root}/.pixi" && touch "$marker"
    fi
fi
