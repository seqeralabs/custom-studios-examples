# Shiny Example

This is a simple Shiny example that demonstrates how to create a Shiny app that can be run both locally and in Seqera Studios.

## Features

- Simple scatter plot visualization
- Interactive data filtering
- Automatic environment detection for local vs Studios deployment
- Compatible with both local Docker testing and Seqera Studios

## Files

- `app_plot_demo.R`: The main Shiny application
- `example_data.csv`: Sample data for the visualization
- `Dockerfile`: Container definition
- `run.sh`: Entrypoint script that handles both local and Studios environments

## Local Testing

To test the app locally:

```bash
docker build --platform=linux/amd64 -t shiny-simple-example .
docker run --rm --platform=linux/amd64 -p 3000:3000 shiny-simple-example
```

The app will be available at http://localhost:3000

## Usage in Seqera Studios

To use this app in Seqera Studios:

1. Select the **Studios** tab in your workspace
2. Click **Add Studio**
3. In the **General config** section:
   - Select **Prebuilt container image** as the container template
   - Enter your container image URI, for example: `cr.seqera.io/scidev/shiny-simple-example`
   - Set a **Studio name** and optional **Description**
4. Configure compute resources in the **Compute and Data** section:
   - Select your compute environment
   - Adjust CPU, GPU, and memory allocations as needed
   - Mount any required data using the **Mount data** option
5. Review the configuration in the **Summary** section
6. Click **Add and start** to create and launch the Studio

The app will automatically detect the Studios environment and use the appropriate port through the `connect-client`.

## How It Works

The `run.sh` script automatically detects the execution environment:

- In Seqera Studios: Uses `connect-client` with the appropriate port from `CONNECT_TOOL_PORT`
- Local testing: Runs directly with the default port 3000

This dual-mode operation is handled by the entrypoint script, which checks for the presence of the `CONNECT_TOOL_PORT` environment variable to determine the execution context.

## Notes

- The app uses a simple scatter plot to demonstrate Shiny's capabilities
- The Dockerfile uses micromamba for efficient package management
- The container is built for linux/amd64 platform compatibility 