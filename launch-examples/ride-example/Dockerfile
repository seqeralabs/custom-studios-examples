# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.8
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Additional base images
# ---------------------------------------------------------------
FROM mambaorg/micromamba:1.5.10-noble as micromamba

FROM ubuntu:24.04

# Just for the automation at Seqera
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# ---------------------------------------------------------------
# 3) Define ARGS and ENV variables
# ---------------------------------------------------------------
ARG TARGETARCH

ARG RSTUDIO_VERSION=2024.12.1-563
ARG MAMBA_USER=root
ARG MAMBA_USER_ID=0
ARG MAMBA_USER_GID=0
ARG MAMBA_DOCKERFILE_ACTIVATE=1
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"
USER $MAMBA_USER
ENV USER=$MAMBA_USER

# ---------------------------------------------------------------
# 4) Install the required packages
# ---------------------------------------------------------------
RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    ca-certificates \
    wget \
    curl \
    git \
    sudo \
    libssl-dev \
    libclang-dev \
    lsb-release \
    psmisc \
    gdebi-core \
    gettext-base \
    nginx && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------
# 5) Install Seqera distro of R-IDE server
# ---------------------------------------------------------------
RUN if [ ${TARGETARCH} = "arm64" ]; then \
      wget https://github.com/seqeralabs/r-ide/releases/download/seqera-v2025.05.0%2B496/arm64.deb -O ride.deb; \
    elif [ ${TARGETARCH} = "amd64" ]; then \
      wget https://github.com/seqeralabs/r-ide/releases/download/seqera-v2025.05.0%2B496/amd64.deb -O ride.deb; \
    else \
      echo "Unsupported architecture: ${TARGETARCH}" && exit 1; \
    fi && \
    gdebi -n ride.deb && \
    rm ride.deb

# ---------------------------------------------------------------
# 6) Micromamba setup
# ---------------------------------------------------------------
COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_entrypoint.sh /usr/local/bin/_entrypoint.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

# ---------------------------------------------------------------
# 7) Initialize user accounts and setup root prefix
# ---------------------------------------------------------------
RUN micromamba shell init --shell bash && \
    /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh

# ---------------------------------------------------------------
# 8) Install additional libs
# ---------------------------------------------------------------
COPY --chown=$MAMBA_USER:$MAMBA_USER ./docker/ride_2025.04.1/env.yaml /tmp/env.yaml
RUN ulimit -n 262144 && \
    micromamba install --yes --file /tmp/env.yaml && \
    micromamba clean --all --yes \
    && rm -f /tmp/env.yaml

# ---------------------------------------------------------------
# 9) Setup RStudio configuration
# ---------------------------------------------------------------
COPY ./docker/ride_2025.04.1/init /init
COPY ./docker/ride_2025.04.1/rserver.conf /etc/rstudio/rserver.conf
COPY ./docker/ride_2025.04.1/rsession.conf /etc/rstudio/rsession.conf
COPY ./docker/ride_2025.04.1/logging.conf /etc/rstudio/logging.conf
COPY ./docker/ride_2025.04.1/keybindings/editor_bindings.json /etc/rstudio/keybindings/editor_bindings.json
COPY ./docker/ride_2025.04.1/keybindings/rstudio_bindings.json /etc/rstudio/keybindings/rstudio_bindings.json
COPY ./docker/ride_2025.04.1/keybindings/addins.json /etc/rstudio/keybindings/addins.json
COPY ./docker/ride_2025.04.1/Renviron /root/rstudio/.Renviron

# ---------------------------------------------------------------
# 10) Make initialization executable
# ---------------------------------------------------------------
RUN chmod +x /init

# ---------------------------------------------------------------
# 11) Configure directories and shell
# ---------------------------------------------------------------
RUN mkdir -p /workspace
SHELL ["/bin/bash", "-c"]

# ---------------------------------------------------------------
# 12) Copy connect-client from the first stage
# ---------------------------------------------------------------
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client

# ---------------------------------------------------------------
# 13) "Install" connect-client (sets up any needed config)
# ---------------------------------------------------------------
RUN /usr/bin/connect-client --install

# ---------------------------------------------------------------
# 14) Optionally set tool identifier for metrics tracking purposes
# ---------------------------------------------------------------
RUN /usr/bin/connect-client --setToolIdentifier custom

# ---------------------------------------------------------------
# 15) Launch with connect-client --entrypoint (for Tower)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# ---------------------------------------------------------------
# 16) Execute the JupyterLab initialization script (port listener, etc)
# ---------------------------------------------------------------
CMD [ "/usr/bin/bash", "-c", "/init"]