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
readonly _AWP_VERSION="1.0.0"

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
  local header_text
  if [[ "$current" == "<none>" ]]; then
    header_text="╔═══════════════════════════════════════════════════════════╗
║ Active: ${current}
╚═══════════════════════════════════════════════════════════╝"
  else
    header_text="╔═══════════════════════════════════════════════════════════╗
║ Active: $(printf '\033[1;32m%s\033[0m' "$current")
╚═══════════════════════════════════════════════════════════╝"
  fi
  
  # Display version outside of fzf
  _awp_header "AWS Profile Manager v${_AWP_VERSION}"
  
  if command -v fzf &>/dev/null; then
    printf "%s\n" \
      "login      │ SSO login + set profile" \
      "switch     │ Set profile (no login)" \
      "whoami     │ Show caller identity" \
      "logout     │ SSO logout + unset" \
      "console    │ Open web console" \
      "quit       │ Exit" \
    | fzf \
        --ansi \
        --prompt="❯ " \
        --header="$header_text" \
        --height=50% \
        --layout=reverse \
        --border=bold \
        --border-label="│ SELECT ACTION │" \
        --border-label-pos=3 \
        --margin=1 \
        --padding=1 \
        --info=hidden \
        --prompt="❯ main " \
        --pointer="▌" \
        --marker="✓" \
        --color="fg:#d8dee9,bg:#2e3440,hl:#88c0d0,fg+:#eceff4,bg+:#3b4252,gutter:#2e3440,hl+:#8fbcbb,info:#81a1c1,prompt:#81a1c1:bold,pointer:#88c0d0:bold,marker:#a3be8c:bold,spinner:#81a1c1,header:#88c0d0:bold,border:#4c566a,label:#81a1c1:bold"
    return $?
  fi

  if command -v whiptail &>/dev/null; then
    whiptail --title "AWS Profile Manager" \
             --menu "Active: ${current}\nSelect:" \
             20 72 6 \
             "login"   "SSO login + set profile" \
             "switch"  "Set profile (no login)" \
             "whoami"  "Show caller identity" \
             "logout"  "SSO logout + unset" \
             "console" "Open web console" \
             "quit"    "Exit" \
             3>&1 1>&2 2>&3
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

  local current="${AWS_PROFILE:-<none>}"
  local header_text
  if [[ "$current" == "<none>" ]]; then
    header_text="╔═══════════════════════════════════════════════════════════╗
║ Active: ${current}
╚═══════════════════════════════════════════════════════════╝"
  else
    header_text="╔═══════════════════════════════════════════════════════════╗
║ Active: $(printf '\033[1;32m%s\033[0m' "$current")
╚═══════════════════════════════════════════════════════════╝"
  fi
  
  if command -v fzf &>/dev/null; then
    echo "$profiles" | \
      AWS_CONFIG_FILE="$cfg" \
      fzf \
        --ansi \
        --no-mouse \
        --prompt="❯ " \
        --header="$header_text" \
        --height=95% \
        --layout=reverse \
        --border=bold \
        --border-label="│ SELECT PROFILE │" \
        --border-label-pos=3 \
        --margin=1 \
        --padding=1 \
        --info=hidden \
        --prompt="❯ profiles " \
        --pointer="▌" \
        --marker="✓" \
        --color="fg:#d8dee9,bg:#2e3440,hl:#88c0d0,fg+:#eceff4,bg+:#3b4252,gutter:#2e3440,hl+:#8fbcbb,info:#81a1c1,prompt:#81a1c1:bold,pointer:#88c0d0:bold,marker:#a3be8c:bold,spinner:#81a1c1,header:#88c0d0:bold,border:#4c566a,label:#81a1c1:bold,preview-bg:#2e3440,preview-fg:#d8dee9,preview-border:#4c566a,preview-label:#81a1c1:bold" \
        --preview-window="right:55%:wrap:border-bold" \
        --preview-label="│ ACCOUNT DETAILS │" \
        --preview='
          p="{}"
          cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"

          # Exit if config missing
          if [[ ! -f "$cfg" ]]; then
            echo ""
            echo "  ERROR: Config file not found"
            echo "  Path: $cfg"
            exit 1
          fi

          # Header box
          printf "\n"
          printf "  \033[38;5;67m╔══════════════════════════════════════════╗\033[0m\n"
          printf "  \033[38;5;67m║\033[0m \033[1;38;5;116m%-40s\033[0m \033[38;5;67m║\033[0m\n" "$p"
          printf "  \033[38;5;67m╚══════════════════════════════════════════╝\033[0m\n"
          printf "\n"

          awk -v profile="$p" -v cfg="$cfg" '\''
            BEGIN {
              section = ""
              target_sess = ""
              found = 0
              
              # Strip quotes from profile name
              gsub(/^[\x27\x22]+|[\x27\x22]+$/, "", profile)
            }

            /^\[profile[[:space:]]/ {
              section = "profile"
              n = $0
              sub(/^\[profile[[:space:]]+/, "", n)
              sub(/\].*$/, "", n)
              current_profile = n
              if (n == profile) found = 1
              next
            }
            
            /^\[default\]/ {
              section = "profile"
              current_profile = "default"
              if (profile == "default") found = 1
              next
            }
            
            /^\[sso-session[[:space:]]/ {
              section = "sso-session"
              n = $0
              sub(/^\[sso-session[[:space:]]+/, "", n)
              sub(/\].*$/, "", n)
              current_session = n
              next
            }
            
            /^\[/ {
              section = ""
              next
            }

            /=/ {
              key = $0
              val = $0
              sub(/[[:space:]]*=.*/, "", key)
              sub(/^[^=]+=[ \t]*/, "", val)
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
              gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)

              if (section == "profile" && current_profile == profile) {
                profile_data[key] = val
                if (key == "sso_session") target_sess = val
              }

              if (section == "sso-session") {
                session_data[current_session, key] = val
              }
            }

            END {
              # Merge session data
              if (target_sess != "") {
                for (combined in session_data) {
                  split(combined, parts, SUBSEP)
                  if (parts[1] == target_sess) {
                    k = parts[2]
                    if (!(k in profile_data)) {
                      profile_data[k] = session_data[combined]
                    }
                  }
                }
              }

              # If no data found, show error
              if (length(profile_data) == 0) {
                printf "  \033[38;5;167mNo data found for profile: %s\033[0m\n", profile
                printf "\n"
                exit
              }

              # Labels and colors
              labels["sso_account_id"] = "ACCOUNT ID";  colors["sso_account_id"] = "\033[1;38;5;108m"
              labels["sso_start_url"] = "SSO URL";      colors["sso_start_url"] = "\033[1;38;5;109m"
              labels["sso_role_name"] = "ROLE";         colors["sso_role_name"] = "\033[1;38;5;140m"
              labels["region"] = "REGION";              colors["region"] = "\033[1;38;5;180m"
              labels["sso_region"] = "SSO REGION";      colors["sso_region"] = "\033[38;5;144m"
              labels["sso_session"] = "SESSION";        colors["sso_session"] = "\033[38;5;109m"

              keys[1] = "sso_account_id"
              keys[2] = "sso_start_url"
              keys[3] = "sso_role_name"
              keys[4] = "region"
              keys[5] = "sso_region"
              keys[6] = "sso_session"

              # Display priority fields
              for (i = 1; i <= 6; i++) {
                k = keys[i]
                if (k in profile_data) {
                  label = (k in labels) ? labels[k] : toupper(k)
                  color = (k in colors) ? colors[k] : "\033[38;5;145m"
                  printf "  %s%-15s\033[0m \033[38;5;59m│\033[0m \033[38;5;188m%s\033[0m\n", color, label, profile_data[k]
                  delete profile_data[k]
                }
              }

              # Skip displaying remaining fields (like sso_registration_scopes)
            }
          '\'' "$cfg"
        '
    return $?
  fi

  if command -v whiptail &>/dev/null; then
    local items=()
    while IFS= read -r p; do
      items+=("$p" " ")
    done <<< "$profiles"
    whiptail --title "AWS Profiles" \
             --menu "Active: ${current}\nChoose:" \
             20 72 12 \
             "${items[@]}" \
             3>&1 1>&2 2>&3
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

  _awp_info "Opening AWS Console for profile ${profile} in region ${region}"

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

  # Main loop - keep showing menu until user quits
  while true; do
    local action
    action="$(_awp_main_menu)" || return 0  # Esc on main menu = exit

    # Normalise fzf full-text selection → key token
    case "$action" in
      login*)   action="login"   ;;
      switch*)  action="switch"  ;;
      whoami*)  action="whoami"  ;;
      logout*)  action="logout"  ;;
      console*) action="console" ;;
      quit*)    return 0         ;;
    esac

    # Run action - if it returns 0, continue loop (back to menu)
    # If user presses Esc in submenu, it returns 1 and loops back
    _awp_run_action "$action" || continue
  done
}

# ---------------------------------------------------------------------------
# Internal: dispatch action
# ---------------------------------------------------------------------------
_awp_run_action() {
  local action="$1"
  local profile

  case "$action" in

    login)
      profile="$(_awp_pick_profile)" || return 0  # Esc = back to menu

      _awp_info "Running: aws sso login --profile ${profile}"
      AWS_PAGER="" aws --no-cli-pager sso login --profile "$profile" \
        || { _awp_error "SSO login failed."; return 0; }

      export AWS_PROFILE="$profile"
      _awp_ok "Login successful — AWS_PROFILE=${profile}"
      ;;

    switch)
      profile="$(_awp_pick_profile)" || return 0  # Esc = back to menu
      
      # Check if profile has valid credentials
      _awp_info "Checking credentials for profile ${profile}..."
      if AWS_PAGER="" aws --no-cli-pager sts get-caller-identity --profile "$profile" &>/dev/null; then
        # Already logged in, just switch
        export AWS_PROFILE="$profile"
        _awp_ok "Switched — AWS_PROFILE=${profile}"
      else
        # Not logged in, need SSO login first
        _awp_warn "Profile not logged in. Running SSO login..."
        AWS_PAGER="" aws --no-cli-pager sso login --profile "$profile" \
          || { _awp_error "SSO login failed."; return 0; }
        
        export AWS_PROFILE="$profile"
        _awp_ok "Login successful — AWS_PROFILE=${profile}"
      fi
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
      return 0
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
