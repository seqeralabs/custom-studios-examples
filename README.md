# Wine for Windows Studio Environment

This branch contains the Seqera Studios configuration for running Windows software on Linux using Wine.

## Quick Start

### Add from Git Repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace
2. Select **Git repository** as the source
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`
4. Select branch: `windows`
5. Select your compute environment
6. Click **Add** then **Start**

### Alternative: Use Pre-built Image

```
ghcr.io/seqeralabs/custom-studios-examples/windows:latest
```

### Alternative: Build with Wave CLI

```bash
wave -f .seqera/Dockerfile --context .seqera --platform linux/amd64 --await --tower-token "$TOWER_ACCESS_TOKEN"
```

## Features

- Reliable installation on all architectures
- Web-accessible Xfce desktop
- Wine pre-configured and ready
- Desktop shortcuts for common tasks
- File manager for easy data access
- No Flatpak/Bottles dependencies

## Docker Image

```
ghcr.io/seqeralabs/custom-studios-examples/windows:latest
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `CONNECT_TOOL_PORT` | Set by platform | Server port |


## References

- [Seqera Studios: Custom Environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Seqera Studios: Add from Git Repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Wine Documentation](https://www.winehq.org/documentation)
- [WineHQ AppDB](https://appdb.winehq.org/) - Check app compatibility
- [Winetricks](https://wiki.winehq.org/Winetricks)
- [Micromamba Documentation](https://mamba.readthedocs.io/)