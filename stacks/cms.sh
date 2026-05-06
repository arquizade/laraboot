#!/bin/bash

DIR=${1:-.}

PACKAGES=(
    "filament/filament"
    "spatie/laravel-medialibrary"
    "spatie/laravel-tags"
)

echo "Installing CMS stack..."
docker run --rm -v "$DIR":/app composer:2 require "${PACKAGES[@]}" --ignore-platform-reqs
echo "CMS stack installed."
