# Fiji KasmVNC Studio Environment

This branch contains the Seqera Studios configuration for running [Fiji](https://imagej.net/software/fiji/) through [KasmVNC](https://kasmweb.com/kasmvnc).

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `kasmvnc-fiji`.
5. Select your compute environment.
6. Click **Add**, then **Start**.

## Configuration

The `.seqera/studio-config.yaml` file uses the Dockerfile template:

```yaml
session:
  template:
    kind: "dockerfile"
    dockerfile: "Dockerfile"
```

Build and run this Studio on `linux/amd64` compatible compute.

## Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Local Docker test

Build the image:

```bash
docker build --platform linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.9 \
  -t kasmvnc-fiji .seqera
```

Run s6 directly to bypass `connect-client` and Fusion outside Seqera Platform:

```bash
docker run --rm --platform linux/amd64 \
  -p 6901:6901 \
  -e STUDIO_PROXY_PORT=6901 \
  -e KASMVNC_UPSTREAM_PORT=3000 \
  -e CUSTOM_PORT=3000 \
  -e CUSTOM_HTTPS_PORT=3001 \
  --entrypoint /init \
  kasmvnc-fiji
```

Open [http://localhost:6901](http://localhost:6901). In Seqera Platform, keep the image entrypoint unchanged so `connect-client` can mount Fusion data.

The image targets `linux/amd64`. On Apple Silicon, Docker runs it through CPU emulation; use an x86_64 Docker host if LinuxServer's s6 init scripts crash under QEMU.

## Features

- Fiji stable 2026-03-07 scientific image analysis desktop
- Browser access through LinuxServer.io KasmVNC
- Single-app mode that launches Fiji directly
- A desktop that expands to fill the browser window
- 30 FPS streaming, four compression threads, and high-quality text updates for responsive interaction
- Startup proxy that serves a loading page until KasmVNC is ready, avoiding first-load 502 errors
- Fusion-mounted data available from Fiji's file browser under `/workspace/data/`
- `HOME=/workspace` so user settings and file dialogs start in the Studio workspace

## Display and streaming defaults

KasmVNC resizes the remote desktop to fill the browser window.

For a different environment, override any of these Studio environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `KASMVNC_FRAME_RATE` | `30` | Maximum streamed frames per second |
| `KASMVNC_RECT_THREADS` | `4` | Parallel compression threads |
| `KASMVNC_DYNAMIC_QUALITY_MIN` | `7` | Lowest quality used while the screen is changing |
| `KASMVNC_DYNAMIC_QUALITY_MAX` | `8` | Quality used for mostly static content such as text |

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Fiji Documentation](https://imagej.net/software/fiji/)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
