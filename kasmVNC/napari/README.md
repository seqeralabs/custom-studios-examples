# napari KasmVNC Studio Environment

This example provides a custom container image for running [napari](https://napari.org/) in Seqera Studios using [KasmVNC](https://kasmweb.com/kasmvnc). It demonstrates how to run Python-based GUI applications in Studios via a web-based VNC interface.

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

This container is designed for use as a [custom Studio environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in Seqera Platform. It provides napari, a fast, interactive viewer for multi-dimensional images, accessible through a web browser via KasmVNC.

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/kasmvnc-napari:latest
```

For specific versions, use the release tag (e.g., `ghcr.io/seqeralabs/custom-studios-examples/kasmvnc-napari:v1.0.0`).

## Features

- Full napari GUI application via web browser
- Based on [LinuxServer.io KasmVNC base image](https://docs.linuxserver.io/images/docker-baseimage-kasmvnc/)
- Single-app mode (no desktop environment, napari launches directly)
- KasmVNC performance optimizations for better streaming
- Python 3.10 with PyQt5 backend
- Supports mounting data via Seqera Data Links

> [!NOTE]
> For common features shared across all KasmVNC examples, see the [KasmVNC README](../README.md).

## Files

- `Dockerfile`: Container definition using multi-stage build with connect-client

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../../README.md#prerequisites).

No additional prerequisites specific to this example.

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

To build the container locally:

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t kasmvnc-napari .
```

## Local Testing

To test napari locally, override the entrypoint to bypass connect-client:

```bash
docker run --rm -it --platform linux/amd64 --shm-size=2g -p 6901:6901 \
    --entrypoint /init kasmvnc-napari
```

napari will be available at http://localhost:6901

> [!NOTE]
> The `--shm-size=2g` flag is recommended for KasmVNC to prevent shared memory issues and improve performance.

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../../README.md#deploying-to-seqera-studios).

Additional steps specific to this example:
1. Follow the common deployment process
2. The KasmVNC server will automatically use the `CONNECT_TOOL_PORT` environment variable in Studios
3. Mount your image data via Data Links - files will be available at `/workspace/data/<link_name>/`

## Notes

- napari supports both x86_64 and arm64 architectures
- The CMD bridges `CONNECT_TOOL_PORT` (Seqera Studios) to `CUSTOM_PORT` (KasmVNC)
- Uses `connect-client --entrypoint` for Fusion filesystem support in Studios
- Uses LinuxServer.io's single-app mode (napari launches directly without a desktop environment)
- The port is automatically configured via the `CONNECT_TOOL_PORT` environment variable in Studios
- Additional napari plugins can be installed by adding `pip install` commands to the Dockerfile

> [!NOTE]
> For common technical notes, see the [KasmVNC README](../README.md).

## References

- [napari Documentation](https://napari.org/stable/)
- [napari GitHub](https://github.com/napari/napari)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
- [LinuxServer.io KasmVNC Base Image](https://docs.linuxserver.io/images/docker-baseimage-kasmvnc/)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
