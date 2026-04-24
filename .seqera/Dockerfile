# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.12
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Final stage: Ubuntu + micromamba + r-shinyngs
# ---------------------------------------------------------------
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    wget \
    ca-certificates \
    bzip2 \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------
# Install micromamba
# ---------------------------------------------------------------
ENV MAMBA_ROOT_PREFIX=/opt/conda
RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
  | tar -xvj --strip-components=1 bin/micromamba \
  && mv micromamba /usr/local/bin/micromamba \
  && mkdir -p /opt/conda \
  && chmod -R 777 /opt/conda

# ---------------------------------------------------------------
# Create a conda env with r-shinyngs (bioconda). r-markdown is
# explicitly loaded by app.R.
# ---------------------------------------------------------------
RUN rm -rf /opt/conda/pkgs/*.lock && \
    micromamba create -y -n shinyngs \
      -c conda-forge -c bioconda \
      r-shinyngs \
      r-markdown \
    && micromamba clean --all --yes \
    && rm -rf /opt/conda/pkgs/*.lock

# Add connect-client version label for Platform capability tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

WORKDIR /app

# Pre-built shinyngs app and its serialised dataset
COPY app.R data.rds /app/

# ---------------------------------------------------------------
# 3) Launch with connect-client --entrypoint (for Platform)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# The port is set by the CONNECT_TOOL_PORT environment variable.
# shinyngs must be attached before app.R is sourced (app.R calls
# prepareApp() without namespacing it). DT, shinyBS, plotly, shinyjs
# are also attached so their Shiny resource paths register with httpuv,
# otherwise widget JS/CSS (e.g. jquery.dataTables.min.js, sbs/shinyBS.css)
# 404 and tables/plots fail to render.
CMD ["micromamba", "run", "-n", "shinyngs", "R", "-e", "library(shinyngs); library(DT); library(shinyBS); library(plotly); library(shinyjs); shiny::runApp('/app', host='0.0.0.0', port=as.integer(Sys.getenv('CONNECT_TOOL_PORT')))"]
