#!/bin/bash

# Build script for Bottles/Wine Seqera Studios containers
# Usage: ./build.sh [bottles|wine|wine-desktop|all] [registry] [--no-cache]

set -e

CONNECT_VERSION="0.8"
DEFAULT_REGISTRY="your-registry"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
    echo -e "${YELLOW}⚠️  Detected ARM64 architecture (Apple Silicon)${NC}"
    echo -e "${YELLOW}Note: Some containers may have limitations on ARM64${NC}"
    echo ""
fi

# Parse arguments
BUILD_TYPE="${1:-wine-desktop}"
REGISTRY="${2:-$DEFAULT_REGISTRY}"
NO_CACHE=""

# Check for --no-cache flag
for arg in "$@"; do
    if [[ "$arg" == "--no-cache" ]]; then
        NO_CACHE="--no-cache"
        echo -e "${YELLOW}Using --no-cache flag (will take longer but ensures fresh build)${NC}"
        echo ""
    fi
done

echo -e "${GREEN}=== Seqera Studios Wine Builder ===${NC}"
echo ""

# Validate build type
if [[ ! "$BUILD_TYPE" =~ ^(bottles|wine|wine-desktop|all)$ ]]; then
    echo -e "${RED}Error: Invalid build type '$BUILD_TYPE'${NC}"
    echo "Usage: ./build.sh [bottles|wine|wine-desktop|all] [registry] [--no-cache]"
    echo ""
    echo "Options:"
    echo "  wine-desktop - Wine with Desktop GUI (RECOMMENDED - most reliable)"
    echo "  wine         - Wine CLI only (lightweight terminal access)"
    echo "  bottles      - Bottles GUI (experimental, may not work on all systems)"
    echo "  all          - Build all three containers"
    echo ""
    echo "Flags:"
    echo "  --no-cache  - Build without using Docker cache (recommended for fixes)"
    echo ""
    echo "Examples:"
    echo "  ./build.sh wine-desktop ghcr.io/myorg"
    echo "  ./build.sh wine docker.io/myuser --no-cache"
    echo "  ./build.sh all cr.seqera.io/myworkspace"
    echo ""
    echo "Recommendations by architecture:"
    if [[ "$ARCH" == "arm64" ]] || [[ "$ARCH" == "aarch64" ]]; then
        echo "  ARM64: Use 'wine-desktop' or 'wine' (Bottles may not work)"
    else
        echo "  x86_64: Any option works, 'wine-desktop' recommended"
    fi
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
    if [[ -n "$NO_CACHE" ]]; then
        echo "Cache: disabled"
    fi
    echo ""
    
    docker build \
        $NO_CACHE \
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
        echo -e "${YELLOW}Troubleshooting tips:${NC}"
        echo "1. Clear Docker cache: docker builder prune -a -f"
        echo "2. Try building with --no-cache flag"
        echo "3. Check you have sufficient disk space"
        echo "4. Review BUILD_FIX.md for known issues"
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
if [[ "$BUILD_TYPE" == "bottles" ]] || [[ "$BUILD_TYPE" == "all" ]]; then
    if build_container "bottles" "Dockerfile.bottles"; then
        echo -e "${YELLOW}Push to registry? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            push_container "bottles"
        fi
    fi
fi

if [[ "$BUILD_TYPE" == "wine" ]] || [[ "$BUILD_TYPE" == "all" ]]; then
    if build_container "wine" "Dockerfile.wine-simple"; then
        echo -e "${YELLOW}Push to registry? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            push_container "wine"
        fi
    fi
fi

if [[ "$BUILD_TYPE" == "wine-desktop" ]] || [[ "$BUILD_TYPE" == "all" ]]; then
    if build_container "wine-desktop" "Dockerfile.wine-desktop"; then
        echo -e "${YELLOW}Push to registry? (y/n)${NC}"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            push_container "wine-desktop"
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
if [[ "$BUILD_TYPE" == "bottles" ]] || [[ "$BUILD_TYPE" == "all" ]]; then
    echo "   - Bottles GUI: ${REGISTRY}/studios-bottles:latest"
fi
if [[ "$BUILD_TYPE" == "wine" ]] || [[ "$BUILD_TYPE" == "all" ]]; then
    echo "   - Wine CLI: ${REGISTRY}/studios-wine:latest"
fi
if [[ "$BUILD_TYPE" == "wine-desktop" ]] || [[ "$BUILD_TYPE" == "all" ]]; then
    echo "   - Wine Desktop (RECOMMENDED): ${REGISTRY}/studios-wine-desktop:latest"
fi
echo ""
echo "See README.md for full deployment instructions"