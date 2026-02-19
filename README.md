# aws-profile

> Lightweight AWS Profile Manager TUI for your terminal — switch IAM/SSO profiles with arrow keys.

[![ShellCheck](https://github.com/YOUR_USERNAME/aws-profile/actions/workflows/lint.yml/badge.svg)](https://github.com/YOUR_USERNAME/aws-profile/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-blue)

---

## Features

- **Arrow-key navigation** via [fzf](https://github.com/junegunn/fzf) (or `whiptail` fallback)
- **SSO Login** — runs `aws sso login` and exports `AWS_PROFILE` in your current shell
- **Profile Switch** — instantly change `AWS_PROFILE` without logging in
- **Who am I** — calls `sts:GetCallerIdentity` to verify your current identity
- **SSO Logout** — runs `aws sso logout` and clears `AWS_PROFILE`
- **Open Console** — opens the AWS web console for the current region in your browser
- **Shell prompt integration** — shows current profile in your `PS1`/`PROMPT`
- **Non-interactive mode** — pass an action directly: `aws-profile login`
- **Zero dependencies** beyond `aws` CLI and `fzf`

---

## Demo

<!-- Replace with an actual demo GIF recorded with asciinema / vhs -->
```
$ aws-profile
╭──────────────────────────────────────────────────────╮
│ AWS Profile Manager v1.0.0  |  Current: my-account   │
│──────────────────────────────────────────────────────│
│ ▶ Login       — aws sso login + export AWS_PROFILE   │
│   Switch      — export AWS_PROFILE (no login)        │
│   Who am I   — sts get-caller-identity               │
│   Logout      — sso logout + unset AWS_PROFILE       │
│   Console     — open AWS web console in browser      │
│   Quit                                               │
╰──────────────────────────────────────────────────────╯
  Profile >
```

---

## Requirements

| Tool | Required | Notes |
|------|----------|-------|
| `aws` | ✅ Yes | [Install](https://aws.amazon.com/cli/) |
| `fzf` | ⭐ Recommended | `brew install fzf` — best experience |
| `whiptail` | Fallback | Usually pre-installed on Linux |

---

## Installation

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/aws-profile/main/install.sh | bash
```

Then restart your shell or run:

```bash
source ~/.zshrc   # or ~/.bashrc
```

### Manual

1. Clone or download this repository:

```bash
git clone https://github.com/YOUR_USERNAME/aws-profile.git ~/.aws-profile
```

2. Source the script in your shell RC file:

```bash
# ~/.zshrc or ~/.bashrc
source ~/.aws-profile/aws-profile.sh
```

3. _(Optional)_ Install shell completion:

```bash
# zsh (oh-my-zsh)
cp completions/_aws-profile.zsh ~/.oh-my-zsh/custom/completions/_aws-profile

# bash
source completions/aws-profile.bash   # add to ~/.bashrc for persistence
```

---

## Usage

### Interactive mode (default)

```bash
aws-profile
```

### Non-interactive / scripting

```bash
aws-profile login     # pick a profile and run sso login
aws-profile switch    # pick a profile and set AWS_PROFILE
aws-profile whoami    # show current caller identity
aws-profile logout    # sso logout + unset AWS_PROFILE
aws-profile console   # open AWS console in browser
```

### Flags

```bash
aws-profile --help
aws-profile --version
```

---

## Shell Prompt Integration

Show the active AWS profile in your shell prompt:

```bash
# ~/.zshrc
PROMPT='$(__awp_ps1)'$PROMPT

# ~/.bashrc
PS1='$(__awp_ps1)'$PS1
```

Result:

```
(aws:my-account) user@host ~ $
```

---

## How it works

`aws-profile` is a **sourced** bash/zsh script (not a standalone binary). Sourcing is required so that `export AWS_PROFILE` affects your *current* shell session — a subprocess cannot modify the parent shell's environment.

All internal functions are prefixed with `_awp_` to avoid polluting your shell namespace.

---

## Configuration

`aws-profile` reads the standard AWS config file:

```
~/.aws/config          (default)
$AWS_CONFIG_FILE       (if set)
```

Profiles must follow the standard format:

```ini
[profile my-account]
sso_start_url  = https://my-org.awsapps.com/start
sso_region     = eu-west-1
sso_account_id = 123456789012
sso_role_name  = DeveloperAccess
region         = eu-west-1
```

---

## Uninstall

```bash
rm -rf ~/.aws-profile
# Remove the source line from ~/.zshrc or ~/.bashrc
```

---

## Contributing

Contributions are welcome! Please open an issue or pull request.

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Run linting: `shellcheck aws-profile.sh`
4. Submit a pull request

---

## License

[MIT](LICENSE) © YOUR_NAME
