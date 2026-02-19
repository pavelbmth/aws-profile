<div align="center">

# 🔐 aws-profile

**Lightweight AWS Profile Manager TUI for your terminal**

Switch IAM / SSO profiles with arrow keys — no more copy-pasting profile names.

[![ShellCheck](https://github.com/pavelbmth/aws-profile/actions/workflows/lint.yml/badge.svg)](https://github.com/pavelbmth/aws-profile/actions/workflows/lint.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Shell](https://img.shields.io/badge/shell-bash%20%7C%20zsh-informational)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey)

</div>

---

## ✨ Features

| | Feature |
|---|---|
| 🎯 | **Arrow-key navigation** via [fzf](https://github.com/junegunn/fzf) (or `whiptail` fallback) |
| 🔑 | **SSO Login** — runs `aws sso login` and exports `AWS_PROFILE` in your current shell |
| 🔄 | **Profile Switch** — instantly change `AWS_PROFILE` without logging in again |
| 🕵️ | **Who am I** — calls `sts:GetCallerIdentity` to verify your current identity |
| 🚪 | **Logout** — runs `aws sso logout` and clears `AWS_PROFILE` |
| 🌐 | **Open Console** — opens the AWS web console in your browser |
| 💡 | **Shell prompt badge** — shows active profile in your `PS1` / `PROMPT` |
| ⚡ | **Non-interactive mode** — scriptable: `aws-profile login` |
| 🪶 | **Zero extra dependencies** beyond `aws` CLI and `fzf` |

---

## 📺 Demo

```
$ aws-profile

  AWS Profile Manager v1.0.0  |  Current: my-account
 ╭──────────────────────────────────────────────────────────╮
 │ ▶ Login       — aws sso login + export AWS_PROFILE       │
 │   Switch      — export AWS_PROFILE (no login)            │
 │   Who am I   — sts get-caller-identity                   │
 │   Logout      — sso logout + unset AWS_PROFILE           │
 │   Console     — open AWS web console in browser          │
 │   Quit                                                   │
 ╰──────────────────────────────────────────────────────────╯
  Action >
```

> **Tip:** Record a demo GIF with [vhs](https://github.com/charmbracelet/vhs) — `brew install vhs` — and replace this block.

---

## 📋 Requirements

| Tool | Required | Install |
|------|:--------:|---------|
| `aws` | ✅ | [aws.amazon.com/cli](https://aws.amazon.com/cli/) |
| `fzf` | ⭐ Recommended | `brew install fzf` |
| `whiptail` | Fallback only | Pre-installed on most Linux distros |

---

## 🚀 Installation

### One-liner — recommended

```bash
curl -fsSL https://raw.githubusercontent.com/pavelbmth/aws-profile/main/install.sh | bash
```

Restart your shell (or reload it):

```bash
source ~/.zshrc    # zsh
source ~/.bashrc   # bash
```

---

### Manual install

**1. Clone the repo:**

```bash
git clone https://github.com/pavelbmth/aws-profile.git ~/.aws-profile
```

**2. Source it in your shell RC file:**

```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'source ~/.aws-profile/aws-profile.sh' >> ~/.zshrc
source ~/.zshrc
```

**3. (Optional) Install shell completions:**

```bash
# zsh — oh-my-zsh
cp ~/.aws-profile/completions/_aws-profile.zsh \
   ~/.oh-my-zsh/custom/completions/_aws-profile

# bash
echo 'source ~/.aws-profile/completions/aws-profile.bash' >> ~/.bashrc
```

---

## 🎮 Usage

### Interactive menu (default)

```bash
aws-profile
```

Use `↑` `↓` arrows or type to search, press `Enter` to confirm, `Esc` to cancel.

### Direct sub-commands (non-interactive)

```bash
aws-profile login     # pick a profile → aws sso login → set AWS_PROFILE
aws-profile switch    # pick a profile → set AWS_PROFILE (no login)
aws-profile whoami    # show sts:GetCallerIdentity for current profile
aws-profile logout    # aws sso logout → unset AWS_PROFILE
aws-profile console   # open AWS web console in browser
```

### Flags

```bash
aws-profile --help       # show help
aws-profile --version    # show version
```

---

## 💻 Shell Prompt Badge

Show the active AWS profile next to your shell prompt:

```bash
# ~/.zshrc
PROMPT='$(__awp_ps1)'$PROMPT

# ~/.bashrc
PS1='$(__awp_ps1)'$PS1
```

Result:

```
(aws:my-account) user@host ~/projects $
```

---

## ⚙️ Configuration

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

## 🔍 How it works

`aws-profile` is a **sourced** shell script, not a standalone binary.

Sourcing is intentional — a subprocess cannot modify the parent shell's environment, so `export AWS_PROFILE` must run in your current session. All internal helpers are prefixed `_awp_` to avoid polluting your shell namespace.

---

## 🗑️ Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/pavelbmth/aws-profile/main/uninstall.sh | bash
```

Or manually:

```bash
rm -rf ~/.aws-profile

# Remove the source line from your shell RC
# Open ~/.zshrc or ~/.bashrc and delete the line:
#   source ~/.aws-profile/aws-profile.sh
```

---

## 🤝 Contributing

Contributions, issues and feature requests are welcome!

1. Fork the repo
2. Create a feature branch: `git checkout -b feat/my-feature`
3. Lint your changes: `shellcheck aws-profile.sh`
4. Open a pull request

---

## 📄 License

[MIT](LICENSE) © [pavelbmth](https://github.com/pavelbmth)
