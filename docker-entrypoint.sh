#!/usr/bin/env bash
# Entrypoint for the liulab-runtime container.
#
# Behaviour:
#   * No args              -> interactive shell in the `default` env.
#   * `pixi ...`           -> run pixi verbatim (e.g. `pixi run -e align-rna STAR`).
#   * `bash` / `sh`        -> a plain shell (no env activated).
#   * anything else        -> run it inside the `default` env via `pixi run`.
#
# Pick the active environment for the no-arg case with: -e LIULAB_ENV=<env>
set -euo pipefail

ENV_NAME="${LIULAB_ENV:-default}"

if [ "$#" -eq 0 ]; then
    exec pixi shell -e "$ENV_NAME"
fi

case "$1" in
    pixi|bash|sh)
        exec "$@"
        ;;
    *)
        exec pixi run -e "$ENV_NAME" "$@"
        ;;
esac
