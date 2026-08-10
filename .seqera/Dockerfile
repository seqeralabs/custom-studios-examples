# Copyright 2023-2026, Seqera Labs
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# KEEP THIS FILE UNDER 7500 BYTES. Platform base64-encodes it before handing it to Wave
# and rejects the build over 10000 encoded bytes ("Container file size exceeds the
# maximum allowed size of 10000 bytes"), which is 7500 raw. That is why the rationale
# for these instructions lives in ../README.md rather than in comments here.

ARG CONNECT_CLIENT_VERSION=0.12
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Debian, not ubuntu-xfce: on Ubuntu 25.10 every image decode goes through glycin, which
# needs a bwrap sandbox the container cannot grant, and the failure kills xfce4-panel.
FROM lscr.io/linuxserver/webtop:debian-xfce

LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="Selkies Debian XFCE Desktop"
ENV START_DOCKER="false"
ENV PIXELFLUX_WAYLAND="false"
ENV DISABLE_ZINK="true"
ENV DISABLE_DRI3="true"
ENV LC_ALL="C.UTF-8"

# MAX_RES is deliberately unset: svc-xorg uses it as the Xvfb screen size, so capping it
# strands the desktop in the corner of a larger browser window. Selkies applies DPI
# itself, so readable text comes from SELKIES_SCALING_DPI and not from Xft defaults.
ENV SELKIES_SCALING_DPI="144"

ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Drop webtop's HTTPS server block: Platform terminates TLS in front of the Studio.
# init-nginx rewrites 3000 then 3001, so CUSTOM_PORT must never be set to 3001.
RUN awk '/^server \{/{n++} n<2' /defaults/default.conf > /defaults/default.conf.http \
    && mv /defaults/default.conf.http /defaults/default.conf \
    && ! grep -q 3001 /defaults/default.conf

# mesa-utils is only for glxgears. default-jre-headless is Java 21 on trixie, which is
# what Nextflow needs; its postinst calls update-alternatives, which fails unless
# /usr/share/man/man1 exists, and the base image ships no man pages.
RUN mkdir -p /usr/share/man/man1 \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        mesa-utils \
        curl \
        wget \
        htop \
        default-jre-headless \
    && rm -rf /var/lib/apt/lists/* \
    && printf '%s\n' \
        '[Desktop Entry]' \
        'Type=Application' \
        'Name=GL Gears (stream benchmark)' \
        'Comment=Spinning gears with a frame-rate counter on stdout' \
        'Exec=xfce4-terminal --title="GL Gears" --command="glxgears -info"' \
        'Icon=utilities-system-monitor' \
        'Terminal=false' \
        'Categories=System;Monitor;' \
        > /usr/share/applications/glxgears.desktop

# Chromium cannot start under Studios without --no-sandbox; see chromium-studio-flags.
# The asserts fail the build if /usr/bin/chromium stops being Debian's launcher script,
# since a raw binary would ignore /etc/chromium.d and the browser would break silently.
COPY chromium-studio-flags /etc/chromium.d/zz-studio-flags
RUN test -f /etc/chromium.d/default-flags \
    && grep -q '/etc/chromium.d' /usr/bin/chromium \
    && grep -q 'CHROMIUM_FLAGS' /usr/bin/chromium \
    && sh -n /etc/chromium.d/zz-studio-flags

# NXF_HOME is shared and world-writable rather than under the desktop user's home: the
# launcher downloads its distribution on first run, and PUID/PGID are set at runtime, so
# a build-time chown would guess the wrong uid.
ENV NXF_HOME="/opt/nextflow"
RUN cd /usr/local/bin \
    && curl -s https://get.nextflow.io | bash \
    && chmod 0755 /usr/local/bin/nextflow \
    && mkdir -p "$NXF_HOME" \
    && chmod -R a+rX "$NXF_HOME" \
    && find "$NXF_HOME" -type d -exec chmod 1777 {} + \
    && su -s /bin/bash abc -c "nextflow -version"

# svc-nginx sweeps stale masters with pkill -f "[n]ginx:", which matches the studio proxy
# too and would unbind the Studio port while Platform probes it. Narrow the sweep to
# webtop's own master. The pattern must stay space-free: two call sites pass it unquoted.
RUN sed -i 's|\[n\]ginx:|[n]ginx:.*/usr/sbin/nginx|g' /etc/s6-overlay/s6-rc.d/svc-nginx/run \
    && grep -q 'pgrep -f "\[n\]ginx:\.\*/usr/sbin/nginx"' /etc/s6-overlay/s6-rc.d/svc-nginx/run \
    && ! grep -qE '\[n\]ginx:($|[^.])' /etc/s6-overlay/s6-rc.d/svc-nginx/run

# Bind the Studio port from the first moment s6 is up, ahead of the desktop. See
# studio-proxy-run for why webtop's own nginx cannot own CONNECT_TOOL_PORT.
RUN mkdir -p /etc/s6-overlay/s6-rc.d/svc-studio-proxy /etc/s6-overlay/s6-rc.d/user/contents.d
COPY studio-proxy-run /etc/s6-overlay/s6-rc.d/svc-studio-proxy/run
RUN chmod +x /etc/s6-overlay/s6-rc.d/svc-studio-proxy/run \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/svc-studio-proxy/type \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/svc-studio-proxy

COPY studio-entry /usr/local/bin/studio-entry
RUN chmod +x /usr/local/bin/studio-entry

# Where studio-entry writes /init's output so it outlives the terminated instance.
# ponytail: debug scaffolding, delete with the block in studio-entry.
ENV STUDIO_DEBUG_DIR="/fusion/s3/scidev-playground-eu-west-1"

ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

CMD ["/usr/local/bin/studio-entry"]
