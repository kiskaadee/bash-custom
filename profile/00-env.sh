export NIXIP="${NIXIP:-192.168.1.36}"
export NIXURI="${NIXURI:-arch-services.mywire.org}"
export EDITOR="${EDITOR:-nvim}"

[[ -d "/usr/lib/ccache/bin" ]] && export PATH="/usr/lib/ccache/bin:$PATH"
[[ -d "$HOME/.cargo/bin" ]] && export PATH="$PATH:$HOME/.cargo/bin"
[[ -d "$HOME/.local/bin" ]] && export PATH="$PATH:$HOME/.local/bin"
[[ -d "$HOME/.npm-global/bin" ]] && export PATH="$PATH:$HOME/.npm-global/bin"
[[ -d "/usr/lib/jvm/default" ]] && export JAVA_HOME="/usr/lib/jvm/default"


