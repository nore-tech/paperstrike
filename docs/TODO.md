# Todo

The firing range is the weapon and damage test level. Later phases stay pending until someone asks for them.

- [x] Godot 4 project, directory layout, and design docs
- [x] First playable prototype: test room, first-person move and look, hitscan shooting, target dummy
- [x] Paper and cardboard presentation on the test room, dummy, muzzle, and hit scraps
- [x] Pistol, rifle, and shotgun: fire modes, magazines, reserve ammo, reload, recoil, spread, sights, sway, ammo HUD, placeholder audio
- [x] Firing range: shared interactables, weapon pickups, ammunition crate, target manager, respawn button
- [ ] Enemy AI
- [ ] Objective and extraction level
- [ ] Final weapon art, HUD polish, and audio beyond the placeholders

## Adding a weapon pickup

Instance `scenes/pickups/weapon_pickup.tscn` and assign a `WeaponStats` resource. See `docs/CURRENT_STATE.md`. A new number key is a bind in `scripts/player/player.gd`, not a new pickup script.

## Adding a firing-range target

Instance `scenes/characters/target_dummy.tscn` in `scenes/levels/test_room.tscn`, earlier in the tree than `RangeTargets`. The manager registers `range_target` nodes and restores them in place. Do not add AI.
