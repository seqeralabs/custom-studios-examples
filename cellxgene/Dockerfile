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
ENV USER_DATA_DIR=/user-data/cellxgene
ENV ANNOTATIONS_DIR=/user-data/cellxgene

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
# Process dataset path\n\
DATASET_CLOUD=${DATASET_FILE#*://}\n\
DATASET_BUCKET=${DATASET_CLOUD%%/*}\n\
DATASET_OBJECT=${DATASET_CLOUD#*/}\n\
DATASET_LOCAL=\"/workspace/data/${DATASET_BUCKET}/${DATASET_OBJECT}\"\n\
\n\
# Process user data and annotations paths using the function\n\
USERDATA_LOCAL=$(convert_path \"${USER_DATA_DIR}\")\n\
ANNOTATIONS_LOCAL=$(convert_path \"${ANNOTATIONS_DIR}\")\n\
\n\
# Ensure directories exist\n\
mkdir -p \"${USERDATA_LOCAL}\" \"${ANNOTATIONS_LOCAL}\"\n\
\n\
# Launch cellxgene\n\
/usr/local/bin/cellxgene launch --host 0.0.0.0 --port ${CONNECT_TOOL_PORT} \\\n\
  --user-generated-data-dir \"${USERDATA_LOCAL}\" \\\n\
  --annotations-dir \"${ANNOTATIONS_LOCAL}\" \\\n\
  --title \"${DATASET_TITLE}\" \"${DATASET_LOCAL}\"\n\
EOF"]