# TTYD Studio Environment

This example provides a custom container image for running an interactive terminal session in Seqera Studios using [TTYD](https://github.com/tsl0922/ttyd). It uses a commodity [SAMtools](https://www.htslib.org/) image from [Seqera containers](https://github.com/seqeralabs/containers) (built using the [Bioconda](https://bioconda.github.io/) SAMtools recipe) as the base, demonstrating how Studios can run arbitrary container images.

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

This container is designed for use as a [custom Studio environment](https://docs.seqera.io/platform-cloud/studios/custom-envs) in Seqera Platform. It provides a web-based terminal interface with full write permissions and access to bioinformatics tools.

![Screenshot of TTYD terminal](screenshot.png)

## Features

- Interactive web-based terminal using TTYD 1.7.7
- Based on [SAMtools](https://www.htslib.org/) 1.21 container from [Seqera containers](https://github.com/seqeralabs/containers)
- Full terminal access with write permissions
- Includes basic bioinformatics tools from [SAMtools](https://www.htslib.org/) via [Bioconda](https://bioconda.github.io/)

> [!NOTE]
> For common features shared across all examples, see the [main README](../README.md#common-features).

## Files

- `Dockerfile`: Container definition using multi-stage build

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../README.md#prerequisites).

No additional prerequisites specific to this example.

## Local Testing

To test the terminal locally:

```bash
docker build --platform=linux/amd64 -t ttyd-example .
docker run -p 3000:3000 --entrypoint ttyd ttyd-example -W -p 3000 bash
```

The terminal will be available at http://localhost:3000

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

Additional steps specific to this example:
1. Follow the common deployment process
2. The terminal will automatically use the `CONNECT_TOOL_PORT` environment variable in Studios

## Notes

- The terminal uses TTYD 1.7.7 for web-based terminal access
- The terminal runs with write permissions enabled (-W flag)
- The base image includes SAMtools 1.21 and other bioinformatics tools
- The port is automatically configured via the CONNECT_TOOL_PORT environment variable in Studios

> [!NOTE]
> For common technical notes, see the [main README](../README.md#common-features).

## References

- [TTYD Documentation](https://github.com/tsl0922/ttyd)
- [SAMtools Documentation](https://www.htslib.org/)
- [Seqera Containers](https://github.com/seqeralabs/containers)
- [Bioconda Documentation](https://bioconda.github.io/)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wave Documentation](https://docs.seqera.io/platform-cloud/wave/) 