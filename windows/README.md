# Bottles & Wine for Seqera Studios

Run Windows software on Linux in Seqera Studios. This repository provides two options:

1. **Bottles (GUI)**: Full desktop environment with Bottles application for easy Windows software management
2. **Wine (CLI)**: Lightweight command-line Wine access via web terminal

## Choose Your Option

### Option 1: Bottles (Full GUI) - Recommended for Most Users

**Best for:**
- Users who prefer graphical interfaces
- Installing Windows applications with setup wizards
- Running complex Windows software
- Managing multiple Windows environments

**What you get:**
- Full Xfce desktop in your browser
- Bottles GUI for easy Wine management
- Pre-configured environments
- Graphical dependency management

**File**: `Dockerfile.bottles`

### Option 2: Wine (Command-Line) - Lightweight Alternative

**Best for:**
- Command-line users
- Simpler Windows console applications
- Scripts and automation
- Minimal resource usage

**What you get:**
- Web-based terminal (TTYD)
- Direct Wine CLI access
- Smaller container size
- Faster startup

**File**: `Dockerfile.wine-simple`

---

## Quick Start

### Building

Use the provided build script:

```bash
# Build both containers
./build.sh both your-registry

# Build only Bottles GUI
./build.sh bottles ghcr.io/myorg

# Build only Wine CLI
./build.sh wine cr.seqera.io/myworkspace
```

Or build manually:

```bash
# Bottles GUI
docker build --build-arg CONNECT_CLIENT_VERSION=0.9 \
  -t your-registry/studios-bottles:latest \
  -f Dockerfile.bottles .

# Wine CLI
docker build --build-arg CONNECT_CLIENT_VERSION=0.9 \
  -t your-registry/studios-wine:latest \
  -f Dockerfile.wine-simple .
```

---

## Detailed Documentation

## What is Bottles?

Bottles is a user-friendly application that manages Wine environments (called "bottles") to run Windows software on Linux. It provides:
- Easy installation of Windows applications (.exe, .msi files)
- Pre-configured environments for gaming and applications
- Dependency management
- Multiple isolated Windows environments
- GUI for managing Wine prefixes

## How This Works

This container uses:
- **Xfce**: Lightweight desktop environment
- **TigerVNC**: VNC server for remote desktop access
- **noVNC**: Web-based VNC client (accessible via browser)
- **Bottles**: Installed via Flatpak for managing Windows software

When you launch this Studio, you'll access a full Linux desktop through your browser, where Bottles is ready to use.

## Building the Container

### Prerequisites
- Docker installed
- Access to a container registry (e.g., Docker Hub, GitHub Container Registry, Amazon ECR)

### Build Command

```bash
docker build \
  --build-arg CONNECT_CLIENT_VERSION=0.9 \
  -t your-registry/bottles-studios:latest \
  -f Dockerfile.bottles \
  .
```

### Push to Registry

```bash
docker push your-registry/bottles-studios:latest
```

## Testing Locally (Optional)

You can test the container locally before deploying to Studios:

```bash
# Run the container
docker run -p 8080:8080 \
  -e CONNECT_TOOL_PORT=8080 \
  your-registry/bottles-studios:latest

# Access in browser at http://localhost:8080
```

## Deploying to Seqera Studios

### Step 1: Configure Wave (if not already done)
Ensure Wave is configured in your workspace. See [Wave documentation](https://docs.seqera.io/platform-cloud/wave/).

### Step 2: Set Container Repository
In your workspace:
1. Go to **Settings > Studios > Container repository**
2. Set the target repository where images will be pushed

### Step 3: Add the Studio

1. Navigate to **Studios** tab in Seqera Platform
2. Click **Add Studio**

#### General Config Tab:
- **Container template**: Select "Prebuilt container image"
- **Container image**: Enter your image URI (e.g., `your-registry/bottles-studios:latest`)
- **Studio name**: "Bottles Windows Software"
- **Description**: "Run Windows applications via Bottles and Wine"

#### Compute and Data Tab:
- **Compute environment**: Select your compute environment
- **CPU**: Minimum 2 CPUs (4+ recommended for better performance)
- **Memory**: Minimum 4 GB (8+ GB recommended)
- **GPU**: Optional (can improve graphics performance for some applications)

**Mount Data** (if you have Windows installers or data):
- Mount any S3 buckets containing your Windows software installers
- Files will be available at `/workspace/data/<bucket-name>/`

3. Click **Add and start**

## Using Bottles in Studios

### First Launch

1. Once the Studio starts, you'll see an Xfce desktop in your browser
2. On the desktop, you'll find a "Bottles" icon
3. Double-click to launch Bottles

### Installing Windows Software

1. **Create a Bottle**:
   - Click "Create New Bottle"
   - Choose a name (e.g., "MyApp")
   - Select environment type:
     - **Application**: For general Windows software
     - **Gaming**: For Windows games
     - **Custom**: For advanced users

2. **Install Software**:
   - Click on your bottle to open it
   - Click the "Run Executable" button (cube icon)
   - Browse to your .exe or .msi installer
   - Follow the Windows installation wizard

3. **Run Software**:
   - After installation, installed programs appear under "Programs"
   - Click the play/arrow icon to launch them

### Accessing Your Files

If you mounted S3 buckets in Studios:
- Your data is available at `/workspace/data/<bucket-name>/`
- Use the Xfce file manager to navigate to these locations
- You can install Windows software from these locations

### Tips for Best Performance

1. **Resolution**: The desktop is set to 1920x1080. Adjust if needed in Display Settings.

2. **Wine Version**: Bottles manages Wine versions automatically. For better compatibility:
   - Go to Preferences > Runners in Bottles
   - Try different Wine or Proton versions

3. **Dependencies**: Bottles has a dependency manager:
   - In your bottle, go to Dependencies tab
   - Install common libraries like .NET, Visual C++ runtimes as needed

4. **Persistence**: 
   - Bottles data persists within the EC2 instance during the Studio session
   - To keep Bottles data between sessions, consider mounting a persistent EBS volume
   - Alternatively, use Bottles' export/import feature to backup bottles

## Architecture Details

### Container Structure

```
┌─────────────────────────────────────┐
│     Seqera Studios (Browser)        │
└──────────────┬──────────────────────┘
               │ HTTP
               ↓
┌─────────────────────────────────────┐
│  noVNC (port $CONNECT_TOOL_PORT)    │
└──────────────┬──────────────────────┘
               │ WebSocket
               ↓
┌─────────────────────────────────────┐
│    TigerVNC Server (port 5901)      │
└──────────────┬──────────────────────┘
               │ X11
               ↓
┌─────────────────────────────────────┐
│      Xfce Desktop Environment       │
│    ┌────────────────────────────┐   │
│    │  Bottles (Flatpak)         │   │
│    │    └── Wine/Proton         │   │
│    │        └── Windows Apps    │   │
│    └────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Environment Variables

- `CONNECT_TOOL_PORT`: Automatically set by Studios, used by noVNC
- `DISPLAY`: Set to `:1` for VNC display

### Signal Handling

The container properly handles SIGTERM for graceful shutdown, ensuring:
- VNC server stops cleanly
- Desktop sessions close properly
- No orphaned processes

## Limitations and Considerations

1. **Performance**: Running a full desktop in a container adds overhead. Performance depends on:
   - Allocated CPU/memory
   - Network latency
   - Complexity of Windows applications

2. **Graphics**: 
   - Software rendering only (no GPU acceleration by default)
   - May not be suitable for graphics-intensive games or CAD software
   - Can add GPU support if needed for specific workloads

3. **Windows Compatibility**:
   - Not all Windows software works perfectly in Wine
   - Check [WineHQ AppDB](https://appdb.winehq.org/) for compatibility
   - Complex applications may require additional configuration

4. **Security**:
   - VNC runs without authentication (protected by Studios access control)
   - Don't expose VNC port directly to internet
   - Studios handles authentication and authorization

## Troubleshooting

### Desktop doesn't load
- Wait 30-60 seconds for all services to start
- Check compute resources are sufficient (min 2 CPU, 4GB RAM)
- Check Studio logs for errors

### Bottles won't launch
- Ensure Flatpak is working: `flatpak list` in terminal
- Check permissions: `flatpak run com.usebottles.bottles` from terminal
- Review logs: `journalctl --user -f`

### Windows application won't install
- Try a different Wine/Proton version in Bottles
- Check if dependencies are needed (vcredist, .NET, etc.)
- Consult WineHQ AppDB for known issues

### Performance issues
- Increase CPU/memory allocation
- Close unnecessary programs
- Use lighter-weight Windows applications when possible

## Using Wine CLI (Simple Option)

If you built the Wine CLI container (`Dockerfile.wine-simple`), here's how to use it:

### First Launch

1. Once the Studio starts, you'll see a web terminal (TTYD)
2. A welcome message displays common Wine commands
3. Wine is pre-initialized and ready to use

### Running Windows Software

```bash
# Run a Windows executable
wine /workspace/data/my-bucket/application.exe

# Install an MSI package
wine msiexec /i /workspace/data/my-bucket/installer.msi

# Install .NET Framework
winetricks dotnet48

# Configure Wine
winecfg
```

### Common Wine Commands

```bash
# Check Wine version
wine --version

# Install Windows components (fonts, libraries, etc.)
winetricks

# List installed components
winetricks list-installed

# Kill Wine processes
wineserver -k

# Show Windows registry editor
wine regedit
```

### Advantages of Wine CLI
- Faster startup (no desktop environment)
- Lower resource usage (~1-2 GB RAM vs 4+ GB for GUI)
- Better for automation and scripts
- Direct command-line control

### Limitations
- No graphical installer wizards
- Requires knowledge of Wine commands
- Less user-friendly for complex setups
- No Bottles GUI features

## Alternative Approach: Command-Line Wine

For a lighter-weight alternative without Bottles GUI, consider using Wine directly with TTYD (web terminal). See the [TTYD example](https://github.com/seqeralabs/custom-studios-examples/tree/master/ttyd) from Seqera's custom Studios repository.

## Resources

- [Bottles Documentation](https://docs.usebottles.com/)
- [Seqera Studios Documentation](https://docs.seqera.io/platform-cloud/studios/custom-envs)
- [Wine HQ](https://www.winehq.org/)
- [Custom Studios Examples](https://github.com/seqeralabs/custom-studios-examples)

## Contributing

To improve this container:
- Optimize desktop startup time
- Add more pre-configured Wine versions
- Improve graphics performance
- Add common Windows dependencies pre-installed

## License

This Dockerfile is provided as-is for use with Seqera Studios. Bottles, Wine, and other components maintain their respective licenses.