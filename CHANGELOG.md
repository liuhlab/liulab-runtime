# Changelog

This project uses date-based (CalVer) versioning: `YYYY.M.D`.

## 2026.7.22

- Added a `update-env` pixi task (`pixi run update-env`, `scripts/update-env.sh`):
  it reports each lab package's locked-vs-latest `main`, `pixi update`s
  `seqforge`/`liulab-data`/`liulab-genome` to their newest `main`, then
  `pixi update`s the rest of the stack — the one-command version of the
  "pull the latest lab packages" sweep. It only rewrites `pixi.lock`; apply
  with `pixi install`. Note: re-resolving must run on Linux — the lab packages
  are git *source* deps and can't build a `linux-64-cuda` sdist on macOS.
- Re-resolved the whole stack against the latest lab-package `main`s:
  - `seqforge` `435abcc` → `cdd0c8e` — now published to PyPI via Trusted
    Publishing (`2026.7.1`); F1 barcode seating/refusal fixes (#42); BD Rhapsody
    Enhanced bead recognition; byte-reproducible dataset hash.
  - `liulab-data` `57e9bb6` → `146fc3d` — new `labdata.tenx` cellranger BAM →
    FASTQ pipeline (with an offline `--from-disk` mode), gzip-integrity
    verification, flattened original-format downloads.
  - `liulab-genome` `8e9f083` → `697e33d` — `get_index` / `get_star_index` to
    retrieve built aligner indexes.
- Refreshed conda/pypi packages across every env within the pinned constraints —
  notably `scvi-tools` 1.4.3 → 1.5.0.post1, `samtools` 1.23.1 → 1.24, `xarray`
  2026.4.0 → 2026.7.0.

## 2026.7.19

- Bumped the pinned `seqforge` commit to `435abcc` (`pixi update seqforge`),
  picking up the latest changes on its `main`. Affects every env carrying the
  `lab` feature (`default`, `align-rna`, `align-dna`, `ml`, `ml-gpu`). This
  ships seqforge's always-on finalize (coordinate-sorted CRAM + gzipped QC
  bundle + `temp()` cleanup).
- Added `snakemake-minimal >=8` to the `lab` feature. seqforge composes
  Snakemake pipelines run via `snakemake`, but that was only seqforge's own
  pixi dependency, not a package dependency — so a consumer env installing the
  seqforge wheel did not get it. This closes that gap.
- Bumped the pinned `liulab-data` commit to `57e9bb6` (`pixi update
  liulab-data`), picking up `experiments_for`, needed by seqforge records.
- Per-env images now activate their baked env on **every** entry, not just
  through the entrypoint/runscript, so they work as drop-in tool containers
  for workflow engines (issue #5). Previously `apptainer exec <sif> STAR` (and
  the `apptainer exec … bash -c "…"` that Snakemake's `container:` runs) landed
  in a shell where the env's `bin/` was not on `PATH`, so `STAR: command not
  found` even though STAR was in the image.
  - `liulab-runtime.def`: `%environment` now sources the env's generated
    activation script (apptainer sources it on both `run` and `exec`).
  - `Dockerfile`: sets `BASH_ENV` to that script (sourced by non-interactive
    `bash -c`, i.e. `docker exec … bash -c`) and prepends the env `bin/` to
    `PATH` as a baseline for shell-less `docker run <image> <cmd>`.
  - Sourcing the generated script (vs. a bare `PATH` prepend) also runs the
    conda `activate.d` hooks (glib/proj/GDAL/…), so activation stays faithful.
  - A Snakemake rule with `container: <align-rna sif>` now runs STARsolo with
    just `--software-deployment-method apptainer` — no `APPTAINERENV_PREPEND_PATH`
    or hand-poked `.pixi/envs/*/bin` on the caller's `PATH`.

## 2026.7.16

- Added `seqforge` (lab repo, GitHub-hosted) to the shared `lab` feature, so
  it's available in every environment except `docs` (`default`, `align-rna`,
  `align-dna`, `ml`, `ml-gpu`). Its dependencies resolve against the existing
  pins — `numpy` (lab's `>=2.1,<2.4` satisfies its `>=2`) and `anndata`.

## 2026.7.9

- Added `celltypist` (automated cell-type annotation) to the `single-cell`
  feature, so it's available in `ml` and `ml-gpu`. Pinned to `1.7.0`: the
  newer `1.7.1` requires `anndata >0.12.10`, which conflicts with lamindb's
  `anndata <=0.12.10` cap.
- `scarches` was **not** added: its only release (`0.6.1`) depends on
  `scHPL`, which hard-pins `pandas <2` — irreconcilable with the pandas 2.x
  stack (`scanpy`, `lamindb`, `liulab-genome`) that `ml`/`ml-gpu` require.
- `register-kernels` now skips the `docs` environment (it only builds the
  docs site, never backs a kernel) and discovers environments straight from
  pixi with no hard-coded fallback list to drift out of sync.

## 2026.7.3

- New `ml` and `ml-gpu` environments for PyTorch-based work: `scvi-tools`,
  `scanpy`, and `scikit-learn` layered on the lab & analysis stack.
  - `ml` installs the CPU build of PyTorch and runs everywhere; on Apple
    Silicon it uses the Mac GPU through PyTorch's Metal (MPS) backend.
  - `ml-gpu` installs the CUDA build (Linux + NVIDIA GPU only), selected via
    the `linux-64-cuda` rich platform (`__cuda >= 12`) that only the `torch-gpu`
    feature targets, plus `pytorch-gpu` + `cuda-version = "12.*"`. Only `ml-gpu`
    installs CUDA packages. Targets CUDA 12 broadly; CUDA 12 minor-version
    compatibility lets the build run on any 12.x driver (e.g. 12.6 nodes).
- Folded the single-cell toolkit (`scanpy`, `python-igraph`, `leidenalg`)
  into both `ml` and `ml-gpu`, and removed the standalone `single-cell`
  environment.
- `register-kernels` now skips environments that can't be installed on the
  current platform (e.g. `ml-gpu` on macOS) instead of aborting the run.
- Containers are now published **one image per environment**
  (`ghcr.io/liuhlab/liulab-runtime:<env>`, e.g. `:align-rna`, `:ml-gpu`)
  instead of a single all-envs image, so each host pulls only what it needs —
  CPU nodes skip `ml-gpu`'s ~12 GB CUDA stack. The published set is the
  `docker-environments` list in `pyproject.toml`; the `Dockerfile` builds one
  env via `--build-arg PIXI_ENV=<env>`. Run the GPU image with
  `--gpus all` (Docker) / `--nv` (Singularity).

## 2026.6.30

- The lab packages (`liulab-data`, `liulab-genome`) and their supporting
  stack (pandas, numpy, gffutils, `faToTwoBit`/`twoBitInfo`) now live in a
  shared `lab` feature included in every environment except `docs`. They
  were previously in `analysis` (only `default` and `single-cell`), so the
  alignment environments now carry them too.

## 2026.6.26

- Added `htslib` and `pigz` to the base layer (every environment).
- New `align-base` environment: aligner-agnostic read processing & QC
  (samtools, sambamba, fastqc, multiqc, repaq).
- Renamed `align-star` → `align-rna` and generalized it: now installs
  STAR, HISAT2, salmon, and alevin-fry, layered on top of `align-base`.
- Jupyter kernels are now registered with a single `pixi run
  register-kernels` (run once after `pixi install`); removed the
  per-environment activation hook.
- Added `osx-arm64` support where packages allow (`align-rna` remains
  Linux / Intel macOS only because STAR has no Apple Silicon build).
- Docs: filled in PyPI and contributing sections, clarified that Linux
  is the primary platform and Windows is unsupported (use WSL2).

## 2026.6.25

Initial release.

- pixi-managed environments defined in `pyproject.toml`.
- `default` environment: `liulab-data`, `liulab-genome`, Jupyter Lab,
  seaborn, pandas, numpy, samtools, bedtools.
- `align-star` environment: STAR aligner + samtools.
- `docs` environment for building the documentation.
- Every environment auto-registers as a Jupyter kernel on first
  activation.
- MkDocs documentation site (getting started + background).
