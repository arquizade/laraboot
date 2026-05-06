#!/bin/bash

DIR=${1:-.}

PACKAGES=(
    "openai-php/laravel"
    "spatie/laravel-data"
    "prism-php/prism"
)

echo "Installing AI stack..."
docker run --rm -v "$DIR":/app composer:2 require "${PACKAGES[@]}" --ignore-platform-reqs
echo "AI stack installed."
