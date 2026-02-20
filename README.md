# Streamlit Studio Environment

This branch contains the Seqera Studios configuration for running a [Streamlit](https://streamlit.io/) application with MultiQC visualization in Seqera Platform.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `streamlit`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/streamlit:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Streamlit-based MultiQC visualization platform
- Interactive data analysis and visualization
- Python 3.11-based environment
- Supports URL, local file, and server path data loading

## Docker Image

The container image is available at:
```
ghcr.io/seqeralabs/custom-studios-examples/streamlit:latest
```

## Data Loading Options

The MultiQC Streamlit app supports three data loading methods:
- **URL**: Load data directly from a web URL
- **Local Files**: Access files from your local machine
- **Server Paths**: Load files from S3 via Fusion

When using Server Paths with data links:
1. Upload your MultiQC data (e.g., `data.zip`) to your S3 bucket
2. Create a data link pointing to that S3 path
3. The data will be available at `/workspace/data/<data-link-name>/data.zip`

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECT_TOOL_PORT` | Set by platform | Server port |

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t streamlit-studio .
```

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Streamlit Documentation](https://docs.streamlit.io/)
- [MultiQC Documentation](https://multiqc.info/)
