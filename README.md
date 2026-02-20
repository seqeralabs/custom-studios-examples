# Custom Studios Examples

Example configurations for deploying custom [Seqera Studio](https://docs.seqera.io/platform-cloud/studios/overview) applications from a Git repository.

> **Do not merge studio configurations into `master`!** Each studio has its own dedicated branch.

## Repository Structure

This repository uses a **branch-per-studio** model (similar to [nf-core/test-datasets](https://github.com/nf-core/test-datasets)). The `master` branch contains only this documentation. Each studio's configuration lives on its own branch with a `.seqera/` directory containing the `studio-config.yaml` and `Dockerfile` required for [launching Studios from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo).

## Available Studios

| Branch | Studio | Description |
|--------|--------|-------------|
| [`marimo`](https://github.com/seqeralabs/custom-studios-examples/tree/marimo) | Marimo | Reactive Python notebook environment |
| [`cellxgene`](https://github.com/seqeralabs/custom-studios-examples/tree/cellxgene) | CellxGene | Interactive single-cell data visualization |
| [`streamlit`](https://github.com/seqeralabs/custom-studios-examples/tree/streamlit) | Streamlit | MultiQC visualization using Streamlit |
| [`shiny`](https://github.com/seqeralabs/custom-studios-examples/tree/shiny) | R Shiny | Interactive data visualization with R Shiny |
| [`ttyd`](https://github.com/seqeralabs/custom-studios-examples/tree/ttyd) | TTYD | Web-based terminal with bioinformatics tools |

## Quick Start: Launch from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select the branch for the studio you want (e.g., `marimo`, `cellxgene`, `streamlit`, `shiny`, `ttyd`)
5. Select your compute environment
6. Click **Add** then **Start**

Each branch contains a `.seqera/` directory with:
- `studio-config.yaml` — Studio configuration pointing to the Dockerfile
- `Dockerfile` — Container definition with connect-client integration
- Any supporting files required by the Dockerfile

## Alternative Deployment: Pre-built Images

Each studio is also available as a pre-built container image:

```
ghcr.io/seqeralabs/custom-studios-examples/marimo:latest
ghcr.io/seqeralabs/custom-studios-examples/cellxgene:latest
ghcr.io/seqeralabs/custom-studios-examples/streamlit:latest
ghcr.io/seqeralabs/custom-studios-examples/shiny:latest
ghcr.io/seqeralabs/custom-studios-examples/ttyd:latest
```

To use a pre-built image, select **Prebuilt container image** instead of **Git repository** when adding a Studio.

## Alternative Deployment: Wave CLI

You can also build any studio with the [Wave CLI](https://docs.seqera.io/wave/):

```bash
# Clone only the branch you need
git clone https://github.com/seqeralabs/custom-studios-examples.git --single-branch --branch <studio-name>

# Build with Wave
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Cloning a Specific Studio

Due to the branch-per-studio model, we recommend cloning only the branch you need:

```bash
git clone https://github.com/seqeralabs/custom-studios-examples.git --single-branch --branch <studio-name>
```

To add another branch later:

```bash
git remote set-branches --add origin <studio-name>
git fetch
```

## Environment Variables

Some studios support environment variable configuration:

| Studio | Variable | Default | Description |
|--------|----------|---------|-------------|
| CellxGene | `DATASET_FILE` | `s3://cellxgene_datasets/pbmc3k.h5ad` | Path to .h5ad dataset |
| CellxGene | `DATASET_TITLE` | `PBMCs 3k test dataset` | Display title |
| CellxGene | `USER_DATA_DIR` | `/user-data/cellxgene` | User data storage |
| CellxGene | `ANNOTATIONS_DIR` | `/user-data/cellxgene` | Annotations storage |
| Shiny | `DATA_PATH` | `s3://shiny-inputs/data.csv` | Path to CSV data file |

Studios without listed variables (Marimo, Streamlit, TTYD) work with their default configurations.

## Common Features

All studios in this repository:
- Use the `.seqera/` directory convention for Git-based Studio deployment
- Include the required Seqera `connect-client` for platform integration
- Support data mounting via datalinks in Studios
- Are built for `linux/amd64` platform compatibility
- Use multi-stage Docker builds with connect-client

## Documentation

- [Add a Studio from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Custom studio environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wave CLI](https://docs.seqera.io/wave/)
- [Deploying custom applications in Seqera Studios](https://seqera.io/blog/deploy-custom-apps-studios/)

## Contributing

To add a new studio:

1. Create a new branch from an empty root (orphan branch): `git checkout --orphan <studio-name>`
2. Add a `.seqera/` directory with `studio-config.yaml` and `Dockerfile`
3. Add a `README.md` documenting the studio
4. Push the branch
5. Update this README on `master` to list the new studio
