# Waymote Studio Environment

This branch contains the Seqera Studios configuration for streaming a [Labwc](https://github.com/labwc/labwc) Wayland desktop to the browser with [Waymote](https://github.com/rockorager/waymote).

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `waymote`.
5. Select your compute environment.
6. Click **Add**, then **Start**.

## Configuration

The `.seqera/studio-config.yaml` file uses the Dockerfile template:

```yaml
schemaVersion: "0.0.1"
kind: "studio-config"
session:
  template:
    kind: "dockerfile"
    dockerfile: "Dockerfile"
```

## Building locally

```bash
docker build --platform linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.12 \
  -t waymote-studio .seqera
```

Override the connect-client entrypoint for local runs:

```bash
docker run --rm --platform linux/amd64 -p 3000:3000 \
  -e CONNECT_TOOL_PORT=3000 \
  --entrypoint /usr/local/bin/start-waymote \
  waymote-studio
```

Open [http://localhost:3000](http://localhost:3000). Use a Chromium-based browser (WebCodecs). Super+Return opens a terminal; Super+E opens the file manager.

The image targets `linux/amd64`. In Seqera Platform, keep the image entrypoint unchanged so `connect-client` can mount Fusion data.

## Features

- Wayland-native streaming (Labwc + Waymote 0.1.4) instead of VNC
- Browser UI with H.264 video, keyboard/pointer forwarding, and text clipboard sync
- `foot` terminal and `pcmanfm` rooted at `/workspace` for Fusion-mounted data (`/workspace/data/`)
- Software compositor (`pixman`) and `libx264` encoder — no GPU required
- Super+Return (terminal) and Super+E (file manager)

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `WAYMOTE_WIDTH` | `1280` | Fixed remote output width |
| `WAYMOTE_HEIGHT` | `720` | Fixed remote output height |
| `WAYMOTE_FRAME_RATE` | `30` | Capture and encoder frame rate |
| `WAYMOTE_BITRATE` | `8000` | Encoder target bitrate in kbps |
| `WAYMOTE_XKB_LAYOUT` | `us` | Keyboard layout forwarded to Waymote |

The gateway listens on `$CONNECT_TOOL_PORT`. `-public-url` is left unset so WebSocket connections succeed behind Platform's TLS proxy.

## Notes

- Encoding is software (`libx264`). CPU usage scales with resolution, frame rate, and bitrate.
- Waymote does not authenticate sessions. Platform terminates TLS and gates access.
- Labwc config lives in `.seqera/labwc/` and is installed to `/etc/xdg/labwc/` in the image.

## References

- [Waymote](https://github.com/rockorager/waymote)
- [Labwc](https://github.com/labwc/labwc)
- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
