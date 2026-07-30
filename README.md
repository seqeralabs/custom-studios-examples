# Selkies Webtop Studio Environment

This branch contains a prototype Seqera Studios configuration for running a full Ubuntu KDE desktop through [Selkies](https://selkies-project.github.io/selkies/) using the LinuxServer.io Webtop base image.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `feat/selkies-webtop`.
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

This prototype uses `lscr.io/linuxserver/webtop:ubuntu-kde`, so it is best suited to `linux/amd64` compute with enough CPU and memory for a full desktop session.

## Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Full Ubuntu KDE desktop delivered through Selkies
- Seqera `connect-client` integration for Studio-compatible startup
- Wayland-first desktop configuration for the modern low-latency rendering path
- Automatic GPU enablement when `/dev/dri` is available in the runtime
- Direct binding of Webtop's internal HTTP listener to `CONNECT_TOOL_PORT` for simpler Studio startup

## Runtime defaults

The container is configured with these defaults:

| Variable | Default | Purpose |
| --- | --- | --- |
| `TITLE` | `Selkies Ubuntu KDE Desktop` | Browser tab title shown by Webtop |
| `SELKIES_DESKTOP` | `true` | Enables the full desktop experience in Selkies mode |
| `PIXELFLUX_WAYLAND` | `true` | Uses the modern Wayland rendering path when supported |
| `AUTO_GPU` | `true` | Automatically uses the first available render node for acceleration |

If you want a lighter prototype later, the base image can be switched to `lscr.io/linuxserver/webtop:ubuntu-xfce`.

## Notes

- I did not run `docker build`, because this environment is set to avoid Docker execution unless explicitly requested.
- LinuxServer’s Webtop documentation notes that Wayland mode is the preferred acceleration path and that the image listens on internal HTTP port `3000` by default. This Studio overrides that with `CUSTOM_PORT=$CONNECT_TOOL_PORT` so the container binds directly to the port Seqera expects.

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [LinuxServer Webtop](https://github.com/linuxserver/docker-webtop)
- [Selkies documentation](https://selkies-project.github.io/selkies/)
