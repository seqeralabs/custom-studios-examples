# CytoExploreR Studio Environment

This example provides a custom container image for running [CytoExploreR](https://github.com/DillonHammill/CytoExploreR), an interactive flow cytometry analysis platform, in RStudio Server as a Studio environment in Seqera Platform.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Files](#files)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Local Testing](#local-testing)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [Using CytoExploreR](#using-cytoexplorer)
- [Notes](#notes)
- [References](#references)

## Overview

This container is designed for use as a [custom Studio environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in Seqera Platform. It provides an interactive RStudio Server interface for flow cytometry data analysis using the CytoExploreR package.

CytoExploreR is a comprehensive R package for interactive cytometry data analysis developed by Dillon Hammill. It provides:
- Interactive gating with manual gate drawing and editing
- Comprehensive visualization and plotting functions
- Automatic spillover compensation
- Dimensionality reduction (PCA, t-SNE, UMAP, EmbedSOM)
- Integration with openCyto and FlowJo workspaces
- User-friendly interface designed for users with no coding experience

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/cytoexplorer:latest
```

For specific versions, use the release tag (e.g., `ghcr.io/seqeralabs/custom-studios-examples/cytoexplorer:v1.0.0`).

## Features

- RStudio Server browser-based interface
- CytoExploreR pre-installed with all dependencies
- Interactive flow cytometry data analysis and gating
- Compatible with both local Docker testing and Seqera Studios
- Automatic data mounting via datalinks
- Full R/RStudio environment with flow cytometry tools
- Support for FIt-SNE dimensionality reduction

> [!NOTE]
> For common features shared across all examples, see the [main README](https://github.com/seqeralabs/custom-studios-examples#common-features).

## Files

- `Dockerfile`: Container definition using multi-stage build
- `build.sh`: Build script with registry push support
- `README.md`: This documentation file
- `QUICKSTART.md`: Quick reference guide
- `.dockerignore`: Files to exclude from Docker build context
- `.gitignore`: Git ignore patterns

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](https://github.com/seqeralabs/custom-studios-examples#prerequisites).

Additional requirements specific to this example:
- Flow cytometry data files (FCS format)
- Recommended: 4 CPU cores, 8GB RAM minimum for analysis

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

To build the container locally:

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t cytoexplorer-example .
```

Or use the provided build script:

```bash
./build.sh
```

Build times: Approximately 15-20 minutes due to R package compilation and dependency installation.

## Local Testing

To test the app locally, you need to override the entrypoint:

```bash
docker run -p 8787:8787 -e PASSWORD=test --entrypoint /usr/lib/rstudio-server/bin/rserver cytoexplorer-example --server-daemonize=0 --www-port=8787 --www-address=0.0.0.0
```

The RStudio Server will be available at http://localhost:8787

Default credentials:
- **Username:** `rstudio`
- **Password:** `test` (or whatever you set with `-e PASSWORD=yourpassword`)

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](https://github.com/seqeralabs/custom-studios-examples#deploying-to-seqera-studios).

Additional steps specific to this example:
1. Follow the common deployment process
2. Configure compute resources:
   - Minimum: 4 CPU cores, 8GB RAM
   - Recommended: 8 CPU cores, 16GB RAM for large datasets
3. When mounting data, ensure to mount directories containing FCS files or other flow cytometry data using the **Mount data** option
4. Set the `PASSWORD` environment variable to customize the RStudio login password (optional, defaults to `rstudio`)

### Data Access

When using data links with Seqera Studios:
1. Upload your flow cytometry data (e.g., `.fcs` files) to your S3 bucket
2. Create a data link (e.g., `flow_data`) pointing to that S3 path
3. The data will be available at `/workspace/data/flow_data/` in RStudio
4. Access files in R using standard file paths

## Using CytoExploreR

Once in RStudio:

```r
# Load the package
library(CytoExploreR)

# Load example data (included in package)
data(Activation, package = "CytoExploreRData")

# Setup experiment
gs <- cyto_setup(Activation,
                 gatingTemplate = "Activation-gatingTemplate.csv")

# Interactive gating
cyto_gate_draw(gs,
               parent = "root",
               alias = "Cells",
               channels = c("FSC-A", "SSC-A"))

# View results
cyto_plot(gs, parent = "Cells")
```

For more examples, see the [CytoExploreR documentation](https://dillonhammill.github.io/CytoExploreR/).

## Notes

- The container uses RStudio Server (rocker/rstudio) as the base image
- CytoExploreR and all dependencies are installed from source during build
- FIt-SNE is compiled for dimensionality reduction capabilities
- The Dockerfile uses a multi-stage build to include the connect-client
- The container is built for linux/amd64 platform compatibility
- Default RStudio credentials: username `rstudio`, password `rstudio` (customizable via PASSWORD environment variable)
- Build time is approximately 15-20 minutes due to R package compilation

> [!NOTE]
> For common technical notes, see the [main README](https://github.com/seqeralabs/custom-studios-examples#common-features).

## References

- [CytoExploreR Documentation](https://dillonhammill.github.io/CytoExploreR/)
- [CytoExploreR GitHub Repository](https://github.com/DillonHammill/CytoExploreR)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [RStudio Server](https://posit.co/products/open-source/rstudio-server/)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/)
