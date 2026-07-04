#!/usr/bin/env bash
# Entrypoint for the liulab-runtime container.
#
# Each image bakes in its environment via LIULAB_ENV (set in the Dockerfile);
# these images ship a single env, so LIULAB_ENV is that env.
#
# Behaviour:
#   * No args              -> interactive shell in $LIULAB_ENV.
#   * `pixi ...`           -> run pixi verbatim (e.g. `pixi run STAR --version`).
#   * `bash` / `sh`        -> a plain shell (no env activated).
#   * anything else        -> run it inside $LIULAB_ENV via `pixi run`.
#
# Override the env at runtime (rarely needed) with: -e LIULAB_ENV=<env>
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
