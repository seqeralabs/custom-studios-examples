# ============================================================================
# Custom Studios Container for Flow Cytometry RShiny App
# ============================================================================

# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Final stage: Ubuntu + micromamba + R + Flow Cytometry packages
# ---------------------------------------------------------------
FROM ubuntu:22.04

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install minimal tools + build dependencies
RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    wget \
    ca-certificates \
    bzip2 \
    git \
    build-essential \
    libxml2-dev \
    libssl-dev \
    libcurl4-openssl-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
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
# Create conda environment with R, Shiny, and Bioconductor packages
# ---------------------------------------------------------------
RUN rm -rf /opt/conda/pkgs/*.lock && \
    micromamba create -y -n flowcyto \
    -c conda-forge \
    -c bioconda \
    r-base=4.3 \
    r-shiny \
    r-ggplot2 \
    r-hexbin \
    r-viridis \
    bioconductor-flowcore \
    bioconductor-flowworkspace \
    bioconductor-cytolib \
    bioconductor-ncdfflow \
    bioconductor-s4vectors \
    bioconductor-biocgenerics \
    && micromamba clean --all --yes \
    && rm -rf /opt/conda/pkgs/*.lock

# ---------------------------------------------------------------
# Verify core packages are installed
# ---------------------------------------------------------------
RUN micromamba run -n flowcyto R -e "\
    cat('Verifying R package installation...\n'); \
    packages <- c('shiny', 'ggplot2', 'flowCore', 'flowWorkspace'); \
    for(pkg in packages) { \
        if (!require(pkg, character.only = TRUE, quietly = TRUE)) { \
            stop(paste('Package', pkg, 'not found!')); \
        } \
    }; \
    cat('All required packages verified!\n'); \
    "

# Add connect-client version label to image for supported capabilities tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# "Install" connect-client (sets up any needed config)
RUN /usr/bin/connect-client --install

# Set a working directory for your app
WORKDIR /app

# Copy your Shiny app code
COPY app.R /app/

# ---------------------------------------------------------------
# 3) Launch with connect-client --entrypoint (for Seqera Platform)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# ---------------------------------------------------------------
# 4) Command: Run your Shiny app via micromamba
# ---------------------------------------------------------------
# The port is set by CONNECT_TOOL_PORT environment variable
CMD ["micromamba", "run", "-n", "flowcyto", "R", "-e", "shiny::runApp('/app/app.R', host='0.0.0.0', port=as.integer(Sys.getenv('CONNECT_TOOL_PORT')))"]
