# Current state

The test room is now the firing range. The player spawns with the pistol. The assault rifle and shotgun are physical pickups. Stationary dummies sit at three distances, and a button resets them without reloading the scene. Movement is a state machine on the player: idle, walking, sprinting, crouching, prone, sliding, jumping, and falling. Weapons are layered paper meshes with iron sights, aim-down-sights alignment, and split camera/visual recoil. Enemy AI, objectives, and extraction are not implemented. The next phase has not been started.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Account: `nore-tech`
- Branch: `main`
- Engine: Godot 4.x, feature `4.4`, Forward Plus. Main scene: `scenes/levels/test_room.tscn`.

## Movement

`MovementProfile` (`resources/player/movement_profile.tres`, script `scripts/player/movement_profile.gd`) holds the speeds, acceleration, jump height, capsule sizes, slide friction, and camera bob. `Player` is the only reader. Change that resource to retune movement. Do not copy the numbers into other scripts.

Horizontal speed eases toward the wish direction with `1 - exp(-rate * delta)`. Ground acceleration is fast on purpose. Diagonals come from `Input.get_vector`. Releasing the keys eases speed back to zero. In the air, steering is lighter and does not raise speed above the faster of the current speed and the ground target. There is no stamina.

Sprint is Left Shift. It stops while crouching, prone, or while aim blend is at least 0.2. Firing and reload keep working.

Crouch is hold Left Ctrl. The capsule shortens around the feet, and the camera eases down inside it. A standing-capsule query blocks standing up into a ceiling.

Prone is Z, a toggle, and its own state. The collision becomes a low box (`prone_height`, `prone_width`, `prone_length`) so the body is actually shorter, not just a lower camera. Crawl speed is `prone_speed`. Sprint and jump do not run while prone. Going prone is refused when that box does not fit. Z again stands if the ceiling is clear, or settles into a crouch when a crouch fits and a stand does not. Holding Ctrl while prone also returns to a crouch when the crouch fits.

Slide is Left Ctrl while sprinting and at least `slide_min_speed`. Entry multiplies current speed by `slide_entry_boost` (default 1.1) and caps it at 115% of sprint speed, so the slide starts faster than the sprint instead of braking. Friction then eases it down across about a second (`slide_friction`, `slide_max_seconds`). Steering uses `slide_steer`. Look is never locked. Another slide waits out `slide_cooldown` and needs a sprint again. Jump does not start during a slide. When it ends, leftover horizontal speed stays. Shift still held, and the ceiling clear, goes straight back into a sprint. Ctrl held, or a ceiling, stays crouched.

Jump is Space, from walk, sprint, or crouch, only while grounded, with a short lock so the floor cannot double-fire it. Jump speed is `sqrt(2 * gravity * jump_height)`.

The camera keeps mouse look and the vertical clamp. A small vertical bob is added while walking, reduced by `bob_ads_scale`, `bob_crouch_scale`, and further while prone. A short landing dip plays after a hard landing. The weapon stays parented to the camera.

## Aim, sights, and recoil

`PaperWeaponView` builds the pistol, rifle, and shotgun from layered boxes on the existing paper material: receiver, barrel, grip, magazine or tube, stock where it belongs, and a rear notch plus a front post. `WeaponStats.form` picks the mesh. Hip position, hip rotation, ADS FOV, ADS time, and `ads_eye_distance` are on that same resource.

Aim is right click. The viewmodel pose is not a shove toward the camera. `HitscanWeapon` reads the `RearSight` and `FrontSight` markers and solves a basis so that sight line lies on the camera forward axis, with the rear sight `ads_eye_distance` in front of the eye. Hip and ADS poses blend over `ads_time`. The hip-fire crosshair hides once aim blend passes 0.45. Hitscan rays still leave the camera along its look direction, which is the same line as the sights when recoil and sway are zero. Spread still applies.

Firing adds two recoils. A fraction `camera_recover` springs the view back. The rest is added to the camera and stays, so automatic fire climbs and the mouse has to pull it down. The gun mesh also kicks backward and pitches up, then `visual_recovery` eases it home. `ads_recoil_scale` reduces both while aiming. Per-weapon values live on the three `WeaponStats` resources. Yaw alternates sign instead of being fully random.

Stationary prone cuts weapon sway. ADS cuts it further. Shooting, reloading, weapon switching, and pickups are unchanged by the stance.

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

On this slice, import and `--quit-after 30` exited 0 with no script errors. The movement script below was run after the controller change. The firing-range list is from the previous slice and was not re-run; the movement script did repeat an unowned-rifle check and one pistol shot.

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

A later headless script, not committed, printed `CHECK_OK handling` after the slide, prone, sight, and recoil pass:

- A sprint into Ctrl starts the slide above the sprint speed and still above 72% of sprint speed 0.4 s later. The slide ends with speed left, and holding Shift returns to sprint.
- Z enters prone, shortens the collider, lowers the camera, and refuses sprint speed. A low ceiling blocks standing. A wall close in front refuses prone. Z stands back up when the space is clear.
- With aim held, the pistol, rifle, and shotgun sight markers sit within 2.5 cm of the camera forward ray. The crosshair hides.
- One pistol shot sets visual pitch, held camera recoil, and a camera kick. A seeded shot still damages the close dummy.

A headless script before that, also not committed, printed `CHECK_OK movement` against the same range:

- Walk speed eases in, then returns to idle after the keys are released. Diagonal speed stays near the forward speed. Reversing direction reaches a positive Z velocity within 0.35 s.
- Sprint exceeds the walk speed and stays at or under the sprint speed. Holding aim brings it back down to a walk.
- Crouch shortens the capsule, lowers the camera, and slows movement. A ceiling blocks standing until it is removed.
- A sprint into Ctrl enters the slide state, speed drops, jump does not leave the floor, and the slide ends in a crouch. Holding crouch and shift does not start another slide.
- One Space leaves the ground. A second press in the air does not increase upward speed. After landing, Space jumps again.
- Walking bob moves the camera by a small span. A drop from 2.6 m produces a landing dip.
- An unowned rifle still cannot be selected, and a seeded pistol shot still damages the close dummy.

This was not a manual playthrough in a window. Two physics frame rates were not compared. The step uses delta, but that property was not measured by running the game at two refresh rates.

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
- Jumping is disabled during a slide and while prone. There is no coyote time and no air jump.
- Part of each shot's camera kick stays until the player pulls the mouse down. That is intentional.
- Sight alignment was measured in a headless run, not judged by eye in a window. The guns are built from boxes, not finished art.
- Headless play does not keep the mouse captured, so the handling script confirmed aim with the aim action held and confirmed the recoil kick by calling the weapon update directly.
- A slide adds a capped entry boost, then eases off. It does not keep climbing if you chain slides.
- Gun art and sounds are still placeholders in the sense that the meshes are procedural boxes. They are no longer a single crate.
- Camera bob is only vertical and small. The viewmodel still has its own bob, so the gun is not perfectly still.
- Crouch and slide clearance is the shortened capsule. Very thin gaps under `crouch_height` (1.05 m) will not pass.
- Head bob while crouched or aiming is scaled in code. The headless check measured walking bob and the landing dip, not a separate crouch-bob sample.

## Recommended next

Phase 2B has not been started. Do not begin it until asked.
