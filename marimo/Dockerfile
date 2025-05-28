# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Choose a python version that you know works with your application
FROM python:3.11-slim

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# Install uv for fast package management
COPY --from=ghcr.io/astral-sh/uv:0.4.20 /uv /bin/uv

ENV UV_SYSTEM_PYTHON=1

WORKDIR /app

# Install the requirements using uv
RUN uv pip install scikit-learn pandas altair micropip marimo==0.11.13

# Define the port for the marimo server
EXPOSE $CONNECT_TOOL_PORT

COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /bin/sh -c "/usr/bin/connect-client --install"
RUN echo "deb http://deb.debian.org/debian bookworm-backports main contrib non-free-firmware" | tee -a /etc/apt/sources.list
RUN apt update && apt install -y btrfs-progs=6.14-1~bpo12+1
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

CMD marimo edit -p $CONNECT_TOOL_PORT --no-token
