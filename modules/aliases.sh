# Common wrappers
alias src="source ~/.bashrc" # quick source 
alias ls='eza --icons --group-directories-first' # ls wrapper
alias ll='eza -la --icons --octal-permissions --git' # ll wrapper

# Shortcuts


# Jumpers
cnf() { _fuzzy_jump "$HOME/.config" "Config" "$1" 3; }
pj()  { _fuzzy_jump "$HOME/Projects" "Project" "$1"; }
vlt() { _fuzzy_jump "$HOME/Vaults" "Vaults" "$1"; }
dl()  { _fuzzy_jump "$HOME/Downloads" "Downloads" "$1"; }
rp()  { _fuzzy_jump "$HOME/Repositories" "Repositories" "$1"; }
sc()  { _fuzzy_jump "$HOME/Scripts" "Scripts" "$1"; }