#!/usr/bin/env bats

setup() {
    MOCK_DIR="$(mktemp -d)"
    export PATH="$MOCK_DIR:$PATH"
    
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    GRIMSHOT="$REPO_ROOT/grimshot"
    
    # Mock dep_check
    cat <<EOM > "$MOCK_DIR/dep_check"
#!/bin/sh
exit 0
EOM
    chmod +x "$MOCK_DIR/dep_check"

    # Mock notify-send
    cat <<EOM > "$MOCK_DIR/notify-send"
#!/bin/sh
exit 0
EOM
    chmod +x "$MOCK_DIR/notify-send"

    # Mock wl-copy
    cat <<EOM > "$MOCK_DIR/wl-copy"
#!/bin/sh
exit 0
EOM
    chmod +x "$MOCK_DIR/wl-copy"
    
    export XDG_CURRENT_DESKTOP="Hyprland"
}

teardown() {
    rm -rf "$MOCK_DIR"
}

@test "explicit cancellation (Escape) exits status 0" {
    cat <<'EOM' > "$MOCK_DIR/slurp"
#!/bin/sh
if [ "$1" != "-f" ]; then
    echo "Missing -f: $1" >&2
    exit 1
fi
echo "selection cancelled" >&2
exit 1
EOM
    chmod +x "$MOCK_DIR/slurp"

    run "$GRIMSHOT" selection
    [ "$status" -eq 0 ]
}

@test "labeled monitor-click success resolves window" {
    cat <<'EOM' > "$MOCK_DIR/slurp"
#!/bin/sh
echo "0,0 1920x1080 monitor"
EOM
    chmod +x "$MOCK_DIR/slurp"

    cat <<'EOM' > "$MOCK_DIR/hyprctl"
#!/bin/sh
if [ "$1" = "monitors" ]; then
    echo '[{"x":0,"y":0,"width":1920,"height":1080}]'
elif [ "$1" = "activewindow" ]; then
    echo '{"at": [10,20], "size": [100,200]}'
fi
EOM
    chmod +x "$MOCK_DIR/hyprctl"

    cat <<'EOM' > "$MOCK_DIR/grim"
#!/bin/sh
for last; do :; done
for arg in "$@"; do
    if [ "$arg" = "10,20 100x200" ]; then
        echo "fake data" > "$last"
        exit 0
    fi
done
exit 1
EOM
    chmod +x "$MOCK_DIR/grim"

    run "$GRIMSHOT" selection
    [ "$status" -eq 0 ]
}

@test "unlabeled drag-selection success uses geometry" {
    cat <<'EOM' > "$MOCK_DIR/slurp"
#!/bin/sh
echo "100,100 300x400 "
EOM
    chmod +x "$MOCK_DIR/slurp"

    cat <<'EOM' > "$MOCK_DIR/grim"
#!/bin/sh
for last; do :; done
for arg in "$@"; do
    if [ "$arg" = "100,100 300x400" ]; then
        echo "fake data" > "$last"
        exit 0
    fi
done
exit 1
EOM
    chmod +x "$MOCK_DIR/grim"

    run "$GRIMSHOT" selection
    [ "$status" -eq 0 ]
}
