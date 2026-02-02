# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) KasmVNC base image with QuPath
# ---------------------------------------------------------------
FROM lscr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="QuPath"

# KasmVNC Performance Optimizations
ENV KASM_VNC_ENABLE_WEBP=1
ENV KASM_VNC_JPEG_QUALITY=5
ENV KASM_VNC_MAX_FRAME_RATE=30
ENV KASM_VNC_THREADS=4

# Install dependencies for QuPath
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    xz-utils \
    libgl1 \
    libgtk-3-0 \
    libopenslide0 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install QuPath
ARG QUPATH_VERSION="0.6.0"
RUN wget -q https://github.com/qupath/qupath/releases/download/v${QUPATH_VERSION}/QuPath-v${QUPATH_VERSION}-Linux.tar.xz -O /tmp/qupath.tar.xz \
    && mkdir -p /opt/qupath \
    && tar -xf /tmp/qupath.tar.xz -C /opt/qupath --strip-components=1 \
    && chmod +x /opt/qupath/bin/QuPath \
    && rm /tmp/qupath.tar.xz

# Single-app mode: application launches directly, no desktop
RUN echo "/opt/qupath/bin/QuPath" > /defaults/autostart

# ---------------------------------------------------------------
# 3) Seqera Studios integration
# ---------------------------------------------------------------

# Add connect-client version label to image for supported capabilities tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# Install connect-client and set tool identifier
RUN /usr/bin/connect-client --install
RUN /usr/bin/connect-client --setToolIdentifier kasmvnc

# Seqera Studios entrypoint (connect-client handles fusion filesystem)
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# CMD bridges CONNECT_TOOL_PORT to KasmVNC's CUSTOM_PORT and launches the init
CMD ["/bin/bash", "-c", "export CUSTOM_PORT=${CONNECT_TOOL_PORT:-6901} && exec /init"]
