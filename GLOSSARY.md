# liulab-runtime

The pixi workspace that defines the lab's analysis environments, and the container images
built from them.

## Language

**Base layer**:
The packages under `[tool.pixi.dependencies]`, which every environment and every image
includes.
_Avoid_: core, common dependencies

**Feature**:
A named bundle of packages under `[tool.pixi.feature.<name>]`. Nothing installs a feature
alone; an environment combines features.
_Avoid_: module, extra

**Environment**:
One installable set of packages: the base layer plus the features listed for it under
`[tool.pixi.environments]`. Each can back a Jupyter kernel, and some ship as an image.
_Avoid_: env stack, profile

**Solve group**:
Environments pixi resolves together, so a package they share has one version in all of them.
`ml` and `ml-gpu` stay out of one, so their CPU and CUDA PyTorch builds resolve apart.

**Rich platform**:
A platform entry that adds virtual packages to a plain one. `linux-64-cuda` is `linux-64`
with CUDA 12 advertised, and only `ml-gpu` targets it.
_Avoid_: CUDA platform

**Baked environment**:
The one environment an image holds, chosen at build time with `PIXI_ENV` and active on every
way into the container.
_Avoid_: default environment, which names a different thing

**Moving tag**:
An image tag, `<env>`, that every build of that environment replaces.
_Avoid_: latest

**Pinned tag**:
An image tag, `<env>-<version>`, made once by a release tag and never moved.

**Dangling tag**:
An image tag whose index names a child manifest the registry no longer holds, so the image
cannot be pulled.

**The stack**:
This repo and the three lab packages it pins by git URL, `seqforge`, `liulab-data` and
`liulab-genome`, checked out side by side under one parent folder.
_Avoid_: monorepo, superproject
