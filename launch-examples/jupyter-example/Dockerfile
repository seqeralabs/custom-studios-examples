# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.8
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Additional base image
# ---------------------------------------------------------------
FROM python:3.11-slim

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# ---------------------------------------------------------------
# 3) Set the work dir
# ---------------------------------------------------------------
WORKDIR /app

# ---------------------------------------------------------------
# 4) Copy the intialization script and make it executable
# ---------------------------------------------------------------
COPY ./_start_jupyter.sh /init
RUN chmod +x /init

# ---------------------------------------------------------------
# 5) Expose the port
# ---------------------------------------------------------------
EXPOSE $CONNECT_TOOL_PORT

# ---------------------------------------------------------------
# 6) Copy connect-client from the first stage
# ---------------------------------------------------------------
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# ---------------------------------------------------------------
# 7) "Install" connect-client (sets up any needed config)
# ---------------------------------------------------------------
RUN /usr/bin/connect-client --install

# ---------------------------------------------------------------
# 8) Launch with connect-client --entrypoint (for Tower)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# ---------------------------------------------------------------
# 9) Execute the JupyterLab initialization script (port listener, etc)
# ---------------------------------------------------------------
CMD [ "/usr/bin/bash", "-c", "/init"]