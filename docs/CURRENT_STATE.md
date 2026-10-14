# Current state

GitHub **`main`** launches the main menu. **Play** loads The Cardboard Compound (Milestone 3.5 layout). **Firing Range** remains available.

Player scale: capsule radius 0.35 m, stand 1.7 m, jump ~1.03 m. Level doors ≥1.4 m, corridors ≥2.5 m, elevations use ramps.

## Validate

```
godot --headless --path . -s res://scripts/tools/level_validator.gd
godot --headless --path . -s res://scripts/tools/milestone3_check.gd
```

## Key paths

| Piece | Path |
| --- | --- |
| Main scene | `scenes/ui/main_menu.tscn` |
| Compound | `scenes/levels/cardboard_compound.tscn` |
| Level kit | `scripts/levels/level_kit.gd` |
| Validator | `scripts/tools/level_validator.gd` |

See `docs/MILESTONE_3_5_PROGRESS.md`.
