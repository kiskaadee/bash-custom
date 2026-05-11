#!/usr/bin/env bats

# grimshot.bats
#
# BATS regression tests for grimshot.

setup() {
    # Create a temporary directory for mocks
    MOCK_DIR="$(mktemp -d)"
    export PATH="$MOCK_DIR:$PATH"
    
    # Path to the real grimshot script
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    GRIMSHOT="$REPO_ROOT/grimshot"
    
    # Mock dep_check
    cat <<EOF > "$MOCK_DIR/dep_check"
#!/bin/sh
exit 0
EOF
    chmod +x "$MOCK_DIR/dep_check"

    # Mock notify-send
    cat <<EOF > "$MOCK_DIR/notify-send"
#!/bin/sh
echo "NOTIFY: \$*" >> "$MOCK_DIR/notify.log"
EOF
    chmod +x "$MOCK_DIR/notify-send"

    # Mock wl-copy
    cat <<EOF > "$MOCK_DIR/wl-copy"
#!/bin/sh
cat > "$MOCK_DIR/clipboard.png"
EOF
    chmod +x "$MOCK_DIR/wl-copy"
    
    # Mock current_desktop to return hyprland by default
    export XDG_CURRENT_DESKTOP="Hyprland"
}

teardown() {
    rm -rf "$MOCK_DIR"
}

@test "selection capture with valid geometry" {
    cat <<EOF > "$MOCK_DIR/slurp"
#!/bin/sh
# Return without label to simulate drag
echo "100,200 300x400 "
EOF
    chmod +x "$MOCK_DIR/slurp"

    cat <<EOF > "$MOCK_DIR/grim"
#!/bin/sh
# Validate geometry format: X,Y WxH
for last; do :; done
geom_arg=""
while [ \$# -gt 1 ]; do
    if [ "\$1" = "-g" ]; then
        geom_arg="\$2"
        shift
    fi
    shift
done

if ! echo "\$geom_arg" | grep -qE "^[0-9]+,[0-9]+ [0-9]+x[0-9]+$"; then
    echo "ERROR: Invalid geometry format: [\$geom_arg]" >&2
    exit 1
fi
echo "fake image data" > "\$last"
EOF
    chmod +x "$MOCK_DIR/grim"

    run "$GRIMSHOT" selection
    [ "$status" -eq 0 ]
    [ -f "$MOCK_DIR/clipboard.png" ]
}

@test "single-click selection fallback to window" {
    cat <<EOF > "$MOCK_DIR/slurp"
#!/bin/sh
# Return with "monitor" label to simulate click
echo "0,0 1920x1080 monitor"
EOF
    chmod +x "$MOCK_DIR/slurp"

    cat <<EOF > "$MOCK_DIR/hyprctl"
#!/bin/sh
if [ "\$1" = "activewindow" ]; then
    echo '{"at": [10,20], "size": [100,200]}'
elif [ "\$1" = "monitors" ]; then
    echo '[{"x":0,"y":0,"width":1920,"height":1080}]'
fi
EOF
    chmod +x "$MOCK_DIR/hyprctl"

    cat <<EOF > "$MOCK_DIR/grim"
#!/bin/sh
# For fallback, it should be the window geometry
for last; do :; done
geom_arg=""
while [ \$# -gt 1 ]; do
    if [ "\$1" = "-g" ]; then
        geom_arg="\$2"
        shift
    fi
    shift
done

if [ "\$geom_arg" != "10,20 100x200" ]; then
    echo "ERROR: Expected window geometry 10,20 100x200, got [\$geom_arg]" >&2
    exit 1
fi
echo "fake image data" > "\$last"
EOF
    chmod +x "$MOCK_DIR/grim"

    run "$GRIMSHOT" selection
    [ "$status" -eq 0 ]
    [ -f "$MOCK_DIR/clipboard.png" ]
}

@test "fallback retry polling succeeds" {
    cat <<EOF > "$MOCK_DIR/slurp"
#!/bin/sh
echo "0,0 1920x1080 monitor"
EOF
    chmod +x "$MOCK_DIR/slurp"

    cat <<EOF > "$MOCK_DIR/hyprctl"
#!/bin/sh
COUNT_FILE="$MOCK_DIR/hypr_count"
[ ! -f "\$COUNT_FILE" ] && echo 0 > "\$COUNT_FILE"
COUNT=\$(cat "\$COUNT_FILE")
if [ "\$1" = "activewindow" ]; then
    if [ "\$COUNT" -lt 2 ]; then
        echo '{}'
        echo \$((COUNT + 1)) > "\$COUNT_FILE"
    else
        echo '{"at": [10,20], "size": [100,200]}'
    fi
elif [ "\$1" = "monitors" ]; then
    echo '[{"x":0,"y":0,"width":1920,"height":1080}]'
fi
EOF
    chmod +x "$MOCK_DIR/hyprctl"

    cat <<EOF > "$MOCK_DIR/grim"
#!/bin/sh
for last; do :; done
echo "fake image data" > "\$last"
EOF
    chmod +x "$MOCK_DIR/grim"

    run "$GRIMSHOT" selection
    [ "$status" -eq 0 ]
}

@test "exhausted retries returns non-zero" {
    cat <<EOF > "$MOCK_DIR/slurp"
#!/bin/sh
echo "0,0 1920x1080 monitor"
EOF
    chmod +x "$MOCK_DIR/slurp"

    cat <<EOF > "$MOCK_DIR/hyprctl"
#!/bin/sh
if [ "\$1" = "activewindow" ]; then
    echo '{}'
elif [ "\$1" = "monitors" ]; then
    echo '[{"x":0,"y":0,"width":1920,"height":1080}]'
fi
EOF
    chmod +x "$MOCK_DIR/hyprctl"

    run "$GRIMSHOT" selection
    [ "$status" -eq 1 ]
    [[ "$output" == *"No active window detected"* ]]
}

@test "whitespace-only geometry is rejected" {
    cat <<EOF > "$MOCK_DIR/slurp"
#!/bin/sh
echo "   "
EOF
    chmod +x "$MOCK_DIR/slurp"

    run "$GRIMSHOT" selection
    [ "$status" -eq 1 ]
    [[ "$output" == *"No active selection detected"* ]]
}
