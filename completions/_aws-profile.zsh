#compdef aws-profile
# Zsh completion for aws-profile
# Install: copy to a directory in $fpath, e.g. /usr/local/share/zsh/site-functions/
# Or let install.sh handle it automatically.

_aws_profile_profiles() {
  local cfg="${AWS_CONFIG_FILE:-$HOME/.aws/config}"
  [[ -f "$cfg" ]] || return
  local profiles
  profiles=$(awk '
    /^\[profile[[:space:]]+/ {
      line=$0; sub(/^\[profile[[:space:]]+/, "", line); sub(/\].*$/, "", line); print line
    }
    /^\[default\]/ { print "default" }
  ' "$cfg" | sort -u)
  _values 'profile' ${(f)profiles}
}

_aws_profile() {
  local -a actions flags

  actions=(
    'login:Run aws sso login and set AWS_PROFILE'
    'switch:Set AWS_PROFILE without logging in'
    'whoami:Show sts get-caller-identity'
    'logout:Run aws sso logout and unset AWS_PROFILE'
    'console:Open AWS web console in browser'
  )

  flags=(
    {-h,--help}'[Show help]'
    {-v,--version}'[Show version]'
  )

  _arguments -C \
    "${flags[@]}" \
    ':action:(login switch whoami logout console)' \
    && return 0
}

_aws_profile "$@"
