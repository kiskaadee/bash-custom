#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    export ORIGINAL_PATH="$PATH"

    MOCK_DIR="$(mktemp -d)"

    export PATH="$MOCK_DIR:$REPO_ROOT/bin:$PATH"

    create_mock_pacman
    create_mock_paru
    create_mock_yay
}

teardown() {
    PATH="$ORIGINAL_PATH"
    rm -rf "$MOCK_DIR"
}

create_mock() {
    local name="$1"
    local body="$2"

    cat > "$MOCK_DIR/$name" <<EOF
#!/usr/bin/env bash
$body
EOF

    chmod +x "$MOCK_DIR/$name"
}

create_mock_pacman() {
    create_mock "pacman" '
if [[ "$1" == "-Si" ]]; then
    case "$2" in
        official-suite)
            exit 0
            ;;
        *)
            exit 1
            ;;
    esac
fi

exit 1
'
}

create_mock_paru() {
    create_mock "paru" '
if [[ "$1" == "-Si" ]]; then
    case "$2" in
        aur-suite-bin)
            exit 0
            ;;
        *)
            exit 1
            ;;
    esac
fi

exit 1
'
}

create_mock_yay() {
    create_mock "yay" '
exit 0
'
}

# --- Tests ---

@test "1. Succeeds when all commands exist" {
    run dep_check "test-suite" "bash" "grep"

    [ "$status" -eq 0 ]
}

@test "2. Prints standalone success message" {
    run bash "$REPO_ROOT/dep_check" "test-suite" "bash"

    [ "$status" -eq 0 ]

    [[ "$output" =~ "All dependencies satisfied" ]]
}

@test "3. Fails and reports missing tools" {
    run dep_check "test-suite" \
        "missing-cmd-123"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "Missing tools:" ]]
    [[ "$output" =~ "missing-cmd-123" ]]
}

@test "4. Identifies official repository packages" {
    run dep_check "test-suite" \
        "official-tool:official-suite"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "Found in official repositories" ]]
    [[ "$output" =~ "official-suite" ]]
}

@test "5. Identifies AUR packages" {
    run dep_check "test-suite" \
        "aur-tool:aur-suite-bin"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "Found in AUR" ]]
    [[ "$output" =~ "aur-suite-bin" ]]
}

@test "6. Reports packages not found anywhere" {
    run dep_check "test-suite" \
        "fake-tool:nonexistent-package"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "Not found in repositories" ]]
}

@test "7. Uses SC_PKG_MGR when suggesting fixes" {
    export SC_PKG_MGR="yay -S"

    run dep_check "test-suite" \
        "official-tool:official-suite"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "yay -S official-suite" ]]
}

@test "8. Handles mixed dependency states" {
    run dep_check "test-suite" \
        "bash" \
        "official-tool:official-suite" \
        "aur-tool:aur-suite-bin"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "official-tool" ]]
    [[ "$output" =~ "aur-tool" ]]

    [[ "$output" =~ "Found in official repositories" ]]
    [[ "$output" =~ "Found in AUR" ]]
}

@test "9. Deduplicates package suggestions" {
    run dep_check "test-suite" \
        "official-tool-1:official-suite" \
        "official-tool-2:official-suite"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "Fix:" ]]

    fix_line="$(grep "Fix:" <<< "$output")"

    count="$(grep -o "official-suite" <<< "$fix_line" | wc -l)"

    [ "$count" -eq 1 ]
}

@test "10. Shows manual installation warning if at least one package is unresolved" {
    run dep_check "test-suite" \
        "official-tool:official-suite" \
        "bad-tool:nonexistent-package"

    [ "$status" -eq 1 ]

    [[ "$output" =~ "Manual installation required" ]]
}
