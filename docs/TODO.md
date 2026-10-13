# Todo

The firing range is the weapon and damage test level. Movement tuning lives in `resources/player/movement_profile.tres`. Weapon feel lives on each `WeaponStats` resource. The next phase has not been started.

- [x] Godot 4 project, directory layout, and design docs
- [x] First playable prototype: test room, first-person move and look, hitscan shooting, target dummy
- [x] Paper and cardboard presentation on the test room, dummy, muzzle, and hit scraps
- [x] Pistol, rifle, and shotgun: fire modes, magazines, reserve ammo, reload, recoil, spread, sights, sway, ammo HUD, placeholder audio
- [x] Firing range: shared interactables, weapon pickups, ammunition crate, target manager, respawn button
- [x] Player movement: accel, sprint, crouch, slide, jump, bob, and landing dip from `MovementProfile`
- [x] Movement and weapon handling: longer slides, prone, paper guns, iron-sight ADS, visible recoil
- [x] Slide cancels (jump, sprint, crouch release, prone) and one cardboard assault rifle
- [ ] Cardboard pistol and shotgun at the same detail as the rifle
- [ ] Enemy AI
- [ ] Objective and extraction level
- [ ] Recorded gunshots to replace the synthesized placeholders, HUD polish

## Adding a weapon pickup

Instance `scenes/pickups/weapon_pickup.tscn` and assign a `WeaponStats` resource. See `docs/CURRENT_STATE.md`. A new number key is a bind in `scripts/player/player.gd`, not a new pickup script.

## Adding a firing-range target

Instance `scenes/characters/target_dummy.tscn` in `scenes/levels/test_room.tscn`, earlier in the tree than `RangeTargets`. The manager registers `range_target` nodes and restores them in place. Do not add AI.
