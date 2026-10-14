# Roguelite implementation tracker

Goal: end-to-end Paperstrike run loop (hub → tree → encounters → rewards → boss → death/meta).

## Reuse

| Existing | Role |
| --- | --- |
| `Player` + `MovementProfile` | FPS body |
| `HitscanWeapon` + `WeaponStats` | Guns |
| `CardboardEnemy` + `EnemyStats` | AI |
| `LevelKit` / `PaperBlock` | Arenas |
| `GameSession` | Pause, scene routing, settings |
| Firing range `test_room` | Sandbox (no meta progress) |

## Checklist

- [x] `PlayerProfile` save (`user://paperstrike_profile.json`, versioned)
- [x] Permanent upgrades + hub station
- [x] `RunManager` (seed, tree, loadout, temp mods, currency)
- [x] Always start with pistol only
- [x] Marksman rifle (5th weapon) + rarity wrappers
- [x] Floating damage numbers
- [x] ≥15 temporary run upgrades
- [x] Branching level tree UI (seeded)
- [x] Encounter runner (combat/elite/supply/shop/event/boss)
- [x] Modular arenas
- [x] Enemy variants used in encounters
- [x] Cardboard Commander boss
- [x] Rewards UI + shop
- [x] Hub scene
- [x] Death / victory summaries
- [x] HUD: health, armor, ammo, run currency, objective
- [x] Headless tests (`scripts/tools/roguelite_check.gd`)
- [x] Update PROJECT_CONTEXT

## Loop status

**Playable end-to-end.**

```
Main Menu → Safehouse → Start Run → Level Map → Encounter
  → Combat clear → Rewards → Map → … → Boss → Act 2 or Victory
Death → Run Summary → scrap award → Safehouse upgrades → new run
```

## Important files

| Path | Role |
| --- | --- |
| `scripts/autoload/player_profile.gd` | Permanent save |
| `scripts/autoload/run_manager.gd` | Active run state |
| `scripts/roguelite/*` | Tree, arenas, rarity, upgrades, damage text, rewards |
| `scripts/characters/cardboard_commander.gd` | Boss |
| `scenes/ui/hub.tscn` | Safehouse |
| `scenes/ui/level_map.tscn` | Branching map |
| `scenes/levels/encounter.tscn` | Encounter runner |
| `scenes/ui/run_summary.tscn` | Death/victory |
| `resources/weapons/marksman.tres` | 5th weapon |
| `resources/ai/{commander,elite,marksman}.tres` | Extra AI kits |

## Controls (run)

Same FPS controls as before. Keys **1–5** select pistol / AR / shotgun / SMG / marksman when owned. Esc pauses in encounters.

## Known limitations

- Arenas are template-built at runtime (not hand-authored `.tscn` rooms); navigation mesh is basic.
- Boss has burst + slam telegraph; no third phase spectacle yet.
- Event nodes are simple random parcels (three outcomes).
- No mid-run save to disk yet (profile saves; run is session memory).
- Compound campaign level remains available from the main menu as a separate mode.

## Tests

```bash
godot --headless --path . -s res://scripts/tools/roguelite_check.gd
```
