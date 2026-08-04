# Legacy wrapper for backward compatibility - delegates to wayland.sh
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/wayland.sh" ]]; then
    source "$SCRIPT_DIR/wayland.sh"
fi
