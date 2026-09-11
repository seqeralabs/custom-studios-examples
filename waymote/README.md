# Waymote Studio Environment

This example streams a [Labwc](https://github.com/labwc/labwc) Wayland desktop to the browser with [Waymote](https://github.com/rockorager/waymote). Waymote captures the compositor over Wayland protocols, encodes H.264 and Opus, and serves an interactive WebCodecs client — a Wayland-native alternative to VNC-based remote desktops.

> This directory is the `master` reference tree. Platform Git deployment uses the dedicated [`waymote`](https://github.com/seqeralabs/custom-studios-examples/tree/waymote) branch (`.seqera/` layout). See the [main README](../README.md).

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Files](#files)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Local Testing](#local-testing)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [Environment variables](#environment-variables)
- [Notes](#notes)
- [References](#references)

## Overview

The container starts a headless Labwc session (`WLR_BACKENDS=headless`, `WLR_RENDERER=pixman`), launches a terminal (`foot`) and file manager (`pcmanfm` on `/workspace`), then binds [waymote-gateway](https://github.com/rockorager/waymote) to `$CONNECT_TOOL_PORT`. Fusion-mounted data appears under `/workspace/data/`.

## Docker Image

```
ghcr.io/seqeralabs/custom-studios-examples/waymote:latest
```

For specific versions, use the release tag (e.g. `ghcr.io/seqeralabs/custom-studios-examples/waymote:v1.0.0`).

## Features

- Wayland-native streaming (Labwc + Waymote 0.1.4) instead of VNC
- Browser UI with H.264 video and keyboard/pointer forwarding
- `foot` terminal and `pcmanfm` rooted at `/workspace` for Fusion data
- Software compositor (`pixman`) and `libx264` encoder — no GPU required
- Tunable output size, frame rate, and bitrate via Studio environment variables

> [!NOTE]
> For common features shared across all examples, see the [main README](../README.md#common-features).

## Files

- `Dockerfile`: Multi-stage build with connect-client, Debian Trixie, Labwc, and the Waymote server archive
- `start-waymote`: PulseAudio, Labwc, output mode, and gateway startup
- `labwc/autostart`: Session applications
- `labwc/rc.xml`: Super+Return (terminal) and Super+E (file manager)

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../README.md#prerequisites).

The image is **linux/amd64** only (Waymote's packaged server target). Use a Chromium-based browser: Waymote needs WebCodecs for H.264 and Opus.

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.12 -t waymote-studio .
```

## Local Testing

Override the connect-client entrypoint and bind the gateway to port 3000:

```bash
docker run --rm --platform linux/amd64 -p 3000:3000 \
  -e CONNECT_TOOL_PORT=3000 \
  --entrypoint /usr/local/bin/start-waymote \
  waymote-studio
```

Open http://localhost:3000. Super+Return opens another terminal; Super+E opens the file manager.

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

1. Add a Studio from **Git repository** `https://github.com/seqeralabs/custom-studios-examples`, branch `waymote`, or from the prebuilt image URI above.
2. Mount data as needed; files appear under `/workspace/data/` in pcmanfm.
3. Optionally override the streaming environment variables below.

## Environment variables

| Variable | Default | Purpose |
| --- | --- | --- |
| `WAYMOTE_WIDTH` | `1280` | Fixed remote output width |
| `WAYMOTE_HEIGHT` | `720` | Fixed remote output height |
| `WAYMOTE_FRAME_RATE` | `30` | Capture and encoder frame rate |
| `WAYMOTE_BITRATE` | `8000` | Encoder target bitrate in kbps |
| `WAYMOTE_XKB_LAYOUT` | `us` | Keyboard layout forwarded to Waymote |

The gateway listens on `$CONNECT_TOOL_PORT` (set by Studios). `-public-url` is left unset so WebSocket connections succeed behind Platform's TLS proxy.

## Notes

- Encoding is software (`libx264`) and the compositor uses `pixman`. Expect CPU usage to scale with resolution, frame rate, and bitrate.
- Waymote does not authenticate sessions. Seqera Platform terminates TLS and gates access; do not publish this container's port on an untrusted network.
- Clipboard sync is text-only and needs `ext_data_control_manager_v1`. Debian Trixie's Labwc 0.8.3 does not advertise that protocol, so the gateway logs `clipboard unavailable` and clipboard buttons stay disconnected. Capture, input, and audio still work.
- Audio needs a user gesture in the browser (`Enable audio` in the bundled UI).
- Labwc autostart lives in `/etc/xdg/labwc/`. Replace or extend those files to launch a different desktop application.

## References

- [Waymote](https://github.com/rockorager/waymote)
- [Labwc](https://github.com/labwc/labwc)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
