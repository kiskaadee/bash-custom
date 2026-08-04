# In profile/10-aliases.sh
reload() {
    if [ -n "${ZSH_VERSION:-}" ]; then
        source ~/.zshrc
    else
        source ~/.bashrc
    fi
    echo "Shell configuration reloaded."
}
alias src="reload"

# General Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias .....="cd ../../../.."

alias p5='uv run py5-run-sketch'
alias p5w='uv run watchfiles "py5-run-sketch main.py"'
alias pgoog="ping google.com -c 3"
alias parch="ping archlinux.org -c 3"
alias ff="fastfetch --logo none"
# alias find="fd"

alias v="${EDITOR:-nvim}"
alias vi="${EDITOR:-nvim}"
alias v.="${EDITOR:-nvim} ."

alias wifi="nmtui"
alias lock="hyprlock"
alias clock="tty-clock"
alias sys="btop" 
alias ql="quicklinks"
alias cd="z"
alias zi="zoxide query -i --preview 'eza --tree --level 2 --color=always {}'"
alias zed="zeditor"

# EZA navigation
alias ls="eza --icons --group-directories-first"
alias ll="eza -la --icons --octal-permissions --git"
alias lt="eza -a --tree --level=2 --icons=always"
alias home="cd ~/"
alias root="home"
alias h="home"

# Volume Control
alias vol1="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.2"
alias vol2="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.4"
alias vol3="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.6"
alias vol4="wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.8"
alias vol5="wpctl set-volume @DEFAULT_AUDIO_SINK@ 1.0"
alias volM="wpctl set-mute @DEFAULT_AUDIO_SINK@ 1"
alias volU="wpctl set-mute @DEFAULT_AUDIO_SINK@ 0"

# System Management
alias shutdown="systemctl poweroff"
alias reboot="systemctl reboot"
alias suspend="systemctl suspend"
alias hibernate="systemctl hibernate"
if [[ -f /etc/NIXOS ]]; then
    alias nix-switch="sudo nixos-rebuild switch --flake ~/Config#$(hostname)"
fi

# Git Productivity
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash && git pull"
alias gfo="git fetch origin"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"
alias gadc="git add -A && git diff --staged | wl-copy"
 
