#!/usr/bin/env bash
# update-env -- pull the latest lab packages, then refresh every pinned package.
#
# liulab-runtime pins the lab's own packages (seqforge, liulab-data, liulab-genome) by git URL with
# no rev, so each tracks its repo's `main`. A push to any of those mains does NOT reach this
# environment until the lock is re-resolved. This task does that in one sweep:
#
#   1. report the locked commit vs. the latest `main` for each lab package
#   2. `pixi update` the three lab packages -- re-resolves their git refs to the newest `main`
#   3. `pixi update` everything else -- bumps conda/pypi packages within the pyproject constraints
#
# Run it via the pixi task (from the repo root):
#   pixi run update-env
#
# It only rewrites pixi.lock. To apply and record the bump afterwards:
#   pixi install                 # materialize the new lock into your environments
#   git diff pixi.lock           # review what moved
#   # then add a CHANGELOG.md entry + bump [project].version in pyproject.toml (see CLAUDE.md)

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" # .../liulab-runtime/scripts
ROOT="$(cd "$HERE/.." && pwd)"                        # the repo root
LOCK="$ROOT/pixi.lock"
LAB_PKGS=(seqforge liulab-data liulab-genome)

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
dim() { printf '\033[2m%s\033[0m\n' "$*"; }

# Body lives in main() so no user function is called at top level; that (plus the git-lookup command
# substitutions below) keeps clear of a shellcheck SC2218 false positive -- the reason the lab-commit
# lookups are inlined here rather than pulled into named helpers.
main() {
  bold "== Checking lab package updates"
  for pkg in "${LAB_PKGS[@]}"; do
    # locked: the 40-hex commit pinned for this package in pixi.lock (empty if not present).
    locked="$(grep -oE "github\.com/liuhlab/$pkg\.git#[0-9a-f]{40}" "$LOCK" 2>/dev/null | head -n1 | cut -d'#' -f2)"
    # remote: the current tip of the package repo's default branch (empty if GitHub is unreachable).
    remote="$(git ls-remote "https://github.com/liuhlab/$pkg.git" HEAD 2>/dev/null | cut -f1)"
    if [ -z "$remote" ]; then
      dim "   $pkg: could not reach GitHub, skipping check"
    elif [ "$locked" = "$remote" ]; then
      dim "   $pkg: up to date (${locked:0:7})"
    else
      printf '   \033[1m%s\033[0m: %s -> %s\n' "$pkg" "${locked:0:7}" "${remote:0:7}"
    fi
  done
  echo

  bold "== Updating lab packages: pixi update ${LAB_PKGS[*]}"
  pixi update "${LAB_PKGS[@]}" || return 1
  echo

  bold "== Updating the rest: pixi update"
  pixi update || return 1
  echo

  bold "== Done -- pixi.lock refreshed"
  echo "Next: \`pixi install\` to apply it, then record the bump (CHANGELOG.md + pyproject version)."
}

main "$@"
