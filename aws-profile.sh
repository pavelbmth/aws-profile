#!/usr/bin/env bash
# =============================================================================
# aws-profile — AWS Profile Manager TUI
# https://github.com/YOUR_USERNAME/aws-profile
#
# Source this file in your shell rc (.zshrc / .bashrc):
#   source /path/to/aws-profile.sh
#
# Then run:  aws-profile
# =============================================================================

# Guard: prevent double-sourcing
[[ -n "${_AWS_PROFILE_LOADED:-}" ]] && return 0
readonly _AWS_PROFILE_LOADED=1

# ---------------------------------------------------------------------------
# Version
# ---------------------------------------------------------------------------
readonly _AWP_VERSION="1.1.0"

# ---------------------------------------------------------------------------
# Colors (ANSI) — gracefully disabled when not a TTY
# ---------------------------------------------------------------------------
if [[ -t 2 ]]; then
  _AWP_BOLD="\033[1m"
  _AWP_BLUE="\033[34m"
  _AWP_CYAN="\033[36m"
  _AWP_GREEN="\033[32m"
  _AWP_YELLOW="\033[33m"
  _AWP_RED="\033[31m"
  _AWP_DIM="\033[2m"
  _AWP_RESET="\033[0m"
else
  _AWP_BOLD="" _AWP_BLUE="" _AWP_CYAN="" _AWP_GREEN=""
  _AWP_YELLOW="" _AWP_RED="" _AWP_DIM="" _AWP_RESET=""
fi

_awp_info()    { printf "%b%s%b\n"        "$_AWP_BLUE"   "  $*" "$_AWP_RESET" >&2; }
_awp_ok()      { printf "%b%s%b\n"        "$_AWP_GREEN"  "✓ $*" "$_AWP_RESET" >&2; }
_awp_warn()    { printf "%b%s%b\n"        "$_AWP_YELLOW" "⚠ $*" "$_AWP_RESET" >&2; }
_awp_error()   { printf "%b%s%b\n"        "$_AWP_RED"    "✗ $*" "$_AWP_RESET" >&2; }
_awp_header()  { printf "%b%b%s%b\n"      "$_AWP_BOLD"   "$_AWP_CYAN" "$*" "$_AWP_RESET" >&2; }
_awp_dim()     { printf "%b%s%b\n"        "$_AWP_DIM"    "$*" "$_AWP_RESET" >&2; }

# ---------------------------------------------------------------------------
# Internal: list profiles from ~/.aws/config
# ---------------------------------------------------------------------------
_awp_profiles() {
  local cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  [[ -f "$cfg" ]] || { _awp_error "Config file not found: $cfg"; return 1; }

  awk '
    /^\[profile[[:space:]]+/ {
      line = $0
      sub(/^\[profile[[:space:]]+/, "", line)
      sub(/\].*$/, "", line)
      print line
    }
    /^\[default\]/ { print "default" }
  ' "$cfg" | awk 'NF' | sort -u
}

# ---------------------------------------------------------------------------
# Internal: fzf wrapper with consistent styling
# ---------------------------------------------------------------------------
_awp_fzf() {
  local prompt="$1" header="$2"
  shift 2
  fzf --prompt="  $prompt " \
      --header="$header" \
      --height=50% \
      --min-height=10 \
      --border=rounded \
      --margin=1,2 \
      --padding=0,1 \
      --info=hidden \
      --pointer="▶" \
      --marker="✓" \
      --color="header:cyan:bold,prompt:blue:bold,pointer:green,marker:green" \
      "$@"
}

# ---------------------------------------------------------------------------
# Internal: whiptail fallback menu
# ---------------------------------------------------------------------------
_awp_whiptail_menu() {
  local title="$1" prompt="$2"; shift 2
  whiptail --title "$title" \
           --menu "$prompt" \
           20 72 12 \
           "$@" \
           3>&1 1>&2 2>&3
}

# ---------------------------------------------------------------------------
# Internal: main action menu
# ---------------------------------------------------------------------------
_awp_main_menu() {
  local current="${AWS_PROFILE:-<none>}"
  local header="AWS Profile Manager v${_AWP_VERSION}  |  Current: ${current}"

  local actions=(
    "login"    "Login       — aws sso login + export AWS_PROFILE"
    "switch"   "Switch      — export AWS_PROFILE (no login)"
    "whoami"   "Who am I   — sts get-caller-identity"
    "logout"   "Logout      — sso logout + unset AWS_PROFILE"
    "console"  "Console     — open AWS web console in browser"
    "quit"     "Quit"
  )

  if command -v fzf &>/dev/null; then
    # Build display list; show tag only in fzf, use --nth for search
    printf "%s\n" \
      "Login       — aws sso login + export AWS_PROFILE" \
      "Switch      — export AWS_PROFILE (no login)" \
      "Who am I   — sts get-caller-identity" \
      "Logout      — sso logout + unset AWS_PROFILE" \
      "Console     — open AWS web console in browser" \
      "Quit" \
    | _awp_fzf "Action > " "$header"
    return $?
  fi

  if command -v whiptail &>/dev/null; then
    _awp_whiptail_menu "AWS Profile Manager" \
      "Current profile: ${current}\nSelect an action:" \
      "${actions[@]}"
    return $?
  fi

  _awp_error "fzf or whiptail is required.  Install: brew install fzf"
  return 1
}

# ---------------------------------------------------------------------------
# Internal: profile picker  (with fzf right-side preview panel)
# ---------------------------------------------------------------------------
_awp_pick_profile() {
  local cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  local profiles
  profiles="$(_awp_profiles)" || return 1
  [[ -n "$profiles" ]] || { _awp_error "No profiles found in $cfg"; return 1; }

  local current="${AWS_PROFILE:-}"
  local header="AWS Profiles  |  Current: ${current:-<none>}  |  ↑↓ navigate  · Enter select  · Esc cancel"

  if command -v fzf &>/dev/null; then
    local default_flag=()
    [[ -n "$current" ]] && default_flag=(--query "$current")

    # Preview script (single-quoted so no parent-shell expansion).
    # '\'' embeds a literal ' inside a single-quoted string.
    # AWS_CONFIG_FILE is exported so the preview subprocess inherits it.
    echo "$profiles" | \
      AWS_CONFIG_FILE="$cfg" \
      fzf \
        --prompt="  Profile > " \
        --header="$header" \
        --height=80% \
        --min-height=20 \
        --border=rounded \
        --margin=1,2 \
        --padding=0,1 \
        --info=hidden \
        --pointer="▶" \
        --marker="✓" \
        --color="header:cyan:bold,prompt:blue:bold,pointer:green,marker:green,preview-border:238,preview-label:cyan:bold" \
        --preview-window="right:52%:wrap:border-left" \
        --preview-label=" Account Details " \
        --preview='
          p="{}"
          cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

          printf "\033[1;36m\n  Profile: %s\033[0m\n" "$p"
          printf "\033[38;5;238m  %s\033[0m\n\n" "$(printf "─%.0s" {1..40})"

          awk -v profile="$p" '\''
            BEGIN { in_s = 0 }
            /^\[/            { in_s = 0 }
            /^\[profile[[:space:]]/ {
              n = $0
              sub(/^\[profile[[:space:]]+/, "", n)
              sub(/\].*$/, "", n)
              if (n == profile) in_s = 1
            }
            /^\[default\]/   { if (profile == "default") in_s = 1 }
            in_s && !/^\[/ && /=/ {
              key = $0; val = $0
              sub(/[[:space:]]*=.*/,    "", key)
              sub(/^[^=]+=[ \t]*/,     "", val)
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)

              # Highlight important fields
              color = "\033[33m"
              if (key == "sso_account_id")  color = "\033[1;32m"
              if (key == "sso_start_url")   color = "\033[1;34m"
              if (key == "sso_role_name")   color = "\033[1;35m"
              if (key == "region")          color = "\033[1;33m"

              printf "  %s%-26s\033[0m  %s\n", color, key, val
            }
          '\'' "$cfg"

          printf "\n\033[38;5;238m  Config: %s\033[0m\n" "$cfg"
        ' \
        "${default_flag[@]}"
    return $?
  fi

  if command -v whiptail &>/dev/null; then
    local items=()
    while IFS= read -r p; do
      items+=("$p" " ")
    done <<< "$profiles"
    _awp_whiptail_menu "AWS Profiles" "Choose a profile:" "${items[@]}"
    return $?
  fi

  _awp_error "fzf or whiptail is required.  Install: brew install fzf"
  return 1
}

# ---------------------------------------------------------------------------
# Internal: open AWS console in default browser
# ---------------------------------------------------------------------------
_awp_open_console() {
  local profile="${AWS_PROFILE:-default}"
  local region

  # Attempt to read region from config
  region="$(aws configure get region --profile "$profile" 2>/dev/null)"
  region="${region:-us-east-1}"

  local url="https://console.aws.amazon.com/console/home?region=${region}"

  _awp_info "Opening AWS Console for profile '${profile}' (region: ${region})"

  if command -v open &>/dev/null; then
    open "$url"
  elif command -v xdg-open &>/dev/null; then
    xdg-open "$url"
  else
    _awp_warn "Cannot detect browser opener. URL: $url"
  fi
}

# ---------------------------------------------------------------------------
# Shell prompt helper — add to PS1 / PROMPT
#   Usage in .zshrc:
#     PROMPT='$(__awp_ps1)'$PROMPT
#   Usage in .bashrc:
#     PS1='$(__awp_ps1)'$PS1
# ---------------------------------------------------------------------------
__awp_ps1() {
  local p="${AWS_PROFILE:-}"
  [[ -z "$p" ]] && return 0
  printf "(%b%s%b) " "\033[33m" "aws:$p" "\033[0m"
}

# ---------------------------------------------------------------------------
# Public command: aws-profile
# ---------------------------------------------------------------------------
aws-profile() {
  # ---- Flags ----
  case "${1:-}" in
    -v|--version)
      echo "aws-profile v${_AWP_VERSION}"
      return 0
      ;;
    -h|--help)
      _awp_usage
      return 0
      ;;
    # Allow direct sub-commands (non-interactive)
    login|switch|whoami|logout|console)
      _awp_run_action "$1"
      return $?
      ;;
  esac

  command -v aws &>/dev/null || { _awp_error "aws CLI not found in PATH."; return 127; }

  local action
  action="$(_awp_main_menu)" || return 0  # user pressed Escape / Ctrl-C = quiet exit

  # Normalise fzf full-text selection → key token
  case "$action" in
    Login*)   action="login"   ;;
    Switch*)  action="switch"  ;;
    "Who am"*) action="whoami" ;;
    Logout*)  action="logout"  ;;
    Console*) action="console" ;;
    Quit*)    return 0         ;;
  esac

  _awp_run_action "$action"
}

# ---------------------------------------------------------------------------
# Internal: dispatch action
# ---------------------------------------------------------------------------
_awp_run_action() {
  local action="$1"
  local profile

  case "$action" in

    login)
      profile="$(_awp_pick_profile)" || return 1

      _awp_info "Running: aws sso login --profile ${profile}"
      AWS_PAGER="" aws --no-cli-pager sso login --profile "$profile" \
        || { _awp_error "SSO login failed."; return 1; }

      export AWS_PROFILE="$profile"
      _awp_ok "Login successful — AWS_PROFILE=${profile}"
      ;;

    switch)
      profile="$(_awp_pick_profile)" || return 1
      export AWS_PROFILE="$profile"
      _awp_ok "Switched — AWS_PROFILE=${profile}"
      ;;

    whoami)
      local p="${AWS_PROFILE:-default}"
      _awp_header "─── Identity ──────────────────────────────"
      _awp_info "AWS_PROFILE: ${p}"
      AWS_PAGER="" aws --no-cli-pager sts get-caller-identity --profile "$p" 2>/dev/null \
        || _awp_error "Cannot call sts:GetCallerIdentity (not logged in or no permission)."
      ;;

    logout)
      local p="${AWS_PROFILE:-default}"
      _awp_info "Running: aws sso logout --profile ${p}"
      AWS_PAGER="" aws --no-cli-pager sso logout --profile "$p" 2>/dev/null \
        || _awp_warn "sso logout returned an error (session may have already expired)."
      unset AWS_PROFILE
      _awp_ok "Logged out — AWS_PROFILE unset"
      ;;

    console)
      _awp_open_console
      ;;

    *)
      _awp_error "Unknown action: ${action}"
      return 1
      ;;
  esac
}

# ---------------------------------------------------------------------------
# Usage / help
# ---------------------------------------------------------------------------
_awp_usage() {
  cat >&2 <<EOF

${_AWP_BOLD}${_AWP_CYAN}aws-profile v${_AWP_VERSION}${_AWP_RESET}
AWS Profile Manager TUI — interactive profile switching with arrow-key navigation.

${_AWP_BOLD}USAGE${_AWP_RESET}
  aws-profile [action] [flags]

${_AWP_BOLD}ACTIONS${_AWP_RESET} (optional, launches interactive menu when omitted)
  login      Run aws sso login and set AWS_PROFILE
  switch     Set AWS_PROFILE without logging in
  whoami     Show sts get-caller-identity for current profile
  logout     Run aws sso logout and unset AWS_PROFILE
  console    Open AWS web console in your browser

${_AWP_BOLD}FLAGS${_AWP_RESET}
  -h, --help       Show this help
  -v, --version    Show version

${_AWP_BOLD}SHELL PROMPT INTEGRATION${_AWP_RESET}
  Add the current AWS profile to your shell prompt:

  # zsh — add to ~/.zshrc
  PROMPT='\$(__awp_ps1)'\$PROMPT

  # bash — add to ~/.bashrc
  PS1='\$(__awp_ps1)'\$PS1

${_AWP_BOLD}DEPENDENCIES${_AWP_RESET}
  Required : aws (https://aws.amazon.com/cli/)
  Recommended: fzf (brew install fzf)
  Fallback : whiptail

EOF
}
