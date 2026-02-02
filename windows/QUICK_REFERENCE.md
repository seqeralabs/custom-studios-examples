# Quick Reference Card

## Container Images

### Bottles GUI (Full Desktop)
- **Dockerfile**: `Dockerfile.bottles`
- **Image tag**: `your-registry/studios-bottles:latest`
- **Size**: ~2-3 GB
- **Startup**: ~30-60 seconds
- **Resources**: 2+ CPU, 4+ GB RAM

### Wine CLI (Terminal)
- **Dockerfile**: `Dockerfile.wine-simple`
- **Image tag**: `your-registry/studios-wine:latest`
- **Size**: ~800 MB
- **Startup**: ~10-15 seconds
- **Resources**: 1+ CPU, 2+ GB RAM

## Build Commands

```bash
# Quick build both
./build.sh both your-registry

# Manual build
docker build --build-arg CONNECT_CLIENT_VERSION=0.9 \
  -t TAG -f DOCKERFILE .
```

## Deployment in Seqera Studios

1. **General Config**:
   - Container template: "Prebuilt container image"
   - Container image: `your-registry/studios-[bottles|wine]:latest`

2. **Compute & Data**:
   - CPU: 2+ (Bottles), 1+ (Wine)
   - Memory: 4+ GB (Bottles), 2+ GB (Wine)
   - Mount S3 buckets with Windows installers

3. **Click**: "Add and start"

## Common Issues

| Issue | Solution |
|-------|----------|
| Desktop doesn't load | Wait 60s, check resources |
| Bottles won't start | Run `flatpak run com.usebottles.bottles` |
| App won't install | Check Wine version, install dependencies |
| Slow performance | Increase CPU/RAM allocation |

## Useful Wine Commands

```bash
# Run Windows app
wine app.exe

# Install MSI
wine msiexec /i installer.msi

# Configure Wine
winecfg

# Install dependencies
winetricks dotnet48 vcrun2019

# Kill Wine
wineserver -k
```

## File Access

Mounted S3 buckets appear at:
```
/workspace/data/<bucket-name>/
```

## Support Resources

- [Bottles Docs](https://docs.usebottles.com/)
- [Wine HQ](https://www.winehq.org/)
- [WineHQ AppDB](https://appdb.winehq.org/)
- [Seqera Studios Docs](https://docs.seqera.io/platform-cloud/studios/custom-envs)