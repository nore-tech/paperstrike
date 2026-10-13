# Paperstrike

A single-player first-person shooter with a handcrafted cardboard / papercraft look. Combat, movement, AI, and levels are fully 3D.

## Play

1. Install [Godot 4.4](https://godotengine.org/download).
2. Open this folder (`project.godot`).
3. Press Play. You start at the main menu.

**PLAY** launches **The Cardboard Compound**.  
**FIRING RANGE** opens the training room.  
**Esc** pauses in-game.

### Controls

| Input | Action |
| --- | --- |
| WASD | Move |
| Shift | Sprint |
| Ctrl | Crouch / slide (from sprint) |
| Space | Jump (cancels slide) |
| Z | Prone |
| Mouse | Look |
| LMB / RMB | Fire / ADS |
| R | Reload |
| E | Interact |
| 1–4 | Pistol / Rifle / Shotgun / SMG |
| Esc | Pause |

## Docs

- [Project context](docs/PROJECT_CONTEXT.md)
- [Current state](docs/CURRENT_STATE.md)
- [Milestone 3 plan](docs/MILESTONE_3_PLAN.md)
- [Milestone 3 progress](docs/MILESTONE_3_PROGRESS.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Game design](docs/GAME_DESIGN.md)

## Headless check

```bash
godot --headless --path . -s res://scripts/tools/milestone3_check.gd
```
