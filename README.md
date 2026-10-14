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

## Build a container image

```bash
git clone https://github.com/seqeralabs/custom-studios-examples.git --single-branch --branch waymote
cd custom-studios-examples
docker build --platform=linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.14.0 \
  -f .seqera/Dockerfile \
  -t <your-registry>/<your-image>:<tag> \
  .seqera
docker push <your-registry>/<your-image>:<tag>
```

Use **Prebuilt container image** in Seqera Studios with your registry URI. `CONNECT_CLIENT_VERSION` defaults to `0.14.0` in `.seqera/Dockerfile`.

## Configuration

The `.seqera/studio-config.yaml` file uses the Dockerfile template:

```yaml
schemaVersion: "0.0.1"
kind: "studio-config"
session:
  template:
    kind: "dockerfile"
    dockerfile: "Dockerfile"
  clone:
    enabled: false
```

Repository cloning is disabled. The image does not include `git`, and the repository only holds the Studio build files.

## Building locally

```bash
docker build --platform linux/amd64 \
  --build-arg CONNECT_CLIENT_VERSION=0.14.0 \
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

## Browser page

The Studio serves its own page from `.seqera/web/` instead of the Waymote demo page:

- The remote desktop fills the whole browser window. Its resolution follows the window size, up to 2560x1600 pixels. Above that, the remote desktop keeps the same layout at a lower resolution.
- Only the remote cursor shows. The page hides the local cursor over the desktop.
- Frames show as soon as they are decoded (latency target 0 ms).
- Move the pointer to the top edge to show the toolbar: full screen, audio, text input, and clipboard buttons. In full screen, the browser sends Escape and Super to the remote desktop.

Every viewer resizes the remote desktop to their own window. If two people open the same Studio, the resolution follows the last window that changed size.

## Agent control

Agents can drive Waymote without browser automation by connecting to the
`/control` WebSocket. A client sends the text message `acquire`, waits for a
`control-state` response with `state: "active"`, then sends the 16-byte
little-endian pointer and keyboard records documented in the
[Waymote wire protocol](https://github.com/rockorager/waymote/blob/main/docs/protocol.md).
Only one client owns input at a time; other clients receive `state: "busy"`.

This has been tested by sending Super+Return to Labwc, typing commands into the
new terminal, and verifying their output independently from the rendered video.

For a hosted Studio, the Connect proxy protects `/control` with the same
`data-studio:view` OIDC session as the browser UI. A Seqera Platform API token
can create and manage the Studio but does not authenticate a direct WebSocket
client. Use an authenticated browser session or another approved Connect access
path when controlling a hosted Studio.

The image targets `linux/amd64`. In Seqera Platform, keep the image entrypoint unchanged so `connect-client` can mount Fusion data.

## Features

- Wayland-native streaming (Labwc + Waymote 0.1.4) instead of VNC
- Full-window browser page with H.264 video and keyboard/pointer forwarding
- `foot` terminal and `pcmanfm` rooted at `/workspace` for Fusion-mounted data (`/workspace/data/`)
- Software compositor (`pixman`) and `libx264` encoder — no GPU required
- Super+Return (terminal) and Super+E (file manager)

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `WAYMOTE_WIDTH` | `1280` | Remote output width until the first browser connects |
| `WAYMOTE_HEIGHT` | `720` | Remote output height until the first browser connects |
| `WAYMOTE_FRAME_RATE` | `60` | Capture and encoder frame rate |
| `WAYMOTE_BITRATE` | `12000` | Encoder target bitrate in kbps |
| `WAYMOTE_XKB_LAYOUT` | `us` | Keyboard layout forwarded to Waymote |
| `WAYMOTE_PUBLIC_URL` | Derived from `CONNECT_PUBLIC_ADDRESS` | Browser origin the gateway accepts for WebSockets |

nginx listens on `$CONNECT_TOOL_PORT`. It serves the Studio page and passes all other requests to the Waymote gateway on a random loopback port. Under Connect, the container shares the host network, so nginx listens on `127.0.0.1` only. connect-client connects through loopback, and other hosts in the VPC cannot reach the unauthenticated desktop. Local runs without `CONNECT_PUBLIC_ADDRESS` listen on `0.0.0.0` so that `docker run -p` works.

The gateway accepts a WebSocket only when the browser origin matches the request `Host` header or `-public-url`. The Connect proxy changes the `Host` header, so `start-waymote` passes this Studio's exact origin as `-public-url`. Connect sets `CONNECT_PUBLIC_ADDRESS` to `https://connect.<domain>/studios/<id>`, and the script turns it into `https://a<id>.<domain>`. Set `WAYMOTE_PUBLIC_URL` only if your Studio URL has a different form. Do not use a wildcard: it lets pages in other Studios control this desktop. Local runs on `localhost` work because the origin matches the `Host` header.

## Notes

- Encoding is software (`libx264`). CPU usage scales with resolution, frame rate, and bitrate.
- Waymote does not authenticate sessions. Platform terminates TLS and gates access: without a Seqera login, every request, including WebSocket upgrades, gets a redirect to the `data-studio:view` login.
- Anyone who can open the Studio in Seqera Platform can control the desktop. Mark the Studio as private if other workspace members must not use it.
- Clipboard sync needs `ext_data_control_manager_v1`. Debian Trixie's Labwc 0.8.3 does not advertise that protocol, so the gateway logs `clipboard unavailable`. Capture, input, and audio still work.
- Labwc config lives in `.seqera/labwc/` and is installed to `/etc/xdg/labwc/` in the image.

## References

- [Waymote](https://github.com/rockorager/waymote)
- [Labwc](https://github.com/labwc/labwc)
- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
