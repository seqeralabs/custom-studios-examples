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

FROM lscr.io/linuxserver/webtop:ubuntu-kde

LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV TITLE="Selkies Ubuntu KDE Desktop"
ENV START_DOCKER="false"
ENV SELKIES_DESKTOP="true"
ENV PIXELFLUX_WAYLAND="true"
ENV AUTO_GPU="true"
ENV LC_ALL="C.UTF-8"

ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

CMD ["/bin/bash", "-c", "set -euo pipefail; export CUSTOM_PORT=${CONNECT_TOOL_PORT:-3000}; export CUSTOM_HTTPS_PORT=${CUSTOM_HTTPS_PORT:-3001}; export CUSTOM_WS_PORT=${CUSTOM_WS_PORT:-8082}; exec /init"]
