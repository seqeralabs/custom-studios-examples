# QuPath KasmVNC Studio Environment

This branch contains the Seqera Studios configuration for running [QuPath](https://qupath.github.io/) through [KasmVNC](https://kasmweb.com/kasmvnc).

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `kasmvnc-qupath`.
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

QuPath is x86_64 only, so run this Studio on `linux/amd64` compatible compute.

## Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- QuPath 0.6.0 bioimage analysis desktop
- Browser access through LinuxServer.io KasmVNC
- Single-app mode that launches QuPath directly
- A desktop that expands to fill the browser window
- A 1.5× QuPath interface scale so controls remain readable on large displays
- 30 FPS streaming, four compression threads, and high-quality text updates for responsive interaction
- Startup proxy that serves a loading page until KasmVNC is ready, avoiding first-load 502 errors

## Display and streaming defaults

KasmVNC resizes the remote desktop to fill the browser window. QuPath's JavaFX interface is scaled independently, so the extra space does not make its menus and controls too small.

For a different environment, override any of these Studio environment variables:

| Variable | Default | Purpose |
| --- | --- | --- |
| `QUPATH_UI_SCALE` | `1.5` | QuPath interface scale; use `1.0` for standard density or increase it for high-density displays |
| `KASMVNC_FRAME_RATE` | `30` | Maximum streamed frames per second |
| `KASMVNC_RECT_THREADS` | `4` | Parallel compression threads |
| `KASMVNC_DYNAMIC_QUALITY_MIN` | `7` | Lowest quality used while the screen is changing |
| `KASMVNC_DYNAMIC_QUALITY_MAX` | `8` | Quality used for mostly static content such as text |

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [QuPath Documentation](https://qupath.readthedocs.io/)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
