#!/bin/bash

set -e

LARABOOT_VERSION="v1.0.0"
PHP_VERSION="8.4"
APP_PORT=""

CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
BAR_BG='\033[0;30;46m'
RESET='\033[0m'
BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'

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
        --port=*)
            APP_PORT="${arg#--port=}"
            ;;
        *)
            PACKAGES+=("$arg")
            ;;
    esac
done

# Port resolution: explicit > 80 > 8000 > error
resolve_port() {
    if [ -n "$APP_PORT" ]; then
        echo -e "  ${CYAN}Using specified port: ${BOLD}${APP_PORT}${RESET}"
        return 0
    fi

    if ! lsof -i :80 -sTCP:LISTEN -t > /dev/null 2>&1; then
        APP_PORT=80
        echo -e "  ${GREEN}Port 80 is available. Using port 80.${RESET}"
        return 0
    fi

    echo -e "  ${YELLOW}Warning: Port 80 is in use.${RESET}"

    if ! lsof -i :8000 -sTCP:LISTEN -t > /dev/null 2>&1; then
        APP_PORT=8000
        echo -e "  ${YELLOW}Falling back to port 8000.${RESET}"
        return 0
    fi

    echo -e "  ${RED}Error: Both port 80 and port 8000 are in use.${RESET}"
    echo -e "  ${RED}Free up one of those ports or pass --port=<number> to specify another.${RESET}"
    exit 1
}

echo -e "${BOLD}Resolving port...${RESET}"
resolve_port
APP_URL="http://localhost"
[ "$APP_PORT" != "80" ] && APP_URL="http://localhost:${APP_PORT}"
echo ""

if [ -n "$LARAVEL_VERSION" ]; then
    LARAVEL_PACKAGE="laravel/laravel:^$LARAVEL_VERSION"
else
    LARAVEL_PACKAGE="laravel/laravel"
    LARAVEL_VERSION="latest"
fi

# Resolve install directory
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

# Download Makefile
echo ""
echo "Downloading Makefile..."
curl -fsSL https://raw.githubusercontent.com/arquizade/laraboot/main/Makefile -o "$DIR/Makefile"
echo "  ✓ Makefile saved."

# Enter project directory
echo ""
echo -e "${BOLD}Entering project directory:${RESET} $DIR"
cd "$DIR"

# Run make setup
echo ""
echo -e "${BOLD}Running make setup...${RESET}"
if ! make setup; then
    echo ""
    echo -e "${RED}Error: make setup failed. Check the output above.${RESET}"
    exit 1
fi

# Run make start in background so script can continue
echo ""
echo -e "${BOLD}Running make start...${RESET}"
make start &
MAKE_START_PID=$!

# Wait for the app to respond
echo ""
echo -e "${YELLOW}Waiting for app to be ready at ${APP_URL}...${RESET}"

MAX_RETRIES=30
RETRY_INTERVAL=2
RETRIES=0
APP_READY=false

while [ $RETRIES -lt $MAX_RETRIES ]; do
    if curl -sf --max-time 2 "$APP_URL" > /dev/null 2>&1; then
        APP_READY=true
        break
    fi
    RETRIES=$((RETRIES + 1))
    echo -e "  ${YELLOW}Attempt $RETRIES/$MAX_RETRIES — not ready yet, retrying in ${RETRY_INTERVAL}s...${RESET}"
    sleep $RETRY_INTERVAL
done

# Open browser
open_browser() {
    if command -v xdg-open &> /dev/null; then
        xdg-open "$1"
    elif command -v open &> /dev/null; then
        open "$1"
    elif command -v start &> /dev/null; then
        start "$1"
    else
        echo -e "  Open manually: ${BOLD}$1${RESET}"
    fi
}

echo ""
echo -e "${CYAN}─────────────────────────────────────────${RESET}"

if [ "$APP_READY" = true ]; then
    echo -e "${GREEN}  ✓ App is up at: ${BOLD}${APP_URL}${RESET}"
    echo -e "${CYAN}─────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  Opening ${BOLD}${APP_URL}${RESET} in your default browser..."
    open_browser "$APP_URL"
else
    echo -e "${RED}  ✗ App did not respond after $((MAX_RETRIES * RETRY_INTERVAL))s.${RESET}"
    echo -e "${CYAN}─────────────────────────────────────────${RESET}"
    echo ""
    echo -e "  ${YELLOW}make start is still running (PID: $MAKE_START_PID).${RESET}"
    echo -e "  Check the process or open manually: ${BOLD}${APP_URL}${RESET}"
fi

echo ""
