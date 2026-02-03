# KasmVNC Studio Environments

This folder contains custom container images for running GUI desktop applications in Seqera Studios using [KasmVNC](https://kasmweb.com/kasmvnc). All images are based on the [LinuxServer.io KasmVNC base image](https://docs.linuxserver.io/images/docker-baseimage-kasmvnc/) and run in single-app mode (no desktop environment).

## Available Applications

| Application | Description | Platform |
|-------------|-------------|----------|
| [QuPath](./qupath/) | Bioimage analysis for pathology | x86_64 only |
| [napari](./napari/) | Python-based multi-dimensional image viewer | x86_64, arm64 |

## Common Architecture

All KasmVNC images share the same architecture:

```
┌─────────────────────────────────────────────┐
│  LinuxServer.io KasmVNC Base Image          │
│  (Ubuntu Jammy + KasmVNC server)            │
├─────────────────────────────────────────────┤
│  Application Layer                          │
│  (QuPath / napari)                          │
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

## Building Images

All images require the `CONNECT_CLIENT_VERSION` build argument:

```bash
# QuPath
cd qupath && docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t kasmvnc-qupath .

# napari
cd napari && docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t kasmvnc-napari .
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
