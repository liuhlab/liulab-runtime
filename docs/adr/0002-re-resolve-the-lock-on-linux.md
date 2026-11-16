---
search:
  exclude: true
---

# Re-resolve the lock on Linux

The lab packages are git source dependencies. Re-solving one for the `linux-64-cuda`
platform, which only `ml-gpu` targets, builds a Linux sdist, and that fails on `osx-arm64`
with "no compatible Python interpreter". So `pixi run update-env`, and any `pixi update` that
moves a lab package, runs on Linux: a Linux machine, or a `linux/amd64` container from the
pixi image with `git` installed, as the `Dockerfile` does.

A Mac can install from a lock written elsewhere. `pixi lock` there succeeds only while
nothing makes it re-solve a lab package; when it fails, finish the job on Linux rather than
dropping a platform.
