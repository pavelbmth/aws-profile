# Bash completion for aws-profile
# Install: source this file in ~/.bashrc, or copy to /etc/bash_completion.d/

_aws_profile_complete() {
  local cur prev words cword
  _init_completion 2>/dev/null || {
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
  }

  local actions="login switch whoami logout console"
  local flags="--help --version -h -v"

  case "$prev" in
    aws-profile)
      # shellcheck disable=SC2207
      COMPREPLY=($(compgen -W "$actions $flags" -- "$cur"))
      return 0
      ;;
  esac

  COMPREPLY=()
}

complete -F _aws_profile_complete aws-profile
