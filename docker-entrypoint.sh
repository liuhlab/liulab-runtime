#!/usr/bin/env bash
# Entrypoint for the liulab-runtime container.
#
# Each image ships a SINGLE environment, baked in via LIULAB_ENV (set in the
# Dockerfile). Only that env is installed, so anything that would fall back to
# pixi's `default` env is redirected to $LIULAB_ENV.
#
# Behaviour:
#   * No args                    -> interactive shell in $LIULAB_ENV.
#   * `bash` / `sh`              -> a plain shell (no env activated).
#   * `pixi run|shell …`         -> runs in $LIULAB_ENV unless you passed -e/--environment.
#   * `pixi <other> …`           -> pixi verbatim (list, info, update, …).
#   * anything else              -> run it inside $LIULAB_ENV via `pixi run`.
#
# Override the env at runtime (rarely needed) with: -e LIULAB_ENV=<env>
set -euo pipefail

ENV_NAME="${LIULAB_ENV:-default}"

if [ "$#" -eq 0 ]; then
    exec pixi shell -e "$ENV_NAME"
fi

case "$1" in
    bash|sh)
        exec "$@"
        ;;
    pixi)
        shift
        # `run`/`shell` take an environment — default it to the baked env
        # unless the caller already chose one. Other subcommands pass through.
        if [ "${1:-}" = run ] || [ "${1:-}" = shell ]; then
            sub="$1"; shift
            for arg in "$@"; do
                case "$arg" in
                    -e|--environment|--environment=*)
                        exec pixi "$sub" "$@" ;;   # caller chose an env
                esac
            done
            exec pixi "$sub" -e "$ENV_NAME" "$@"   # inject the baked env
        fi
        exec pixi "$@"
        ;;
    *)
        exec pixi run -e "$ENV_NAME" "$@"
        ;;
esac
