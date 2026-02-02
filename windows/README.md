# Wine for Windows Software in Seqera Studios

Run Windows software on Linux in Seqera Studios using Wine. **Three container options** are provided, with varying complexity and compatibility.

## ⚠️ Architecture Notice

If you're building on **Apple Silicon (ARM64)**, use the **Wine Desktop** option. Bottles may not work due to Flatpak limitations on ARM architecture.

## 🎯 Recommended Option: Wine Desktop

**Use `Dockerfile.wine-desktop`** - This provides:
- ✅ Reliable installation on all architectures
- ✅ Web-accessible Xfce desktop
- ✅ Wine pre-configured and ready
- ✅ Desktop shortcuts for common tasks
- ✅ File manager for easy data access
- ✅ No Flatpak/Bottles dependencies

## Three Container Options

### 1. Wine Desktop (RECOMMENDED) ⭐

**File**: `Dockerfile.wine-desktop`  
**Best for**: Most users, works on ARM64 and x86_64

**Features**:
- Full Xfce desktop in browser
- Wine pre-installed and configured
- Desktop shortcuts for Wine tools
- File manager access to mounted data
- Most reliable and compatible

**Resources**: 2+ CPU, 4+ GB RAM

---

### 2. Wine CLI (Lightweight)

**File**: `Dockerfile.wine-simple`  
**Best for**: Command-line users, automation

**Features**:
- Web terminal (TTYD)
- Direct Wine CLI access
- Minimal resources
- Faster startup

**Resources**: 1+ CPU, 2+ GB RAM

---

### 3. Bottles GUI (Experimental)

**File**: `Dockerfile.bottles`  
**Best for**: Users who specifically need Bottles

**Features**:
- Bottles application GUI
- Wine environment management
- May not work on all systems

**Resources**: 2+ CPU, 4+ GB RAM

⚠️ **Note**: Bottles installation via Flatpak can be unreliable, especially on ARM64. If this fails, use Wine Desktop instead.

---

## Quick Start

### Build the Recommended Container

```bash
# Build Wine Desktop (recommended)
./build.sh wine-desktop ghcr.io/myorg

# Or build manually
docker build --build-arg CONNECT_CLIENT_VERSION=0.8 \
  -t your-registry/studios-wine-desktop:latest \
  -f Dockerfile.wine-desktop .
```

### Build All Containers

```bash
./build.sh all ghcr.io/myorg --no-cache
```

---

## Deploying to Seqera Studios

### Prerequisites
- Wave configured in workspace ([docs](https://docs.seqera.io/platform-cloud/wave/))
- Container repository set in **Settings > Studios > Container repository**
- Credentials for your registry

### Deployment Steps

1. **Navigate to Studios** tab
2. **Click "Add Studio"**

#### General Config:
- Container template: **"Prebuilt container image"**
- Container image: `your-registry/studios-wine-desktop:latest`
- Studio name: "Wine Desktop for Windows Apps"

#### Compute and Data:
- **CPU**: 2+ (4 recommended)
- **Memory**: 4+ GB (8 GB recommended)
- **Mount data**: Mount S3 buckets with Windows installers

3. **Click "Add and start"**

---

## Using Wine in Studios

### Wine Desktop Option

1. **Access the Desktop**: Studio opens showing Xfce desktop
2. **Desktop Shortcuts Available**:
   - **Wine Configuration**: Configure Wine settings
   - **Winetricks**: Install Windows components (DirectX, .NET, etc.)
   - **Data Files**: Browse your mounted S3 data
   - **Terminal**: Command-line access

3. **Install Windows Software**:
   - Open **Data Files** to browse to your .exe/.msi file
   - Right-click → **Open With** → **Wine**
   - Follow installation wizard

4. **Run Windows Apps**:
   - Installed apps appear in Xfce application menu
   - Or run from terminal: `wine /path/to/app.exe`

### Wine CLI Option

1. **Access Terminal**: Studio opens web terminal
2. **Run Windows Software**:
   ```bash
   # Run executable
   wine /workspace/data/my-bucket/app.exe
   
   # Install MSI
   wine msiexec /i /workspace/data/my-bucket/installer.msi
   
   # Configure Wine
   winecfg
   
   # Install components
   winetricks dotnet48 vcrun2019
   ```

---

## Architecture Compatibility

| Container | x86_64 | ARM64 (Apple Silicon) |
|-----------|--------|----------------------|
| Wine Desktop | ✅ Full support | ✅ Works (64-bit only) |
| Wine CLI | ✅ Full support | ✅ Works (64-bit only) |
| Bottles GUI | ✅ Should work | ⚠️ May fail |

**Notes**:
- ARM64 runs 64-bit Windows apps only (no 32-bit support)
- Most modern Windows apps are 64-bit compatible
- For 32-bit app support, build/deploy on x86_64 systems

---

## Troubleshooting

### Build Failures

**Problem**: Bottles installation fails  
**Solution**: Use Wine Desktop instead: `./build.sh wine-desktop`

**Problem**: Wine fails on ARM64  
**Solution**: This is expected - we removed 32-bit support for ARM compatibility

**Problem**: Build very slow  
**Solution**: Normal - desktop environment is large (~1-2 GB)

### Runtime Issues

**Desktop doesn't load**:
- Wait 60 seconds for full startup
- Check CPU/RAM allocation meets minimum
- Check Studio logs for errors

**Windows app won't run**:
- Try different Wine version via `winecfg`
- Install dependencies: `winetricks vcrun2019 dotnet48`
- Check [WineHQ AppDB](https://appdb.winehq.org/) for known issues

**Performance issues**:
- Increase CPU/memory allocation
- Use Wine CLI for simpler apps
- Some Windows apps are inherently slow in Wine

---

## File Access

Mounted S3 buckets appear at:
```
/workspace/data/<bucket-name>/
```

**Wine Desktop**: Use "Data Files" shortcut or file manager  
**Wine CLI**: Navigate with `cd /workspace/data/`

---

## Common Wine Commands

```bash
# Check Wine version
wine --version

# Configure Wine (opens GUI)
winecfg

# Install Windows components
winetricks

# Common components:
winetricks dotnet48      # .NET Framework
winetricks vcrun2019     # Visual C++ Runtime
winetricks corefonts     # Microsoft fonts
winetricks d3dx9         # DirectX 9

# Run Windows executable
wine application.exe

# Install MSI package
wine msiexec /i installer.msi

# Kill Wine processes
wineserver -k

# List installed programs
ls ~/.wine/drive_c/Program\ Files/
```

---

## Comparison Table

| Feature | Wine Desktop | Wine CLI | Bottles GUI |
|---------|-------------|----------|-------------|
| **Ease of Use** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Reliability** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| **ARM64 Support** | ✅ | ✅ | ❌ |
| **Resource Usage** | Medium | Low | Medium-High |
| **GUI Installers** | ✅ | ❌ | ✅ |
| **File Browsing** | ✅ | ❌ | ✅ |
| **Startup Time** | ~30-60s | ~10s | ~30-60s |

---

## Advanced Configuration

### Custom Wine Versions

Wine Desktop and Wine CLI use system Wine. To use specific versions:

1. Modify Dockerfile to add Wine HQ repository:
```dockerfile
RUN wget -nc https://dl.winehq.org/wine-builds/winehq.key && \
    apt-key add winehq.key && \
    add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ jammy main'
```

2. Install specific version:
```dockerfile
RUN apt-get install -y --install-recommends winehq-stable
```

### Persistent Wine Configuration

Wine prefix is at `/root/.wine` in the container. For persistence between Studio sessions, consider:
- Mounting an EBS volume to `/root/.wine`
- Using Wine's export feature before session ends
- Storing complete Wine prefix in S3

---

## Resources

- [Wine Documentation](https://www.winehq.org/documentation)
- [WineHQ AppDB](https://appdb.winehq.org/) - Check app compatibility
- [Winetricks](https://wiki.winehq.org/Winetricks)
- [Seqera Studios Docs](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Custom Studios Examples](https://github.com/seqeralabs/custom-studios-examples)

---

## Contributing

Improvements welcome:
- Better Wine configuration defaults
- Additional pre-installed components
- Performance optimizations
- Better Bottles/Flatpak installation

---

## License

This Dockerfile is provided as-is for use with Seqera Studios. Wine and other components maintain their respective licenses.