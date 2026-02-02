ARG CONNECT_CLIENT_VERSION=0.9

FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

FROM mambaorg/micromamba:1.5.10-noble AS micromamba

FROM ubuntu:24.04


LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

ARG TARGETARCH

ARG MAMBA_USER=root
ARG MAMBA_USER_ID=0
ARG MAMBA_USER_GID=0
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"

USER $MAMBA_USER

RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    ca-certificates \
    git \
    wget \
    sudo \
    libatomic1 \
    curl \
    openjdk-17-jdk \
    openjdk-17-jre && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

RUN /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
# need to have lower ulimit given micromamba issue:
# https://github.com/mamba-org/micromamba-docker/issues/368#issuecomment-1706054594
# https://github.com/DaanDeMeyer/reproc/pull/103
RUN ulimit -n 262144 && \
    micromamba install --yes --file /tmp/env.yaml && \
    micromamba clean --all --yes

ARG MAMBA_DOCKERFILE_ACTIVATE=1

ARG VSCODE_RELEASE="v1.106.3"
ARG VSCODE_ROOT="/home/.vscode"

RUN if [ ${TARGETARCH} = "amd64" ]; then \
      ARCH="x64"; \
    elif [ ${TARGETARCH} = "arm64" ]; then \
      ARCH="arm64"; \
    else \
      echo "Unsupported architecture ${TARGETARCH}" && exit 1; \
    fi && \
    wget https://github.com/gitpod-io/openvscode-server/releases/download/openvscode-server-${VSCODE_RELEASE}/openvscode-server-${VSCODE_RELEASE}-linux-${ARCH}.tar.gz && \
    tar -xzf openvscode-server-${VSCODE_RELEASE}-linux-${ARCH}.tar.gz && \
    mv -f openvscode-server-${VSCODE_RELEASE}-linux-${ARCH} ${VSCODE_ROOT} && \
    cp ${VSCODE_ROOT}/bin/remote-cli/openvscode-server ${VSCODE_ROOT}/bin/remote-cli/code && \
    rm -f openvscode-server-${VSCODE_RELEASE}-linux-${ARCH}.tar.gz


# install docker
RUN install -m 0755 -d /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc && \
    chmod a+r /etc/apt/keyrings/docker.asc  && \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null && \
    apt-get update --yes && \
    apt-get install --yes docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
# patch service so that it can work inside docker
RUN sed -i 's/ulimit -Hn \([0-9]\+\)/ulimit -n \1/' /etc/init.d/docker # patch the

WORKDIR /workspace


# install nextflow
RUN curl -s https://get.nextflow.io | bash
RUN mkdir -p /workspace/.nextflow-bin && mv ./nextflow /workspace/.nextflow-bin/nextflow

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    HOME=/workspace \
    EDITOR=code \
    VISUAL=code \
    GIT_EDITOR="code --wait" \
    VSCODE_ROOT=${VSCODE_ROOT} \
    SHELL=bash \
    PATH=${PATH}:/workspace/.nextflow-bin

RUN ${VSCODE_ROOT}/bin/openvscode-server --install-extension nextflow.nextflow

# preheat nextflow
RUN nextflow help > /dev/null

COPY ./init /init

# Add connect binary
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
# Install connect dependencies
RUN /usr/bin/connect-client --install
# Optionally set tool identifier for metrics tracking purposes
RUN /usr/bin/connect-client --setToolIdentifier vscode

ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]
CMD ["/usr/bin/bash", "-c", "/init"]