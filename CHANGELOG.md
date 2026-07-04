# Changelog

This project uses date-based (CalVer) versioning: `YYYY.M.D`.

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
