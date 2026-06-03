# KasmVNC QuPath Studio Environment

This folder contains the custom container image for running [QuPath](https://qupath.github.io/) in Seqera Studios using [KasmVNC](https://kasmweb.com/kasmvnc). The image is based on the [LinuxServer.io KasmVNC base image](https://docs.linuxserver.io/images/docker-baseimage-kasmvnc/) and runs in single-app mode (no desktop environment).

## Available Application

| Application | Description | Platform |
|-------------|-------------|----------|
| [QuPath](./qupath/) | Bioimage analysis for pathology | x86_64 only |

## Common Architecture

The QuPath KasmVNC image uses this architecture:

```
┌─────────────────────────────────────────────┐
│  LinuxServer.io KasmVNC Base Image          │
│  (Ubuntu Jammy + KasmVNC server)            │
├─────────────────────────────────────────────┤
│  Application Layer                          │
│  (QuPath)                                   │
├─────────────────────────────────────────────┤
│  Seqera Studios Integration                 │
│  (connect-client + Fusion filesystem)       │
└─────────────────────────────────────────────┘
```

## Performance Optimizations

All images include KasmVNC performance optimizations for better streaming responsiveness:

```dockerfile
ENV KASM_VNC_ENABLE_WEBP=1      # WebP compression (better than JPEG)
ENV KASM_VNC_JPEG_QUALITY=5     # 1-9, lower = faster/smaller
ENV KASM_VNC_MAX_FRAME_RATE=30  # Limit FPS
ENV KASM_VNC_THREADS=4          # Match vCPU count
```

**Runtime recommendations:**
- Use `--shm-size=2g` or higher for Java/GUI apps when testing locally
- Use compute-optimized EC2 instances (c6i, c7i) for better responsiveness in Studios
- Deploy in regions close to users to minimize latency

## Building Image

The image requires the `CONNECT_CLIENT_VERSION` build argument:

```bash
cd qupath && docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t kasmvnc-qupath .
```

## Local Testing

To test locally, override the entrypoint to bypass connect-client:

```bash
docker run --rm -it --platform linux/amd64 --shm-size=2g -p 6901:6901 \
    --entrypoint /init <image-name>
```

Access the application at http://localhost:6901

## References

- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
- [LinuxServer.io KasmVNC Base Image](https://docs.linuxserver.io/images/docker-baseimage-kasmvnc/)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
