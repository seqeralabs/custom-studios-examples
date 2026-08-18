# napari KasmVNC Studio Environment

This branch contains the Seqera Studios configuration for running [napari](https://napari.org/) through [KasmVNC](https://kasmweb.com/kasmvnc).

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `kasmvnc-napari`.
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
  -t kasmvnc-napari .seqera
```

Run s6 directly to bypass `connect-client` and Fusion outside Seqera Platform:

```bash
docker run --rm --platform linux/amd64 \
  -p 6901:8080 \
  -e STUDIO_PROXY_PORT=8080 \
  -e KASMVNC_UPSTREAM_PORT=3000 \
  -e CUSTOM_PORT=3000 \
  -e CUSTOM_HTTPS_PORT=3001 \
  --entrypoint /init \
  kasmvnc-napari
```

Open [http://localhost:6901](http://localhost:6901). In Seqera Platform, keep the image entrypoint unchanged so `connect-client` can mount Fusion data.

The image targets `linux/amd64`. On Apple Silicon, Docker runs it through CPU emulation; use an x86_64 Docker host if LinuxServer's s6 init scripts crash under QEMU.

## Features

- napari 0.8.0 multidimensional image viewer
- Browser access through LinuxServer.io KasmVNC
- Single-app mode that launches napari directly
- Full-screen startup indicator that remains visible until the napari window is ready
- A desktop that expands to fill the browser window
- Mesa software rendering for compute environments without a GPU
- 30 FPS streaming, four compression threads, and high-quality text updates for responsive interaction
- Startup proxy that serves a loading page until KasmVNC is ready, avoiding first-load 502 errors
- Fusion-mounted data available from napari's file browser under `/workspace/data/`
- `HOME=/workspace` so user settings and file dialogs start in the Studio workspace

## Display and streaming defaults

KasmVNC resizes the remote desktop to fill the browser window. napari uses Mesa software rendering by default so it also works when compute does not expose a GPU.

For a different environment, override any of these Studio environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `LIBGL_ALWAYS_SOFTWARE` | `1` | Use Mesa software rendering; set to `0` only when compatible GPU rendering is available |
| `KASMVNC_FRAME_RATE` | `30` | Maximum streamed frames per second |
| `KASMVNC_RECT_THREADS` | `4` | Parallel compression threads |
| `KASMVNC_DYNAMIC_QUALITY_MIN` | `7` | Lowest quality used while the screen is changing |
| `KASMVNC_DYNAMIC_QUALITY_MAX` | `8` | Quality used for mostly static content such as text |

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [napari Documentation](https://napari.org/stable/)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
