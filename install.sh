#!/bin/bash
set -e

REPO="stevelee477/alpine-claude-code"
INSTALL_DIR="${CLAUDE_CODE_DIR:-$HOME/.local/share/claude-code}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Check architecture
ARCH=$(uname -m)
[ "$ARCH" = "x86_64" ] || error "Only x86_64 is supported (detected: $ARCH)"
[ "$(uname -s)" = "Linux" ] || error "Only Linux is supported"

# Get latest release tag
info "Fetching latest release..."
LATEST_TAG=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/')
[ -n "$LATEST_TAG" ] || error "Failed to get latest release"
info "Latest version: $LATEST_TAG"

# Check if already installed with same version
if [ -f "$INSTALL_DIR/VERSION" ]; then
  CURRENT=$(cat "$INSTALL_DIR/VERSION" | tr -d '[:space:]')
  LATEST_VER="${LATEST_TAG#v}"
  if [ "$CURRENT" = "$LATEST_VER" ]; then
    info "Already up to date ($CURRENT)"
    exit 0
  fi
  info "Upgrading from $CURRENT to $LATEST_VER"
fi

# Download
TARBALL="claude-code-musl-x86_64-${LATEST_TAG}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${TARBALL}"

info "Downloading $TARBALL..."
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fSL --progress-bar -o "$TMP_DIR/$TARBALL" "$DOWNLOAD_URL"

# Verify checksum if available
SHA_URL="${DOWNLOAD_URL}.sha256"
if curl -fsSL -o "$TMP_DIR/${TARBALL}.sha256" "$SHA_URL" 2>/dev/null; then
  info "Verifying checksum..."
  cd "$TMP_DIR"
  sha256sum -c "${TARBALL}.sha256" || error "Checksum verification failed!"
  cd - > /dev/null
fi

# Extract
info "Installing to $INSTALL_DIR..."
mkdir -p "$INSTALL_DIR"
tar xzf "$TMP_DIR/$TARBALL" -C "$INSTALL_DIR"

# Symlink musl dynamic linker
MUSL_LIB="$INSTALL_DIR/lib/ld-musl-x86_64.so.1"
if [ -f "$MUSL_LIB" ]; then
  if [ ! -f /lib/ld-musl-x86_64.so.1 ]; then
    info "Symlinking musl dynamic linker (requires sudo)..."
    sudo ln -fs "$MUSL_LIB" /lib/ld-musl-x86_64.so.1 || {
      warn "Could not create symlink. Run manually:"
      warn "  sudo ln -fs $MUSL_LIB /lib/ld-musl-x86_64.so.1"
    }
  fi
fi

# Copy settings if not exist
if [ -f "$INSTALL_DIR/settings.json" ] && [ ! -f "$HOME/.claude/settings.json" ]; then
  mkdir -p "$HOME/.claude"
  cp "$INSTALL_DIR/settings.json" "$HOME/.claude/settings.json"
  info "Copied settings.json to ~/.claude/"
fi

# PATH setup
BIN_DIR="$INSTALL_DIR/bin"
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$BIN_DIR"; then
  info ""
  info "Add Claude Code to your PATH. Run one of:"
  info ""

  SHELL_NAME=$(basename "$SHELL" 2>/dev/null || echo "bash")
  case "$SHELL_NAME" in
    zsh)  RC="$HOME/.zshrc" ;;
    fish) RC="$HOME/.config/fish/config.fish" ;;
    *)    RC="$HOME/.bashrc" ;;
  esac

  if [ "$SHELL_NAME" = "fish" ]; then
    info "  echo 'set -gx PATH $BIN_DIR \$PATH' >> $RC"
  else
    info "  echo 'export PATH=\"$BIN_DIR:\$PATH\"' >> $RC"
  fi
  info ""
  info "Then restart your shell, or run:"
  info "  export PATH=\"$BIN_DIR:\$PATH\""
fi

info ""
info "Claude Code installed successfully!"
"$BIN_DIR/claude" --version 2>/dev/null && true
