# Project context

Paperstrike is a single-player 2.5D first-person shooter. Movement, hits, and levels are 3D. Characters and weapons are paper and cardboard: billboards and layered flat meshes, not realistic models.

The playable level is the firing range, `scenes/levels/test_room.tscn`. It is the permanent test bed for weapons, damage, recoil, and movement. There is no enemy AI yet.

## What is in the build

- First-person movement on `Player`, tuned by `resources/player/movement_profile.tres`. States are idle, walking, sprinting, crouching, prone, sliding, jumping, and falling.
- One `HitscanWeapon` driven by `WeaponStats`. The pistol is the spawn weapon. The rifle and shotgun are world pickups. Keys 1–3 switch owned guns. E interacts.
- Paper weapon meshes with a rear sight and a front sight. Right click aims so those markers sit on the camera's forward ray. Recoil is split: part of the camera kick stays, the gun mesh kicks and settles.
- Stationary target dummies and a respawn button that does not reload the scene or clear weapons.

Design and the longer status writeup are in `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/CURRENT_STATE.md`, and `docs/TODO.md`.

## Controls

WASD move, Shift sprint, Left Ctrl crouch or slide, Z prone, Space jump, mouse look, left click fire, right click aim, R reload, E interact, 1/2/3 owned weapons, Esc mouse.

## Repo

https://github.com/nore-tech/paperstrike on `main`. Godot 4.4, Forward Plus.

## Not started

Enemy AI, objectives, extraction, and any phase after this movement and weapon-handling pass.
