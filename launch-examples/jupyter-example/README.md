# Launch Examples

This example shows how to specifically launch a JupterLab or R-IDE environment (last mile).

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

## Features

- Python 3.11-based environment

## Files

- `Dockerfile`: Container definition using multi-stage build.

## Prerequisites

- [Docker](https://www.docker.com/) installed
- [Wave](https://docs.seqera.io/platform-cloud/wave/) configured in your Seqera Platform workspace
- Access to a container registry (public or Amazon ECR) if you wish to push your image

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

To build the container locally:

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.8 -t launch-example .
```

## Notes

- The app uses Streamlit for interactive data visualization
- The Dockerfile uses a multi-stage build to include the connect-client
- The container is built for linux/amd64 platform compatibility
- The example is based on the MultiQC Streamlit application
- The container uses Python 3.11 as the base image

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/) 
