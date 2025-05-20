# CellxGene Studio Environment

This example provides a custom container image for running [CellxGene](https://chanzuckerberg.github.io/cellxgene/), an interactive single-cell data visualization platform, as a Studio environment in Seqera Platform.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Files](#files)
- [Prerequisites](#prerequisites)
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

> [!NOTE]
> For common features shared across all examples, see the [main README](../README.md#common-features).

## Files

- `Dockerfile`: Container definition using multi-stage build
- `pbmc3k.h5ad`: Example dataset (mounted via datalink)

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../README.md#prerequisites).

Additional requirements specific to this example:
- .h5ad format single-cell datasets

## Local Testing

To test the app locally:

```bash
docker build --platform=linux/amd64 -t cellxgene-example .
docker run -p 3000:3000 --entrypoint /usr/local/bin/cellxgene cellxgene-example launch \
    --host 0.0.0.0 \
    --port 3000 \
    --user-generated-data-dir /user-data/cellxgene \
    --annotations-dir /user-data/cellxgene \
    --title "PBMCs 3k test dataset" \
    /path/to/your/dataset.h5ad
```

To use a specific data file, make it available at /workspace/data/cellxgene_datasets/ in the 
container:

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

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

Additional steps specific to this example:
1. Create a data link called 'cellxgene_datasets' and place your .h5ad file there
2. Follow the common deployment process
3. When mounting data, ensure to mount 'cellxgene_datasets' using the **Mount data** option

## Notes

- The app uses CellxGene 1.3.0 for interactive single-cell data visualization
- User data and annotations are stored in /user-data/cellxgene
- The default dataset is pbmc3k.h5ad, but can be changed via the DATASET_NAME environment variable

> [!NOTE]
> For common technical notes, see the [main README](../README.md#common-features).

## References

- [CellxGene Documentation](https://chanzuckerberg.github.io/cellxgene/)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/)