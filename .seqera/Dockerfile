# Copyright 2023-2026, Seqera Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
# renovate: datasource=docker depName=public.cr.seqera.io/platform/connect-client
ARG CONNECT_CLIENT_VERSION=0.15
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
# renovate: datasource=pypi depName=cellxgene
RUN pip install cellxgene==1.3.0

# Demo dataset, used when the dataset DATASET_FILE points to is not found (e.g. no data mounted).
# pbmc3k.h5ad from the cellxgene project's example data, pinned to the 1.3.0 tag and a checksum.
RUN mkdir -p /opt/cellxgene-demo && \
    wget -nv -O /opt/cellxgene-demo/pbmc3k.h5ad \
      https://raw.githubusercontent.com/chanzuckerberg/cellxgene/1.3.0/example-dataset/pbmc3k.h5ad && \
    echo "0db367b991dd95809732b218539ede489bea99113807f62ebd7ccc970025fe38  /opt/cellxgene-demo/pbmc3k.h5ad" | sha256sum -c -

# Define CellxGene dataset path and title with defaults
ENV DATASET_FILE=s3://cellxgene_datasets/pbmc3k.h5ad
ENV DATASET_TITLE="PBMCs 3k test dataset"
ENV USER_DATA_DIR=/user-data/cellxgene
ENV ANNOTATIONS_DIR=/user-data/cellxgene

# Create user-data directory
RUN mkdir -p /user-data/cellxgene

# Add connect-client version label to image for supported capabilties tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

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
CMD ["/bin/bash", "-c", "bash <<'EOF'\n\
# Function to convert cloud storage path to local Studio path\n\
convert_path() {\n\
  local input_path=\"$1\"\n\
  if [[ \"$input_path\" =~ ^(s3|gs|az):// ]]; then\n\
    local cloud_path=${input_path#*://}\n\
    local bucket_name=${cloud_path%%/*}\n\
    local object_path=${cloud_path#*/}\n\
    echo \"/workspace/data/$bucket_name/$object_path\"\n\
  else\n\
    echo \"$input_path\"\n\
  fi\n\
}\n\
\n\
DATASET_LOCAL=$(convert_path \"${DATASET_FILE}\")\n\
USERDATA_LOCAL=$(convert_path \"${USER_DATA_DIR}\")\n\
ANNOTATIONS_LOCAL=$(convert_path \"${ANNOTATIONS_DIR}\")\n\
\n\
# With no dataset at that path (e.g. no data mounted), start on the demo dataset in the image\n\
if [[ \"${DATASET_LOCAL}\" != *://* && ! -e \"${DATASET_LOCAL}\" ]]; then\n\
  echo \"[cellxgene-studio] Dataset not found: ${DATASET_LOCAL} (DATASET_FILE=${DATASET_FILE}).\"\n\
  echo \"[cellxgene-studio] Starting on the demo dataset /opt/cellxgene-demo/pbmc3k.h5ad instead.\"\n\
  echo \"[cellxgene-studio] To open your own data, mount the data-link that holds it (Mount data) and set the environment variable DATASET_FILE to the .h5ad file: /workspace/data/<data-link name>/<path>, or s3://<bucket>/<path> (also gs://, az://), which is read from /workspace/data/<bucket>/<path>.\"\n\
  DATASET_LOCAL=/opt/cellxgene-demo/pbmc3k.h5ad\n\
  DATASET_TITLE=\"PBMC 3k demo dataset\"\n\
fi\n\
\n\
# A directory that cannot be created (e.g. its data-link is not mounted) falls back to the one in the image\n\
ensure_dir() {\n\
  if mkdir -p \"$2\"; then\n\
    echo \"$2\"\n\
  else\n\
    echo \"[cellxgene-studio] $1: cannot create $2 (is its data-link mounted?). Using /user-data/cellxgene inside the Studio instead.\" >&2\n\
    echo \"/user-data/cellxgene\"\n\
  fi\n\
}\n\
\n\
USERDATA_LOCAL=$(ensure_dir USER_DATA_DIR \"${USERDATA_LOCAL}\")\n\
ANNOTATIONS_LOCAL=$(ensure_dir ANNOTATIONS_DIR \"${ANNOTATIONS_LOCAL}\")\n\
\n\
/usr/local/bin/cellxgene launch --host 0.0.0.0 --port ${CONNECT_TOOL_PORT} \\\n\
  --user-generated-data-dir \"${USERDATA_LOCAL}\" \\\n\
  --annotations-dir \"${ANNOTATIONS_LOCAL}\" \\\n\
  --title \"${DATASET_TITLE}\" \"${DATASET_LOCAL}\"\n\
EOF"]
