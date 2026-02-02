#!/bin/bash

# Build script for Bottles/Wine Seqera Studios containers
# Usage: ./build.sh [bottles|wine|both] [registry]

set -e

CONNECT_VERSION="0.9"
DEFAULT_REGISTRY="your-registry"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
BUILD_TYPE="${1:-both}"
REGISTRY="${2:-$DEFAULT_REGISTRY}"

echo -e "${GREEN}=== Seqera Studios Bottles/Wine Builder ===${NC}"
echo ""

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(bottles|wine|both)$ ]]; then
    echo -e "${RED}Error: Invalid build type '$BUILD_TYPE'${NC}"
    echo "Usage: ./build.sh [bottles|wine|both] [registry]"
    echo ""
    echo "Options:"
    echo "  bottles  - Build Bottles GUI container (full desktop)"
    echo "  wine     - Build Wine CLI container (terminal only)"
    echo "  both     - Build both containers"
    echo ""
    echo "Example:"
    echo "  ./build.sh bottles ghcr.io/myorg"
    echo "  ./build.sh wine docker.io/myuser"
    echo "  ./build.sh both cr.seqera.io/myworkspace"
    exit 1
fi

# Function to build and tag
build_container() {
    local name=$1
    local dockerfile=$2
    local tag="${REGISTRY}/studios-${name}:latest"
    
    echo -e "${YELLOW}Building ${name} container...${NC}"
    echo "Dockerfile: ${dockerfile}"
    echo "Tag: ${tag}"
    echo ""
    
    docker build \
        --build-arg CONNECT_CLIENT_VERSION=${CONNECT_VERSION} \
        -t "${tag}" \
        -f "${dockerfile}" \
        .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully built ${name}${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Failed to build ${name}${NC}"
        echo ""
        return 1
    fi
}

# Function to push container
push_container() {
    local name=$1
    local tag="${REGISTRY}/studios-${name}:latest"
    
    echo -e "${YELLOW}Pushing ${name} to registry...${NC}"
    docker push "${tag}"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Successfully pushed ${name}${NC}"
        echo "Image: ${tag}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Failed to push ${name}${NC}"
        echo ""
        return 1
    fi
}

# Build based on type
if [[ "$BUILD_TYPE" == "bottles" ]] || [[ "$BUILD_TYPE" == "both" ]]; then
    if build_container "bottles" "Dockerfile.bottles"; then
        echo -e "${YELLOW}Push to registry? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            push_container "bottles"
        fi
    fi
fi

if [[ "$BUILD_TYPE" == "wine" ]] || [[ "$BUILD_TYPE" == "both" ]]; then
    if build_container "wine" "Dockerfile.wine-simple"; then
        echo -e "${YELLOW}Push to registry? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            push_container "wine"
        fi
    fi
fi

echo ""
echo -e "${GREEN}=== Build Complete ===${NC}"
echo ""
echo "Next steps:"
echo "1. Ensure Wave is configured in your Seqera workspace"
echo "2. Set container repository in Settings > Studios"
echo "3. Add a new Studio with your container image:"
if [[ "$BUILD_TYPE" == "bottles" ]] || [[ "$BUILD_TYPE" == "both" ]]; then
    echo "   - Bottles GUI: ${REGISTRY}/studios-bottles:latest"
fi
if [[ "$BUILD_TYPE" == "wine" ]] || [[ "$BUILD_TYPE" == "both" ]]; then
    echo "   - Wine CLI: ${REGISTRY}/studios-wine:latest"
fi
echo ""
echo "See README.md for full deployment instructions"