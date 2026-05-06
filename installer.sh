#!/bin/bash

set -e

LARABOOT_VERSION="v1.0.0"
PHP_VERSION="8.4"

# --- Visual Banner (Inspired by image_694211.png) ---
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BAR_BG='\033[0;30;46m' # Black text on Cyan background
RESET='\033[0m'
BOLD='\033[1m'

clear
echo -e "${CYAN}██╗      █████╗ ██████╗  █████╗ ██████╗  ██████╗  ██████╗ ████████╗${RESET}"
echo -e "${CYAN}██║     ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔═══██╗██╔═══██╗╚══██╔══╝${RESET}"
echo -e "${BLUE}██║     ███████║██████╔╝███████║██████╔╝██║   ██║██║   ██║   ██║   ${RESET}"
echo -e "${BLUE}██║     ██╔══██║██╔══██╗██╔══██║██╔══██╗██║   ██║██║   ██║   ██║   ${RESET}"
echo -e "${PURPLE}███████╗██║  ██║██║  ██║██║  ██║██████╔╝╚██████╔╝╚██████╔╝   ██║   ${RESET}"
echo -e "${PURPLE}╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝  ╚═════╝    ╚═╝   ${RESET}"
echo -e "${BAR_BG} ♦ Laraboot $LARABOOT_VERSION :: PHP $PHP_VERSION :: We Must Ship ♦ ${RESET}"
echo ""

# Check Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Error: Docker is not installed."
    echo ""
    echo "Install Docker from:"
    echo "  Mac:     https://docs.docker.com/desktop/install/mac-install/"
    echo "  Windows: https://docs.docker.com/desktop/install/windows-install/"
    echo "  Linux:   https://docs.docker.com/engine/install/"
    exit 1
fi

# Check Docker is running
if ! docker info &> /dev/null; then
    echo "Error: Docker is installed but not running."
    echo ""
    echo "  Mac/Windows: Open Docker Desktop and wait for it to start."
    echo "  Linux:       Run: sudo systemctl start docker"
    exit 1
fi

TARGET=${1:-.}
shift || true

PACKAGES=()
STARTER_KIT=""
STACK=""
LARAVEL_VERSION=""

# Parse arguments
for arg in "$@"; do
    case $arg in
        --using=*)
            STARTER_KIT="${arg#--using=}"
            ;;
        --stack=*)
            STACK="${arg#--stack=}"
            ;;
        --laravel=*)
            LARAVEL_VERSION="${arg#--laravel=}"
            ;;
        *)
            PACKAGES+=("$arg")
            ;;
    esac
done

# Resolve Laravel package version
if [ -n "$LARAVEL_VERSION" ]; then
    LARAVEL_PACKAGE="laravel/laravel:^$LARAVEL_VERSION"
else
    LARAVEL_PACKAGE="laravel/laravel"
    LARAVEL_VERSION="latest"
fi

if [ "$TARGET" = "." ]; then
    DIR=$(pwd)
else
    mkdir -p "$TARGET"
    DIR=$(pwd)/$TARGET
fi

echo -e "${BOLD}Installing Laravel $LARAVEL_VERSION in:${RESET} $DIR"
echo ""

# Create project
docker run --rm -v "$DIR":/app composer:2 create-project "$LARAVEL_PACKAGE" . --ignore-platform-reqs

# Install dependencies
docker run --rm -v "$DIR":/app composer:2 install --ignore-platform-reqs

# Install starter kit if provided
if [ -n "$STARTER_KIT" ]; then
    echo ""
    echo "Installing starter kit: $STARTER_KIT"
    docker run --rm -v "$DIR":/app composer:2 require "$STARTER_KIT" --ignore-platform-reqs
fi

# Load stack if provided
if [ -n "$STACK" ]; then
    echo ""
    echo "Loading stack: $STACK"
    STACK_FILE=$(mktemp)
    curl -fsSL "https://raw.githubusercontent.com/arquizade/laraboot/main/stacks/$STACK.sh" -o "$STACK_FILE"
    source "$STACK_FILE" "$DIR"
    rm "$STACK_FILE"
fi

# Install extra packages if provided
if [ ${#PACKAGES[@]} -gt 0 ]; then
    echo ""
    echo "Installing packages: ${PACKAGES[*]}"
    docker run --rm -v "$DIR":/app composer:2 require "${PACKAGES[@]}" --ignore-platform-reqs
fi

# Download Makefile into project folder
echo ""
echo "Downloading Makefile..."
curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/Makefile -o "$DIR/Makefile"

echo ""
echo -e "${CYAN}Done.${RESET}"
echo ""
if [ "$TARGET" = "." ]; then
    echo -e "  ${BOLD}make setup${RESET}"
else
    echo -e "  ${BOLD}cd $TARGET && make setup${RESET}"
fi
echo ""
