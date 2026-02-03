# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.9
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) KasmVNC base image with CellProfiler
# ---------------------------------------------------------------
FROM lscr.io/linuxserver/baseimage-kasmvnc:ubuntujammy

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="CellProfiler"

# KasmVNC Performance Optimizations
ENV KASM_VNC_ENABLE_WEBP=1
ENV KASM_VNC_JPEG_QUALITY=5
ENV KASM_VNC_MAX_FRAME_RATE=30
ENV KASM_VNC_THREADS=4

# Install system dependencies for CellProfiler
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-dev \
    python3-pip \
    build-essential \
    default-jdk \
    libgtk-3-0 \
    libgtk-3-dev \
    libmysqlclient-dev \
    libnotify4 \
    libsdl2-2.0-0 \
    libsm6 \
    libgl1 \
    libglib2.0-0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME for CellProfiler
ENV JAVA_HOME=/usr/lib/jvm/default-java

# Install CellProfiler with compatible dependencies
# Upgrade pip first to ensure it finds pre-built wheels (e.g., wxPython)
# Pin numpy<2 to avoid scikit-learn build issues with numpy 2.x
RUN pip3 install --no-cache-dir --upgrade pip setuptools wheel && \
    pip3 install --no-cache-dir "numpy<2" scikit-learn && \
    pip3 install --no-cache-dir cellprofiler

# Single-app mode: application launches directly, no desktop
RUN echo "cellprofiler" > /defaults/autostart

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
