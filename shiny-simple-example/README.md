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

To test the app locally for testing purposes you need to override the entrypoint:

```bash
docker build --platform=linux/amd64 -t shiny-simple-example .
docker run -p 3000:3000 --entrypoint micromamba shiny-simple-example run -n shiny R -e "shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=3000)"
```

To point at a specific data file rather than the input example, make it available at /workspace/data/shiny-inputs/data.csv in the container. For example if data.csv was in the current directory:

```bash
docker run -p 3000:3000 --entrypoint micromamba -v $(pwd)/../data/shiny-inputs:/workspace/data/shiny-inputs shiny-simple-example run -n shiny R -e "shiny::runApp('/app/app_plot_demo.R', host='0.0.0.0', port=3000)"
```

The app will be available at http://localhost:3000

## Usage in Seqera Studios

To use this app in Seqera Studios:

Create a data link called 'shiny-inputs' and place your input file called 'data.csv' there.

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

## Notes

- The app uses a simple scatter plot to demonstrate Shiny's capabilities
- The Dockerfile uses micromamba for efficient package management
- The container is built for linux/amd64 platform compatibility 