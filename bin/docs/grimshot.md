# Grimshot Refactoring Plan

## Objective
Reimplement and simplify the `grimshot` utility to use explicit selection intent detection via labeled monitor regions in `slurp`, ensuring robust single-click window capture and deterministic cancellation semantics while preserving custom rectangle dragging.

## Key Architectural Changes

1.  **Smart Selection Intent Resolution:**
    *   **Selection Mode:** Monitors are queried from the compositor and piped to `slurp` as labeled regions (e.g., `x,y wxh monitor`).
    *   **Intent Logic:** 
        *   If `slurp` fails with "selection cancelled" -> Escape (Exit 0).
        *   If `slurp` returns a geometry with the "monitor" label -> Single Click -> `TARGET` becomes `window`.
        *   If `slurp` returns a geometry without a label -> Custom Drag -> Use the geometry directly.
    *   **Benefit:** This avoids the limitation of `slurp -p` (which disables dragging) and ensures `slurp` succeeds on single-clicks (preventing ambiguity).

2.  **Pure Geometry Fetching:**
    *   `get_geometry()` remains a pure function that takes a target and returns geometry.
    *   Compositor-specific logic is isolated here.

3.  **Polling/Retry Logic:**
    *   `get_window_geometry_with_retry()` handles focus restoration after `slurp` closes (critical for Hyprland).
    *   Configured for 15 attempts with a 20ms delay.

4.  **Simplified Orchestration in `main()`:**
    ```bash
    main() {
        parse_args "$@"
        local geom=""

        # Phase 1: Target Resolution (Selection Intent)
        if [[ "$TARGET" == "selection" ]]; then
            geom=$(slurp -p) || handle_cancel_or_die
            if [[ "$geom" is_point ]]; then
                TARGET="window"
                geom=""
            fi
        fi

        # Phase 2: Geometry Resolution
        if [[ -z "$geom" ]]; then
            if [[ "$TARGET" == "window" ]]; then
                geom=$(get_window_geometry_with_retry)
            else
                geom=$(get_geometry "$TARGET")
            fi
        fi
        ...
    }
    ```

## Testing Strategy
*   `bin/tests/bats/grimshot.bats`: Standard functional tests.
*   `bin/tests/bats/grimshot_semantics.bats`: Deep dives into cancellation and point-click fallback.
*   `bin/tests/bats/grimshot-regression.bats`: Validates robustness against malformed/whitespace geometry.

## Implementation Guidelines
*   Terminology changed from `area` to `selection` to reflect hybrid behavior.
*   Use `slurp -p` for explicit point detection.
*   Avoid hidden state or fallback recursion.
