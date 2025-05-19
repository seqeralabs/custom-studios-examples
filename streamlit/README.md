# Streamlit Example

This example contains a Dockerfile that builds a container image for running a Streamlit application with Seqera Studios.

![Screenshot of the Streamlit app](screenshot.png)

## Features

- Streamlit-based MultiQC visualization platform
- Interactive data analysis and visualization
- Compatible with both local Docker testing and Seqera Studios
- Automatic data mounting via datalinks

## Files

- `Dockerfile`: Container definition using multi-stage build that clones the MultiQC example repository and its dependencies

## Local Testing

To test the app locally for testing purposes you need to override the entrypoint:

```bash
docker build --platform=linux/amd64 -t streamlit-example .
docker run -p 3000:3000 --entrypoint streamlit streamlit-example run /app/multiqc_app.py \
    --server.port=3000 \
    --server.address=0.0.0.0 \
    --server.enableCORS=false \
    --server.enableXsrfProtection=false \
    --server.enableWebsocketCompression=false \
    --browser.gatherUsageStats=false
```

The app will be available at http://localhost:3000

## Usage in Seqera Studios

To use this app in Seqera Studios:

1. Select the **Studios** tab in your workspace
2. Click **Add Studio**
3. In the **General config** section:
   - Select **Prebuilt container image** as the container template
   - Enter your container image URI: `cr.seqera.io/scidev/custom-studio-streamlit`
   - Set a **Studio name** and optional **Description**
4. Configure compute resources in the **Compute and Data** section:
   - Select your compute environment
   - Adjust CPU, GPU, and memory allocations as needed
   - Mount any required data using the **Mount data** option
5. Review the configuration in the **Summary** section
6. Click **Add and start** to create and launch the Studio

## Notes

- The app uses Streamlit for interactive data visualization
- The Dockerfile uses a multi-stage build to include the connect-client
- The container is built for linux/amd64 platform compatibility
- The example is based on the MultiQC Streamlit application
- The container uses Python 3.11 as the base image 