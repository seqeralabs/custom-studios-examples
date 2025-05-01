# Simple Shiny Example

This is a minimal example demonstrating basic Shiny plotting capabilities using only base R graphics. It's designed to work reliably in Seqera Studios.

## Features

- Interactive plot type selection (Scatter, Bar, Line)
- Color customization
- Point size adjustment for scatter plots
- Dynamic number of points/bars
- CSV file upload support
- No external JavaScript dependencies
- Lightweight base R graphics
- Works with multiple concurrent connections

## Files

- `Dockerfile`: Container configuration using micromamba and R-Shiny
- `app_plot_demo.R`: The Shiny application code
- `example_data.csv`: Sample data file for testing
- `run.sh`: Script that handles both local testing and Seqera Studios deployment

## Container

The container is available at:
```
cr.seqera.io/scidev/shiny-simple-example
```

## Running the Example

### Local Testing

1. Build the container:
   ```bash
   docker build -t shiny-simple-example .
   ```

2. Run the container:
   ```bash
   docker run --rm --platform=linux/amd64 -p 3000:3000 shiny-simple-example
   ```

   The container automatically detects whether it's running locally or in Seqera Studios and configures itself accordingly.

3. Access the app at `http://localhost:3000`

### Using in Seqera Studios

To use this container in Seqera Studios:

1. Push the container to your container registry
2. In Seqera Platform Cloud:
   - Go to Studios tab
   - Click "Add Studio"
   - In the "General config" section:
     - Select "Prebuilt container image" as the container template
     - Enter your container image URI
   - Configure other settings as needed (compute resources, data mounts, etc.)
   - Click "Add and start" to create and launch the Studio

## Usage

1. You can either:
   - Use the default generated data by adjusting the number of points/bars
   - Upload your own CSV file with 'x' and 'y' columns

2. Customize the plot:
   - Select different plot types (Scatter, Bar, Line)
   - Choose different colors
   - Adjust point size for scatter plots

## Notes

- This example uses only base R graphics to avoid JavaScript dependency issues
- The app is designed to work reliably in Seqera Studios
- The container uses micromamba for efficient R package management 