# QuPath KasmVNC Studio Environment

This branch contains the Seqera Studios configuration for running [QuPath](https://qupath.github.io/) with [KasmVNC](https://kasmweb.com/kasmvnc), making the QuPath desktop available through a browser in Seqera Platform.

> This is a branch of the [custom-studios-examples](https://github.com/seqeralabs/custom-studios-examples) repository. Each branch contains a different custom Studio configuration. See the `master` branch for an overview of all available Studios.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `kasmvnc-qupath`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/kasmvnc-qupath:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- QuPath 0.6.0 bioimage analysis desktop
- Browser access through LinuxServer.io KasmVNC
- Single-app mode that launches QuPath directly
- KasmVNC WebP, quality, frame-rate, and thread tuning for interactive use
- Compatible with Seqera Studios custom environments and Data Link mounts

> **Note:** QuPath is x86_64 only. Build and run this Studio as `linux/amd64`.

## Docker Image

The container image is available at:

```
ghcr.io/seqeralabs/custom-studios-examples/kasmvnc-qupath:latest
```

## Local Testing

```bash
cd .seqera
docker build --platform=linux/amd64 --build-arg CONNECT_CLIENT_VERSION=0.9 -t kasmvnc-qupath .
docker run --rm --platform linux/amd64 --shm-size=2g -p 6901:6901 --entrypoint /init kasmvnc-qupath
```

QuPath will be available at http://localhost:6901.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECT_TOOL_PORT` | Set by platform | KasmVNC web port in Seqera Studios |
| `CUSTOM_PORT` | `CONNECT_TOOL_PORT` or `6901` | KasmVNC web port used by the base image |

## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [QuPath Documentation](https://qupath.readthedocs.io/)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
