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

# renovate: datasource=docker depName=public.cr.seqera.io/platform/connect-client
ARG CONNECT_CLIENT_VERSION=0.14.0
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

FROM debian:trixie-slim

LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/root \
    XDG_CONFIG_HOME=/etc/xdg \
    WAYMOTE_WIDTH=1280 \
    WAYMOTE_HEIGHT=720 \
    WAYMOTE_FRAME_RATE=60 \
    WAYMOTE_BITRATE=12000 \
    WAYMOTE_XKB_LAYOUT=us

ARG WAYMOTE_VERSION=0.1.4
ARG WAYMOTE_SHA256=b8030f6518f9539d6b01d3da6b63089f737544d7db73562f4611b934f4df2b37

RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        ffmpeg \
        fonts-dejavu-core \
        foot \
        labwc \
        nginx \
        pcmanfm \
        pulseaudio \
        pulseaudio-utils \
        wayland-utils \
        wlr-randr \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/waymote.tgz \
        "https://github.com/rockorager/waymote/releases/download/v${WAYMOTE_VERSION}/waymote-server-${WAYMOTE_VERSION}-linux-x86_64.tar.gz" \
    && echo "${WAYMOTE_SHA256}  /tmp/waymote.tgz" | sha256sum -c - \
    && tar -xzf /tmp/waymote.tgz -C /tmp \
    && install -m 0755 /tmp/waymote-server-${WAYMOTE_VERSION}-linux-x86_64/bin/waymote-gateway /usr/local/bin/waymote-gateway \
    && install -m 0755 /tmp/waymote-server-${WAYMOTE_VERSION}-linux-x86_64/bin/waymote-streamd /usr/local/bin/waymote-streamd \
    && rm -rf /tmp/waymote.tgz /tmp/waymote-server-${WAYMOTE_VERSION}-linux-x86_64

COPY start-waymote /usr/local/bin/start-waymote
COPY labwc/ /etc/xdg/labwc/
COPY web/ /usr/local/share/waymote-studio/
COPY nginx.conf /etc/nginx/waymote.conf
COPY waymote-headers.conf /etc/nginx/waymote-headers.conf
# The browser shows its own cursor without network delay, so make every remote
# cursor transparent. Labwc, GTK and foot all load the Adwaita theme.
# transparent-cursor is a 1x1 Xcursor file with one fully transparent pixel.
COPY transparent-cursor /tmp/transparent-cursor
RUN chmod 0755 /usr/local/bin/start-waymote /etc/xdg/labwc/autostart \
    && mkdir -p /workspace \
    && for cursor in /usr/share/icons/Adwaita/cursors/*; do \
        rm -f "$cursor" && cp /tmp/transparent-cursor "$cursor"; \
    done \
    && rm /tmp/transparent-cursor

ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]
CMD ["/usr/local/bin/start-waymote"]
