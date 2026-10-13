# Project context

Paperstrike is a single-player 2.5D first-person shooter. Movement, hits, and levels are 3D. Characters are paper. The assault rifle is a handmade cardboard model: layered panels, a faceted tube barrel, folded edge flaps, and a separate magazine. The pistol and shotgun are still the earlier layered paper meshes.

The playable level is the firing range, `scenes/levels/test_room.tscn`. It is the permanent test bed for weapons, damage, recoil, and movement. There is no enemy AI yet.

## What is in the build

- First-person movement on `Player`, tuned by `resources/player/movement_profile.tres`. States are idle, walking, sprinting, crouching, prone, sliding, jumping, and falling.
- One `HitscanWeapon` driven by `WeaponStats`. The pistol is the spawn weapon. The rifle and shotgun are world pickups. Keys 1–3 switch owned guns. E interacts.
- The assault rifle viewmodel is built from cardboard panels and tube sections, with named parts (receiver, barrel, handguard, stock, grip, trigger guard, magazine, muzzle, sights). Right click aims through the rear and front sight markers. The mesh kicks and climbs under fire, separate from the camera recoil. Drawing a gun raises it into place. Sprinting lowers it. Reloading dips the gun and the magazine.
- Stationary target dummies and a respawn button that does not reload the scene or clear weapons.

Design and the longer status writeup are in `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/CURRENT_STATE.md`, and `docs/TODO.md`.

## Controls

WASD move, Shift sprint, hold Left Ctrl to crouch. Hold Ctrl while sprinting to slide, and keep holding it to stay in the slide. Space jumps out of a slide and keeps the horizontal speed. Press Shift again during a slide to stand into a sprint when the ceiling allows. Z goes prone, including from a slide. Mouse look, left click fire, right click aim, R reload, E interact, 1/2/3 owned weapons, Esc mouse.

## Repo

https://github.com/nore-tech/paperstrike on `main`. Godot 4.4, Forward Plus.

## Not started

Enemy AI, objectives, extraction, and any phase after this movement and weapon-handling pass.
