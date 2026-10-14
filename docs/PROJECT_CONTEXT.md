# Project context

Paperstrike is a single-player first-person shooter. Movement, hits, AI, and levels are 3D. Presentation is handcrafted cardboard / papercraft.

Main scene: `scenes/ui/main_menu.tscn`  
Combat level: `scenes/levels/cardboard_compound.tscn` (**The Cardboard Compound**)  
Training: `scenes/levels/test_room.tscn` (firing range)

## What is in the build

- CoD-inspired movement on `Player` + `MovementProfile`: walk, sprint, slide (+ cancel), jump, crouch, prone.
- Hitscan weapons via `WeaponStats`: pistol, assault rifle, SMG, shotgun. ADS iron sights, recoil, ammo, reload. Keys 1–4.
- Player health (100), damage vignette, death screen, checkpoint respawn.
- Cardboard enemy soldiers with FSM AI, vision/hearing, cover points, Standard/Light/Heavy variants.
- Compound level with five sections, objectives, checkpoints, extraction, completion stats.
- Main menu, pause menu, firing range retained as a separate mode.
- `GameSession` autoload owns scene routing, pause, settings, run statistics, checkpoint memory.

## Controls

WASD move, Shift sprint, hold Left Ctrl crouch/slide, Space jump, Z prone, mouse look, LMB fire, RMB ADS, R reload, E interact, 1–4 weapons, Esc pause (or free mouse on range if pause disabled).

## Repo

https://github.com/nore-tech/paperstrike — Godot 4.4, Forward Plus.

## Milestone status

Milestone 3 is on **`main`**. Milestone 3.5 redesigned compound accessibility/combat layout. See `docs/MILESTONE_3_5_PROGRESS.md`.
