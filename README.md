# Custom Studios Examples

This repository contains example Dockerfiles and configurations for custom Seqera Studio applications. Each example demonstrates how to create and deploy different types of interactive applications in Seqera Studios.

## Available Examples

- [Marimo Studio Environment](marimo/README.md) - A reactive Python notebook environment
- [CellxGene Example](cellxgene/README.md) - Interactive single-cell data visualization
- [Streamlit Example](streamlit/README.md) - MultiQC visualization using Streamlit
- [Shiny Example](shiny-simple-example/README.md) - Interactive data visualization with R Shiny

## Prerequisites

All examples in this repository require:
- [Docker](https://www.docker.com/) installed
- [Wave](https://docs.seqera.io/platform-cloud/wave/) configured in your Seqera Platform workspace
- Access to a container registry (public or Amazon ECR) for pushing your images

## Common Features

All examples in this repository:
- Are compatible with both local Docker testing and Seqera Studios
- Use the required Seqera base image and connect-client
- Include detailed setup and usage instructions
- Support data mounting via datalinks in Studios
- Are built for linux/amd64 platform compatibility
- Use multi-stage builds to include the connect-client
- Follow consistent container best practices

## Deploying to Seqera Studios

All examples follow the same deployment process:

1. Select the **Studios** tab in your workspace
2. Click **Add Studio**
3. In the **General config** section:
   - Select **Prebuilt container image** as the container template
   - Enter your container image URI (e.g., `cr.seqera.io/scidev/your-example`)
   - Set a **Studio name** and optional **Description**
4. Configure compute resources in the **Compute and Data** section:
   - Select your compute environment
   - Adjust CPU, GPU, and memory allocations as needed
   - Mount any required data using the **Mount data** option
5. Review the configuration in the **Summary** section
6. Click **Add and start** to create and launch the Studio

## Documentation

- [Official documentation on building custom studio environments](https://docs.seqera.io/platform-cloud/studios/custom-envs#custom-containers)
- Each example's README contains specific instructions for:
  - Building and testing locally
  - Required dependencies and configurations
  - Example-specific features and usage
  - Data format requirements
  - Customization options

## Contributing

Feel free to contribute new examples or improvements to existing ones. Each example should:
- Follow the established README structure
- Include comprehensive documentation
- Maintain consistency with common features
- Provide clear prerequisites and deployment instructions
- Include example data or clear data requirements

<!-- TODO Add a link to the blog post -->
