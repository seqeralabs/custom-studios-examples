# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
# renovate: datasource=docker depName=public.cr.seqera.io/platform/connect-client
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Final image: Start from an arbitrary container
FROM community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# Set environment variables to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm

# Install extra dependencies and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install TTYD binary
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    && mv ttyd.x86_64 /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Add connect-client version label to image for supported capabilties tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy Connect binary and install dependencies
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Set connect as the entrypoint
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Default command to run TTYD with writable mode
CMD ["/usr/bin/bash", "-c", "ttyd -W -p $CONNECT_TOOL_PORT bash"]