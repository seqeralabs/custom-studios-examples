# Marimo Studio Environment

This branch contains the Seqera Studios configuration for running [marimo](https://marimo.io), an open-source reactive Python notebook, as a Studio environment in Seqera Platform.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `marimo`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/marimo:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Open-source, reactive Python notebook (marimo)
- Reproducible and git-friendly
- SQL built-in, script execution, and app sharing
- Compatible with Seqera Studios custom environments

> **Warning:** Marimo does not support opening the same notebook in multiple tabs to avoid state conflicts.

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/marimo:latest
```

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t marimo-studio .
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [marimo Documentation](https://marimo.io)
