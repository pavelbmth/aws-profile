#!/usr/bin/env bash
# =============================================================================
# aws-profile uninstaller
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/pavelbmth/aws-profile/main/uninstall.sh | bash
# =============================================================================
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.aws-profile}"
SCRIPT_FILE="$INSTALL_DIR/aws-profile.sh"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()  { printf "\033[34m  %s\033[0m\n" "$*"; }
ok()    { printf "\033[32m✓ %s\033[0m\n" "$*"; }
warn()  { printf "\033[33m⚠ %s\033[0m\n" "$*"; }
bold()  { printf "\033[1m%s\033[0m\n" "$*"; }

remove_source_line() {
  local rc_file="$1"
  [[ -f "$rc_file" ]] || return 0

  if grep -qF "$SCRIPT_FILE" "$rc_file" 2>/dev/null; then
    # Remove the comment + source line (both the auto-added comment and the source line)
    local tmpfile
    tmpfile="$(mktemp)"
    grep -v -F "$SCRIPT_FILE" "$rc_file" | \
      grep -v "^# aws-profile manager$" > "$tmpfile"
    mv "$tmpfile" "$rc_file"
    ok "Removed source line from $rc_file"
  else
    info "No source line found in $rc_file — skipping"
  fi
}

# ---------------------------------------------------------------------------
# Start
# ---------------------------------------------------------------------------
bold "aws-profile uninstaller"
echo ""

# Remove install directory
if [[ -d "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
  ok "Removed $INSTALL_DIR"
else
  warn "Install directory not found: $INSTALL_DIR"
fi

# Remove zsh completion (oh-my-zsh)
ZSH_COMP="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/completions/_aws-profile"
if [[ -f "$ZSH_COMP" ]]; then
  rm -f "$ZSH_COMP"
  ok "Removed zsh completion: $ZSH_COMP"
fi

# Clean up shell RC files
remove_source_line "$HOME/.zshrc"
remove_source_line "$HOME/.bashrc"
remove_source_line "$HOME/.bash_profile"

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
echo ""
bold "Uninstall complete!"
info "Restart your shell or open a new terminal to finish."
info "If AWS_PROFILE is still set in this session, run:  unset AWS_PROFILE"
