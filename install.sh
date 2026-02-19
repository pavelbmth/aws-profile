#!/usr/bin/env bash
# =============================================================================
# aws-profile installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pavelbmth/aws-profile/main/install.sh | bash
# =============================================================================
set -euo pipefail

REPO_URL="https://raw.githubusercontent.com/pavelbmth/aws-profile/main"
INSTALL_DIR="${INSTALL_DIR:-$HOME/.aws-profile}"
SCRIPT_NAME="aws-profile.sh"
SHELL_RC=""

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { printf "\033[34m  %s\033[0m\n" "$*"; }
ok()    { printf "\033[32m✓ %s\033[0m\n" "$*"; }
warn()  { printf "\033[33m⚠ %s\033[0m\n" "$*"; }
error() { printf "\033[31m✗ %s\033[0m\n" "$*" >&2; exit 1; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

detect_shell_rc() {
  local shell_name
  shell_name="$(basename "${SHELL:-/bin/bash}")"
  case "$shell_name" in
    zsh)   echo "$HOME/.zshrc"  ;;
    bash)  echo "$HOME/.bashrc" ;;
    *)     echo ""              ;;
  esac
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
bold "aws-profile installer"
echo ""

command -v aws &>/dev/null || warn "aws CLI not found — install it from https://aws.amazon.com/cli/"

if ! command -v fzf &>/dev/null; then
  warn "fzf not found (recommended for best experience)"
  info "Install with: brew install fzf"
fi

# ---------------------------------------------------------------------------
# Download
# ---------------------------------------------------------------------------
info "Installing to $INSTALL_DIR ..."
mkdir -p "$INSTALL_DIR"

if command -v curl &>/dev/null; then
  curl -fsSL "$REPO_URL/$SCRIPT_NAME" -o "$INSTALL_DIR/$SCRIPT_NAME"
elif command -v wget &>/dev/null; then
  wget -qO "$INSTALL_DIR/$SCRIPT_NAME" "$REPO_URL/$SCRIPT_NAME"
else
  error "curl or wget is required."
fi

ok "Downloaded $SCRIPT_NAME to $INSTALL_DIR"

# ---------------------------------------------------------------------------
# Shell RC wiring
# ---------------------------------------------------------------------------
SHELL_RC="$(detect_shell_rc)"

SOURCE_LINE="source \"$INSTALL_DIR/$SCRIPT_NAME\""

if [[ -n "$SHELL_RC" ]]; then
  if grep -qF "$INSTALL_DIR/$SCRIPT_NAME" "$SHELL_RC" 2>/dev/null; then
    ok "Already sourced in $SHELL_RC"
  else
    printf "\n# aws-profile manager\n%s\n" "$SOURCE_LINE" >> "$SHELL_RC"
    ok "Added source line to $SHELL_RC"
  fi
else
  warn "Could not detect shell RC file. Add this line manually:"
  printf "  %s\n" "$SOURCE_LINE"
fi

# ---------------------------------------------------------------------------
# Completion (zsh)
# ---------------------------------------------------------------------------
if [[ "$(basename "${SHELL:-}")" == "zsh" ]]; then
  ZSH_COMP_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/completions"
  if [[ -d "$ZSH_COMP_DIR" ]] || mkdir -p "$ZSH_COMP_DIR" 2>/dev/null; then
    curl -fsSL "$REPO_URL/completions/_aws-profile.zsh" \
      -o "$ZSH_COMP_DIR/_aws-profile" 2>/dev/null && ok "Installed zsh completion"
  fi
fi

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
bold "Installation complete!"
info "Restart your shell or run:  source $SHELL_RC"
info "Then use:  aws-profile"
