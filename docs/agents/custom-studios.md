# Creating custom Seqera Studios

Guide for AI agents composing new custom Studio environments. Synthesized from:

- [Deploying custom applications in Seqera Studios](https://seqera.io/blog/deploy-custom-apps-studios/) (May 2025)
- [Custom studio environments](https://docs.seqera.io/platform-cloud/studios/custom-envs) (official docs)
- Patterns in this repository (`marimo/`, `cellxgene/`, `streamlit/`, `shiny-simple-example/`, `ttyd/`)

---

## When to read this doc

Use this file when the task involves **creating or modifying** a custom Studio — not when only building/running existing examples (see root `AGENTS.md` for that).

---

## Application requirements

A tool can run as a custom Studio if:

1. **It installs in a container** (most web/GUI tools qualify).
2. **It serves its UI over HTTP** on a port you can configure at startup.

Non-HTTP Linux desktop apps can use the **Xpra** built-in template instead of a custom Dockerfile ([blog](https://seqera.io/blog/deploy-custom-apps-studios/)).

---

## Two ways to add a Studio

### Option A — Extend a built-in template (Conda + Wave)

Use when you only need extra packages on an existing template (Jupyter, R IDE, VS Code, Xpra):

1. In Seqera Platform: **Studios → Add Studio**.
2. Choose a base template and supply a **Conda environment specification** on the second screen.
3. Wave builds a new image with your dependencies layered on the template.

Example from the blog: add IGV to the Xpra template via Conda.

**No custom Dockerfile required.** Best for small dependency additions.

### Option B — Custom Dockerfile (this repo's model)

Use when the app is not covered by templates, or you need full control over the runtime (Python/R base, arbitrary tools, custom startup logic).

Every example in this repo follows Option B.

---

## Standard Dockerfile structure

All studios in this repo use the same multi-stage pattern. Required steps:

### 1. Pull connect-client (multi-stage)

Connect mediates communication between the app and Seqera Platform and includes Fusion (POSIX-like cloud storage access).

```dockerfile
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect
```

Pass the version at build time: `--build-arg CONNECT_CLIENT_VERSION=0.9`. Dockerfiles in this repo default to `0.9`.

### 2. Choose an application base image

Install your app on a base that supports package management (`apt-get` or `yum` required for `connect-client --install`):

| Pattern | Example in this repo |
|---------|----------------------|
| Python slim + pip/uv | `marimo/`, `streamlit/`, `cellxgene/` |
| Ubuntu + micromamba | `shiny-simple-example/` |
| Existing community image + inject tools | `ttyd/` (SAMtools base + TTYD) |

Stripped images without `apt-get`/`yum` cannot run `connect-client --install`.

### 3. Define environment variables (optional)

Expose tunable defaults with `ENV`. Users override them when launching the Studio in Platform:

```dockerfile
ENV DATASET_FILE=s3://cellxgene_datasets/pbmc3k.h5ad
ENV DATASET_TITLE="PBMCs 3k test dataset"
```

See [Environment variables](#environment-variables) below for per-studio variables in this repo.

### 4. Install connect-client in the final stage

```dockerfile
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install
```

Some Python-based images also install `btrfs-progs` from Debian backports (see `marimo/Dockerfile`, `cellxgene/Dockerfile`) — follow neighboring examples when using `python:*-slim`.

### 5. Set the entrypoint

```dockerfile
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]
```

**Do not skip this** for Platform deployment. For local Docker testing, override `--entrypoint` (see root `AGENTS.md`).

### 6. Start the app on `$CONNECT_TOOL_PORT`

Studios sets `CONNECT_TOOL_PORT` at runtime. Your `CMD` must bind the app to that port:

```dockerfile
# Python HTTP server (minimal example from blog)
CMD ["/usr/bin/bash", "-c", "python3 -m http.server $CONNECT_TOOL_PORT"]

# Marimo (this repo)
CMD marimo edit -p $CONNECT_TOOL_PORT --no-token

# Streamlit (this repo)
CMD streamlit run /app/multiqc_app.py \
    --server.port=$CONNECT_TOOL_PORT \
    --server.address=0.0.0.0 \
    --server.enableCORS=false \
    --server.enableXsrfProtection=false \
    --server.enableWebsocketCompression=false \
    --browser.gatherUsageStats=false

# TTYD (this repo)
CMD ["/usr/bin/bash", "-c", "ttyd -W -p $CONNECT_TOOL_PORT bash"]
```

Always listen on `0.0.0.0` (not `127.0.0.1`) for web apps.

---

## Cloud storage paths and data links

### How mounted data appears in the container

When users mount buckets or create **data links** in Platform, files appear under:

```
/workspace/data/<data-link-name>/...
```

An S3 URI `s3://my-bucket/path/file.csv` maps to:

```
/workspace/data/my-bucket/path/file.csv
```

Supported prefixes for path translation in this repo: `s3://`, `gs://`, `az://`.

### Bash `convert_path()` pattern (CellxGene, blog)

Used in `cellxgene/Dockerfile` CMD — converts cloud URIs to local Studio paths:

```bash
convert_path() {
  local input_path="$1"
  if [[ "$input_path" =~ ^(s3|gs|az):// ]]; then
    local cloud_path=${input_path#*://}
    local bucket_name=${cloud_path%%/*}
    local object_path=${cloud_path#*/}
    echo "/workspace/data/$bucket_name/$object_path"
  else
    echo "$input_path"
  fi
}
LOCAL_PATH=$(convert_path "${DATASET_FILE}")
```

### R path translation (Shiny example)

`shiny-simple-example/app_plot_demo.R` reads `DATA_PATH` and converts in application code:

```r
data_path <- Sys.getenv('DATA_PATH', 's3://shiny-inputs/data.csv')
if (grepl('^s3://|^gs://|^az://', data_path)) {
  cloud_path <- sub('^[^:]+://', '', data_path)
  bucket_name <- strsplit(cloud_path, '/')[[1]][1]
  object_path <- sub(paste0('^', bucket_name, '/'), '', cloud_path)
  file_path <- paste0('/workspace/data/', bucket_name, '/', object_path)
} else {
  file_path <- data_path
}
```

Choose Bash (startup script) or app-level translation depending on how your tool accepts input paths.

### Streamlit + Fusion

`streamlit/` clones [MultiQC/example-streamlit](https://github.com/MultiQC/example-streamlit). Users load data via **Server Paths** pointing at `/workspace/data/<link>/file.zip` after mounting — no app code changes needed for Fusion access.

---

## Environment variables

Variables defined in the Dockerfile can be overridden at Studio launch in Platform.

| Studio | Variable | Default | Purpose |
|--------|----------|---------|---------|
| CellxGene | `DATASET_FILE` | `s3://cellxgene_datasets/pbmc3k.h5ad` | Input `.h5ad` |
| CellxGene | `DATASET_TITLE` | `PBMCs 3k test dataset` | Display title |
| CellxGene | `USER_DATA_DIR` | `/user-data/cellxgene` | User-generated data |
| CellxGene | `ANNOTATIONS_DIR` | `/user-data/cellxgene` | Annotations |
| Shiny | `DATA_PATH` | `s3://shiny-inputs/data.csv` | Input CSV |

Marimo, Streamlit, and TTYD use defaults only (no required env vars).

---

## Build and validate locally

```bash
cd <studio-directory>
sudo docker build --platform=linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.9 \
  -t my-studio .
```

Override the entrypoint for local runs (connect-client needs Platform). Each studio README documents the local command.

CI (`.github/workflows/docker-pr.yml`) builds changed Dockerfiles on PR and runs Trivy scans.

---

## Deploy to Seqera Platform

### Pre-built container image

1. Push the image to a registry accessible from Platform (GHCR, ECR, etc.).
2. **Studios → Add Studio → Prebuilt container image**.
3. Enter the image URI (e.g. `ghcr.io/seqeralabs/custom-studios-examples/shiny:latest`).
4. **Compute and Data**: select compute env, CPU/memory/GPU, **Mount data** for required buckets.
5. **General config**: set name, description, and any env vars (`DATA_PATH`, `DATASET_FILE`, …).
6. Review and **Add → Start**.

Pre-built images for this repo:

```
ghcr.io/seqeralabs/custom-studios-examples/marimo:latest
ghcr.io/seqeralabs/custom-studios-examples/cellxgene:latest
ghcr.io/seqeralabs/custom-studios-examples/streamlit:latest
ghcr.io/seqeralabs/custom-studios-examples/shiny:latest
ghcr.io/seqeralabs/custom-studios-examples/ttyd:latest
```

### Git repository deployment (branch-per-studio)

This repo uses a **branch-per-studio** model ([README](../../README.md)):

- `master` — documentation + reference Dockerfiles (do **not** merge studio configs into master).
- Each studio branch (e.g. `marimo`, `shiny`, `cellxgene`) contains a `.seqera/` directory:

```
.seqera/
├── studio-config.yaml
└── Dockerfile
```

**`studio-config.yaml`** (from `origin/marimo`):

```yaml
schemaVersion: "0.0.1"
kind: "studio-config"
session:
  template:
    kind: "dockerfile"
    dockerfile: "Dockerfile"
```

To deploy from Git:

1. **Studios → Add Studio → Git repository**.
2. URL: `https://github.com/seqeralabs/custom-studios-examples`
3. Select the studio branch (e.g. `marimo`).
4. Platform builds from `.seqera/Dockerfile` per `studio-config.yaml`.

### Wave CLI (alternative build)

```bash
git clone https://github.com/seqeralabs/custom-studios-examples.git \
  --single-branch --branch <studio-name>

wave -f .seqera/Dockerfile --context .seqera \
  --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

---

## Adding a new studio to this repository

Follow the [Contributing](../../README.md#contributing) section in the root README:

1. Create an orphan branch: `git checkout --orphan <studio-name>`
2. Add `.seqera/studio-config.yaml` and `.seqera/Dockerfile` (and supporting files).
3. Add `README.md` with build, local test, and Platform deployment instructions.
4. Push the branch.
5. Open a PR to `master` updating the studio table in root `README.md` only (not the `.seqera/` config).

Reference implementations to copy:

| Goal | Start from |
|------|------------|
| Python notebook | `marimo/Dockerfile` |
| Python web app | `streamlit/Dockerfile` |
| Python + input file env vars | `cellxgene/Dockerfile` |
| R Shiny + CSV data | `shiny-simple-example/` |
| Terminal in existing tool image | `ttyd/Dockerfile` |

---

## Checklist for a new custom Studio

- [ ] App serves UI over HTTP; port bound to `$CONNECT_TOOL_PORT`
- [ ] Multi-stage build with `connect-client` copied and `--install` run
- [ ] `ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]`
- [ ] Base image has `apt-get` or `yum`
- [ ] Built for `linux/amd64`
- [ ] `CONNECT_CLIENT_VERSION` build arg provided
- [ ] Optional: `ENV` defaults for user-configurable inputs
- [ ] Optional: cloud path → `/workspace/data/...` translation if app reads files
- [ ] README with local test command (entrypoint override)
- [ ] For this repo: orphan branch + `.seqera/` layout if deploying via Git

---

## Further reading

- [Deploying custom applications in Seqera Studios](https://seqera.io/blog/deploy-custom-apps-studios/)
- [Custom studio environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Add a Studio from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Wave CLI](https://docs.seqera.io/wave/)
- [Data Studios custom environments (blog)](https://seqera.io/blog/data-studios-custom-environments/)
