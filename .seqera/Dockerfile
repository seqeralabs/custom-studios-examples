ARG CONNECT_CLIENT_VERSION=0.14
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect
FROM node:22.22.3-bookworm-slim
ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"
RUN apt-get update && apt-get install -y --no-install-recommends bash git ca-certificates util-linux procps \
    && rm -rf /var/lib/apt/lists/*
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci --omit=dev && npm cache clean --force
COPY storage.mjs server.mjs seqera-mcp.mjs index.html start.sh ./
ENV CONNECT_TOOL_PORT=3000 PI_INSTANCE=pi-durable PI_PROVIDER=openai
EXPOSE 3000
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]
CMD ["/app/start.sh"]
