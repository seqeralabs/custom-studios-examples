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

# KasmVNC Performance Optimizations
ENV KASM_VNC_ENABLE_WEBP=1
ENV KASM_VNC_JPEG_QUALITY=5
ENV KASM_VNC_MAX_FRAME_RATE=30
ENV KASM_VNC_THREADS=4

# Install Python and system dependencies for napari
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 \
    python3.10-venv \
    python3-pip \
    libgl1 \
    libglib2.0-0 \
    libfontconfig1 \
    libxcb-icccm4 \
    libxcb-image0 \
    libxcb-keysyms1 \
    libxcb-randr0 \
    libxcb-render-util0 \
    libxcb-shape0 \
    libxcb-xinerama0 \
    libxcb-xkb1 \
    libxkbcommon-x11-0 \
    libdbus-1-3 \
    libegl1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install napari with PyQt5 backend
RUN pip3 install --no-cache-dir "napari[all]" pyqt5

# Single-app mode: application launches directly, no desktop
RUN echo "napari" > /defaults/autostart

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

# Seqera Studios entrypoint (connect-client handles fusion filesystem)
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# CMD bridges CONNECT_TOOL_PORT to KasmVNC's CUSTOM_PORT and launches the init
CMD ["/bin/bash", "-c", "export CUSTOM_PORT=${CONNECT_TOOL_PORT:-6901} && exec /init"]
