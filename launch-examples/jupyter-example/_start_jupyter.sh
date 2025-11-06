#!/usr/bin/env bash

# Path to bash
export SHELL=/usr/bin/bash

# Configure Jupyter
if [ -n "$CONNECT_TOOL_PATH_PREFIX" ]; then
  JUPYTER_BASE_PATH="--NotebookApp.base_url=$CONNECT_TOOL_PATH_PREFIX"
else
  JUPYTER_BASE_PATH=""
fi

# Initialize Jupyter and listen on Connect port
exec jupyter lab \
     --port $CONNECT_TOOL_PORT \
     --IdentityProvider.token='' \
     --allow-root \
     --ServerApp.allow_remote_access=True \
     --no-browser \
     --NotebookApp.allow_origin=* \
     $JUPYTER_BASE_PATH