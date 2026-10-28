# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.12
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Final image
FROM ubuntu:24.04

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bash \
        ca-certificates \
        curl \
        git \
        less \
        vim-tiny && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Studios run linux/amd64; arm64 is supported for local testing on ARM hosts.
ARG TARGETARCH

# Install TTYD binary (web terminal served on CONNECT_TOOL_PORT)
RUN case "${TARGETARCH}" in arm64) ttyd_arch=aarch64 ;; *) ttyd_arch=x86_64 ;; esac && \
    curl -fsSL -o /usr/local/bin/ttyd \
        "https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.${ttyd_arch}" && \
    chmod +x /usr/local/bin/ttyd

# Install Rex from its public release archive, pinned by commit and checksum.
# List releases with: curl -fsS https://blob.superlogical.com/api/releases/rex/snapshot
ARG REX_CHANNEL=snapshot
ARG REX_COMMIT=ac26dc62e1e92cc2e4eabde482e5400cf9a97961
ARG REX_SHA256_AMD64=479edf62100b0e781763a781dbf83030095fa30d20ad86c2b128a80f159700fe
ARG REX_SHA256_ARM64=1cbd9b6d4ec78fc2f5e059bde14991a5b0edad29c95d9d46e24a1f2ff3bc5e25
RUN case "${TARGETARCH}" in arm64) arch=arm64 sha="${REX_SHA256_ARM64}" ;; *) arch=amd64 sha="${REX_SHA256_AMD64}" ;; esac && \
    curl -fsSL -o /tmp/rex.tar.gz \
        "https://blob.superlogical.com/download/rex/${REX_CHANNEL}/${REX_COMMIT}/rex-linux-${arch}.tar.gz" && \
    echo "${sha}  /tmp/rex.tar.gz" | sha256sum -c - && \
    tar -xzf /tmp/rex.tar.gz -C /tmp rex && \
    install -m 0755 /tmp/rex /usr/local/bin/rex && \
    rm -f /tmp/rex.tar.gz /tmp/rex

COPY start-rex-studio.sh /usr/local/bin/start-rex-studio.sh
RUN chmod +x /usr/local/bin/start-rex-studio.sh

# Add connect-client version label to image for supported capabilties tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy Connect binary and install dependencies
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Set connect as the entrypoint
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Start the Rex server, then a writable web terminal on the Studio port
CMD ["/usr/local/bin/start-rex-studio.sh"]
