#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" # path to repo root
    GIT_READY="$REPO_ROOT/git-ready"

    # Sandboxing $HOME
    # Running this test will not affect the local git configuration
    TEST_TEMP_DIR="$(mktemp -d)"
    export HOME="$TEST_TEMP_DIR"

    # Tests failing due to inaccessible util dep_check;
    # this creates a "Bridge" script that mocks dep_check and executes the script
    cat <<EOF > "$TEST_TEMP_DIR/runner.sh"
#!/usr/bin/env bash
dep_check() { return 0; } # Mock success
export -f dep_check
source "$GIT_READY" "\$@"
EOF
    chmod +x "$TEST_TEMP_DIR/runner.sh"

    MOCK_YML="$TEST_TEMP_DIR/test-git.yml"
    echo "user.name: Test User" > "$MOCK_YML"
    echo "user.email: test@example.com" >> "$MOCK_YML"
}

teardown() {
    # Clean up the temp directory after each test
    rm -rf "$TEST_TEMP_DIR"
}

# --- Tests ---
@test "git-ready fails if no argument provided" {
    # Use runner to ensure dep_check doesn't crash the script
    run bash "$TEST_TEMP_DIR/runner.sh"
    [ "$status" -eq 1 ]
    [[ "$output" == *"Usage"* ]]
}

@test "git-ready fails if config file does not exist" {
    run bash "$TEST_TEMP_DIR/runner.sh" "/non/sense/path.yml"
    [ "$status" -eq 1 ]
    [[ "$output" == *"not found"* ]]
}

@test "git-ready correctly parses identity from YAML" {
    run bash "$TEST_TEMP_DIR/runner.sh" "$MOCK_YML"
    [ "$status" -eq 0 ]
    [ "$(git config --global user.name)" = "Test User" ]
    [ "$(git config --global user.email)" = "test@example.com" ]
}

@test "git-ready configures delta as default pager" {
    run bash "$TEST_TEMP_DIR/runner.sh" "$MOCK_YML"
    [ "$status" -eq 0 ]
    [ "$(git config --global core.pager)" == "delta" ]
}

@test "git-ready installs complex function aliases" {
    run bash "$TEST_TEMP_DIR/runner.sh" "$MOCK_YML"
    run git config --global alias.nuke
    [[ "$output" == *"reset --hard"* ]]
    [[ "$output" == *"clean -fd"* ]]
}
