# Simplified Windows Desktop for Seqera Studios

# Stage 1: Get Seqera Connect client
ARG CONNECT_CLIENT_VERSION=0.10
FROM public.cr.seqera.io/platform/connect-client:${CONNECT_CLIENT_VERSION} AS connect

# Stage 2: Windows Desktop environment
FROM ubuntu:22.04

ARG CONNECT_CLIENT_VERSION
LABEL io.seqera.connect.version="${CONNECT_CLIENT_VERSION}"
LABEL org.opencontainers.image.source="https://github.com/seqeralabs/custom-studios-examples"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install desktop environment and Wine
RUN rm -f /etc/apt/sources.list.d/ubuntu.sources && \
    echo "deb [trusted=yes] http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb [trusted=yes] http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb [trusted=yes] http://security.ubuntu.com/ubuntu jammy-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update && apt-get install -y \
    # Get xdpyinfo
    x11-utils \
    # Lightweight desktop
    xfce4 \
    xfce4-terminal \
    dbus-x11 \
    # VNC server
    tigervnc-standalone-server \
    tigervnc-common \
    # noVNC for web access
    novnc \
    websockify \
    # Wine (works on both ARM64 and x86_64)
    wine \
    winetricks \
    winbind \
    # File manager and utilities
    thunar \
    mousepad \
    # Additional utilities
    wget \
    curl \
    unzip \
    cabextract \
    p7zip-full \
    xvfb \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create symlink so noVNC serves the VNC client at root URL
RUN ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Set up Wine environment
ENV WINEPREFIX=/root/.wine
ENV WINEARCH=win64
ENV DISPLAY=:1

# Initialize Wine
RUN wine wineboot --init && wineserver -w || true

# Set up VNC
RUN mkdir -p ~/.vnc && \
    echo "password" | vncpasswd -f > ~/.vnc/passwd && \
    chmod 600 ~/.vnc/passwd

# Configure Xfce
RUN mkdir -p ~/.config/xfce4/xfconf/xfce-perchannel-xml

# Copy Seqera Connect client
COPY --from=connect /usr/bin/connect-client /usr/bin/connect-client
RUN apt-get update && /usr/bin/connect-client --install

# Create startup script with Wine utilities
RUN mkdir -p /app && \
    echo '#!/bin/bash\n\
set -e\n\
\n\
cleanup() {\n\
    echo "Shutting down..."\n\
    kill $NOVNC_PID 2>/dev/null || true\n\
    vncserver -kill :1 2>/dev/null || true\n\
    exit 0\n\
}\n\
trap cleanup SIGTERM SIGINT\n\
\n\
export DISPLAY=:1\n\
\n\
# Kill existing VNC\n\
vncserver -kill :1 2>/dev/null || true\n\
\n\
# Start VNC\n\
echo "Starting VNC server on display :1"\n\
vncserver :1 -geometry 1920x1080 -depth 24 -localhost no -SecurityTypes None --I-KNOW-THIS-IS-INSECURE\n\
until xdpyinfo -display :1 >/dev/null 2>&1; do sleep 0.5; done\n\
\n\
# Start Xfce\n\
echo "Starting Xfce desktop environment"\n\
DISPLAY=:1 startxfce4 &\n\
\n\
# Create desktop shortcuts\n\
mkdir -p ~/Desktop\n\
\n\
# Wine Configuration\n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=Wine Configuration\n\
Comment=Configure Wine\n\
Exec=wine winecfg\n\
Icon=wine\n\
Terminal=false\n\
Categories=Wine;" > ~/Desktop/winecfg.desktop\n\
chmod +x ~/Desktop/winecfg.desktop\n\
\n\
# Winetricks\n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=Winetricks\n\
Comment=Install Windows components\n\
Exec=winetricks\n\
Icon=wine\n\
Terminal=true\n\
Categories=Wine;" > ~/Desktop/winetricks.desktop\n\
chmod +x ~/Desktop/winetricks.desktop\n\
\n\
# Notepad\n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=Notepad\n\
Comment=Windows Notepad via Wine\n\
Exec=wine notepad\n\
Icon=wine\n\
Terminal=false\n\
Categories=Wine;" > ~/Desktop/notepad.desktop\n\
chmod +x ~/Desktop/notepad.desktop\n\
\n\
# File Manager for data access\n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=Data Files\n\
Comment=Access mounted data\n\
Exec=thunar /workspace/data\n\
Icon=folder\n\
Terminal=false\n\
Categories=Utility;" > ~/Desktop/data.desktop\n\
chmod +x ~/Desktop/data.desktop\n\
\n\
# Terminal\n\
echo "[Desktop Entry]\n\
Version=1.0\n\
Type=Application\n\
Name=Terminal\n\
Comment=Open Terminal\n\
Exec=xfce4-terminal\n\
Icon=utilities-terminal\n\
Terminal=false\n\
Categories=System;" > ~/Desktop/terminal.desktop\n\
chmod +x ~/Desktop/terminal.desktop\n\
\n\
# Start noVNC\n\
echo "Starting noVNC web interface on port $CONNECT_TOOL_PORT"\n\
websockify --web /usr/share/novnc $CONNECT_TOOL_PORT localhost:5901 &\n\
NOVNC_PID=$!\n\
\n\
echo ""\n\
echo "========================================"\n\
echo "Wine Desktop Ready!"\n\
echo "========================================"\n\
echo ""\n\
echo "Desktop shortcuts available:"\n\
echo "  - Wine Configuration (winecfg)"\n\
echo "  - Winetricks (install components)"\n\
echo "  - Data Files (access /workspace/data)"\n\
echo "  - Terminal"\n\
echo ""\n\
echo "To run Windows apps:"\n\
echo "  1. Use File Manager to browse to your .exe file"\n\
echo "  2. Right-click and select Open With > Wine"\n\
echo "  OR"\n\
echo "  3. Open Terminal and run: wine /path/to/app.exe"\n\
echo ""\n\
echo "========================================"\n\
echo ""\n\
\n\
wait $NOVNC_PID' > /app/start.sh && \
    chmod +x /app/start.sh

# Set entrypoint
ENTRYPOINT ["/usr/bin/connect-client", "--entrypoint"]

# Start the application
CMD ["/bin/bash", "/app/start.sh"]