ARG CONNECT_CLIENT_VERSION=0.14
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect
FROM node:22.23.3-bookworm-slim
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"
RUN apt-get update && apt-get install -y --no-install-recommends bash git ca-certificates util-linux procps \
    && rm -rf /var/lib/apt/lists/*
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install
RUN apt-get update && apt-get install -y --no-install-recommends python3 \
    && rm -rf /var/lib/apt/lists/*
ARG OPENCODE_VERSION=2.0.23
RUN npm install --global --ignore-scripts @opencode/cli-linux-x64-baseline@${OPENCODE_VERSION} \
    && ln -s /usr/local/lib/node_modules/@opencode/cli-linux-x64-baseline/bin/opencode /usr/local/bin/opencode \
    && npm cache clean --force \
    && opencode --version
WORKDIR /app
COPY studio.py opencode.json ./
ENV CONNECT_TOOL_PORT=3000 OPENCODE_INSTANCE=opencode OPENCODE_BACKUP_INTERVAL=60
EXPOSE 3000
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]
CMD ["python3", "/app/studio.py"]
