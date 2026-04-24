# Shinyngs Studio Environment

This branch contains the Seqera Studios configuration for running the
[shinyngs](https://github.com/pinin4fjords/shinyngs) RNA-seq exploration app as
a standalone Shiny application in Seqera Platform.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples)
> repository. Each branch contains a different custom Studio configuration.
> See `master` for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `shinyngs`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.12 \
  -t shinyngs-studio .

# Run without the connect-client entrypoint for local browser testing
docker run --rm --platform=linux/amd64 \
  -p 3838:3838 \
  -e CONNECT_TOOL_PORT=3838 \
  --entrypoint micromamba \
  shinyngs-studio \
  run -n shinyngs R -e \
  "shiny::runApp('/app', host='0.0.0.0', port=as.integer(Sys.getenv('CONNECT_TOOL_PORT')))"
```

Then open http://localhost:3838.

## What's in the image

- `r-shinyngs` from Bioconda, installed into a micromamba env named `shinyngs`
- `connect-client` 0.12 for Studios session bootstrapping
- A baked-in RNA-seq demo app generated at build time from the bundled
  `SRP254919` test dataset via `shinyngs`'s `make_app_from_files.R`, producing
  `/app/app.R` and `/app/data.rds`

## Customising the data

To swap in your own dataset, replace the files under `.seqera/` with your own
expression matrix, sample metadata, feature metadata, contrasts, and
differential-results TSVs, then rebuild. See `shinyngs`'s
`make_app_from_files.R --help` for input schema.

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [shinyngs](https://github.com/pinin4fjords/shinyngs)
