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

ARG CONNECT_CLIENT_VERSION=0.12
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Debian rather than Ubuntu: the ubuntu-xfce flavor is built on Ubuntu 25.10, whose
# GTK3 and gdk-pixbuf route every image decode through glycin, which in turn decodes
# inside a "bwrap --unshare-all" sandbox. Containers do not get the privileges bwrap
# needs, so the loader exits non-zero and GTK aborts on a failed assertion — taking
# xfce4-panel and the first xfce4-session down with it and leaving a black desktop.
# The Debian flavor keeps the classic gdk-pixbuf loaders and needs no sandbox.
FROM lscr.io/linuxserver/webtop:debian-xfce

LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="Selkies Debian XFCE Desktop"
ENV START_DOCKER="false"
ENV PIXELFLUX_WAYLAND="false"
ENV DISABLE_ZINK="true"
ENV DISABLE_DRI3="true"
ENV LC_ALL="C.UTF-8"

# MAX_RES is deliberately unset. It does not "cap for efficiency" — svc-xorg uses it
# as the Xvfb virtual screen size, which is the ceiling RANDR can resize within, so
# setting 1920x1080 leaves the desktop stranded in the corner of any larger browser
# window. Webtop's own default is 15360x8640, which lets the desktop track the
# browser size. Selkies applies DPI itself (xfconf /Xft/DPI plus ~/.Xresources), so
# readable text on a large display comes from SELKIES_SCALING_DPI, not from Xft
# defaults, which selkies would overwrite with its own default of 96.
ENV SELKIES_SCALING_DPI="144"

ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Drop webtop's HTTPS server block from the nginx template. Platform terminates TLS
# in front of the Studio, so the internal listener is dead weight and its
# certificate generation is startup time spent on nothing. Note that init-nginx
# rewrites ports with two chained seds ("s/3000/$CUSTOM_PORT/" then
# "s/3001/$CUSTOM_HTTPS_PORT/"), so CUSTOM_PORT must never be set to 3001: it would
# be substituted twice and land both blocks on one port.
RUN awk '/^server \{/{n++} n<2' /defaults/default.conf > /defaults/default.conf.http \
    && mv /defaults/default.conf.http /defaults/default.conf \
    && ! grep -q 3001 /defaults/default.conf

# No wallpaper. Under Xvfb xfdesktop covers the root window with opaque black and
# ignores every /backdrop/... property it is given, and painting the root window
# instead means dropping xfdesktop along with the desktop icons and right-click menu.
# A plain black desktop is also the cheapest thing to stream: a still, uniform
# backdrop encodes to almost nothing, where a photo backdrop is re-encoded on every
# resize and behind every moving window.

# glxgears gives a visible frame-rate demo for showing off stream responsiveness.
RUN apt-get update \
    && apt-get install -y --no-install-recommends mesa-utils \
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

# svc-nginx sweeps leftover nginx processes with pgrep/pkill -f "[n]ginx:", and an
# nginx master titles itself "nginx: master process ...", so that pattern matches the
# studio proxy too and webtop would kill it on startup, unbinding the Studio port
# exactly when Platform is probing it. Narrow the sweep to webtop's own master, which
# is the only one launched from the absolute path. Keep the pattern space-free: two
# of the four call sites pass it unquoted.
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
