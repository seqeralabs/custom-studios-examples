# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.8
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Additional base image for CellxGene
# ---------------------------------------------------------------
FROM python:3.10-slim

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# Avoid interactive prompts during package install
ENV DEBIAN_FRONTEND=noninteractive

# Add backports repository and install specific btrfs-progs version
RUN echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free-firmware" | tee -a /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y btrfs-progs=6.14-1~bpo12+1

# Update packages and install minimal tools
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    && rm -rf /var/lib/apt/lists/*

# Install CellxGene and its dependencies
RUN pip install cellxgene==1.3.0

# Define CellxGene dataset path and title with defaults
ENV DATASET_FILE=s3://cellxgene_datasets/pbmc3k.h5ad
ENV DATASET_TITLE="PBMCs 3k test dataset"

# Create user-data directory
RUN mkdir -p /user-data/cellxgene

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# "Install" connect-client (sets up any needed config)
RUN /usr/bin/connect-client --install

# ---------------------------------------------------------------
# 3) Launch with connect-client --entrypoint (for Tower)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# ---------------------------------------------------------------
# 4) Command: Run CellxGene with cloud storage path translation
# ---------------------------------------------------------------
# The port is set by CONNECT_TOOL_PORT environment variable
# Convert cloud storage paths to local Studio paths
CMD ["/bin/bash", "-c", "CLOUD_PATH=${DATASET_FILE#*://}; BUCKET_NAME=${CLOUD_PATH%%/*}; OBJECT_PATH=${CLOUD_PATH#*/}; LOCAL_PATH=\"/workspace/data/${BUCKET_NAME}/${OBJECT_PATH}\"; echo \"Converting cloud path ${DATASET_FILE} to local path ${LOCAL_PATH}\"; /usr/local/bin/cellxgene launch --host 0.0.0.0 --port ${CONNECT_TOOL_PORT} --user-generated-data-dir /user-data/cellxgene --annotations-dir /user-data/cellxgene --title \"${DATASET_TITLE}\" \"${LOCAL_PATH}\""]