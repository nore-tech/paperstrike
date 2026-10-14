# Milestone 3.5 progress — level playability overhaul

## Problems discovered

See `docs/MILESTONE_3_5_PROBLEMS.md` (unreachable mezzanine, disconnected side corridor, floating doorways, spawn/cover overlaps, nav mismatch).

## Changes made

- Merged Milestone 3 into GitHub **`main`** (`0d68d7d`) so Godot on `main` opens the menu.
- Redesigned compound geometry via `scripts/levels/level_kit.gd` (doors ≥1.4 m, corridors ≥2.5 m, ramps, low/full cover).
- Five connected areas with explicit wall openings (no floating fake doorways).
- East flank corridor joined through real doors in the interior east wall.
- Warehouse mezzanine reachable by a shallow ramp (~14°).
- Enemy/cover positions separated; checkpoints respawn on designed pads.
- Added `scripts/tools/level_validator.gd` (VALID / INVALID / MANUAL).

## Accessibility validation

```
godot --headless --path . -s res://scripts/tools/level_validator.gd
→ VALID=55 INVALID=0 MANUAL=2
→ CHECK_OK level_validator
```

MANUAL remaining: extract-after-final combat, full doorway walkthrough feel.

Also: `milestone3_check.gd` → `CHECK_OK milestone3`.

## Tests actually performed

- Headless import
- Level validator (capsule route, spawns, checkpoints, objectives)
- Milestone 3 smoke (menu/range/compound systems)

Not performed: full manual window playthrough of all five arenas end-to-end.

## Remaining limitations

- Navmesh is still assembled from floor/ramp rects (not a full geometry bake).
- Ramp collision is a rotated box — feel should be judged in-editor.
- Visual polish is modular cardboard, not unique art-directed set pieces per room.
