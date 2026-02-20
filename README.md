# Shiny Studio Environment

This branch contains the Seqera Studios configuration for running an [R Shiny](https://shiny.rstudio.com/) application in Seqera Platform, demonstrating interactive data visualization capabilities.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `shiny`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/shiny:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Advanced data visualization with multiple plot types (scatter, line, bar, box, density)
- Interactive controls and color themes (default, viridis, brewer blues, brewer reds)
- Efficient package management with micromamba
- Configurable data path via environment variables
- Cloud storage path support with automatic translation to local Studio paths

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/shiny:latest
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `DATA_PATH` | `s3://shiny-inputs/data.csv` | Path to CSV data file |
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

## Cloud Storage Path Translation

The application automatically converts cloud storage paths to local Studio paths:

- **Amazon S3**: `s3://bucket/path/to/data.csv` -> `/workspace/data/bucket/path/to/data.csv`
- **Google Cloud Storage**: `gs://bucket/path/to/data.csv` -> `/workspace/data/bucket/path/to/data.csv`
- **Azure Blob Storage**: `az://container/path/to/data.csv` -> `/workspace/data/container/path/to/data.csv`

> **Note:** Ensure the corresponding cloud storage buckets are mounted in your Studio via the **Mount data** option.

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t shiny-studio .
```

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [R Shiny Documentation](https://shiny.rstudio.com/)
- [Micromamba Documentation](https://mamba.readthedocs.io/)
