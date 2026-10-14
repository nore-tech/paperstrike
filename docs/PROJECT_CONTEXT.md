# Project context

Paperstrike is a single-player first-person shooter with a cardboard / papercraft look. Milestone 4 adds a full single-player **roguelite** loop on top of the existing FPS systems.

Main scene: `scenes/ui/main_menu.tscn`  
Hub: `scenes/ui/hub.tscn`  
Run map: `scenes/ui/level_map.tscn`  
Encounters: `scenes/levels/encounter.tscn`  
Campaign setpiece: `scenes/levels/cardboard_compound.tscn` (**The Cardboard Compound**)  
Training: `scenes/levels/test_room.tscn` (firing range — all five weapons, no meta progress)

## What is in the build

### FPS core
- CoD-inspired movement on `Player` + `MovementProfile`: walk, sprint, slide (+ cancel), jump, crouch, prone.
- Hitscan weapons via `WeaponStats`: pistol, assault rifle, SMG, shotgun, **marksman rifle**. ADS, recoil, ammo, reload. Keys 1–5.
- Player health, **armor**, damage vignette, death handling.
- Cardboard enemy soldiers with FSM AI (Standard / Light / Heavy / Marksman / Elite) plus **Cardboard Commander** boss.
- Compound campaign level retained as a separate menu option.
- Firing range retained; grants all weapons for sandbox testing.

### Roguelite loop
- `PlayerProfile` autoload — permanent scrap, upgrades, lifetime stats (`user://paperstrike_profile.json`, versioned).
- `RunManager` autoload — act/node tree, run scrap, temp upgrades, loadout, health/armor.
- Safehouse hub: start run, buy permanent upgrades, view stats, open range/settings/menu.
- Seeded branching level tree (combat / elite / supply / shop / event / boss).
- Encounter arenas via `ArenaBuilder` + `LevelKit`.
- Rewards, shops (run scrap), temporary upgrades (≥15), weapon rarity (Common→Legendary).
- Floating damage numbers (normal / headshot / crit / armor / kill colors).
- Death and victory summaries award permanent scrap and return to hub.
- New runs always start with a **common pistol only**.

## Controls

WASD move, Shift sprint, hold Left Ctrl crouch/slide, Space jump, Z prone, mouse look, LMB fire, RMB ADS, R reload, E interact, 1–5 weapons, Esc pause (encounters) or free mouse on range if pause disabled.

## Autoloads

- `GameSession` — scene routing, pause, settings, compound checkpoints
- `PlayerProfile` — permanent meta
- `RunManager` — active run

## Repo

https://github.com/nore-tech/paperstrike — Godot 4.4, Forward Plus.

## Milestone status

- Milestone 3 / 3.5: compound combat level on `main`.
- **Milestone 4 (roguelite):** feature branch `cursor/milestone-4-roguelite-fa4d`. See `docs/ROGUELITE_IMPLEMENTATION.md`.
