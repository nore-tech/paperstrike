# Paperstrike

A small single-player 2.5D first-person shooter. Gameplay, collision, movement, AI, and levels are 3D. Characters and props use 2D sprites and billboards, and the world is simple geometry, so it looks like paper and cardboard.

The current slice is a test room: walk, look, jump, sprint, and shoot a target dummy. There is no enemy AI.

## Play

1. Install [Godot 4.4](https://godotengine.org/download) or another Godot 4.x editor.
2. Open this folder as a project (`project.godot`).
3. Press Play. The main scene is `scenes/levels/test_room.tscn`.

WASD moves, Shift sprints, Space jumps, and the mouse looks. Left click fires. Esc releases the mouse. The dummy ahead of the spawn point is a flat paper card with a 3D hit volume. It flashes, sheds a paper scrap, and disappears at zero health.

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
