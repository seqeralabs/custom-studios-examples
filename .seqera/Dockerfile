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

# ---------------------------------------------------------------
# 1) Multi-stage build: Pull the connect-client binary
# ---------------------------------------------------------------
ARG CONNECT_CLIENT_VERSION=0.12
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# ---------------------------------------------------------------
# 2) Final stage: Ubuntu + micromamba + r-shinyngs
# ---------------------------------------------------------------
FROM ubuntu:22.04

LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update --yes && apt-get install --yes --no-install-recommends \
    wget \
    ca-certificates \
    bzip2 \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------
# Install micromamba
# ---------------------------------------------------------------
ENV MAMBA_ROOT_PREFIX=/opt/conda
RUN wget -qO- https://micromamba.snakepit.net/api/micromamba/linux-64/latest \
  | tar -xvj --strip-components=1 bin/micromamba \
  && mv micromamba /usr/local/bin/micromamba \
  && mkdir -p /opt/conda \
  && chmod -R 777 /opt/conda

# ---------------------------------------------------------------
# Create a conda env with r-shinyngs (bioconda). r-markdown is
# explicitly loaded by app.R.
# ---------------------------------------------------------------
RUN rm -rf /opt/conda/pkgs/*.lock && \
    micromamba create -y -n shinyngs \
      -c conda-forge -c bioconda \
      r-shinyngs \
      r-markdown \
    && micromamba clean --all --yes \
    && rm -rf /opt/conda/pkgs/*.lock

# TEMPORARY: async-patch htmlwidgets 1.6.4 shinyBinding.renderValue so
# widget plugins load before the binding runs. Drop once
# https://github.com/pinin4fjords/shinyngs/pull/92 ships via bioconda.
RUN f=/opt/conda/envs/shinyngs/lib/R/library/htmlwidgets/www/htmlwidgets.js \
 && if grep -q 'await (Shiny.renderDependenciesAsync' "$f"; then \
      echo "htmlwidgets.js already patched, skipping"; \
    elif grep -q 'shinyBinding\.renderValue = function(el, data)' "$f"; then \
      sed -i \
        -e 's|shinyBinding\.renderValue = function(el, data) {|shinyBinding.renderValue = async function(el, data) {|' \
        -e 's|Shiny\.renderDependencies(data\.deps);|await (Shiny.renderDependenciesAsync ? Shiny.renderDependenciesAsync(data.deps) : Shiny.renderDependencies(data.deps));|' \
        "$f"; \
    else \
      echo "ERROR: htmlwidgets.js renderValue pattern not found" >&2; exit 1; \
    fi

# Add connect-client version label for Platform capability tracking
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"

COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

WORKDIR /app

# Pre-built shinyngs app and its serialised dataset
COPY app.R data.rds /app/

# ---------------------------------------------------------------
# 3) Launch with connect-client --entrypoint (for Platform)
# ---------------------------------------------------------------
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Port is set by CONNECT_TOOL_PORT. library() calls are required:
# shinyngs attaches prepareApp() for app.R; shinyBS/shinyjs register
# their addResourcePath hooks (else sbs/shinyBS.css etc. 404).
CMD ["micromamba", "run", "-n", "shinyngs", "R", "-e", "library(shinyngs); library(shinyBS); library(shinyjs); library(markdown); shiny::runApp('/app', host='0.0.0.0', port=as.integer(Sys.getenv('CONNECT_TOOL_PORT')))"]
