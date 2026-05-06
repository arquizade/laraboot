#!/bin/bash

DIR=${1:-.}

PACKAGES=(
    "laravel/sanctum"
    "spatie/laravel-query-builder"
    "spatie/laravel-fractal"
)

echo "Installing API stack..."
docker run --rm -v "$DIR":/app composer:2 require "${PACKAGES[@]}" --ignore-platform-reqs
echo "API stack installed."
