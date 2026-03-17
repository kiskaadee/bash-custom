# 🚀 Shell Environment & Script Modules

This repository is a modular configuration framework designed to automate the setup of a fresh Arch Linux environment. It replaces a static `.bashrc` with a dynamic entry point that loads customized modular workflows and tools.

## 🛠 Core Requirements

This framework assumes an Arch Linux environment running [Hyprland](https://hypr.land/) (Wayland).

* **Shell**: Bash 5.0+

* **System Tools**: `wl-clipboard`, `git`, `bc`

* **Rust-based CLI Suite**:

    * `starship` (Prompt)

    * `fastfetch` (System Info)

    * `eza` (LS replacement)

    * `fzf` (Fuzzy Finder)

    * `fd` (Find replacement)

    * `rg` (Ripgrep)

    * `bat` (Cat clone)



## 📂 Structure

* `init`: The idempotent setup script.

* `main.sh`: The entry point (sourced by .bashrc).

* `modules/`: Individual feature sets (Aliases, Fuzzy Jumpers, Git Tools).

## ⚡ Quick Start

On a new machine, simply clone and initialize:

```bash
git clone https://github.com/kiskaadee/bash-custom ~/Scripts
cd ~/Scripts
./init
```

Install dependencies: 

```bash
sudo pacman -Syu && sudo pacman -S wl-clipboard git bc starship fastfetch eza fzf fd ripgrep bat 

```
The init script will back up your existing `.bashrc`, truncate it, and insert a hook pointing to `main.sh`.

---

## 🔍 Fuzzy Navigation Engine

A collection of composable shell functions for rapid filesystem navigation and file manipulation using `fd`, `rg`, and `fzf`.

## 🧩 Logic Flow

The engine separates Selection (finding the path) from Action (doing something with it).

### ⌨️ Available Commands

|   Command     |   Action              |   Base Directory  |
|   ---        |	---     |	---    |
|   pj          |	Jump to Project     |	`~/Projects`    |
|   sc          |	Jump to Scripts     |	`~/Scripts`     |
|   cnf         |	Jump to Config      |   `~/.config` (Depth: 3) |
|   edit_dir    |	Open Dir in Neovim  |	`~/Projects`    |
|   copy_dir    |	Copy Path to Clipboard | 	`$HOME`     |
| jump_search	| Jump by File Content	| Specified Base    |

### ⚙️ Configuration

You can toggle the post-jump behavior in main.sh:

* `JUMP_VERBOSE=true`: Shows the target path and an eza tree listing after jumping.

* `JUMP_VERBOSE=false`: Silent navigation (only changes directory).

