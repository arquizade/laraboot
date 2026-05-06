#!/bin/bash

DIR=${1:-.}

PACKAGES=(
    "livewire/livewire"
    "spatie/laravel-permission"
)

echo "Installing Fullstack stack..."
docker run --rm -v "$DIR":/app composer:2 require "${PACKAGES[@]}" --ignore-platform-reqs
echo "Fullstack stack installed."
