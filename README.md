# 🚀 Arch Custom Bash/Zsh Shell

A high-performance, modular configuration framework designed for Arch Linux (Wayland/Hyprland). This 2.0 refactor implements a "Unix-standard" architecture, separating interactive environments from standalone executables.

## 📂 Architecture & Load Order

The framework differentiates between what is stored in memory and what is executed on demand to maximize performance.

1.  **`bin/` (The Executables):** Standalone scripts added to `$PATH`. Accessible by Hyprland and other processes without sourcing.
2.  **`lib/` (The Logic):** Private functions and shared utilities. Sourced by the shell and `bin/` scripts.
3.  **`profile/` (The Interactive Layer):** Sourced environment variables, aliases, and prompts.
4.  **`main.sh` (The Orchestrator):** Entry point that handles shell-agnostic path resolution and module loading.

## 🛠 Prerequisites & Dependencies

This framework relies on several external tools. The `dep_check` utility automatically verifies these when a script or function is executed.

| Category | Command | Package (Arch Linux) | Repository |
| :--- | :--- | :--- | :--- |
| **Core Shell** | `bash` / `zsh` | `bash` / `zsh` | `core` |
| **CLI Essentials** | `git`, `gh`, `bc` | `git`, `github-cli`, `bc` | `extra` |
| **Wayland/Hyprland** | `grim`, `slurp`, `swappy` | `grim`, `slurp`, `swappy` | `extra` |
| | `wl-copy`, `notify-send` | `wl-clipboard`, `libnotify` | `extra` |
| | `hyprctl`, `hyprlock` | `hyprland`, `hyprlock` | `extra` |
| **Modern CLI Tools** | `starship`, `fastfetch` | `starship`, `fastfetch` | `extra` |
| | `eza`, `fzf`, `fd`, `rg` | `eza`, `fzf`, `fd`, `ripgrep` | `extra` |
| | `bat`, `zoxide`, `yazi` | `bat`, `zoxide`, `yazi` | `extra` |
| | `delta` | `git-delta` | `extra` |
| **Development** | `nvim`, `zed` | `neovim`, `zed` | `extra` |
| | `uv`, `sqlite3` | `uv`, `sqlite` | `extra` / `core` |
| **System/Utils** | `btop`, `nmtui`, `wpctl` | `btop`, `networkmanager`, `wireplumber` | `extra` |
| | `qpdf`, `jq`, `pgrep` | `qpdf`, `jq`, `procps-ng` | `extra` |
| | `tty-clock` | `tty-clock` | `AUR` |

### ⚡ Quick Start
```bash
# 1. Install Core Dependencies
sudo pacman -Syu && sudo pacman -S git github-cli bc wl-clipboard starship fastfetch eza fzf fd ripgrep bat zoxide qpdf grim slurp jq swappy libnotify hyprland neovim yazi btop wireplumber sqlite git-delta

# 2. Install AUR Dependencies (if using paru)
paru -S tty-clock

# 3. Clone to ~/Scripts
git clone https://github.com/kiskaadee/bash-custom ~/Scripts

# 4. Bootstrap ~/.bashrc
cp ~/.bashrc ~/.bashrc_backup
cp ~/Scripts/bashrc-example.txt ~/.bashrc
```

## 🔍 Key Workflows

### 📸 Screenshot Engine (`bin/grimshot`)
A standalone utility for Wayland, with native support for Hyprland, Niri, and Sway.
- `grimshot selection`: Interactive selection tool.
  - **Smart Selection:** Drag to capture a custom rectangle; single-click to automatically fall back to `window` capture for the focused window.
  - **Deterministic Cancellation:** Escape aborts cleanly without notifications or clipboard updates.
- `grimshot screen [--all]`: Capture the focused monitor or all monitors.
- `grimshot window`: Capture the currently focused window.
- **Advanced Options:** Supports `--edit` (Swappy) and `--save [path]`.
- **Compositor Features:**
  - **Hyprland:** Uses `hyprctl` for precise window and monitor targeting.
  - **Niri:** Uses native `niri msg` actions for window/screen capture. Note: `selection` fallback (1x1 click) is not supported due to IPC streaming limitations.
  - **Sway:** Uses `swaymsg` for window geometry and monitor targeting.
- **Deps:** `grim`, `slurp`, `wl-clipboard`, `jq`, `swappy`, `libnotify`.

### 🐙 Git Quickstart (`bin/git-ready`)
Bootstraps a professional Git environment with `delta` integration and a suite of productivity aliases.
- **Initialization:** `git-ready path/to/git.yml`
- **Modern UI:** Automatically configures `git-delta` for side-by-side diffs, syntax highlighting, and `zdiff3` conflict markers.
- **Power Aliases:**
  - `git st`, `git co`, `git br`: Shorthand for status, checkout, and branch.
  - `git dc`: Diff and copy to clipboard (Wayland native).
  - `git acp <branch> "<message>"`: Atomic Add, Commit, and Push.
  - `git sync`: Prune-fetch and pull in one command.
  - `git lg`: Beautiful graph-based history view.
  - `git undo` / `git unstage`: Quick recovery from mistakes.
  - `git nuke`: Destructive reset to match remote `HEAD`.
- **Deps:** `git`, `neovim`, `git-delta`, `wl-clipboard`.

### 🏎 Fuzzy Navigation
Powered by `zoxide` (history) and `fd` (discovery).
- `cd <query>`: Z-powered frequency-based jump.
- `zi`: Interactive history search with `eza` previews.
- `pj`, `sc`, `cnf`: Context-aware jumpers to Projects, Scripts, and Configs.
- **Deps:** `fzf`, `fd`, `eza`, `zoxide`.

### 🛡️ Dependency Guard (`bin/dep_check`)
A "Doctor" utility to verify system health.
- `dep_check my-script git fzf`: Validates dependencies and provides `pacman` fix commands on failure.
- Now supports command-to-package mapping (e.g., `wl-copy:wl-clipboard`).

## ⏱ Performance
The current architecture keeps the startup cost $T$ independent of the number of tools in `bin/`:
$$T \approx \sum_{i=1}^{n_{profile}} (p_i + e_i)$$

Toggle `DEBUG_LOAD=true` in `main.sh` to view microsecond metrics.
