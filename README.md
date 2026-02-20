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

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/cellxgene:latest
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DATASET_FILE` | `s3://cellxgene_datasets/pbmc3k.h5ad` | Path to .h5ad dataset |
| `DATASET_TITLE` | `PBMCs 3k test dataset` | Display title |
| `USER_DATA_DIR` | `/user-data/cellxgene` | User data storage |
| `ANNOTATIONS_DIR` | `/user-data/cellxgene` | Annotations storage |
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

## Cloud Storage Path Translation

The container automatically converts cloud storage paths to local Studio paths:

- **Amazon S3**: `s3://bucket/path/to/dataset.h5ad` -> `/workspace/data/bucket/path/to/dataset.h5ad`
- **Google Cloud Storage**: `gs://bucket/path/to/dataset.h5ad` -> `/workspace/data/bucket/path/to/dataset.h5ad`
- **Azure Blob Storage**: `az://container/path/to/dataset.h5ad` -> `/workspace/data/container/path/to/dataset.h5ad`

> **Note:** Ensure the corresponding cloud storage buckets are mounted in your Studio via the **Mount data** option.

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t cellxgene-studio .
```

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [CellxGene Documentation](https://chanzuckerberg.github.io/cellxgene/)
