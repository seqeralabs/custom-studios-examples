#!/bin/bash

# Set the port based on environment
PORT=${CONNECT_TOOL_PORT:-3000}

# Run the app
if [ -n "$CONNECT_TOOL_PORT" ]; then
    # Run with connect-client entrypoint (for Seqera Studios)
    exec /usr/bin/connect-client --entrypoint micromamba run -n shiny R -e "shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=$PORT)"
else
    # Run directly for local testing
    exec micromamba run -n shiny R -e "shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=$PORT)"
fi 