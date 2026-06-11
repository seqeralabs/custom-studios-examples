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
- KasmVNC WebP, quality, frame-rate, and thread tuning for interactive use

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [QuPath Documentation](https://qupath.readthedocs.io/)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
