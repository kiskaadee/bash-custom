# --- Shell Hooks ---
if [ -n "$BASH_VERSION" ]; then
    eval "$(starship init bash)"
    eval "$(zoxide init bash)"
    eval "$(direnv hook bash)"
elif [ -n "$ZSH_VERSION" ]; then
    eval "$(starship init zsh)"
    eval "$(zoxide init zsh)"
    eval "$(direnv hook zsh)"
fi

# --- Visual Entry ---
# Only run fastfetch if the shell is interactive
if [[ $- == *i* ]]; then
    fastfetch --logo none
fi
