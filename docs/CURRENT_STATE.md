# Current state

The game launches to a main menu. **Play** loads The Cardboard Compound. **Firing Range** loads the original training room. Enemy AI, player health, checkpoints, objectives, extraction, pause, and completion screens are in place.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Engine: Godot 4.4, Forward Plus
- Main scene: `scenes/ui/main_menu.tscn`
- Autoload: `GameSession`

## Systems

| System | Location |
| --- | --- |
| Movement | `scripts/player/player.gd`, `resources/player/movement_profile.tres` |
| Weapons | `scripts/weapons/*`, `resources/weapons/*` |
| Enemies | `scripts/characters/cardboard_enemy.gd`, `resources/ai/*` |
| Compound | `scripts/levels/compound_level.gd` |
| Range | `scripts/levels/test_room.gd` |
| Menus / HUD | `scripts/ui/*`, `scenes/ui/*` |
| Session | `scripts/autoload/game_session.gd` |

## Weapons

| Weapon | Key | Notes |
| --- | --- | --- |
| Pistol | 1 | Spawn default |
| Assault Rifle | 2 | Cardboard viewmodel |
| Shotgun | 3 | Pellet spread |
| Paper SMG | 4 | Fast auto, reuses rifle form mesh |

## Compound flow

1. Insertion bay (spawn, rifle on table, medkit/ammo)
2. Outer compound — Light/Standard enemies, cover crates
3. Interior facility — rooms + side corridor
4. Warehouse — Heavy + elevated platform
5. Final arena — mixed squad → extract pad

Objectives advance on zone entry and encounter clears. Checkpoints store pose, health, loadout, objective index, and cleared encounter ids.

## Validation

```
godot --headless --path . -s res://scripts/tools/milestone3_check.gd
```

Prints `CHECK_OK milestone3`.

## Known limitations

- Navmesh is hand-authored quads (not full bake from meshes).
- Cover is move-to-point only.
- Pistol/shotgun meshes still simpler than the rifle.
- No dedicated footstep loops yet.
- Interactive window playtest not run in the headless environment.
