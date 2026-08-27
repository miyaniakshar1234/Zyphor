#!/usr/bin/env bash
# ==============================================================================
# Zyphor Universal One-Line Installer for Linux & macOS
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/miyaniakshar1234/Zyphor/master/install.sh | bash
# ==============================================================================

set -e

REPO="miyaniakshar1234/Zyphor"
BINARY="zyphor"

# Color helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈"
echo "  ┃            ZYPHOR SYSTEM OBSERVATORY              ┃"
echo "  ┃        Universal Installer (Linux & macOS)        ┃"
echo "  ◈━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━◈"
echo -e "${NC}"

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     PLATFORM="linux" ;;
    Darwin*)    PLATFORM="macos" ;;
    *)          echo -e "${RED}Error: Unsupported operating system: ${OS}${NC}"; exit 1 ;;
esac

# Detect Architecture
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64|amd64)   ARCH_NAME="x86_64" ;;
    arm64|aarch64)  ARCH_NAME="aarch64" ;;
    *)              echo -e "${RED}Error: Unsupported architecture: ${ARCH}${NC}"; exit 1 ;;
esac

echo -e "${BLUE}==>${NC} Detecting system environment: ${BOLD}${PLATFORM}-${ARCH_NAME}${NC}"

# Fetch latest release tag from GitHub API
echo -e "${BLUE}==>${NC} Querying latest release from GitHub (${REPO})..."
LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "${LATEST_TAG}" ]; then
    LATEST_TAG="v0.1.0"
    echo -e "${YELLOW}Warning: Could not fetch latest tag from API. Defaulting to ${LATEST_TAG}.${NC}"
fi

echo -e "${BLUE}==>${NC} Target release version: ${BOLD}${LATEST_TAG}${NC}"

ASSET_NAME="zyphor-${PLATFORM}-${ARCH_NAME}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${ASSET_NAME}"

# Temp working directory
TMP_DIR=$(mktemp -d)
trap 'rm -rf "${TMP_DIR}"' EXIT

echo -e "${BLUE}==>${NC} Downloading ${DOWNLOAD_URL}..."
if ! curl -fsSL "${DOWNLOAD_URL}" -o "${TMP_DIR}/${ASSET_NAME}"; then
    echo -e "${YELLOW}Notice: Direct architecture asset not found, trying fallback package...${NC}"
    FALLBACK_ASSET="zyphor-${PLATFORM}-x86_64.tar.gz"
    FALLBACK_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${FALLBACK_ASSET}"
    if ! curl -fsSL "${FALLBACK_URL}" -o "${TMP_DIR}/${ASSET_NAME}"; then
        echo -e "${RED}Error: Failed to download release asset from ${DOWNLOAD_URL}.${NC}"
        echo -e "${YELLOW}Please visit https://github.com/${REPO}/releases to install manually.${NC}"
        exit 1
    fi
fi

# Extract archive
echo -e "${BLUE}==>${NC} Unpacking binary payload..."
tar -xzf "${TMP_DIR}/${ASSET_NAME}" -C "${TMP_DIR}"

if [ ! -f "${TMP_DIR}/${BINARY}" ]; then
    FOUND_BIN=$(find "${TMP_DIR}" -type f -name "${BINARY}" | head -n 1)
    if [ -n "${FOUND_BIN}" ]; then
        mv "${FOUND_BIN}" "${TMP_DIR}/${BINARY}"
    else
        echo -e "${RED}Error: Binary '${BINARY}' not found in archive.${NC}"; exit 1
    fi
fi

chmod +x "${TMP_DIR}/${BINARY}"

# Determine target installation path
if [ "$(id -u)" -eq 0 ]; then
    INSTALL_DIR="/usr/local/bin"
else
    if [ -d "${HOME}/.local/bin" ] || mkdir -p "${HOME}/.local/bin" 2>/dev/null; then
        INSTALL_DIR="${HOME}/.local/bin"
    else
        INSTALL_DIR="/usr/local/bin"
    fi
fi

echo -e "${BLUE}==>${NC} Installing to ${BOLD}${INSTALL_DIR}/${BINARY}${NC}..."
if [ -w "${INSTALL_DIR}" ]; then
    mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
else
    echo -e "${YELLOW}Escalating permissions with sudo to install into ${INSTALL_DIR}...${NC}"
    sudo mv "${TMP_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}"
fi

echo -e "${GREEN}${BOLD}✓ Successfully installed Zyphor ${LATEST_TAG}!${NC}\n"

# Verify PATH
if ! command -v zyphor >/dev/null 2>&1; then
    echo -e "${YELLOW}Notice: ${INSTALL_DIR} is not in your current PATH.${NC}"
    echo -e "Add the following line to your ~/.bashrc or ~/.zshrc:"
    echo -e "  export PATH=\"${INSTALL_DIR}:\$PATH\"\n"
fi

echo -e "${CYAN}Run Zyphor anytime with:${NC}"
echo -e "  ${BOLD}zyphor${NC}         # Launch Interactive Observatory TUI"
echo -e "  ${BOLD}zyphor doctor${NC}  # Run System Diagnostics Audit"
echo -e "  ${BOLD}zyphor bench${NC}   # Run Hardware Multi-Core Benchmark"
echo -e "  ${BOLD}zyphor --help${NC}  # View CLI commands & options\n"
