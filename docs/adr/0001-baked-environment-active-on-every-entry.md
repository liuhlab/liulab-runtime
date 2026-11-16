---
search:
  exclude: true
---

# The baked environment is active on every entry

An image must find its environment's tools however it is entered, not only through the
entrypoint or the runscript. Workflow engines (a Snakemake or Nextflow `container:`) and
`docker exec` or `apptainer exec … bash -c "…"` bypass both, so activation lives in two
places, and the two must stay in sync:

- `Dockerfile`: `BASH_ENV` points at the generated `activate-<env>.sh`, which a
  non-interactive `bash -c` sources, plus a `PATH` prepend of the environment's `bin/` for a
  command run with no shell at all.
- `liulab-runtime.def`: `%environment` sources the same script, which Apptainer runs on both
  `run` and `exec`.

Source the generated script rather than editing `PATH` alone: it also runs the conda
`activate.d` hooks (glib, proj, GDAL). Remove neither hook. `apptainer exec <sif> <tool>` must
work with no setup by the caller.
