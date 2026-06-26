# liulab-runtime

The Liu Lab's **one-stop environment manager** for data analysis.

Instead of every project juggling its own conda environments, this
repository uses [pixi](https://pixi.sh) to provide a small set of
ready-made, reproducible environments — bundling the lab's own packages
([liulab-data](https://github.com/liuhlab/liulab-data),
[liulab-genome](https://github.com/liuhlab/liulab-genome)) together with
common tools like Jupyter Lab, seaborn, samtools, and bedtools.

Every environment also registers itself as a **Jupyter kernel**, so you
can switch between them inside a notebook.

## Quick start

```bash
# 1. Install pixi (once per machine)
curl -fsSL https://pixi.sh/install.sh | bash

# 2. Get this repo and install the environments
git clone https://github.com/liuhlab/liulab-runtime.git
cd liulab-runtime
pixi install

# 3. Drop into the default analysis environment
pixi shell

# 4. ...or launch Jupyter Lab
pixi run lab
```

The first time you enter an environment it registers itself as a Jupyter
kernel automatically.

## Available environments

| Environment  | What it's for                                   |
| ------------ | ----------------------------------------------- |
| `default`    | Everyday analysis: lab packages, Jupyter, plotting, samtools, bedtools |
| `align-star` | RNA-seq alignment with the STAR aligner          |
| `docs`       | Building this documentation site                 |

Enter a specific one with `pixi shell -e align-star`.

## Documentation

Full setup guide and background reading live in [`docs/`](docs/index.md),
or run `pixi run docs` to browse them locally.
