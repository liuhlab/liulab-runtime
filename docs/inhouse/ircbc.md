# Running JupyterLab on IRCBC HPC

!!! info "Inhouse tutorial — lab members only"
    This guide is for Liu Lab members with an **IRCBC** cluster account. It
    refers to lab-internal infrastructure; the addresses, accounts, and keys
    you need come from the lab admin.

New to the lab's **IRCBC** cluster? This page takes you from a fresh ssh
account to **JupyterLab running the `ml` environment**, open in your laptop's
browser. Just follow the steps top to bottom.

The `ml` environment (PyTorch, scanpy, scvi-tools, and the rest of the
single-cell stack) runs inside a ready-made **Singularity container** — you
don't install anything on the cluster yourself.

!!! info "How this guide is organized"
    **Steps 1–4 are a one-time setup — you do them once.** After that, your
    daily routine is just **step 5**: submit a job, open the tunnel, and work
    in JupyterLab. Step 6 is etiquette for sharing the cluster.

!!! warning "Do you need the VPN?"
    IRCBC sits on the lab network (LAN).

    - **On-site** (your computer is on the lab network): you can `ssh` straight
      to IRCBC — **no VPN needed**.
    - **Off-site** (home, travelling, any other network): first connect the lab
      VPN (**`<VPN>`**, the atrust app), *then* `ssh`.

    If `ssh` hangs from off-site, the VPN is almost always the reason —
    reconnect it and try again.

!!! note "Which computer am I typing on?"
    Beginners often mix up their laptop and the cluster. Every code block below
    is introduced with **where to run it**:

    - **On your laptop** — your own computer's terminal.
    - **On IRCBC** — a shell on the cluster, which you get by running `ssh ircbc`.

    A command written as `ssh ircbc '…'` is run **from your laptop**, but the part
    in quotes executes **on the cluster** — a shortcut for one-off commands
    without logging in first.

Throughout this page, anything in `<ANGLE_BRACKETS>` is a value you fill in
(ask the lab admin, or use your own). **Real addresses and keys go only in
your `~/.ssh/config` — never in a shared document.**

---

## 1. What to ask the lab admin

Before you start, request these from whoever manages the cluster:

| You need | Used below as |
| --- | --- |
| IRCBC login address + your **login** account and key | `<LOGIN_IP>`, `<LOGIN_USER>`, `<LOGIN_PASSWORD>` |
| **ircbc-transfer** account (a *separate, shared* lab account) + its key | `<TRANSFER_IP>`, `<TRANSFER_USER>`, `<TRANSFER_PASSWORD>` |
| VPN account — only for **off-site** access | `<VPN>` |

---

## 2. Set up SSH on your laptop

Everything in this section happens **on your laptop**.

### 1. Make an SSH key

On your laptop, create a key pair:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/<LOGIN_KEY>
```

Send the **public** half (the `.pub` file) to the admin so they can add it to
your account:

```bash
cat ~/.ssh/<LOGIN_KEY>.pub
```

The transfer host uses its **own** account and key — repeat this for
`<TRANSFER_KEY>` if the admin gives you a separate one.

### 2. Add the hosts to `~/.ssh/config`

On your laptop, open the file `~/.ssh/config` (create it if it doesn't exist)
and paste these three blocks, filling in your placeholders:

```
# 1. Login node — light work only (editing, git, submitting jobs)
Host ircbc
    HostName <LOGIN_IP>
    User <LOGIN_USER>
    IdentityFile ~/.ssh/<LOGIN_KEY>

# 2. Transfer node — moving files in and out (separate shared account + key)
Host ircbc-transfer
    HostName <TRANSFER_IP>
    User <TRANSFER_USER>
    IdentityFile ~/.ssh/<TRANSFER_KEY>

# 3. Compute nodes — reached *through* the login node (the "jump")
Host cpu01 cpu02 cpu03 cpu04 cpu05 cpu06 cpu07 cpu08
    HostName %h
    User <LOGIN_USER>
    ProxyJump ircbc
    IdentityFile ~/.ssh/<LOGIN_KEY>
    ServerAliveInterval 15
    TCPKeepAlive yes
```

That third block is the **jump**: `ProxyJump ircbc` lets your laptop reach a
compute node (`cpu01`…`cpu08`) by hopping through the login node
automatically. It only works while you have a job running on that node
(more on that in step 5).

### 3. Test it

On your laptop, connect to the login node:

```bash
ssh ircbc hostname
```

You should see the login node's name printed back. (Run `ssh ircbc` with no
command to get an interactive shell **on IRCBC**; type `exit` to return to your
laptop.)

!!! tip "Command hangs?"
    From off-site, that's almost always the VPN — reconnect `<VPN>` and try
    once more. Don't keep retrying a stuck connection.

---

## 3. Give the login node internet (SOCKS proxy)

The IRCBC **login node has no direct scientific internet (access website like github is slow)** — it borrows the transfer
node's connection through an SSH SOCKS proxy to speed up. You set this up once, in two
files **on IRCBC** (log in with `ssh ircbc` first). It may already be
configured for you — check with the admin — but here's the full setup so you
understand it.

### a. Let the login node reach the transfer node

You added `ircbc-transfer` to your *laptop's* config in step 2 (for file
transfer). The **login node needs its own copy** so it can open the proxy. On
IRCBC, edit `~/.ssh/config` and add:

```
Host ircbc-transfer
    HostName <TRANSFER_IP>
    User <TRANSFER_USER>
    IdentityFile ~/.ssh/<TRANSFER_KEY>

    # reuse one shared connection so the proxy stays efficient
    ControlMaster auto
    ControlPath ~/.ssh/cm-%r@%h:%p
    ControlPersist 8h

    # skip the first-time host-key prompt so the automatic tunnel can't stall
    StrictHostKeyChecking no
```

The shared transfer key must also live on the login node at
`~/.ssh/<TRANSFER_KEY>` (the admin gives you this). Test it while logged in on
IRCBC:

```bash
ssh ircbc-transfer hostname
```

### b. Open the proxy and export the settings

Still on IRCBC, add this to `~/.bashrc`:

```bash
# Start SOCKS proxy through transfer node
if ! nc -z 127.0.0.1 1080 2>/dev/null; then
    ssh -f -N -D 127.0.0.1:1080 ircbc-transfer
fi
export ALL_PROXY="socks5h://127.0.0.1:1080"
export HTTP_PROXY="socks5h://127.0.0.1:1080"
export HTTPS_PROXY="socks5h://127.0.0.1:1080"
export all_proxy="socks5h://127.0.0.1:1080"
export http_proxy="socks5h://127.0.0.1:1080"
export https_proxy="socks5h://127.0.0.1:1080"

export LIU_LAB_PACKAGES=/share/lhqlab/liulab_data/packages   # shared image store
```

Log out and back in (or run `source ~/.bashrc`) to apply. The `nc` check opens
the tunnel only if it isn't already running, so it's safe on every login: it
`ssh -D`'s into `ircbc-transfer` (using the config block above) to expose a
SOCKS proxy at `127.0.0.1:1080`, then points the proxy variables at it.

!!! note "Login node only"
    With this proxy, `git`, `curl`, and downloads work on the **login** node.
    **Compute nodes have no internet at all** — fetch your data on the login
    node first, then run your analysis on a compute node.

---

## 4. Find and try the `ml` image

The `ml` environment is published as a container image and pre-built for you
on IRCBC as a single file:

- On GitHub: `ghcr.io/liuhlab/liulab-runtime:ml`
- On IRCBC: `$LIU_LAB_PACKAGES/liulab-runtime_ml.sif`

From your laptop, check it's there:

```bash
ssh ircbc 'ls -lh $LIU_LAB_PACKAGES/liulab-runtime_ml.sif'
```

!!! note "Missing or out of date?"
    Usually you just ask the lab admin to refresh the shared image. You *can*
    also build it yourself from the published container — that's not covered
    here; see the [Containers guide](../containers.md).

Now run a quick command inside the image. Always do this on a **compute node**
(via `srun`), never on the login node. From your laptop:

```bash
ssh ircbc 'srun -p compute_cpu -c 2 -t 10 bash -c "\
  module load singularity && \
  singularity exec $LIU_LAB_PACKAGES/liulab-runtime_ml.sif \
    bash -c \"source /app/.pixi/activate-ml.sh && python -c \\\"import scanpy; print(scanpy.__version__)\\\"\""'
```

If it prints a version number, the environment works.

That command looks dense, but it's just a stack of small steps:

| Piece | What it does |
| --- | --- |
| `ssh ircbc '…'` | from your laptop, run the quoted part on the cluster |
| `srun -p compute_cpu -c 2 -t 10` | borrow a compute node: partition `compute_cpu`, 2 CPUs, for 10 minutes |
| `module load singularity` | make the `singularity` command available |
| `singularity exec …_ml.sif` | run inside the `ml` container image |
| `source /app/.pixi/activate-ml.sh` | activate the `ml` environment inside the image |
| `python -c "import scanpy; …"` | the actual thing you want to run |

The nested `"` and `\"` just keep those layers separate — you only ever edit
the **last** part (the command you want to run).

!!! note "The image is read-only"
    You can't `pip install` inside the container — it's fixed. Need a new
    package? Add it to `liulab-runtime`'s `pyproject.toml`
    (see [Background → Adding your own environment](../background.md#adding-your-own-environment))
    and ask for a refreshed image.

---

## 5. Start JupyterLab and open it in your browser

**This is your everyday routine.** Steps 1–4 were a one-time setup; from now
on, just repeat the steps below whenever you want to work.

### 1. Submit a job

**On IRCBC** (log in with `ssh ircbc` first), create a file named
`jupyter-ml.sbatch` with a text editor (e.g. `nano jupyter-ml.sbatch`) and
paste:

```bash
#!/bin/bash
#SBATCH -p compute_cpu       # IRCBC CPU partition
#SBATCH -c 8                 # CPUs  — ask for what you need
#SBATCH --mem=32G            # memory
#SBATCH -t 08:00:00          # time  — always set one
#SBATCH -J jupyter-ml
#SBATCH -o %x.%j.log         # this log holds your JupyterLab link

# Compute nodes have no internet, so drop the login node's proxy settings
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY all_proxy

module load singularity
singularity exec --bind /share/lhqlab $LIU_LAB_PACKAGES/liulab-runtime_ml.sif \
  bash -c "source /app/.pixi/activate-ml.sh && jupyter lab --no-browser --ip=127.0.0.1 --port=<PORT>"
```

Pick any `<PORT>` between 8000 and 9999 (e.g. `9990`) and use the same number
everywhere below. Then submit it — from your laptop:

```bash
ssh ircbc 'sbatch jupyter-ml.sbatch'
```

### 2. Find your node and link

From your laptop, check the job and note the node name under `NODELIST` —
that's your `<NODE>` (one of `cpu01`…`cpu08`):

```bash
ssh ircbc 'squeue -u $USER'
```

Once it shows `R` (running), grab the JupyterLab URL from the log:

```bash
ssh ircbc 'grep token= jupyter-ml.<JOBID>.log'
```

### 3. Open the tunnel

On your laptop, open a tunnel to the job's node (the jump through the login
node is automatic):

```bash
ssh -f -N -L <PORT>:localhost:<PORT> <NODE>
```

Then open this in your **laptop's browser** (use the token from the log):

```
http://localhost:<PORT>/lab?token=<token>
```

### 4. Confirm it works

In a new notebook cell (in the browser):

```python
import scanpy, anndata, scvi, torch
print("ok", scanpy.__version__)
```

The `ml` environment also includes scvi-tools, celltypist, and more — see the
[full list](../index.md#available-environments).

### 5. When you're done

On your laptop:

```bash
pkill -f "ssh -f -N -L <PORT>"      # close the tunnel on your laptop
ssh ircbc 'scancel <JOBID>'         # free the compute node
```

---

## 6. Be a good HPC citizen

- **Never run analysis on the login node.** Always get a job (`sbatch` or
  `srun`) and work on the `cpu0N` node it gives you.
- **Ask for what you need.** Set sensible CPUs, memory, and a `--time`; don't
  hold a big node when you're only editing.
- **Download first.** Fetch data on the login node, then compute — compute
  nodes have no internet.
- **Share nicely.** Don't delete other people's images or cancel jobs that
  aren't yours, and `scancel` your JupyterLab job when you finish.

---

## See also

- [Getting started](../index.md) — installing environments with pixi on your own machine
- [Containers](../containers.md) — the container images in general (Docker & Singularity)
- [Background](../background.md) — how the environments are put together
