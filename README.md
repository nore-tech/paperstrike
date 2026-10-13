# Paperstrike

A small single-player 2.5D first-person shooter. Gameplay, collision, movement, AI, and levels are 3D. Characters and props use 2D sprites and billboards, and the world is simple geometry, so it looks like paper and cardboard.

Gameplay is not implemented yet. This repository is the Godot 4 project and the design docs.

## Open it

1. Install [Godot 4.4](https://godotengine.org/download) or another Godot 4.x editor.
2. Open this folder as a project (`project.godot`).
3. There is no main scene yet. The editor should open on an empty project.

## Docs

- [Game design](docs/GAME_DESIGN.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Current state](docs/CURRENT_STATE.md)
- [Todo](docs/TODO.md)
- [Agent rules](AGENTS.md)

## Layout

| Path | Purpose |
| --- | --- |
| `scenes/` | Godot scenes |
| `scripts/` | GDScript |
| `resources/` | Data resources (weapons, enemies, objectives) |
| `assets/` | Sprites, meshes, materials |
| `audio/` | Sound and music |
| `ui/` | HUD theme and controls |
