# CellxGene Studio Environment

This branch contains the Seqera Studios configuration for running [CellxGene](https://chanzuckerberg.github.io/cellxgene/), an interactive single-cell data visualization platform, as a Studio environment in Seqera Platform.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `cellxgene`
5. Select your compute environment
6. Click **Add** then **Start**

With no data mounted, the Studio starts on a built-in [demo dataset](#demo-dataset).

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/cellxgene:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- CellxGene 1.3.0 visualization platform
- Support for .h5ad datasets
- Interactive single-cell data exploration
- Configurable dataset path, title, and storage directories via environment variables
- Cloud storage path support with automatic translation to local Studio paths
- Built-in demo dataset, used when no dataset is found, so the Studio starts without mounted data

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/cellxgene:latest
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DATASET_FILE` | `s3://cellxgene_datasets/pbmc3k.h5ad` | Path to .h5ad dataset. If no file is found there, the [demo dataset](#demo-dataset) is used |
| `DATASET_TITLE` | `PBMCs 3k test dataset` | Display title (not applied to the demo dataset) |
| `USER_DATA_DIR` | `/user-data/cellxgene` | User data storage |
| `ANNOTATIONS_DIR` | `/user-data/cellxgene` | Annotations storage |
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

## Demo dataset

If the file `DATASET_FILE` points to does not exist when the Studio starts, CellxGene starts on a demo dataset that is built into the image. This is what happens when the Studio is started with the defaults and no data mounted. The Studio log says so and names the path that was not found:

```
[cellxgene-studio] Dataset not found: /workspace/data/cellxgene_datasets/pbmc3k.h5ad (DATASET_FILE=s3://cellxgene_datasets/pbmc3k.h5ad).
[cellxgene-studio] Starting on the demo dataset /opt/cellxgene-demo/pbmc3k.h5ad instead.
```

The demo dataset is shown with the title `PBMC 3k demo dataset`, whatever `DATASET_TITLE` is set to.

To open your own data, mount the data-link that holds it via the **Mount data** option and set the environment variable `DATASET_FILE` to the `.h5ad` file, either as `/workspace/data/<data-link name>/<path>` or as a cloud storage path (see below).

If the `USER_DATA_DIR` or `ANNOTATIONS_DIR` directory cannot be created, which can happen when its data-link is not mounted, `/user-data/cellxgene` is used instead and the log says so. That directory is inside the Studio, not in cloud storage.

The demo dataset is `pbmc3k.h5ad` (2,638 cells, about 25 MB) from the [example data of the cellxgene project](https://github.com/chanzuckerberg/cellxgene/tree/1.3.0/example-dataset), whose repository is published under the [MIT license](https://github.com/chanzuckerberg/cellxgene/blob/1.3.0/LICENSE.txt). The cellxgene documentation names [10x Genomics as the source of the data](https://github.com/chanzuckerberg/cellxgene-documentation/blob/main/desktop/quick-start.md#example-datasets). The file is downloaded when the image is built, so starting the Studio does not depend on it being reachable.

## Cloud Storage Path Translation

The container automatically converts cloud storage paths to local Studio paths:

- **Amazon S3**: `s3://bucket/path/to/dataset.h5ad` -> `/workspace/data/bucket/path/to/dataset.h5ad`
- **Google Cloud Storage**: `gs://bucket/path/to/dataset.h5ad` -> `/workspace/data/bucket/path/to/dataset.h5ad`
- **Azure Blob Storage**: `az://container/path/to/dataset.h5ad` -> `/workspace/data/container/path/to/dataset.h5ad`

> **Note:** Ensure the corresponding cloud storage buckets are mounted in your Studio via the **Mount data** option. A dataset that is not found there is replaced by the [demo dataset](#demo-dataset).

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.15 -t cellxgene-studio .
```

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [CellxGene Documentation](https://chanzuckerberg.github.io/cellxgene/)
