#!/bin/bash

set -e

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo ""
    echo "Install Docker from:"
    echo ""
    echo "  Mac:     https://docs.docker.com/desktop/install/mac-install/"
    echo "  Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "  Linux:   https://docs.docker.com/engine/install/"
    echo ""
    exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is installed but not running."
    echo ""
    echo "  Mac/Windows: Open Docker Desktop and wait for it to start."
    echo "  Linux:       Run: sudo systemctl start docker"
    echo ""
    exit 1
fi

TARGET=${1:-.}

if [ "$TARGET" = "." ]; then
    DIR=$(pwd)
else
    mkdir -p "$TARGET"
    DIR=$(pwd)/$TARGET
fi

echo "Installing Laravel 13 in: $DIR"

# Create project
docker run --rm -v "$DIR":/app composer:2 create-project laravel/laravel . --ignore-platform-reqs

# Install dependencies
docker run --rm -v "$DIR":/app composer:2 install --ignore-platform-reqs

echo ""
echo "Done. To start your app run:"
echo ""
echo "  docker run --rm -v \"$DIR\":/app -w /app -p 8000:8000 php:8.4-cli php artisan serve --host=0.0.0.0 --port=8000"
echo ""
echo "Then open: http://localhost:8000"
