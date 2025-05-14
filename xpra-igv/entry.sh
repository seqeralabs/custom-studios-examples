#!/bin/bash

source /usr/local/bin/_activate_current_env.sh
# automatically initialize all future (bash) shells, so that micromambe environments can be activated and deactivated
micromamba shell init --shell bash --root-prefix=~/micromamba

# Default video encoder
video_encoder="x264"

# Check for NVIDIA or AMD GPU presence
if lspci | grep -E "VGA|3D|NVIDIA|AMD"; then
    # Assuming the presence of NVIDIA drivers and utilities
    if command -v nvidia-smi &> /dev/null; then
        video_encoder="nvenc"
    elif glxinfo | grep -i "direct rendering: Yes"; then
        # Check for AMD or other GPU types that support VA-API (Intel included)
        video_encoder="vaapi"
    fi
fi

exec xpra start \
--bind-tcp=0.0.0.0:$CONNECT_TOOL_PORT \
--mdns=no \
--html=on \
--pulseaudio=no \
--clipboard-direction=both \
--clipboard=yes \
--dpi=300 \
--encoding=auto \
--video-encoder=$video_encoder \
--min-quality=95 \
--min-speed=95 \
--desktop-scaling=auto \
--windows=yes \
--daemon=no \
--start="terminator" \
--idle-timeout=21600 \
--mousewheel=on \
--opengl=yes \
--tray=yes \
--system-tray=yes \
--sharing=yes \
--ssl=www \
--exit-with-client=no \
--file-transfer=on \
--open-files=no \
--webcam=no \
--notifications=no \
--bell=no :100
