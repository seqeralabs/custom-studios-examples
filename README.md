# TTYD Studio Environment

This branch contains the Seqera Studios configuration for running an interactive terminal session using [TTYD](https://github.com/tsl0922/ttyd) in Seqera Platform. It uses a [SAMtools](https://www.htslib.org/) image from [Seqera containers](https://github.com/seqeralabs/containers) as the base, demonstrating how Studios can run arbitrary container images.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `ttyd`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/ttyd:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Interactive web-based terminal using TTYD 1.7.7
- Based on SAMtools 1.21 container from Seqera containers
- Full terminal access with write permissions
- Includes bioinformatics tools from Bioconda

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/ttyd:latest
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t ttyd-studio .
```

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [TTYD Documentation](https://github.com/tsl0922/ttyd)
- [SAMtools Documentation](https://www.htslib.org/)
