# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-02-19

### Added
- Interactive TUI menu with fzf (arrow-key navigation) and whiptail fallback
- `login` action: `aws sso login` + `export AWS_PROFILE`
- `switch` action: set `AWS_PROFILE` without running SSO login
- `whoami` action: `sts:GetCallerIdentity` for the current profile
- `logout` action: `aws sso logout` + `unset AWS_PROFILE`
- `console` action: open the AWS web console in the default browser
- Non-interactive / scripting mode (`aws-profile login`, `aws-profile switch`, …)
- Shell prompt helper `__awp_ps1` for PS1/PROMPT integration
- `--help` and `--version` flags
- Zsh completion (`completions/_aws-profile.zsh`)
- Bash completion (`completions/aws-profile.bash`)
- One-liner `install.sh` installer
- ShellCheck CI via GitHub Actions
- Guard against double-sourcing
- Color output gracefully disabled when not a TTY
