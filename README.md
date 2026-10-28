# Rex Remote Studio Environment

This example runs a [Rex](https://www.superlogical.com/rex/docs) server inside a Seqera Studio so you can attach to it from Rex on your own computer. You connect through the Studio's [SSH access](https://docs.seqera.io/platform-cloud/studios/managing), so Seqera Platform authenticates every connection. A [TTYD](https://github.com/tsl0922/ttyd) web terminal on the Studio port gives you a browser fallback.

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Files](#files)
- [Prerequisites](#prerequisites)
- [Building the Container](#building-the-container)
- [Local Testing](#local-testing)
- [Using in Seqera Studios](#using-in-seqera-studios)
- [On-demand Studios with rex-studio](#on-demand-studios-with-rex-studio)
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

1. Runs `rex server start` with a [plain HTTP listener](https://www.superlogical.com/rex/docs/linux/remote-access) bound to **`127.0.0.1:7297` only**.
2. Serves `ttyd` on `$CONNECT_TOOL_PORT`. That is the HTTP UI that Studios proxies.

```
Rex on your computer ──http──▶ localhost:17297
        │ ssh -L, authenticated by Seqera with your Platform SSH key
        ▼
connect.cloud.seqera.io:2222 ──▶ Studio container ──▶ Rex on 127.0.0.1:7297
```

The listener admits anonymous callers, which Rex only allows with `--allow-anonymous`. It is safe here because it's bound to loopback. Nothing outside the container can reach it except through the Studio's SSH proxy, and the proxy only lets in your Platform user with a key registered in your profile.

Rex can't use the Studio's HTTPS address directly. That proxy sends an OAuth redirect to the Platform login page, and the Rex client can't follow it or send cookies or headers.

## Features

- Rex personal server reached through Seqera Studios SSH
- Optional built-in [Tailscale](https://www.superlogical.com/rex/docs/linux/remote-access) instead of, or as well as, SSH
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

- Studio SSH access enabled for your workspace, and your SSH public key in your Seqera Platform user profile
- `connect-client` 0.12 or later, which Studio SSH requires
- Rex on your computer ([Rex for Mac](https://www.superlogical.com/rex/docs) or the `rex` CLI)

## Building the Container

> [!IMPORTANT]
> You must provide the `CONNECT_CLIENT_VERSION` build argument when building the container. Use 0.12 or later for SSH.

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

Override the entrypoint and set the Studio port yourself. `REX_LOCAL_BIND=0.0.0.0` lets Docker forward to Rex. Both ports are published to your machine's loopback only:

```bash
docker run -d --name rex-studio-local \
  -p 127.0.0.1:3000:3000 -p 127.0.0.1:17298:7297 \
  -e CONNECT_TOOL_PORT=3000 -e REX_LOCAL_BIND=0.0.0.0 \
  --entrypoint /usr/local/bin/start-rex-studio.sh rex-studio

rex hosts add studio-local http://127.0.0.1:17298
rex -S studio-local new work
```

The web terminal is at http://localhost:3000.

## Using in Seqera Studios

> [!NOTE]
> For the common deployment process, see the [main README](../README.md#deploying-to-seqera-studios).

1. **Studios → Add Studio → Git repository**, with URL `https://github.com/seqeralabs/custom-studios-examples` and branch `rex`. Turn **SSH Connection** on. Turning it on later requires stopping and restarting the Studio.
2. Start the Studio and note its session ID, such as `6afaa755`.
3. On your computer, open a tunnel. Add `a` in front of the session ID:

   ```bash
   ssh -N -p 2222 -L 17297:127.0.0.1:7297 <platform-username>@a<session-id>@connect.cloud.seqera.io
   ```

4. In another terminal, connect Rex through the tunnel:

   ```bash
   rex hosts add studio http://127.0.0.1:17297
   rex -S studio ls
   rex -S studio new work
   ```

   In Rex for Mac, choose **Add Remote Host…** and enter `http://127.0.0.1:17297`.

Rex sessions live as long as the Studio does. If the tunnel drops, reopen it and reconnect. The sessions are still there.

## On-demand Studios with rex-studio

`bin/rex-studio` does the steps above in one command. It creates a Studio from this branch and waits for it to run. It keeps the SSH tunnel up as a launchd agent on macOS or a systemd user service on Linux, adds a Rex host, and opens a Rex session on it.

```bash
curl -fsSL https://raw.githubusercontent.com/seqeralabs/custom-studios-examples/rex/install.sh | sh
export TOWER_ACCESS_TOKEN=<token>
export REX_STUDIO_WORKSPACE=<org>/<workspace>
rex-studio doctor
rex-studio new work
rex -S studio-work ls
```

| Command | What it does |
|---------|--------------|
| `rex-studio new [NAME]` | Create a Studio, its tunnel, Rex host `studio-NAME`, and Rex session `NAME` |
| `rex-studio ls [--all]` | Your Studios from this branch, with status and tunnel state |
| `rex-studio start NAME` / `stop NAME` | Start or stop a Studio and its tunnel |
| `rex-studio rm NAME [--yes]` | Delete a Studio, its tunnel and its Rex host |
| `rex-studio sync` | Bring tunnels and Rex hosts in line with your Studios |
| `rex-studio ssh NAME` | Open a shell in a Studio |

Each tunnel listens on its own port on `127.0.0.1`, from 20000 up (set `REX_STUDIO_PORT_BASE` to move the range), and the Rex host points at `http://127.0.0.1:PORT`. A Studio keeps the same port across runs. Run `rex-studio help` for every option. Tunnel ports and logs are in `~/.local/state/rex-studio`. To set it up with a coding agent, paste [INSTALL-PROMPT.md](INSTALL-PROMPT.md) into it.

To get **New Seqera Studio** and **List Seqera Studios** in the Rex command palette, paste [rex-actions.lua](rex-actions.lua) into `~/.config/rex/init.lua` and run `rex config reload`.

The tests stub every external command: `bats tests/rex-studio.bats`.

## Environment Variables

| Variable | Default | Purpose |
|----------|---------|---------|
| `REX_LOCAL_PORT` | `7297` | Loopback port for Rex's HTTP listener. `off` disables it. |
| `REX_TAILSCALE` | `false` | `true` also joins your tailnet through Rex's built-in Tailscale. The tailnet needs MagicDNS and HTTPS certificates. |
| `TS_AUTHKEY` | _(unset)_ | With `REX_TAILSCALE=true`, a Tailscale auth key that joins without a browser. Use a **reusable, ephemeral** key: Tailscale state is lost when the Studio stops, so a one-time key works only for the first start. At startup the key goes into a private temp file that's deleted afterwards. It's unset before TTYD starts and isn't passed to Rex sessions. It does stay in the container's PID 1 environment, like any Studio env var. |
| `REX_TAILSCALE_HOSTNAME` | `rex-studio-<container hostname>` | Tailnet device name |
| `REX_ALLOW_TAILNET_MEMBERS` | `false` | `true` lets any tailnet member your ACLs allow connect, not just the device owner |
| `REX_TAILSCALE_TAG` | _(unset)_ | Advertise an ACL tag such as `tag:studio`. A tagged device has no owner, so this also turns on `--tailscale-allow-tailnet-members`. |
| `REX_EXTRA_ARGS` | _(unset)_ | Extra flags for `rex server start`, e.g. `--max-sessions 16` |

## Notes

- Anyone who can connect to the Rex server can run programs as the Studio's user (root). With SSH, that means anyone who can open a shell in the Studio anyway.
- Any process inside the container can also reach the loopback listener.
- Rex is pre-release software. This image pins a `snapshot` build, because the `stable` channel has no releases yet.

> [!NOTE]
> For common technical notes, see the [main README](../README.md#common-features).

## References

- [Rex: Server Modes](https://www.superlogical.com/rex/docs/linux/server-modes)
- [Rex: Remote Access](https://www.superlogical.com/rex/docs/linux/remote-access)
- [Seqera Studios: Connect via SSH](https://docs.seqera.io/platform-cloud/studios/managing)
- [TTYD Documentation](https://github.com/tsl0922/ttyd)
- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
