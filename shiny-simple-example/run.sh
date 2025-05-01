#!/bin/bash

# Set port based on environment
PORT=${CONNECT_TOOL_PORT:-3000}

# Define the Shiny command
SHINY_CMD="shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=${PORT})"

# Run the appropriate command based on environment
if [ -n "$CONNECT_TOOL_PORT" ]; then
    # In Seqera Studios
    exec /usr/bin/connect-client --entrypoint "micromamba run -n shiny R -e '${SHINY_CMD}'"
else
    # Local testing
    micromamba run -n shiny R -e "${SHINY_CMD}"
fi 