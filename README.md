# 🚀 Agnostic Custom Bash/Zsh Shell

A high-performance, modular shell utility framework designed to be **distro-agnostic** across any FHS-compliant Linux distribution (Arch Linux, NixOS, Debian/Ubuntu, Fedora, Alpine, etc.).

This framework separates interactive shell functions, library helpers, and standalone executables into a clean, observable Unix-standard architecture.

## 📂 Architecture & Load Order

1.  **`bin/` (Executables):** Standalone scripts automatically injected into `$PATH`. Accessible by your window manager, compositors, and system processes without sourcing.
2.  **`lib/` (Core Logic):** Pure bash helper functions (`jump`, `gitignore`, `gacp`, `wlc`, `pdf_dc`, `quicklinks`, `fm`). Sourced in-memory by `main.sh`.
3.  **`profile/` (Interactive Layer):** Modular environment variables (`00-env.sh`), productive aliases (`10-aliases.sh`), and autostart shell hooks (`30-autostart.sh`).
4.  **`main.sh` (Orchestrator):** Portable entry point handling shell-agnostic root resolution and zero-overhead module loading.

## 🛠 Prerequisites & Distro-Agnostic Dependency Guard

The framework features `bin/dep_check`, an automatic multi-distro dependency checker. It dynamically detects your package manager (`paru`, `pacman`, `apt`, `dnf`, `zypper`, `apk`, `nix-env`) to report missing tools.

| Category | Command | Common Package Name |
| :--- | :--- | :--- |
| **Core Shell** | `bash` / `zsh` | `bash` / `zsh` |
| **CLI Essentials** | `git`, `gh`, `direnv` | `git`, `github-cli`, `direnv` |
| **Wayland/Compositors** | `grim`, `slurp`, `swappy`, `wl-copy`, `notify-send` | `grim`, `slurp`, `swappy`, `wl-clipboard`, `libnotify` |
| **Modern CLI Tools** | `starship`, `fastfetch`, `eza`, `fzf`, `fd`, `rg`, `bat`, `zoxide`, `yazi`, `delta` | `starship`, `fastfetch`, `eza`, `fzf`, `fd`, `ripgrep`, `bat`, `zoxide`, `yazi`, `git-delta` |
| **Development & Utils** | `nvim`, `uv`, `qpdf`, `jq`, `btop` | `neovim`, `uv`, `qpdf`, `jq`, `btop` |

### ⚡ Quick Start
```bash
# 1. Clone to ~/Scripts
git clone https://github.com/kiskaadee/bash-custom ~/Scripts

# 2. Bootstrap ~/.bashrc
cp ~/.bashrc ~/.bashrc_backup
cp ~/Scripts/bashrc-example.txt ~/.bashrc
source ~/.bashrc
```

## 🔍 Key Features & Workflows

### 🏎 Fuzzy Navigation & Sticky FM (`lib/jump.sh`)
Powered by `fzf`, `fd`, `eza`, and `yazi`.
- **Root Directory Selection:** Triggering a jumper displays the root directory alongside its subfolders, allowing direct selection of the base path.
- **Shorthand Jumpers:**
  - `cfg`: Jump into config directory (`~/Config` or `~/.config`).
  - `prj`: Jump into `~/Projects`.
  - `lrn`: Jump into `~/Learn`.
  - `dep`: Jump into `~/Deployments`.
  - `dl`: Jump into `~/Downloads`.
  - `med`: Jump into `/media`.
  - `rp`: Jump into `~/Repositories`.
  - `sc`: Jump into `~/Scripts`.
  - `vlt`: Jump into `~/Vaults`.
- **Sticky Yazi File Manager:**
  - `fm`: Launches `yazi` interactive file manager and changes current working directory to Yazi's last active directory on exit.

### 🐙 Git Automation (`lib/git.sh`)
- `gacp "<message>"`: Add all, commit, and push to remote origin on active branch.
- `gitignore <pattern>`: Append pattern to root `.gitignore`, commit, and push.
- `new-repo <name>`: Create local directory, initialize git repo, create starter files, and publish via `gh` CLI.

### 📋 Wayland Clipboard Header (`lib/wayland.sh`)
- `wlc [--headers] <command>`: Runs command, displays output in terminal, and concurrently streams combined output into Wayland clipboard (`wl-copy`).

### 🔒 Distro-Agnostic PDF Decryptor (`lib/pdf.sh`)
- `pdf_dc <file.pdf>`: Decrypts PDF file using `qpdf`. Automatically resolves decryption secret from NixOS sops (`/run/secrets/pdf_decrypt_password`), user config (`~/.config/secrets/pdf_decrypt_password`), or `~/.env`.

### 🚀 Quicklinks Launcher (`lib/quicklinks.sh` / `ql`)
- `ql`: Interactive `fzf` prompt to select and run custom commands defined in `~/.quicklinks`.

## ⏱ Performance & Observability
Startup time is tracked in microseconds. Set `DEBUG_LOAD=true` in your shell environment to display timing metrics:
```bash
export DEBUG_LOAD=true
```
Run `bl` (`bash list`) to view all available custom functions, aliases, and documentation strings loaded in your environment.

