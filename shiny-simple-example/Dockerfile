# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
FROM public.cr.seqera.io/platform/connect-client:0.8 AS connect

# ---------------------------------------------------------------
# 2) Final stage: Ubuntu + micromamba + r-shiny
# ---------------------------------------------------------------
FROM ubuntu:20.04

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Update packages and install minimal tools
RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    wget \
    ca-certificates \
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

# Create a conda env with shiny and additional R packages
RUN rm -rf /opt/conda/pkgs/*.lock && \
    micromamba create -y -n shiny -c conda-forge \
    r-shiny \
    r-ggplot2 \
    r-dplyr \
    && micromamba clean --all --yes \
    && rm -rf /opt/conda/pkgs/*.lock

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# "Install" connect-client (sets up any needed config)
RUN /usr/bin/connect-client --install

# Set a working directory for your app
WORKDIR /app

# Copy your Shiny code and data
COPY app_plot_demo.R /app/
COPY data.csv /app/

# ---------------------------------------------------------------
# 3) Launch with connect-client --entrypoint (for Tower)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# ---------------------------------------------------------------
# 4) Command: Run your Shiny app via micromamba
# ---------------------------------------------------------------
# The port is set by CONNECT_TOOL_PORT environment variable
CMD ["micromamba", "run", "-n", "shiny", "R", "-e", "shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=as.integer(Sys.getenv('CONNECT_TOOL_PORT')))"] 
