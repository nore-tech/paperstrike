# Current state

The test room is now the firing range. The player spawns with the pistol. The assault rifle and shotgun are physical pickups. Stationary dummies sit at three distances, and a button resets them without reloading the scene. Enemy AI, objectives, and extraction are not implemented.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Account: `nore-tech`
- Branch: `main`
- Engine: Godot 4.x, feature `4.4`, Forward Plus. Main scene: `scenes/levels/test_room.tscn`.

## Interaction

`Interactable` (`scripts/interaction/interactable.gd`) is a `StaticBody3D` with an exported `prompt`. `interaction_text()` returns `[E] ` plus that prompt. `interact(player)` does nothing until a subclass overrides it.

Each frame the player raycasts 2.6 m from the camera, excluding its own body, and walks up the hit collider's parents until it finds an `Interactable`. `InteractionPrompt` (group `interaction_prompt`) shows that text while the mouse is captured. The interact key (`E`) calls `interact(self)` on the looked-at object.

A new door, switch, loot pile, or extraction point subclasses `Interactable`, sets `prompt`, and overrides `interact`. It does not need a new input binding.

## Weapon pickups

`WeaponPickup` (`scripts/interaction/weapon_pickup.gd`) is one interactable for every gun. It exports `stats: WeaponStats`. On ready it sets the prompt to `Pick up {display_name}` and builds a colored box from `view_color`. `interact` calls `player.give_weapon(stats)` and then frees the pickup.

Ownership extends the existing weapon switch. It is not a second inventory. The player keeps:

- `_owned` — resource paths the player has picked up
- `_loadout` — the `WeaponStats` for each path
- `_saved_ammo` — magazine and reserve last seen for a holstered gun

`give_weapon`:

- New gun: remember it and equip it through `HitscanWeapon.equip`.
- Already owned and currently equipped: `restock()` back to that resource's magazine and reserve.
- Already owned but holstered: store a full magazine and reserve, then drop the world copy. The next `select_weapon` uses those counts.

`select_weapon` does nothing if the gun is not owned or is already out. Switching saves the current magazine and reserve first, so `equip` does not wipe a partial magazine.

Spawn calls `give_weapon` with `resources/weapons/pistol.tres` only. Keys 1, 2, and 3 call `select_weapon` for the pistol, assault rifle, and shotgun. A key for a gun you do not own yet does nothing.

The ammunition crate is an `Interactable` that stays in the level. It calls `restock_equipped()`, which refills whichever gun is out from that gun's `WeaponStats`. There are no ammo types.

### How to add another weapon pickup

1. Add a `WeaponStats` resource under `resources/weapons/` (copy `pistol.tres`, `rifle.tres`, or `shotgun.tres`).
2. Instance `scenes/pickups/weapon_pickup.tscn` in the level.
3. Assign that resource to the pickup's `stats` property.

No new pickup script. To bind a number key, add one action in `Player._ensure_input_map` that calls `select_weapon` with the new resource. Keys 1–3 are still the only binds.

## Firing range

`test_room.tscn` is a 10 m × 36 m paper room. The player spawns at `(0, 0.85, 14)`, looking down the lanes (−Z).

- Weapon table on the left, near spawn. Pistol, assault rifle, and shotgun pickups sit on it.
- Ammunition crate on the right.
- Red button labeled `RESPAWN TARGETS` beside the spawn.
- Three visual lane stripes. They have no collision.
- Close dummies at z = 8 (about 6 m). Three across. The center one is the full-auto lane.
- Medium dummies at z = 2 (about 12 m).
- Far dummies at z = −10 (about 24 m).

The shotgun's range is 16 m, so it reaches the close and medium rows and not the far row.

## Target manager

`RangeTargetManager` (`scripts/levels/range_target_manager.gd`) sits on the `RangeTargets` node and joins group `range_target_manager`. Each `TargetDummy` joins group `range_target` in `_ready`.

A slot stores the dummy's parent, global transform, the packed scene from `scene_file_path`, and the live node. `reset_all` also scans the group and slots any dummy it has not seen yet.

- Still in the tree: put it back on the saved transform and call `restore()`. That sets health to max, turns collision back on, resets the paper card, and cancels a death that has not freed the node yet.
- Already freed: instance `scenes/characters/target_dummy.tscn` under the original parent at the saved transform.

This does not reload the scene and does not touch the player or weapons.

The button (`scenes/levels/respawn_targets_button.tscn`) is an `Interactable`. Its `Label3D` reads `RESPAWN TARGETS`. `interact` finds the manager group and calls `reset_all`.

### How to add another firing-range target

Instance `scenes/characters/target_dummy.tscn` in `scenes/levels/test_room.tscn` and place it. Leave it earlier in the tree than `RangeTargets` so the manager records it at load. `reset_all` also picks up a `range_target` that still exists and was not registered yet. Do not add behavior to it. Dummies stay stationary.

## Weapons

One `HitscanWeapon` node reads a `WeaponStats` resource. There is no second gun script.

`Player` calls `HitscanWeapon.update` each frame with the camera ray, trigger, aim button, velocity, and mouse delta. It adds the weapon's recoil pitch to the camera and recoil yaw to the body, then lets that recoil settle back. Aim down sights lowers FOV, slows look, moves the viewmodel inward, and tightens spread. Sprint is suppressed while aiming.

The weapon owns the magazine, reserve ammo, fire rate, semi or auto mode, reload timer, recoil, spread, sway, and bob. A shot decrements the magazine, plays the muzzle flash, plays `fire_sound` when one is set, and casts one or more rays. Each hit still emits `hit_registered` and calls `take_damage`. The room turns that signal into a paper scrap. Spread is a random cone, wider from the hip and while moving, tighter in sights. Recovery lerps recoil toward zero.

Reload (`R`) fills the magazine from reserve after `reload_seconds`. It does not load one shell at a time. An empty trigger plays `empty_sound` and does not fire.

| Weapon | Mode | Damage | Rate | Mag / reserve | Notes |
| --- | --- | --- | --- | --- | --- |
| Pistol | Semi | 34 | 4 / s | 10 / 40 | Spawn weapon. Tight hip spread |
| Assault Rifle | Auto | 16 | 9 / s | 30 / 90 | Pickup. Holds the trigger |
| Shotgun | Semi | 12 × 8 pellets | 1.1 / s | 6 / 24 | Pickup. 16 m range, wide cone |

Placeholder noises live in `audio/sfx/`. The viewmodel is still a cardboard box, tinted per weapon. `AmmoHud` shows the name, mode, magazine, reserve, and reloading.

## Validation

Godot 4.4.1 stable (`4.4.1.stable.official.49a5bc7b6`).

Exited 0 with no script errors:

- `--headless --path . --import --quit`
- `--headless --path . --quit-after 30`

A headless script, not committed, loaded the range and printed `CHECK_OK firing range`:

- Spawn owns only the pistol. Selecting the rifle before pickup does nothing.
- The rifle pickup prompt is `[E] Pick up Assault Rifle`. A downward look from in front of the table hits `RiflePickup` and equips Assault Rifle.
- Switching back to the pistol works. Picking up the pistol again restocks it to 10 / 40.
- The shotgun pickup equips Shotgun, and it is still owned after switching away.
- Damaging the close center dummy to 60, then `reset_all`, returns it to 100 and does not change the magazine.
- Freeing the far-left dummy and calling `reset_all` instances a new dummy at that transform with 100 health.
- The ammunition crate restocks the equipped pistol. The button label is `RESPAWN TARGETS`. Using it after a kill restores that dummy and leaves the magazine at 9.
- 0.35 s later that dummy is still in the tree and its card scale is not collapsed.
- A seeded pistol shot from `(0, 1.2, 10)` aimed down the lane left the close center dummy at 66 health before that kill.

This was not a manual playthrough in a window.

## Known limitations

- Keys 1–3 are still hardcoded. A new pickup needs no new pickup code; a new number key is one bind in `player.gd`.
- Picking up a gun you already own removes the world copy and refills it. You cannot hold two of the same gun.
- The ammunition crate refills the equipped weapon only. There are no ammo types.
- The shotgun does not reach the far targets.
- World guns are colored boxes, not finished models.
- Interaction is one camera ray, 2.6 m, against the first body. It does not pick through overlapping props.
- Targets do not move or shoot.
- No inventory grid, weapon mods, penetration, or bullet drop. Reload is one timer. Spread is an even cone. Gun art and sounds are placeholders.
- No enemy AI, objectives, extraction, or player health.

## Recommended next

When asked: one enemy that can fight, using `PaperCard` for the picture and a separate 3D body for hits. Do not start that until asked.
