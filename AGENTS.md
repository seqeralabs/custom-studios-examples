# AGENTS.md

Guidance for AI coding agents working in this repository.

## Repository overview

This is **Seqera Labs Custom Studios Examples** — a collection of Docker-based [Seqera Platform Studios](https://docs.seqera.io/platform-cloud/studios/overview) reference environments. Each studio is a standalone container image (Marimo, CellxGene, Streamlit, R Shiny, Shinyngs, TTYD). There is no root-level package manager, monorepo build, or docker-compose stack.

The `master` branch holds documentation and example directories. Deployable studio configs (`.seqera/studio-config.yaml`) live on dedicated git branches per studio.

## Creating custom studios

Root `AGENTS.md` covers **running existing examples**. To **compose a new custom Studio** (Dockerfile structure, connect-client integration, cloud data paths, Git branch deployment), read:

**[`docs/agents/custom-studios.md`](docs/agents/custom-studios.md)**

That guide distills the [Seqera blog on deploying custom apps](https://seqera.io/blog/deploy-custom-apps-studios/) and patterns from this repo. Load it only when the task involves creating or modifying a studio — not for routine builds of existing examples.

## Cursor Cloud specific instructions

### System dependencies

- **Docker** is required for all development and testing. In Cursor Cloud VMs, Docker must be installed with `fuse-overlayfs` as the storage driver (nested container environment). Use `sudo docker` if the current user is not in the `docker` group.
- Start the daemon if needed: `sudo service docker start`

### No repo-level dependency install

There is no `package.json`, `requirements.txt`, or Makefile at the repository root. Dependencies are installed inside each studio's Dockerfile at image build time. The VM update script is a no-op for this reason.

### Building a studio

Pick one studio directory and build with the required `CONNECT_CLIENT_VERSION` build arg (default `0.9` in Dockerfiles):

```bash
cd shiny-simple-example   # or marimo/, cellxgene/, streamlit/, ttyd/
sudo docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t <image-name> .
```

Pre-built images are also available from GHCR, e.g. `ghcr.io/seqeralabs/custom-studios-examples/shiny:latest`.

### Running locally (override connect-client entrypoint)

Seqera's `connect-client` entrypoint is for platform integration. For local dev, override the entrypoint as documented in each studio's README.

**Shiny** (`shiny-simple-example/`):

```bash
sudo docker run -p 3000:3000 --entrypoint micromamba shiny-simple-example \
  run -n shiny R -e "shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=3000)"
```

**TTYD** (`ttyd/`):

```bash
sudo docker run -p 3000:3000 --entrypoint ttyd ttyd-example -W -p 3000 bash
```

**Marimo** (`marimo/`):

```bash
sudo docker run -p 3000:3000 --entrypoint marimo marimo-studio edit -p 3000 --no-token --host 0.0.0.0
```

**CellxGene** (`cellxgene/`):

```bash
sudo docker run -p 3000:3000 --entrypoint /usr/local/bin/cellxgene cellxgene-example \
  launch --host 0.0.0.0 --port 3000 <dataset.h5ad>
```

**Streamlit** (`streamlit/`):

```bash
sudo docker run -p 3000:3000 --entrypoint streamlit streamlit-example \
  run /app/multiqc_app.py --server.port=3000 --server.address=0.0.0.0
```

Open http://localhost:3000 in a browser after the container starts.

### Lint / test / CI

There are no local lint or unit-test scripts. CI (`.github/workflows/docker-pr.yml`) builds changed Dockerfiles on PRs and runs Trivy security scans. To validate changes locally, build the affected studio's Docker image.

### Gotchas

- All images target **`linux/amd64`**; pass `--platform=linux/amd64` when building on ARM hosts.
- **CellxGene** fails to start if a referenced `s3://`/`gs://`/`az://` dataset path isn't mounted via **Mount data** in the Studio.
- **Marimo** does not support opening the same notebook in multiple tabs (state conflicts).
- **Shiny** ships bundled `data.csv`; override `DATA_PATH` or mount volumes for custom data.
- Do not merge studio branch configs into `master` (project convention).
