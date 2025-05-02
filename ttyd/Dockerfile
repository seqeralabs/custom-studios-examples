# Stage 1: Get the Seqera Connect client
FROM public.cr.seqera.io/platform/connect-client:0.8 AS connect

# Final image: Start from an arbitrary container
FROM community.wave.seqera.io/library/samtools:1.21--0d76da7c3cf7751c

# Install extra dependencies and tools
RUN apt-get update && apt-get install -y \
    wget \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install TTYD binary
RUN wget https://github.com/tsl0922/ttyd/releases/download/1.7.7/ttyd.x86_64 \
    && mv ttyd.x86_64 /usr/local/bin/ttyd \
    && chmod +x /usr/local/bin/ttyd

# Copy Connect binary and install dependencies
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN /usr/bin/connect-client --install

# Set connect as the entrypoint
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Default command to run TTYD with writable mode
CMD ["/usr/bin/bash", "-c", "ttyd -W -p $CONNECT_TOOL_PORT bash"]