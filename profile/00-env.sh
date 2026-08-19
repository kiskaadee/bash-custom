export NIXIP="${NIXIP:-192.168.1.36}"
export NIXURI="${NIXURI:-arch-services.mywire.org}"
export EDITOR="nvim"
export VISUAL="nvim"

# ccache paths (Fedora uses /usr/lib64/ccache, Arch uses /usr/lib/ccache/bin)
[[ -d "/usr/lib64/ccache" ]] && export PATH="/usr/lib64/ccache:$PATH"
[[ -d "/usr/lib/ccache/bin" ]] && export PATH="/usr/lib/ccache/bin:$PATH"

[[ -d "$HOME/.cargo/bin" ]] && export PATH="$PATH:$HOME/.cargo/bin"
[[ -d "$HOME/.local/bin" ]] && export PATH="$PATH:$HOME/.local/bin"
[[ -d "$HOME/.npm-global/bin" ]] && export PATH="$PATH:$HOME/.npm-global/bin"

# Java Home (Fedora / Arch fallback resolution)
for jvm in /usr/lib/jvm/java /usr/lib/jvm/java-openjdk /etc/alternatives/java_sdk /usr/lib/jvm/default; do
    if [[ -d "$jvm" ]]; then
        export JAVA_HOME="$jvm"
        break
    fi
done


