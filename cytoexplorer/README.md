# Flow Cytometry Analysis with Shiny

An interactive flow cytometry data analysis application for Seqera Platform Studios.

## Overview

This example demonstrates how to create a custom Studios container running a Shiny application for flow cytometry data analysis. The app provides an interactive interface for visualizing and analyzing FCS files with support for multi-sample comparisons and data export.

## Features

- **Interactive Visualization**: 2D scatter plots with customizable channels
- **Multi-Sample Analysis**: View up to 9 samples simultaneously in a grid layout
- **File Upload**: Support for standard FCS file formats (2.0, 3.0, 3.1)
- **Sample Data**: Includes test FCS files for quick demonstration
- **Data Export**: Download plots as PNG and data as CSV

## Technology Stack

- **R 4.3** with Bioconductor packages
- **flowCore** & **flowWorkspace**: Flow cytometry data handling
- **Shiny**: Interactive web interface
- **ggplot2**: Data visualization
- **Seqera connect-client**: Studios integration

## Quick Start

### 1. Build the Container

```bash
docker build --platform linux/amd64 -t flowcyto-shiny-app:latest .
```

### 2. Push to Container Registry

```bash
# Example: GitHub Container Registry
docker tag flowcyto-shiny-app:latest ghcr.io/YOUR_USERNAME/flowcyto-shiny-app:latest
docker push ghcr.io/YOUR_USERNAME/flowcyto-shiny-app:latest

# Or Docker Hub
docker tag flowcyto-shiny-app:latest YOUR_USERNAME/flowcyto-shiny-app:latest
docker push YOUR_USERNAME/flowcyto-shiny-app:latest
```

### 3. Configure in Seqera Platform

1. Navigate to your workspace in Seqera Platform
2. Go to **Studios** → **Add Studio**
3. Configure:
   - **Name**: Flow Cytometry Analysis
   - **Container Image**: `ghcr.io/YOUR_USERNAME/flowcyto-shiny-app:latest`
   - **Compute Environment**: Select your environment
   - **Instance Type**: Minimum 2 CPU / 8GB RAM
4. Launch the Studio

## Container Architecture

The Dockerfile demonstrates:

- **Multi-stage build**: Pulling Seqera connect-client binary
- **Conda environment management**: Using micromamba for lightweight package management
- **Bioconductor integration**: Installing specialized bioinformatics packages
- **Proper entrypoint configuration**: Using connect-client for Studios integration
- **Dynamic port binding**: Via `CONNECT_TOOL_PORT` environment variable

## Files Structure

```
.
├── Dockerfile          # Container definition with R and Bioconductor packages
├── app.R              # Shiny application for flow cytometry analysis
├── test_data/         # Sample FCS files for testing
│   ├── sample1_control.fcs
│   ├── sample2_treated.fcs
│   └── sample3_alt.fcs
└── README.md
```

## Usage

### Using Test Data

The app includes three sample FCS files in the `test_data/` directory for immediate testing:
- Control sample
- Treated sample
- Alternative condition sample

### Uploading Custom Data

1. Click "Browse..." to select FCS files
2. Upload one or more files (supports batch upload)
3. Select sample from dropdown
4. Choose X/Y channels for visualization
5. Explore and export results

### Available Visualizations

- **Single Sample View**: Detailed 2D scatter plot with customizable axes
- **Multi-Sample View**: 3x3 grid layout for comparing up to 9 samples
- **Statistics Panel**: Event counts and channel information

## System Requirements


### Runtime Requirements
- **Minimum**: 2 CPU, 8GB RAM
- **Recommended**: 4 CPU, 16GB RAM (for large FCS files)

## Customization

### Adding R Packages

Edit the Dockerfile to include additional packages:

```dockerfile
RUN rm -rf /opt/conda/pkgs/*.lock && \
    micromamba create -y -n flowcyto \
    -c conda-forge \
    -c bioconda \
    r-base=4.3 \
    r-shiny \
    your-additional-package \
    && micromamba clean --all --yes
```

### Modifying the Application

Edit `app.R` to customize:
- UI layout and styling
- Analysis workflows
- Visualization options
- Export formats

## Troubleshooting

### Build Issues

**Long build times**: R package compilation can take 5-10 minutes
- Solution: Be patient, this is normal for Bioconductor packages

**Package installation fails**:
- Check network connectivity
- Verify conda channel availability (conda-forge, bioconda)

### Runtime Issues

**App fails to load**:
- Ensure minimum 8GB RAM is allocated
- Check Seqera Platform logs for startup errors

**Upload fails**:
- Verify FCS file format is valid (2.0, 3.0, or 3.1)
- Check file size limits in your compute environment

## Resources

- [Seqera Platform Documentation](https://docs.seqera.io/)
- [flowCore Documentation](https://bioconductor.org/packages/flowCore/)
- [Shiny Documentation](https://shiny.rstudio.com/)

## License

This example is provided as-is for use with Seqera Platform.

---

**Part of [Seqera Custom Studios Examples](https://github.com/seqeralabs/custom-studios-examples)**
