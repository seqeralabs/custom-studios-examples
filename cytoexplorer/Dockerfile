# ---------------------------------------------------------------
# CytoExploreR Studios - Interactive Flow Cytometry Analysis in R
# ---------------------------------------------------------------
# This Dockerfile creates a container for running CytoExploreR
# in Seqera Studios with RStudio Server web interface.
#
# Based on CytoExploreR's official Docker image and Seqera patterns
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Build from RStudio base image
# ---------------------------------------------------------------
FROM rocker/rstudio:latest

# Metadata for Seqera automation
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies for CytoExploreR
RUN apt-get update && apt-get install --no-install-recommends -y \
    libprotobuf-dev \
    autoconf \
    automake \
    libtool \
    libxml2-dev \
    libhdf5-dev \
    zlib1g-dev \
    libpng-dev \
    tcl \
    wget \
    unzip \
    make \
    g++ \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Download and install FFTW (required for FIt-SNE)
RUN wget http://www.fftw.org/fftw-3.3.8.tar.gz && \
    tar -zxvf fftw-3.3.8.tar.gz && \
    rm -rf fftw-3.3.8.tar.gz && \
    cd fftw-3.3.8 && \
    ./configure && \
    make && \
    make install && \
    cd / && \
    rm -rf fftw-3.3.8

# Install FIt-SNE (dimensionality reduction)
RUN cd / && \
    wget --no-check-certificate -O FIt-SNE.zip https://github.com/KlugerLab/FIt-SNE/archive/master.zip && \
    unzip FIt-SNE.zip && \
    rm -rf FIt-SNE.zip && \
    cd FIt-SNE-master && \
    g++ -std=c++11 -O3 src/sptree.cpp src/tsne.cpp src/nbodyfft.cpp -o bin/fast_tsne -pthread -lfftw3 -lm -Wno-address-of-packed-member && \
    cd / && \
    mv /FIt-SNE-master /home/rstudio/.FIt-SNE

# Install R package dependencies
RUN R -e "install.packages('remotes')" && \
    R -e "install.packages('latticeExtra')" && \
    R -e "install.packages('XML')" && \
    R -e "install.packages('BiocManager')" && \
    R -e "BiocManager::install('cytolib')" && \
    R -e "BiocManager::install('flowCore')" && \
    R -e "BiocManager::install('flowWorkspace')" && \
    R -e "BiocManager::install('flowClust')" && \
    R -e "BiocManager::install('openCyto')" && \
    R -e "BiocManager::install('CytoML')" && \
    R -e "remotes::install_github('DillonHammill/CytoExploreRData')" && \
    R -e "remotes::install_github('DillonHammill/flowAI')" && \
    R -e "remotes::install_github('exaexa/scattermore')" && \
    R -e "remotes::install_github('DillonHammill/CytoExploreR')"

# Setup workspace
WORKDIR /home/rstudio

# Add connect-client version label for capability tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# Install connect-client (sets up configuration)
RUN /usr/bin/connect-client --install

# Note: btrfs-progs is required by Seqera but rocker/rstudio (Ubuntu-based)
# doesn't support Debian backports. Installing whatever version is available.
RUN apt-get update && apt-get install -y btrfs-progs || true

# ---------------------------------------------------------------
# 3) Configure RStudio Server to use CONNECT_TOOL_PORT
# ---------------------------------------------------------------
# Create startup script that configures RStudio Server with the correct port
RUN echo '#!/bin/bash\n\
PORT=${CONNECT_TOOL_PORT:-8787}\n\
echo "Starting RStudio Server on port $PORT"\n\
echo "www-port=$PORT" > /etc/rstudio/rserver.conf\n\
echo "www-address=0.0.0.0" >> /etc/rstudio/rserver.conf\n\
/usr/lib/rstudio-server/bin/rserver --server-daemonize=0\n\
' > /usr/local/bin/start-rstudio.sh && \
    chmod +x /usr/local/bin/start-rstudio.sh

# ---------------------------------------------------------------
# 4) Launch with connect-client --entrypoint (for Seqera Platform)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# ---------------------------------------------------------------
# 5) Start RStudio Server
# ---------------------------------------------------------------
CMD ["/bin/bash", "/usr/local/bin/start-rstudio.sh"]
