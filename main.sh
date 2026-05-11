#!/usr/bin/env bash

# Track startup time
STARTUP_START=${EPOCHREALTIME/./}

# --------------------------------------------------
# 1. Agnostic Root Resolution
# --------------------------------------------------
if [ -n "$ZSH_VERSION" ]; then
    REPO_ROOT="${${(%):-%x}:a:h}"
elif [ -n "$BASH_VERSION" ]; then
    REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
fi

# --------------------------------------------------
# 2. Path Injection
# --------------------------------------------------
# This allows Hyprland and shell to find the custom binaries
REPO_BIN="$REPO_ROOT/bin"
if [[ -d "$REPO_BIN" ]] && [[ ":$PATH:" != *":$REPO_BIN:"* ]]; then
    export PATH="$REPO_BIN:$PATH"
fi

# --------------------------------------------------
# 3. Core Engine (Library Loading)
# --------------------------------------------------
# We source utils first so tools like dep_check are available to everything else
[[ -f "$REPO_ROOT/lib/utils.sh" ]] && source "$REPO_ROOT/lib/utils.sh"

# Load remaining libraries (Functions that stay in memory)
for lib in "$REPO_ROOT/lib/"*.sh; do
    [[ "$(basename "$lib")" == "utils.sh" ]] && continue
    [[ -r "$lib" ]] && source "$lib"
done

# --------------------------------------------------
# 4. Environment & Session (Profile Loading)
# --------------------------------------------------
# Sourcing in numerical order (00-env, 10-aliases, etc.)
if [[ -d "$REPO_ROOT/profile" ]]; then
    for profile in "$REPO_ROOT/profile/"*.sh; do
        [[ -r "$profile" ]] && source "$profile"
    done
fi

# --------------------------------------------------
# Startup summary
# --------------------------------------------------
STARTUP_END=${EPOCHREALTIME/./}
TOTAL_US=$((STARTUP_END - STARTUP_START))
if [[ "$DEBUG_LOAD" == "true" ]]; then
    printf "\033[1;32mShell ready in %d µs\033[0m\n" "$TOTAL_US"
fi
