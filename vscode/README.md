# VS Code Studio Environment

This example provides a custom container image for running an interactive terminal session in Seqera Studios using a version of [VS Code](https://github.com/gitpod-io/openvscode-server), that runs a server on a remote machine and allows access via a web browser.

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

This container is designed for use as a [custom Studio environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in Seqera Platform and provides a web-based interface to the popular IDE.

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/vscode:latest
```

For specific versions, use the release tag (e.g., `ghcr.io/seqeralabs/custom-studios-examples/vscode:v1.0.0`).

## Features

- Fork of the VS Code IDE managed by Gitpod

> [!NOTE]
> For common features shared across all examples, see the [main README](../README.md#common-features).

## Files

- `Dockerfile`: Container definition using multi-stage build
- `env.yaml`: Packages installed by default
- `init`: Bash script to start up VS Code

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../README.md#prerequisites).

No additional prerequisites specific to this example.

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

To build the container locally:

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t vscode .
```

## Local Testing

To test the terminal locally, you need to override the entrypoint:

```bash
docker run -p 3000:3000 --entrypoint vscode vscode -W -p 3000 bash
```

The terminal will be available at http://localhost:3000

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

Additional steps specific to this example:
1. Follow the common deployment process
2. The terminal will automatically use the `CONNECT_TOOL_PORT` environment variable in Studios

## Notes

- The version of VS Code is `v1.106.3`
- The port is automatically configured via the CONNECT_TOOL_PORT environment variable in Studios

> [!NOTE]
> For common technical notes, see the [main README](../README.md#common-features).

## References

- [TTYD Documentation]()
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/) 
