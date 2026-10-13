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

### Alternative: Build Your Own Image

Build from `.seqera/Dockerfile` and push to a registry your organization controls, then use **Prebuilt container image** in Platform. CI on this branch builds and scans images in GitHub Actions only (nothing is published to GHCR). See [Local Testing](#local-testing) for a `docker build` example.

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
  "library(shinyngs); library(shinyBS); library(shinyjs); library(markdown); shiny::runApp('/app', host='0.0.0.0', port=as.integer(Sys.getenv('CONNECT_TOOL_PORT')))"
```

Then open http://localhost:3838.

## What's in the image

- `r-shinyngs` and `r-markdown` from Bioconda/conda-forge, installed into a
  micromamba env named `shinyngs`
- `connect-client` 0.12 for Studios session bootstrapping
- A pre-built shinyngs app for the `SRP254919` RNA-seq test dataset
  (`/app/app.R` + `/app/data.rds`, produced upstream with
  `shinyngs::make_app_from_files.R`)

## Temporary workarounds

The Dockerfile carries two small fixes flagged as `TEMPORARY:` that make
standalone Shiny apps render correctly behind the Studios iframe +
connect-client relay (attaching `shinyBS`/`shinyjs` so their resource paths
register, and patching `htmlwidgets.js` to await plugin scripts before the
widget binding runs). Both go away once
[pinin4fjords/shinyngs#92](https://github.com/pinin4fjords/shinyngs/pull/92)
ships via bioconda; the sed step is idempotent and will skip automatically
when upstream is already async.

## Customising the data

The app is built from five TSVs/CSVs fed to `shinyngs::make_app_from_files.R`
(expression matrix, sample metadata, feature metadata, contrasts,
differential-results). To swap in your own dataset, regenerate `app.R` +
`data.rds` on any machine with `r-shinyngs` installed and replace the files
under `.seqera/`, then rebuild. See `make_app_from_files.R --help` for the
full input schema.

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [shinyngs](https://github.com/pinin4fjords/shinyngs)
