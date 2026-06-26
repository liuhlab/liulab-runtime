# Changelog

This project uses date-based (CalVer) versioning: `YYYY.M.D`.

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
