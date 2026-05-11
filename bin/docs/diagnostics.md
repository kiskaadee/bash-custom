# Grimshot Diagnostic Guide

This document describes how to debug `grimshot` and reproduce the issues identified during the refactor.

## Debugging Runtime Variables

To inspect the exact values passed to `grim` during execution, add the following lines immediately before `run_capture "$geom"` in `main()`:

```bash
printf "DEBUG target=[%s]\n" "$TARGET" >&2
printf "DEBUG geom=[%q]\n" "$geom" >&2
```

When running from a terminal, these will appear in stderr. When running from Hyprland keybindings, you may need to redirect to a file:

```bash
printf "DEBUG target=[%s]\n" "$TARGET" >> /tmp/grimshot_trace.log
printf "DEBUG geom=[%q]\n" "$geom" >> /tmp/grimshot_trace.log
```

## Common Issues Identified

1.  **Subshell State Loss:**
    *   *Symptom:* `TARGET` remains "selection" even after a 1x1 click.
    *   *Cause:* Variable assignment inside command substitution does not propagate to the parent.
    *   *Fix:* Separate target resolution from geometry acquisition in the main flow.

2.  **Focus Race Condition:**
    *   *Symptom:* `hyprctl activewindow` returns empty JSON immediately after `slurp` closes.
    *   *Fix:* Implement a retry loop with 10ms polling.

3.  **Malformed Geometry:**
    *   *Symptom:* `grim -g` fails due to trailing newlines or whitespace.
    *   *Fix:* Use `printf` instead of `echo` and normalize whitespace during validation.

## Running Tests

Automated regression tests use BATS.

```bash
bats bin/tests/bats/grimshot.bats
```

The tests use a mock-based approach by manipulating `$PATH` to substitute actual system tools with controlled scripts that validate arguments (e.g., ensuring `grim -g` receives correctly formatted geometry).
