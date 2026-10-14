# Paperstrike

Single-player cardboard FPS with a roguelite run loop. Godot **4.4**.

## Run

Open the project in Godot 4.4+, or:

```bash
godot --path .
```

Main menu → **Enter Safehouse** for the roguelite loop, **Cardboard Compound** for the campaign setpiece, or **Firing Range** to test weapons.

## Roguelite loop

Safehouse → permanent upgrades → start run (pistol only) → branching act map → combat / elite / supply / shop / event → rewards → boss → next act or victory. Death awards permanent scrap and returns to the hub.

## Headless checks

```bash
godot --headless --path . -s res://scripts/tools/roguelite_check.gd
godot --headless --path . -s res://scripts/tools/milestone3_check.gd
```

## Docs

- `docs/PROJECT_CONTEXT.md` — current build overview
- `docs/ROGUELITE_IMPLEMENTATION.md` — Milestone 4 tracker
- `docs/GAME_DESIGN.md` — design notes
