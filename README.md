# Rex Remote Studio Environment

This example runs a [Rex](https://www.superlogical.com/rex/docs) server inside a Seqera Studio so you can attach to it from Rex on your own computer. The server reaches you over [Tailscale](https://tailscale.com/), which is built into Rex. A [TTYD](https://github.com/tsl0922/ttyd) web terminal on the Studio port gives you a browser fallback and a place to sign the server in.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Files](#files)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Local Testing](#local-testing)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [Environment Variables](#environment-variables)
- [Notes](#notes)
- [References](#references)

## Overview

Rex has three server modes. A Studio container fits only one of them:

| Mode | Fits a Studio? | Why |
|------|----------------|-----|
| [Personal server](https://www.superlogical.com/rex/docs/linux/server-modes) | **Yes (used here)** | Runs as the container's own user and needs no systemd or root setup |
| [Shared server](https://www.superlogical.com/rex/docs/linux/shared-server) | No | A systemd `rex.service` for several Linux users who share one `rex` account |
| [Login server](https://www.superlogical.com/rex/docs/linux/login-server) | No | A root systemd service that uses PAM to give each person their own OS account |

`connect-client` is PID 1 in a Studio, so there is no systemd. A Studio also belongs to one user. On startup, the container:

1. Runs `rex server start --tailscale`. The server joins your tailnet as its own device through Rex's embedded Tailscale (tsnet), so the image doesn't need `tailscaled`.
2. Serves `ttyd` on `$CONNECT_TOOL_PORT`. That is the HTTP UI that Studios proxies.

Rex's own API is deliberately **not** exposed on the Studio port. Platform's proxy requires Platform authentication, which the Rex client can't provide. Rex would also have to accept anonymous callers there.

## Features

- Rex personal server reachable at `https://<hostname>.<tailnet>.ts.net`
- Rex installed from its public release archive, pinned by commit and SHA-256 (no package token needed)
- Web terminal (TTYD 1.7.7) on the Studio port
- Builds for `linux/amd64` (Studios) and `linux/arm64` (local testing on ARM hosts)

> [!NOTE]
> For common features shared across all examples, see the [main README](../README.md#common-features).

## Files

- `.seqera/studio-config.yaml`: Studio config for deploying from this Git branch
- `.seqera/Dockerfile`: Container definition using multi-stage build
- `.seqera/start-rex-studio.sh`: Starts the Rex server, then serves TTYD on `$CONNECT_TOOL_PORT`

## Prerequisites

> [!NOTE]
> For common prerequisites, see the [main README](../README.md#prerequisites).

- A Tailscale tailnet with **MagicDNS** and **HTTPS certificates** turned on
- Rex on your computer ([Rex for Mac](https://www.superlogical.com/rex/docs) or the `rex` CLI)
- Optional: a Tailscale [auth key](https://tailscale.com/kb/1085/auth-keys). Without one, you sign the server in from the Studio terminal.

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container.

```bash
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.12 -t rex-studio .seqera
```

To move to a newer Rex build, look up the commit and checksums, then pass `REX_COMMIT`, `REX_SHA256_AMD64` and `REX_SHA256_ARM64`:

```bash
curl -fsS https://blob.superlogical.com/api/releases/rex/snapshot
```

> [!WARNING]
> When the amd64 image ran under OrbStack's amd64 emulation on Apple Silicon, Rex couldn't start terminals (commands exited with status 127). The native arm64 image works. To test locally on an ARM host, build with `--platform=linux/arm64`.

## Local Testing

Override the entrypoint and set the Studio port yourself:

```bash
docker run -p 3000:3000 -e CONNECT_TOOL_PORT=3000 \
  -e REX_TAILSCALE_HOSTNAME=rex-studio-local \
  --entrypoint /usr/local/bin/start-rex-studio.sh rex-studio
```

Open http://localhost:3000 and run `rex server status`. Under `tailscale:` it shows `needs login` and an `authenticate:` link. Open the link to add the server to your tailnet.

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

1. **Studios → Add Studio → Git repository**, with URL `https://github.com/seqeralabs/custom-studios-examples` and branch `rex`. Optionally, add `TS_AUTHKEY` as an environment variable. Use a **reusable, ephemeral** key, because the container's Tailscale state is lost when the Studio stops.
2. Start the Studio and open it. The terminal is TTYD.
3. Run `rex server status`. If `tailscale:` shows `needs login`, open the `authenticate:` link. Once the server has joined, the status shows its address.
4. On your computer, connect:

   ```bash
   rex hosts add studio https://<hostname>.<tailnet>.ts.net
   rex -S studio ls
   ```

   In Rex for Mac, choose **Add Remote Host…** and enter the same address.

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `TS_AUTHKEY` | _(unset)_ | Tailscale auth key that joins the server to the tailnet without a browser. Use a **reusable, ephemeral** key: Tailscale state is lost when the Studio stops, so a one-time key works only for the first start. At startup the key goes into a private temp file that's deleted afterwards. It's unset before TTYD starts and isn't passed to Rex sessions. It does stay in the container's PID 1 environment, like any Studio env var. |
| `REX_TAILSCALE_HOSTNAME` | `rex-studio-<container hostname>` | Tailnet device name |
| `REX_ALLOW_TAILNET_MEMBERS` | `false` | `true` lets any tailnet member your ACLs allow connect, not just the device owner |
| `REX_TAILSCALE_TAG` | _(unset)_ | Advertise an ACL tag such as `tag:studio`. A tagged device has no owner, so this also turns on `--tailscale-allow-tailnet-members`. |
| `REX_EXTRA_ARGS` | _(unset)_ | Extra flags for `rex server start`, e.g. `--max-sessions 16` |

## Notes

- Anyone who can connect to the Rex server can run programs as the Studio's user. By default, only the Tailscale user who owns the device can connect.
- Rex sessions live as long as the Studio does. Stopping the Studio ends them.
- Rex is pre-release software. This image pins a `snapshot` build, because the `stable` channel has no releases yet.

> [!NOTE]
> For common technical notes, see the [main README](../README.md#common-features).

## References

- [Rex: Server Modes](https://www.superlogical.com/rex/docs/linux/server-modes)
- [Rex: Remote Access](https://www.superlogical.com/rex/docs/linux/remote-access)
- [TTYD Documentation](https://github.com/tsl0922/ttyd)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
