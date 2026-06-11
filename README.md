# QuPath KasmVNC Studio Environment

This branch contains the Seqera Studios configuration for running [QuPath](https://qupath.github.io/) through [KasmVNC](https://kasmweb.com/kasmvnc).

The Studio uses this pre-built container image:

```text
ghcr.io/seqeralabs/custom-studios-examples/development:qupath-pr17
```

## Add from Git repository

1. Navigate to **Studios** > **Add Studio** in your Seqera Platform workspace.
2. Select **Git repository** as the source.
3. Enter the repository URL: `https://github.com/seqeralabs/custom-studios-examples`.
4. Select branch: `kasmvnc-qupath`.
5. Select your compute environment.
6. Click **Add**, then **Start**.

## Configuration

The `.seqera/studio-config.yaml` file uses the registry template:

```yaml
session:
  template:
    kind: "registry"
    registry: "ghcr.io/seqeralabs/custom-studios-examples/development:qupath-pr17"
```

QuPath is x86_64 only, so run this Studio on `linux/amd64` compatible compute.

## References

- [Seqera Studios: Import from a Git repository](https://docs.seqera.io/platform-cloud/studios/add-studio-git-repo)
- [Seqera Studios: Custom environments](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [QuPath Documentation](https://qupath.readthedocs.io/)
- [KasmVNC Documentation](https://kasmweb.com/kasmvnc)
