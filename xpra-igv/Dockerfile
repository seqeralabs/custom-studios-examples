# Add a default Connect client version. Can be overridden by build arg
ARG CONNECT_CLIENT_VERSION="0.8.1-snapshot"

# Path to the public connect-client
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

FROM mambaorg/micromamba:1.5.10-noble AS micromamba

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

ARG MAMBA_USER=root
ARG MAMBA_USER_ID=0
ARG MAMBA_USER_GID=0
ENV MAMBA_USER=$MAMBA_USER
ENV MAMBA_ROOT_PREFIX="/opt/conda"
ENV MAMBA_EXE="/bin/micromamba"

USER $MAMBA_USER

RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    apt-transport-https \
    pciutils \
    cups-filters \
    cups-common \
    cups-pdf \
    ca-certificates \
    git \
    wget \
    sudo \
    libatomic1 \
    python3.12 \
    python3-cups \
    python3-xdg \
    python3-pyinotify \
    python3-paramiko \
    python3-netifaces \
    python-is-python3 \
    gnome-menus \
    curl \
    locales \
    openjdk-17-jre \
    gnupg \
    kmod \
    x11-xkb-utils \
    dbus-x11 \
    xvfb \
    terminator && \
    thunar && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

COPY --from=micromamba "$MAMBA_EXE" "$MAMBA_EXE"
COPY --from=micromamba /usr/local/bin/_activate_current_env.sh /usr/local/bin/_activate_current_env.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_shell.sh /usr/local/bin/_dockerfile_shell.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_initialize_user_accounts.sh /usr/local/bin/_dockerfile_initialize_user_accounts.sh
COPY --from=micromamba /usr/local/bin/_dockerfile_setup_root_prefix.sh /usr/local/bin/_dockerfile_setup_root_prefix.sh

RUN /usr/local/bin/_dockerfile_initialize_user_accounts.sh && \
    /usr/local/bin/_dockerfile_setup_root_prefix.sh
SHELL ["/usr/local/bin/_dockerfile_shell.sh"]


# Install Xpra
RUN wget -O "/usr/share/keyrings/xpra.asc" https://xpra.org/xpra.asc && \
    wget -O "/etc/apt/sources.list.d/xpra.sources"  https://raw.githubusercontent.com/Xpra-org/xpra/master/packaging/repos/noble/xpra.sources

ARG xpra_version=6.2.0-r2-1
RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    xpra-html5 \
    xpra=${xpra_version} \
    xpra-client=${xpra_version} \
    xpra-client-gtk3=${xpra_version} \
    xpra-server=${xpra_version} \
    xpra-codecs=${xpra_version} \
    xpra-codecs-extras=${xpra_version} \
    xpra-common=${xpra_version} \
    xpra-x11=${xpra_version} && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

# Install IGV
ARG igv_version=IGV_Linux_2.19.4
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common \
    default-jre \
    unzip \
    lsof \
    glib-networking-common && \
    mkdir -p /igv && \
    cd /igv && \
    wget "https://data.broadinstitute.org/igv/projects/downloads/2.19/${igv_version}_WithJava.zip" && \
    unzip ${igv_version}_WithJava.zip && \
    cd ${igv_version} && \
    cd /usr/bin && \
    ln -s /igv/${igv_version}/igv.sh ./igv

# Copy the welcome message into the container and append it to the .bashrc
COPY ./docker/xpra_6.2.0-r2-1-igv_2.19.4/welcome_ASCII.txt /root/.welcome_ASCII.txt
RUN echo "cat /root/.welcome_ASCII.txt" >> /root/.bashrc
COPY ./docker/xpra_6.2.0-r2-1-igv_2.19.4/entry.sh /bin

COPY ./docker/xpra_6.2.0-r2-1-igv_2.19.4/seqera-wallpaper.png /usr/share/xpra/www/background.png

WORKDIR /workspace
RUN ln -s /workspace /root

# Add connect binary
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
# Install connect dependencies
RUN /usr/bin/connect-client --install
# Optionally set tool identifier for metrics tracking purposes
RUN /usr/bin/connect-client --setToolIdentifier custom

ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]
CMD ["bash",  "/bin/entry.sh"]
