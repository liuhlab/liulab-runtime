# Changelog

This project uses date-based (CalVer) versioning: `YYYY.M.D`.

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
