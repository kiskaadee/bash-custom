# Refactoring Plan: Shell Architecture 2.0

**Problem Statement:** The current "source-everything" model injects all logic into the shell's active memory. This pollutes the namespace, increases startup latency, and creates circular dependencies when standalone scripts (like those triggered by Hyprland) cannot access sourced functions without redundant loading.

**Objective:** Implement a "Unix-standard" directory structure that differentiates between sourced environment variables/aliases and executable binaries.

**Non-Goals:**
*   Replacing established third-party binaries (`fzf`, `rg`, `eza`).
*   Implementing a full plugin manager (keeping it a "local-first" framework).
*   Deprecating Bash support entirely (maintaining a hybrid Bash/Zsh compatibility).

---

## 1. Implementation Milestones

| Milestone | Phase | Key Deliverables |
| :--- | :--- | :--- |
| **M1: Infrastructure** | Directory Setup | Create `bin/`, `lib/`, `profile/`, and `bin/tests/`. |
| **M2: Core Engine** | Library Migration | Move `dep_check` and utility functions to `lib/utils.sh`. |
| **M3: Env Migration** | Profile Cleanup | Move aliases and exports from `modules/` to `profile/`. |
| **M4: Exec Layer** | Binary Extraction | ✅ Convert standalone functions (e.g., `grimshot`) into files in `bin/`. |
| **M5: Portability** | Zsh Hybridization | Update `main.sh` for cross-shell compatibility and path injection. |
| **M6: Verification** | Testing | ✅ Implement **Bats** tests for critical logic. |

---

## 2. Refactored Blueprint

The new structure ensures that only what is **strictly necessary** for interactive use is loaded into memory.

```text
.
├── bin/                 # EXECUTABLES: Standalone scripts (e.g., grimshot, dep_check)
│   ├── tests/           # VALIDATION: Unit tests using Bats
├── lib/                 # SHARED LOGIC: Private helper functions
├── profile/           # ENVIRONMENT: Sourced aliases, exports, and prompts
│   ├── 00-env.sh
│   ├── 10-aliases.sh
│   └── 20-prompts.sh
├── install.sh           # BOOTSTRAP: Automation for fresh installs
└── main.sh              # ORCHESTRATOR: Entry point for .bashrc / .zshrc
```

---

## 3. Core Logic: The Execution Layer

### Standalone Binaries (`bin/`)
Scripts in `bin/` are added to your system `$PATH`. They are never sourced. They run in their own sub-process, ensuring they don't interfere with your current shell state.

> **Note:** Use `#!/usr/bin/env bash` for scripts in `bin/`. Even if your interactive shell is Zsh, using Bash for scripts ensures maximum stability and avoids Zsh-specific word-splitting behaviors.

### Shared Library (`lib/`)
To avoid circular dependencies, critical logic is placed in `lib/`. For tools that need to be globally accessible without sourcing, they are moved to `bin/` (e.g., `dep_check`).

# In bin/grimshot (Standalone script)
dep_check grim slurp || exit 1

---

## 4. Performance Implications

By moving logic to `bin/`, the shell startup cost $T$ becomes independent of the number of tools you own.

$$T \approx \sum_{i=1}^{n_{profile}} (p_i + e_i)$$

Where $n_{profile}$ is restricted to a few essential files in `profile/`. Standalone tools carry **zero** cost until they are manually invoked.

---

## 5. Zsh Migration & Shell Agnosticism

To support a future move to Zsh without breaking the current setup, the following adaptations must be implemented in `main.sh`:

### Agnostic Path Resolution
Zsh and Bash handle script location differently. The orchestrator must detect the shell to find `REPO_ROOT`.

```bash
if [ -n "$ZSH_VERSION" ]; then
    REPO_ROOT="${${(%):-%x}:a:h}"
elif [ -n "$BASH_VERSION" ]; then
    REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi
```

### Critical "Gotchas"
*   **Array Indexing:** Zsh is 1-indexed; Bash is 0-indexed. Keep logic in `lib/` shell-agnostic by avoiding complex array manipulation where possible.
*   **Word Splitting:** Zsh does not split variables by spaces automatically (`for i in $var`). Use `for i in ${=var}` in Zsh or keep loops within Bash-shebanged scripts in `bin/`.
*   **Injections:** Use the `install.sh` to detect the shell and append the correct line to either `~/.bashrc` or `~/.zshrc`.

---

## 6. Verification (The "Sidequest")

Using **Bats** ensures that high-risk functions like `gitignore` or `pdf_dc` (which involve file manipulation) are safe across updates.

```bash
# bin/tests/bats/utils.bats
@test "dep_check fails on non-existent command" {
  run dep_check "non_existent_command_123"
  [ "$status" -eq 1 ]
}
```
:wa