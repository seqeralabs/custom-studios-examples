# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) KasmVNC base image with napari
# ---------------------------------------------------------------
FROM lscr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="napari"

# Napari renders through Qt/VisPy. Force Mesa software rendering when Studio
# compute does not expose a GPU, while keeping KasmVNC settings overridable.
ENV QT_API=pyqt6 \
    QT_X11_NO_MITSHM=1 \
    LIBGL_ALWAYS_SOFTWARE=1 \
    MAMBA_ROOT_PREFIX=/opt/conda \
    KASMVNC_FRAME_RATE=30 \
    KASMVNC_RECT_THREADS=4 \
    KASMVNC_DYNAMIC_QUALITY_MIN=7 \
    KASMVNC_DYNAMIC_QUALITY_MAX=8

# Install dependencies for napari. The base image can carry stale third-party apt
# sources, so drop NodeSource before refreshing Ubuntu package indexes.
RUN rm -f /etc/apt/sources.list.d/nodesource*.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    bzip2 \
    ca-certificates \
    wget \
    libgl1 \
    libegl1 \
    fontconfig \
    libglib2.0-0 \
    libxkbcommon-x11-0 \
    libxcb-cursor0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install napari and its Qt backend in an isolated Python 3.11 environment.
ARG NAPARI_VERSION="0.8.0"
RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
    | tar -xj --strip-components=1 bin/micromamba \
    && mv micromamba /usr/local/bin/micromamba \
    && micromamba create -y -n napari -c conda-forge \
        python=3.11 \
        napari=${NAPARI_VERSION} \
        pyqt6 \
    && micromamba clean --all --yes

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
RUN echo "/opt/conda/envs/napari/bin/napari" > /defaults/autostart

# ---------------------------------------------------------------
# 3) Seqera Studios integration
# ---------------------------------------------------------------

# Add connect-client version label to image for supported capabilities tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

# Copy connect-client from the first stage
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# Install connect-client. It writes under /config as root during the image build;
# restore ownership for the LinuxServer desktop user before runtime.
RUN /usr/bin/connect-client --install \
    && chown -R abc:abc /config /defaults

# Seqera Studios entrypoint (connect-client handles Fusion filesystem)
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Keep KasmVNC on an internal port and expose CONNECT_TOOL_PORT through the
# startup proxy so the first browser request receives a loading page, not 502.
CMD ["/bin/bash", "-c", "set -euo pipefail; export STUDIO_PROXY_PORT=${CONNECT_TOOL_PORT:-8080}; export KASMVNC_UPSTREAM_PORT=${KASMVNC_UPSTREAM_PORT:-3000}; if [ \"$STUDIO_PROXY_PORT\" = \"$KASMVNC_UPSTREAM_PORT\" ]; then export KASMVNC_UPSTREAM_PORT=3002; fi; export CUSTOM_PORT=\"$KASMVNC_UPSTREAM_PORT\"; export CUSTOM_HTTPS_PORT=${CUSTOM_HTTPS_PORT:-3001}; if [ \"$CUSTOM_HTTPS_PORT\" = \"$STUDIO_PROXY_PORT\" ] || [ \"$CUSTOM_HTTPS_PORT\" = \"$CUSTOM_PORT\" ]; then export CUSTOM_HTTPS_PORT=3003; fi; exec /init"]
