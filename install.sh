#!/bin/bash
set -e

cd "$(dirname "$0")"

echo "Building Alpine image and extracting Claude Code..."

DOCKER_BUILDKIT=1 docker build --progress=plain --output type=local,dest=./dist .

sudo ln -fs "$(pwd)/dist/lib/ld-musl-x86_64.so.1" /lib/ld-musl-x86_64.so.1

echo ""
echo "Done! Add $(pwd)/dist/bin to your PATH:"
echo "  export PATH=\"$(pwd)/dist/bin:\$PATH\""
