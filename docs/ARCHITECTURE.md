# Architecture

This is the target shape for the game. None of these systems are implemented yet. Empty folders reserve the layout.

## Rules

- One system owns one job.
- Systems talk through signals and Godot Resources. No node that ticks weapons, AI, and objectives together.
- Tunable data (weapon stats, enemy stats, the level objective) lives in Resources.
- Presentation (sprites, meshes, audio players) stays separate from simulation (movement, hits, AI state).

## Modules

### Player

Owns first-person movement, mouse look, and the body collision shape. Exposes health. Does not store weapon stats.

### Weapons

Owns the equipped weapon, firing, reload, and ammo. Reads a `WeaponStats` resource. Gets the aim ray from the player. Emits fired, reloaded, and hit. A hit names the collider and the damage. The thing that was hit decides how it reacts.

### AI

Owns sensing, combat state, and 3D navigation. Reads an `EnemyStats` resource. States are patrol, alert, attack, and search. Applies incoming damage. Does not sit inside the weapon script.

### Levels

Owns the 3D layout, navigation region, insert spawn, objective, and extract point. A `LevelObjective` resource describes the goal. When the objective completes, extraction becomes available. The level does not implement shooting.

### Presentation

Billboard sprites, simple meshes, and paper materials. Character sprites follow AI or player state. Changing a sprite does not require an AI change.

### UI

HUD for health, ammo, the objective line, and the extract prompt. Listens to signals. Changes game state only for pause or restart.

### Audio

Plays weapon, footstep, and UI cues named by resources. Other systems request a cue. They do not spawn one-off audio players inside combat scripts once this exists.

## How they talk

- The player emits movement and damage taken.
- Weapons emit fired, reloaded, and hit.
- AI emits alerted and died.
- The level watches the objective and then enables the extract volume.
- Extract emits completed when the player leaves after the objective.
- An autoload, if one is added later, may route scenes. It does not contain weapon or AI logic.

## Layout

| Path | Holds |
| --- | --- |
| `scenes/player/` | Player body and camera |
| `scenes/weapons/` | Viewmodels |
| `scenes/characters/` | Billboard enemies |
| `scenes/levels/` | Level scenes |
| `scenes/ui/` | HUD scene |
| `scripts/` | Matching GDScript, one area per folder |
| `resources/weapons/` | `WeaponStats` |
| `resources/ai/` | `EnemyStats` |
| `resources/levels/` | `LevelObjective` |
| `assets/` | Sprites, meshes, materials |
| `audio/` | Sound and music |
| `ui/` | Theme and shared controls |

## What exists now

The firing range is the test level: weapon pickups, a shared interact key, and a target reset that does not reload the scene. See `docs/CURRENT_STATE.md`. AI, objectives, and extraction are not implemented.
