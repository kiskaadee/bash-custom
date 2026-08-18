if [ -n "${BASH_VERSION:-}" ]; then
    command -v starship >/dev/null && eval "$(starship init bash)"
    command -v zoxide >/dev/null && eval "$(zoxide init bash --cmd cd)"
    command -v direnv >/dev/null && eval "$(direnv hook bash)"
elif [ -n "${ZSH_VERSION:-}" ]; then
    command -v starship >/dev/null && eval "$(starship init zsh)"
    command -v zoxide >/dev/null && eval "$(zoxide init zsh --cmd cd)"
    command -v direnv >/dev/null && eval "$(direnv hook zsh)"
fi

if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
fi

# --- Visual Entry ---
# Only run fastfetch if the shell is interactive and fastfetch is installed
if [[ $- == *i* ]] && command -v fastfetch >/dev/null; then
    fastfetch --logo none
fi

