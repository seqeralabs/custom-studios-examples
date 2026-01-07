# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
# renovate: datasource=docker depName=public.cr.seqera.io/platform/connect-client
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Additional base image for Streamlit
# ---------------------------------------------------------------
FROM python:3.11-slim

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

WORKDIR /app

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Remove any existing directory and clone fresh
RUN rm -rf /app/* && git clone https://github.com/MultiQC/example-streamlit .

RUN pip3 install -r requirements.txt

EXPOSE $CONNECT_TOOL_PORT

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# "Install" connect-client (sets up any needed config)
RUN /usr/bin/connect-client --install

# ---------------------------------------------------------------
# 3) Launch with connect-client --entrypoint (for Tower)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Add backports repository and install specific btrfs-progs version
RUN echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free-firmware" | tee -a /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --allow-downgrades btrfs-progs=6.14-1~bpo12+1

# ---------------------------------------------------------------
# 4) Command: Run Streamlit MultiQC application
# ---------------------------------------------------------------
# The port is set by CONNECT_TOOL_PORT environment variable
CMD streamlit run /app/multiqc_app.py \
    --server.port=$CONNECT_TOOL_PORT \
    --server.address=0.0.0.0 \
    --server.enableCORS=false \
    --server.enableXsrfProtection=false \
    --server.enableWebsocketCompression=false \
    --browser.gatherUsageStats=false