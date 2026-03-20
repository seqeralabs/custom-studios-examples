#!/bin/bash
set -e

REGISTRY="${1:-your-registry}"
NO_CACHE="${2:-}"

docker build \
    $NO_CACHE \
    --platform linux/amd64 \
    --build-arg CONNECT_CLIENT_VERSION=0.10 \
    -t "${REGISTRY}/windows:latest" \
    -f .seqera/Dockerfile \
    .seqera/

echo "Push to registry? (y/n)"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    docker push "${REGISTRY}/windows:latest"
fi