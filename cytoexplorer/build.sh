#!/bin/bash
set -e

# Configuration
CONNECT_CLIENT_VERSION="0.9"
IMAGE_NAME="cytoexplorer-studios"
IMAGE_TAG="latest"

# Parse arguments
REGISTRY=""
PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --registry)
            REGISTRY="$2"
            shift 2
            ;;
        --push)
            PUSH=true
            shift
            ;;
        --tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--registry REGISTRY] [--push] [--tag TAG]"
            echo "  --registry REGISTRY  Container registry URL (e.g., ghcr.io/username)"
            echo "  --push              Push image to registry after build"
            echo "  --tag TAG           Image tag (default: latest)"
            exit 1
            ;;
    esac
done

# Build the image
echo "Building CytoExploreR Studios container..."
docker build \
    --build-arg CONNECT_CLIENT_VERSION=${CONNECT_CLIENT_VERSION} \
    -t ${IMAGE_NAME}:${IMAGE_TAG} \
    .

echo "✅ Build complete: ${IMAGE_NAME}:${IMAGE_TAG}"

# Tag and push if registry specified
if [ -n "$REGISTRY" ]; then
    FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
    echo "Tagging image as ${FULL_IMAGE}..."
    docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${FULL_IMAGE}

    if [ "$PUSH" = true ]; then
        echo "Pushing ${FULL_IMAGE} to registry..."
        docker push ${FULL_IMAGE}
        echo "✅ Push complete!"
        echo ""
        echo "Use this URI in Seqera Studios:"
        echo "  ${FULL_IMAGE}"
    else
        echo ""
        echo "To push to registry, run:"
        echo "  docker push ${FULL_IMAGE}"
        echo ""
        echo "Or re-run with --push flag:"
        echo "  $0 --registry ${REGISTRY} --push"
    fi
else
    echo ""
    echo "To tag and push to a registry:"
    echo "  $0 --registry <your-registry> --push"
    echo ""
    echo "Example registries:"
    echo "  - Docker Hub: docker.io/username"
    echo "  - GitHub: ghcr.io/username"
    echo "  - AWS ECR: 123456789.dkr.ecr.us-east-1.amazonaws.com"
fi
