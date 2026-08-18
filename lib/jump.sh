dep_check "lib/jump.sh" "fzf" "fd:fd-find" "eza" "nvim:neovim" "wl-copy:wl-clipboard" "rg:ripgrep" || return 1

# 1. fm: Interactive file manager wrapper using Yazi.
# Synchronizes active shell working directory to Yazi exit folder.
fm() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        cd -- "$cwd" || return
    fi
    rm -f -- "$tmp"
}

# 2. _fuzzy_select_dir: Internal helper to locate subdirectories (including root base folder) using fd and fzf.
_fuzzy_select_dir() {
    local base="$1"
    local query="$2"
    local max_depth="${3:-2}"

    command -v fzf >/dev/null && command -v fd >/dev/null || return 1
    [[ -d "$base" ]] || return 1

    (echo "$base"; fd . "$base" --type d --mindepth 1 --max-depth "$max_depth" 2>/dev/null) |
    fzf \
        --query="$query" \
        --select-1 \
        --exit-0
}

# 3. _fuzzy_select_dir_preview: Internal helper displaying eza directory previews inside fzf.
_fuzzy_select_dir_preview() {
    local base="$1"
    local query="$2"
    local max_depth="${3:-2}"

    command -v fzf >/dev/null && command -v fd >/dev/null && command -v eza >/dev/null || return 1
    [[ -d "$base" ]] || return 1

    (echo "$base"; fd . "$base" --type d --mindepth 1 --max-depth "$max_depth" 2>/dev/null) |
    fzf \
        --query="$query" \
        --select-1 \
        --exit-0 \
        --preview 'eza --tree --level 2 --icons=always --color=always {}' \
        --preview-window="right:50%:rounded"
}

# 4. _jump_to: Safely enter target folder and optionally list contents.
_jump_to() {
    local dir="$1"
    [[ -d "$dir" ]] || return 1

    cd "$dir" || return 1

    if [[ "${JUMP_VERBOSE:-false}" == true ]]; then
        printf "\033[1;32mJumped to:\033[0m %s\n" "$dir"
        eza -la --icons 2>/dev/null
    fi
}

# 5. jump: Primary entrypoint for fuzzy folder traversal.
jump() {
    local base="$1"
    local query="$2"
    local depth="${3:-2}"

    local dir
    dir=$(_fuzzy_select_dir_preview "$base" "$query" "$depth") || return

    _jump_to "$dir"
}

# 6. _fuzzy_search_dir: Locates files containing text, and returns their parent directory.
_fuzzy_search_dir() {
    local base="$1"
    local query="$2"

    command -v rg >/dev/null && command -v fzf >/dev/null || return 1
    [[ -d "$base" ]] || return 1

    rg --files-with-matches --no-messages "$query" "$base" |
    xargs -I {} dirname {} |
    sort -u |
    fzf --header "Search: $query"
}

# 7. jump_search: Traverses to a directory containing a file matching a query.
jump_search() {
    local base="$1"
    local query="$2"

    local dir
    dir=$(_fuzzy_search_dir "$base" "$query") || return

    _jump_to "$dir"
}

# 8. edit_dir: Fuzzy selects a Projects folder and opens Neovim directly in it.
edit_dir() {
    local base="${1:-$HOME/Projects}"
    local dir
    dir=$(_fuzzy_select_dir "$base") || return
    nvim "$dir"
}

# 9. copy_dir: Fuzzy selects a directory and copies its absolute path to clipboard.
copy_dir() {
    local base="${1:-$HOME}"
    local dir
    dir=$(_fuzzy_select_dir "$base") || return
    printf "%s" "$dir" | wl-copy
}

# 10. Navigation Jumpers (Distro-Agnostic with updated naming conventions)
cfg() {
    if [[ -d "$HOME/Config" ]]; then
        jump "$HOME/Config" "$1" 2
    else
        jump "$HOME/.config" "$1" 2
    fi
}
prj() { jump "$HOME/Projects" "$1"; }
lrn() { jump "$HOME/Learn" "$1"; }
dep() { jump "$HOME/Deployments" "$1"; }
dl()  { jump "$HOME/Downloads" "$1"; }
med() { jump "/media" "$1"; }
rp()  { jump "$HOME/Repositories" "$1"; }
sc()  { jump "$HOME/Scripts" "$1"; }
vlt() { jump "$HOME/Vaults" "$1"; }

# Legacy aliases for backwards compatibility
cnf() { cfg "$@"; }
pj()  { prj "$@"; }