# Selkies Webtop Studio Environment

This branch contains the Seqera Studios configuration for running a full Debian XFCE desktop through [Selkies](https://selkies-project.github.io/selkies/), using the [LinuxServer.io Webtop](https://github.com/linuxserver/docker-webtop) base image.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `selkies-webtop`.
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

This Studio uses `lscr.io/linuxserver/webtop:debian-xfce`, so run it on `linux/amd64` compute with enough CPU and memory for a full desktop session.

## Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Full Debian XFCE desktop delivered through Selkies
- Seqera `connect-client` integration for Studio-compatible startup
- X11 compatibility mode instead of Wayland for safer Studio startup
- Desktop resolution tracks the browser window, at 144 DPI so text stays readable on large displays
- Plain black desktop, which is the cheapest backdrop to stream
- Chromium (from the base image) launched with the flags it needs to start inside a Studio
- Nextflow and a headless JRE on `PATH`, plus `curl`, `wget` and `htop`
- `glxgears` included as a frame-rate demo (**Applications > System > GL Gears (stream benchmark)**)
- Startup proxy that binds `CONNECT_TOOL_PORT` from the first moment s6 is up and serves a loading page until the desktop is ready, avoiding first-load 502 errors
- Webtop's own nginx kept internal and plain-HTTP only, with its HTTPS server block removed

## Runtime defaults

The container is configured with these defaults:

| Variable | Default | Purpose |
| --- | --- | --- |
| `TITLE` | `Selkies Debian XFCE Desktop` | Browser tab title shown by Webtop |
| `PIXELFLUX_WAYLAND` | `false` | Disables Wayland and uses the more compatible X11 startup path |
| `DISABLE_ZINK` | `true` | Avoids GPU-backed Zink rendering in Studio environments |
| `DISABLE_DRI3` | `true` | Avoids DRI3 acceleration assumptions during startup |
| `SELKIES_SCALING_DPI` | `144` | UI/font DPI, so text is readable at native resolution on a large screen |
| `START_DOCKER` | `false` | Skips Webtop's docker-in-docker startup, which a Studio container does not need |
| `NXF_HOME` | `/opt/nextflow` | Shared Nextflow home, writable by the runtime-assigned desktop user |

This branch uses the `debian-xfce` flavor rather than `ubuntu-xfce`. The Ubuntu flavor is built on Ubuntu 25.10, whose GTK3 and gdk-pixbuf decode every image through glycin, which decodes inside a `bwrap --unshare-all` sandbox. Containers do not get the privileges `bwrap` needs, so the loader exits non-zero and GTK aborts on a failed assertion, killing `xfce4-panel` and the first `xfce4-session` and leaving a black desktop with no panel. The Debian flavor keeps the classic gdk-pixbuf loaders and needs no sandbox. XFCE is also preferred over `kde`, which Webtop documents as Wayland-only.

## Notes

- **`.seqera/Dockerfile` must stay under 7500 bytes.** Platform base64-encodes the container file before handing it to Wave and rejects anything over 10000 encoded bytes, which is 7500 raw — the failure is `Docker context preparation failed: ... Container file size exceeds the maximum allowed size of 10000 bytes`, at context-preparation time, so it has nothing to do with the size of the built image and cannot be fixed by removing packages. This is why the rationale for the build steps lives in these notes rather than in Dockerfile comments. If the file does hit the cap again, the next lever is moving the `sed`/`awk` patch steps into a script that is `COPY`'d in, the way `studio-entry` and `studio-proxy-run` already are.
- Webtop's `svc-nginx` sweeps leftover nginx masters with `pgrep`/`pkill -f "[n]ginx:"`. An nginx master titles itself `nginx: master process ...`, so that pattern also matches the studio proxy, and Webtop would kill it during startup — unbinding the Studio port at exactly the moment Platform probes it. The Dockerfile narrows the sweep to `[n]ginx:.*/usr/sbin/nginx`, which is Webtop's own master and the only one launched from an absolute path. The replacement pattern must stay free of spaces, because two of the four call sites pass it unquoted.
- `NXF_HOME` is set to `/opt/nextflow`, a shared world-writable path, rather than somewhere under the desktop user's home. The `nextflow` launcher downloads its own distribution on first run, and `PUID`/`PGID` are assigned at runtime by the base image, so a build-time `chown` would guess the wrong uid.
- `connect-client` proxies **plain HTTP** to `CONNECT_TOOL_PORT`, so nothing in this Studio may serve HTTPS on that port: nginx answers the health probe with `400 Bad Request` and the Studio never starts. TLS is terminated by Platform in front of the Studio, so the browser still gets the secure context that WebCodecs needs.
- **`CONNECT_TOOL_PORT` is owned by the startup proxy, not by Webtop.** `.seqera/studio-proxy-run` is an s6 `longrun` that binds the Studio port as soon as s6 comes up and proxies to Webtop's own nginx on an internal port — `3000`, or `3002` when `CONNECT_TOOL_PORT` is itself `3000`. `connect-client` polls the port and SIGKILLs the tool if nothing binds it inside its readiness window, which surfaces as `execute error: exit status 137`, and Webtop's nginx only binds once the whole desktop startup chain is ready, so it loses that race. Until the desktop answers, the proxy serves a self-refreshing loading page in place of a 502.
- **s6-overlay's `/init` must be pid 1**, or `s6-overlay-suexec` aborts with `can only run as pid 1`. `connect-client` runs the tool as a child process rather than exec'ing it, so `.seqera/studio-entry` re-execs `/init` under `unshare --pid --fork --mount-proc`, where it is pid 1 for real. Skipping suexec instead is not an option: `preinit` reads the UID/GID environment it sets up. The `unshare` needs `CAP_SYS_ADMIN`, which Studio containers have.
- The Dockerfile strips Webtop's HTTPS `server` block from `/defaults/default.conf` at build time. Webtop's `init-nginx` rewrites ports with two chained seds — `s/3000/$CUSTOM_PORT/g` then `s/3001/$CUSTOM_HTTPS_PORT/g` — so a `CUSTOM_PORT` of `3001` is substituted twice and both server blocks collapse onto one port, after which nginx demands a certificate on the plain-HTTP block and exits.
- Selkies' data websocket stays on internal port `8082`; nginx proxies `/websocket` to it from the same HTTP listener, so only `CONNECT_TOOL_PORT` needs to be reachable.
- `PIXELFLUX_WAYLAND=false` is already the Webtop default; it is set explicitly here to pin the X11 startup path rather than inherit a default that may change.
- `MAX_RES` is intentionally **not** set. `svc-xorg` uses it as the Xvfb virtual screen size, which is the ceiling RANDR can resize within, so pinning it to `1920x1080` leaves the desktop stranded in the corner of a larger browser window. Webtop's default of `15360x8640` lets the desktop track the browser.
- DPI comes from `SELKIES_SCALING_DPI` because Selkies applies DPI itself, writing `/Xft/DPI` via `xfconf-query` and `Xft.dpi` into `~/.Xresources`. Seeding Xft defaults instead would be overwritten with Selkies' own default of 96. Note that setting this variable also locks the DPI dropdown in the Selkies sidebar to that single value.
- **The desktop is black and there is no wallpaper.** Under Xvfb `xfdesktop` covers the root window with an opaque black window and ignores every `/backdrop/...` property it is given (verified with image and solid-colour styles, both monitor key spellings, `image-show`, a bounded Xvfb screen, and compositing on and off). Painting the root window directly does work, but only with `xfdesktop` dropped from the session — which also drops the desktop icons and the desktop right-click menu. Black is kept instead, so `xfdesktop` is left as Webtop ships it. A still, uniform backdrop is also the cheapest thing to stream: an image backdrop is re-encoded on every resize and behind every moving window.
- **Chromium needs `--no-sandbox` here, and the base image does not pass it.** Debian's `chromium` package ships no setuid `chrome-sandbox` helper, so the browser has only the unprivileged namespace sandbox, which needs `CLONE_NEWUSER`. When that is refused Chromium prints `Failed to move to new namespace` and exits before a window appears. Webtop's `wrapped-chromium` is meant to handle this — it passes `--no-sandbox` when it judges the container unprivileged, by grepping `/proc/1/status` for `Seccomp:\t0` and treating an unconfined seccomp profile as proof the sandbox will work. Studio containers run privileged (they set up loop devices, btrfs and FUSE mounts), so that grep matches and the flag is withheld: the desktop starts normally and only the browser fails. `.seqera/chromium-studio-flags` is installed to `/etc/chromium.d/zz-studio-flags` to pass the flag unconditionally. That path is Debian's own hook — `/usr/bin/chromium` is a launcher script that clears `CHROMIUM_FLAGS`, sources every `/etc/chromium.d/*` file, then execs the real binary — so the flags apply from the menu, from `xdg-open` and from a shell, without patching a base-image file. Setting `CHROMIUM_FLAGS` as a container environment variable does **not** work, because the launcher clears it first.
- The same snippet adds `--disable-dev-shm-usage`, but only when `/dev/shm` is smaller than 256MB. Chromium puts renderer transport surfaces in `/dev/shm` and tabs die once it fills; upstream's compose file asks for `shm_size: 1gb` against Docker's 64MB default, and the image cannot resize the mount itself. The check is conditional because the `/tmp` fallback is slower, so a compute environment that does provide a large `/dev/shm` keeps the shared-memory path.
- **Clipboard** sync works in both directions but is gated by the browser, not the container. Selkies pushes desktop copies to the browser with `navigator.clipboard.writeText()` (needs the page focused) and reads the host clipboard with `navigator.clipboard.readText()` **only on a window `focus` event**, having first checked the `clipboard-read` permission. In practice: use a Chromium-based browser, allow the clipboard permission when prompted, and after copying on the host click into the desktop once so the page regains focus. Firefox does not expose `readText()` to web content, so host-to-desktop sync cannot work there.

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [LinuxServer Webtop](https://github.com/linuxserver/docker-webtop)
- [Selkies documentation](https://selkies-project.github.io/selkies/)
