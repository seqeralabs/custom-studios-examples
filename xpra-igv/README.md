# Xpra and Integrative Genomics Viewer (IGV) Studio Environment

This repository provides a custom container image for running
[Xpra](https://xpra.org/index.html) and the [IGV](https://igv.org/)
desktop Java application as a Studio environment in Seqera Platform.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [Customizing the Environment](#customizing-the-environment)
- [References](#references)

## Overview

This container is designed for use as a [custom Studio
environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in
Seqera Platform. It is based on the required Seqera base image and
includes the necessary `connect-client` for compatibility.

## Features

- Open-source, remote desktop display server
- IGV desktop Java application (v2.19.4)
- Reproducible and git-friendly
- Compatible with Seqera Studios custom environments

## Prerequisites

- [Docker](https://www.docker.com/) installed
- [Wave](https://docs.seqera.io/platform-cloud/wave/) configured
in your Seqera Platform workspace (required for custom environments)
- Access to a container registry (public or Amazon ECR) if you wish to push your image

## Building the Container

To build the container locally:

```sh
wave -f Dockerfile --await
```

Or, using Docker directly:

```sh
docker build -t xpra-igv .
```

## Using in Seqera Studios

1. **Push your image** to a container registry accessible by Seqera Platform.
2. In Seqera Platform, go to the **Studios** tab and click **Add Studio**.
3. Select **Prebuilt container image** as the template.
4. Enter your container image URI (e.g., `cr.your-registry.io/your-org/marimo-studio:latest`).
5. Configure compute resources and data mounts as needed.
6. Launch the Studio.

For more details, see the [official documentation](https://docs.seqera.io/platform-cloud/studios/custom-envs).

## Customizing the Environment

You can further customize this environment by:

- Adding Conda or pip packages (see [Conda package syntax](https://docs.seqera.io/platform-cloud/studios/custom-envs#conda-package-syntax))
- Modifying the Dockerfile to include additional dependencies

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Xpra Documentation](https://github.com/Xpra-org/xpra/blob/master/README.md)
- [IGV Desktop Documentation](https://github.com/igvteam/igv)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/)
