# Marimo Studio Environment

This repository provides a custom container image for running [marimo](https://marimo.io), an open-source reactive Python notebook, as a Studio environment in Seqera Platform.

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/marimo:latest
```

For specific versions, use the release tag (e.g., `ghcr.io/seqeralabs/custom-studios-examples/marimo:v1.0.0`).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [Customizing the Environment](#customizing-the-environment)
- [Notes](#notes)
- [References](#references)

## Overview

This container is designed for use as a [custom Studio environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in Seqera Platform. It is based on the required Seqera base image and includes the necessary `connect-client` for compatibility.

## Features

- Open-source, reactive Python notebook (marimo)
- Reproducible and git-friendly
- SQL built-in, script execution, and app sharing
- Compatible with Seqera Studios custom environments

> [!WARNING]
> Marimo does not support opening the same notebook in multiple tabs to avoid state conflicts. They have recently added a feature to allow this, but it has not been tested in Seqera Studios.

## Prerequisites

- [Docker](https://www.docker.com/) installed
- [Wave](https://docs.seqera.io/platform-cloud/wave/) configured in your Seqera Platform workspace (required for custom environments)
- Access to a container registry (public or Amazon ECR) if you wish to push your image

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

To build the container locally:

```sh
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.8 -t marimo-studio .
```

> [!NOTE]
> The container must use the value of the `CONNECT_TOOL_PORT` environment variable as the listening port for marimo. The Dockerfile is already configured for this.

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
- [marimo Documentation](https://marimo.io)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/)
