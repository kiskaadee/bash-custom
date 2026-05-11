#!/usr/bin/env bats

setup() {
    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export PATH="$REPO_ROOT:$PATH"
}

@test "Succeeds if dependency exists even if package manager is missing" {
    export SC_PKG_MGR="nonexistent-mgr -S"
    
    # bash exists, so dep_check should succeed now because it shouldn't check SC_PKG_MGR
    run dep_check "repro" "bash"
    
    [ "$status" -eq 0 ]
}

@test "Fails and reports missing tools if dependency is missing, even if package manager is also missing" {
    export SC_PKG_MGR="nonexistent-mgr -S"
    
    run dep_check "repro" "nonexistent-command-123"
    
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Missing tools: nonexistent-command-123" ]]
    [[ "$output" =~ "Configured package manager not found" ]]
}
