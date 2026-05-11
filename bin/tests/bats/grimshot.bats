#!/usr/bin/env bats

setup() {
    TEST_ROOT="$(mktemp -d)"

    export HOME="$TEST_ROOT/home"
    export MOCK_BIN="$TEST_ROOT/bin"

    mkdir -p "$HOME"
    mkdir -p "$MOCK_BIN"

    export OLD_PATH="$PATH"
    export PATH="$MOCK_BIN:$PATH"
    hash -r

    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    GRIMSHOT="$REPO_ROOT/grimshot"

    export XDG_CURRENT_DESKTOP="Hyprland"

    create_base_mocks
}

teardown() {
    export PATH="$OLD_PATH"
    rm -rf "$TEST_ROOT"
}

# --------------------------------------------------
# Helpers
# --------------------------------------------------

mock_cmd() {
    local name="$1"
    local body="$2"

    printf "#!/usr/bin/env bash\nexport TEST_ROOT=\"%s\"\nset -euo pipefail\n%s\n" "$TEST_ROOT" "$body" > "$MOCK_BIN/$name"

    chmod +x "$MOCK_BIN/$name"
}

create_base_mocks() {
    mock_cmd "grim" '
printf "fakepng" > "${@: -1}"
'

    mock_cmd "slurp" '
echo "10,10 300x200"
'

    mock_cmd "wl-copy" '
cat >/dev/null
'

    mock_cmd "jq" '
cat >/dev/null
echo "mock"
'

    mock_cmd "swappy" '
if [[ "$2" != "$4" ]]; then
    cp "$2" "$4"
fi
'

    mock_cmd "notify-send" '
exit 0
'

    mock_cmd "hyprctl" '
echo "{}"
'

    mock_cmd "swaymsg" '
echo "{}"
'

    mock_cmd "niri" '
echo "{}"
'

    mock_cmd "pacman" '
exit 0
'

    mock_cmd "paru" '
exit 0
'
}

assert_success() {
    [ "$status" -eq 0 ]
}

assert_failure() {
    [ "$status" -ne 0 ]
}

# --------------------------------------------------
# Tests
# --------------------------------------------------

@test "1. Selection capture uses slurp geometry" {
    mock_cmd "slurp" '
# slurp now receives monitors on stdin and uses -f
if [[ "$1" == "-f" ]]; then
    # Return a geometry without the "monitor" label to simulate a drag
    echo "25,30 500x400 "
    exit 0
fi
exit 1
'

    mock_cmd "grim" '
if [[ "$1" == "-g" && "$2" == "25,30 500x400" ]]; then
    printf "fakepng" > "$3"
    exit 0
fi

exit 1
'

    run bash "$GRIMSHOT" selection

    assert_success
}

@test "2. Single click selection falls back to window capture" {
    mock_cmd "slurp" '
if [[ "$1" == "-f" ]]; then
    echo "0,0 1920x1080 monitor"
    exit 0
fi
exit 1
'

    mock_cmd "hyprctl" '
if [[ "$1" == "activewindow" ]]; then
    echo "{\"at\":[10,20],\"size\":[800,600]}"
elif [[ "$1" == "monitors" ]]; then
    echo "[{\"x\":0,\"y\":0,\"width\":1920,\"height\":1080}]"
fi
'

    mock_cmd "jq" '
# Capture input to see what it is
IN=$(cat)
if [[ "$*" == *".at"* ]]; then
    echo "10,20 800x600"
elif [[ "$*" == *".x"* ]]; then
    echo "0,0 1920x1080"
fi
'

    mock_cmd "grim" '
if [[ "$1" == "-g" && "$2" == "10,20 800x600" ]]; then
    printf "fakepng" > "$3"
    exit 0
fi

exit 1
'

    run bash "$GRIMSHOT" selection
    assert_success
}

@test "3. Screen capture uses active monitor" {
    mock_cmd "hyprctl" '
echo "[{\"name\":\"eDP-1\",\"focused\":true}]"
'

    mock_cmd "jq" '
cat >/dev/null
echo "eDP-1"
'

    mock_cmd "grim" '
if [[ "$1" == "-o" && "$2" == "eDP-1" ]]; then
    printf "fakepng" > "$3"
    exit 0
fi

exit 1
'

    run bash "$GRIMSHOT" screen

    assert_success
}

@test "4. Screen --all captures all outputs" {
    mock_cmd "grim" '
# In Screen --all, geom is empty, so grim is called with one arg: the tmp file
if [[ $# -eq 1 ]]; then
    printf "fakepng" > "$1"
    exit 0
fi

exit 1
'

    run bash "$GRIMSHOT" screen --all

    assert_success
}

@test "5. Window capture uses active geometry" {
    mock_cmd "hyprctl" '
echo "{\"at\":[50,60],\"size\":[1024,768]}"
'

    mock_cmd "jq" '
cat >/dev/null
echo "50,60 1024x768"
'

    mock_cmd "grim" '
if [[ "$1" == "-g" && "$2" == "50,60 1024x768" ]]; then
    printf "fakepng" > "$3"
    exit 0
fi

exit 1
'

    run bash "$GRIMSHOT" window

    assert_success
}

@test "6. --edit invokes swappy" {
    mock_cmd "swappy" '
touch "$TEST_ROOT/swappy_called"
if [[ "$2" != "$4" ]]; then
    cp "$2" "$4"
fi
'

    run bash "$GRIMSHOT" selection --edit

    assert_success

    [ -f "$TEST_ROOT/swappy_called" ]
}

@test "7. --save persists screenshot to disk" {
    SAVE_DIR="$TEST_ROOT/output"
    mkdir -p "$SAVE_DIR"

    run bash "$GRIMSHOT" selection --save "$SAVE_DIR/"

    assert_success

    compgen -G "$SAVE_DIR/*.png" > /dev/null
}

@test "8. Clipboard persistence always occurs" {
    mock_cmd "wl-copy" "
touch \"$TEST_ROOT/wlcopy_called\"
cat >/dev/null
"

    run bash "$GRIMSHOT" selection

    assert_success

    [ -f "$TEST_ROOT/wlcopy_called" ]
}

@test "9. Invalid action exits with usage" {
    run bash "$GRIMSHOT" invalid

    assert_failure

    [[ "$output" =~ "Usage:" ]]
}

@test "10. Unknown option exits with error" {
    run bash "$GRIMSHOT" selection --wat

    assert_failure

    [[ "$output" =~ "Unknown option" ]]
}
