# Milestone 3.5 — problems found (pre-redesign)

Player collision (from `MovementProfile`): radius **0.35 m**, stand height **1.7 m**, jump height **~1.03 m**. Comfortable door ≥ **1.2 m**, corridor ≥ **2.4 m**.

## Critical / likely blockers

1. **Warehouse mezzanine unreachable** — platform at y≈1.45 with only two tall step blocks (0.7 m / 1.45 m). Player jump is ~1.0 m; cannot climb. Enemy spawn at `(-3, 1.6, -6)` sits on that platform.
2. **Side corridor disconnected** — floor strip at x=7.5 with fences at x=6 and x=9, but no doorway through the interior east wall into that alley.
3. **Floating / decorative doorways** — `_doorway()` places posts and a lintel in open space without matching wall openings; can create fake barriers or visual lies.
4. **Closed rooms without guaranteed through-paths** — `_room(..., open_front=false)` seals north and south; openings rely on those floating doorways and may not leave capsule-clear gaps.
5. **Navmesh vs geometry mismatch** — hand quads ignore crates, dividers, and the mezzanine height; agents path through solid cover or fail elevated routes.
6. **Crate clutter** — several 1.5–2.2 m crates pinch aisles below comfortable flank width.

## Design / feel issues

7. Linear tube of rooms with little landmarking or intentional arena shapes.
8. Cover often too tall / blocky; few low (peek) barriers.
9. Checkpoint markers exist but respawn uses whatever pose was stored at clear time, not the designed safe pads.
10. Objective zone triggers overlap confusingly (interior/warehouse both force objective index 3).

## Standards adopted for redesign

| Rule | Value |
| --- | --- |
| Min door clear width | 1.4 m |
| Min corridor clear width | 2.5 m |
| Ceiling clear | ≥ 2.6 m |
| Max step without ramp | 0.35 m |
| Elevation | ramps ≤ ~20° |
| Cover height (low) | 0.9–1.1 m |
| Cover height (full) | 1.6–1.8 m with gaps |
| Aisles between crates | ≥ 2.5 m |
