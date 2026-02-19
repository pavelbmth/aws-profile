# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] — 2026-02-19

### Added
- Interactive TUI menu with k9s-style design
- Smart profile switching with auto-login detection
- Profile picker with live preview panel showing:
  - Account ID
  - SSO URL
  - Role name
  - Region
  - SSO session details
- Mouse text selection support in preview panel
- Color-coded active profile indicator (green)
- Menu loop navigation (Esc goes back to main menu)
- Actions:
  - `login` - SSO login + export AWS_PROFILE
  - `switch` - Smart switch (auto-detects if login needed)
  - `whoami` - Show sts:GetCallerIdentity
  - `logout` - SSO logout + unset AWS_PROFILE
  - `console` - Open AWS console in browser
- Non-interactive mode for scripting
- Shell prompt helper `__awp_ps1` for PS1/PROMPT integration
- Support for both legacy and new AWS config formats (sso-session)
- Zsh and Bash completion scripts
- One-liner installer and uninstaller
- ShellCheck CI via GitHub Actions
- `--help` and `--version` flags
- Nord color scheme (k9s-inspired)
