# --- Interactive Session Hooks ---
# Navigation jumpers (cfg, prj, lrn, dep, dl, med, rp, sc, vlt) are sourced via lib/jump.sh

# --- Word Deletion & Readline Keybindings ---
if [[ -n "$BASH_VERSION" ]] && [[ "$-" == *i* ]]; then
    # Ctrl+W: Delete entire word under cursor (backward-word + kill-word)
    bind '"\C-w": "\eb\ed"' 2>/dev/null

    # Ctrl+Delete: Forward word delete (matches Alacritty \e[3;5~)
    bind '"\e[3;5~": kill-word' 2>/dev/null
fi

if [[ -n "$ZSH_VERSION" ]] && [[ -o interactive ]]; then
    bindkey '^W' backward-kill-word
    bindkey '^[[3;5~' kill-word
fi