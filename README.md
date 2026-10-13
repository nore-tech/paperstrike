# Paperstrike

A small single-player 2.5D first-person shooter. Gameplay, collision, movement, AI, and levels are 3D. Characters and props use 2D sprites and billboards, and the world is simple geometry, so it looks like paper and cardboard.

The current slice is a firing range: walk, look, jump, sprint, pick up guns, and shoot stationary target dummies. There is no enemy AI.

## Play

1. Install [Godot 4.4](https://godotengine.org/download) or another Godot 4.x editor.
2. Open this folder as a project (`project.godot`).
3. Press Play. The main scene is `scenes/levels/test_room.tscn`.

WASD moves, Shift sprints, Space jumps, and the mouse looks. Hold Left Ctrl to crouch. Press Left Ctrl while sprinting to slide. Z toggles prone. Left click fires. Right click aims down the iron sights. R reloads. E uses whatever you are looking at. Esc releases the mouse. Aiming, crouching, or going prone stops a sprint.

You start with the pistol. The assault rifle and shotgun are on the table to the left. Look at one until it says `[E] Pick up Assault Rifle` (or Pistol, or Shotgun) and press E. Keys 1, 2, and 3 switch among guns you already have. The crate on the right refills the gun you are holding.

Dummies down the lanes are paper cards with 3D hit volumes. They flash, shed a paper scrap, and disappear at zero health. The red `RESPAWN TARGETS` button puts them back. It does not take your guns.

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
