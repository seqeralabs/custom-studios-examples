# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) KasmVNC base image with Fiji
# ---------------------------------------------------------------
FROM lscr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="Fiji"

# The remote desktop follows the browser size. Keep KasmVNC settings
# overridable for different Studio compute environments.
ENV KASMVNC_FRAME_RATE=30 \
    KASMVNC_RECT_THREADS=4 \
    KASMVNC_DYNAMIC_QUALITY_MIN=7 \
    KASMVNC_DYNAMIC_QUALITY_MAX=8

# Install dependencies for Fiji. The base image can carry stale third-party apt
# sources, so drop NodeSource before refreshing Ubuntu package indexes.
RUN rm -f /etc/apt/sources.list.d/nodesource*.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    wget \
    unzip \
    libgl1 \
    libgtk-3-0 \
    fontconfig \
    libglib2.0-0 \
    libxtst6 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install pinned Fiji stable distribution with bundled Java runtime.
ARG FIJI_BUILD="20260307-1417"
RUN wget -q "https://downloads.imagej.net/fiji/archive/stable/${FIJI_BUILD}/fiji-stable-linux64-jdk.zip" -O /tmp/fiji.zip \
    && wget -q "https://downloads.imagej.net/fiji/archive/stable/${FIJI_BUILD}/fiji-stable-linux64-jdk.zip.sha256" -O /tmp/fiji.zip.sha256 \
    && echo "$(cat /tmp/fiji.zip.sha256)  /tmp/fiji.zip" | sha256sum -c - \
    && mkdir -p /opt/fiji \
    && unzip -q /tmp/fiji.zip -d /opt/fiji \
    && chmod +x /opt/fiji/Fiji.app/ImageJ-linux64 \
    && chown -R abc:abc /opt/fiji \
    && rm /tmp/fiji.zip /tmp/fiji.zip.sha256

# Override the base image's KasmVNC service with settings it actually consumes.
COPY kasmvnc-run /etc/s6-overlay/s6-rc.d/svc-kasmvnc/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-kasmvnc/run

# Start a Studio-facing proxy as soon as s6 launches. KasmVNC takes a short time
# to warm up, and this keeps first-time connections from seeing a platform 502.
RUN mkdir -p /etc/s6-overlay/s6-rc.d/svc-studio-proxy
COPY studio-proxy-run /etc/s6-overlay/s6-rc.d/svc-studio-proxy/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-studio-proxy/run \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/svc-studio-proxy/type \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-studio-proxy

# Single-app mode: application launches directly, no desktop.
RUN echo "/opt/fiji/Fiji.app/ImageJ-linux64" > /defaults/autostart

# ---------------------------------------------------------------
# 3) Seqera Studios integration
# ---------------------------------------------------------------

# Add connect-client version label to image for supported capabilities tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# Install connect-client
RUN /usr/bin/connect-client --install

# Seqera Studios entrypoint (connect-client handles Fusion filesystem)
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Keep KasmVNC on an internal port and expose CONNECT_TOOL_PORT through the
# startup proxy so the first browser request receives a loading page, not 502.
CMD ["/bin/bash", "-c", "set -euo pipefail; export STUDIO_PROXY_PORT=${CONNECT_TOOL_PORT:-6901}; export KASMVNC_UPSTREAM_PORT=${KASMVNC_UPSTREAM_PORT:-3000}; if [ \"$STUDIO_PROXY_PORT\" = \"$KASMVNC_UPSTREAM_PORT\" ]; then export KASMVNC_UPSTREAM_PORT=3002; fi; export CUSTOM_PORT=\"$KASMVNC_UPSTREAM_PORT\"; export CUSTOM_HTTPS_PORT=${CUSTOM_HTTPS_PORT:-3001}; if [ \"$CUSTOM_HTTPS_PORT\" = \"$STUDIO_PROXY_PORT\" ] || [ \"$CUSTOM_HTTPS_PORT\" = \"$CUSTOM_PORT\" ]; then export CUSTOM_HTTPS_PORT=3003; fi; exec /init"]
