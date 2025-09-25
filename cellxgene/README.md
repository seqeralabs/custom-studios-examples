# CellxGene Studio Environment

This example provides a custom container image for running [CellxGene](https://chanzuckerberg.github.io/cellxgene/), an interactive single-cell data visualization platform, as a Studio environment in Seqera Platform.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Files](#files)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Local Testing](#local-testing)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [Notes](#notes)
- [References](#references)

## Overview

This container is designed for use as a [custom Studio environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in Seqera Platform. It provides an interactive interface for exploring single-cell data using the CellxGene visualization platform.

![Screenshot of CellxGene](screenshot.png)

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/cellxgene:latest
```

For specific versions, use the release tag (e.g., `ghcr.io/seqeralabs/custom-studios-examples/cellxgene:v1.0.0`).

## Features

- CellxGene 1.3.0 visualization platform
- Support for .h5ad datasets
- Interactive single-cell data exploration
- Automatic data mounting via datalinks
- Configurable dataset path, title, and storage directories via environment variables
- Cloud storage path support with automatic translation to local Studio paths

> [!NOTE]
> For common features shared across all examples, see the [main README](../README.md#common-features).

## Files

- `Dockerfile`: Container definition using multi-stage build
- `README.md`: This documentation file
- `screenshot.png`: Example screenshot of the CellxGene interface

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../README.md#prerequisites).

Additional requirements specific to this example:
- .h5ad format single-cell datasets

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

To build the container locally:

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.8 -t cellxgene-example .
```

## Local Testing

To test the app locally, you need to override the entrypoint:

```bash
docker run -p 3000:3000 --entrypoint /usr/local/bin/cellxgene cellxgene-example launch \
    --host 0.0.0.0 \
    --port 3000 \
    --user-generated-data-dir /user-data/cellxgene \
    --annotations-dir /user-data/cellxgene \
    --title "PBMCs 3k test dataset" \
    /path/to/your/dataset.h5ad
```

To use a specific data file, make it available at /workspace/data/cellxgene_datasets/ in the container:

```bash
docker run -p 3000:3000 --entrypoint /usr/local/bin/cellxgene -v $(pwd)/data:/workspace/data/cellxgene_datasets cellxgene-example launch \
    --host 0.0.0.0 \
    --port 3000 \
    --user-generated-data-dir /user-data/cellxgene \
    --annotations-dir /user-data/cellxgene \
    --title "Your Dataset" \
    /workspace/data/cellxgene_datasets/your_dataset.h5ad
```

The app will be available at http://localhost:3000

## Cloud Storage Path Translation

The container automatically converts cloud storage paths to local Studio paths. Supported providers include:

- **Amazon S3**: `s3://bucket/path/to/dataset.h5ad`
- **Google Cloud Storage**: `gs://bucket/path/to/dataset.h5ad`  
- **Azure Blob Storage**: `az://container/path/to/dataset.h5ad`

**Examples:**
- S3: `s3://my-genomics-data/single-cell/experiment1.h5ad` → `/workspace/data/my-genomics-data/single-cell/experiment1.h5ad`
- GCS: `gs://research-bucket/datasets/pbmc3k.h5ad` → `/workspace/data/research-bucket/datasets/pbmc3k.h5ad`
- Azure: `az://data-container/studies/cellxgene.h5ad` → `/workspace/data/data-container/studies/cellxgene.h5ad`

**Requirements:**
- Mount the cloud storage bucket/container from Data Explorer in Seqera Studios
- Provide cloud storage paths in the `DATASET_FILE` environment variable

> [!WARNING]
> **Bucket Mounting Required**: When using cloud storage paths (`s3://`, `gs://`, `az://`), ensure the corresponding buckets are mounted in your Studio via the **Mount data** option. Unmounted buckets will cause the Studio to fail when trying to access the converted paths.

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

Additional steps specific to this example:
1. In the **Compute and Data** tab, click the **Mount data** button to mount your cloud storage bucket/container
2. Follow the common deployment process
3. Configure environment variables:
   - `DATASET_FILE`: Cloud storage path to your .h5ad file
     - Supports S3 (`s3://`), Google Cloud Storage (`gs://`), and Azure Blob Storage (`az://`) paths
     - Example: `s3://my-genomics-data/single-cell/experiment1.h5ad`
   - `DATASET_TITLE`: Title to display in the CellxGene interface
     - Example: `"My Single-Cell Analysis"`
   - `USER_DATA_DIR`: Path for user-generated data storage
     - Default: `/user-data/cellxgene` (local directory)
     - Supports cloud storage paths (automatically converted to local Studio paths)
     - Example: `s3://my-bucket/user-data/cellxgene`
   - `ANNOTATIONS_DIR`: Path for annotations storage
     - Default: `/user-data/cellxgene` (local directory)
     - Supports cloud storage paths (automatically converted to local Studio paths)
     - Example: `s3://my-bucket/annotations/cellxgene`

> [!WARNING]
> **Bucket Mounting**: If using cloud storage paths for `USER_DATA_DIR` or `ANNOTATIONS_DIR`, ensure the corresponding buckets are mounted in your Studio. Unmounted buckets will cause the Studio to fail when trying to access the converted paths.

## Notes

- The app uses CellxGene 1.3.0 for interactive single-cell data visualization
- User data and annotations directories can be configured via environment variables
- Default storage locations: `/user-data/cellxgene` (can be overridden with cloud storage paths)
- Specify your dataset via the DATASET_FILE environment variable
- Customize the display title via the DATASET_TITLE environment variable

> [!NOTE]
> For common technical notes, see the [main README](../README.md#common-features).

## References

- [CellxGene Documentation](https://chanzuckerberg.github.io/cellxgene/)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/)