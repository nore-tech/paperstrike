# Current state

Paperstrike launches into a paper test room with a first-person controller and three hitscan weapons. Enemy AI, inventory, and the objective loop are not implemented.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Account: `nore-tech`
- Branch: `main`
- Engine: Godot 4.x, feature `4.4`, Forward Plus. Main scene: `scenes/levels/test_room.tscn`.

## Weapons

One `HitscanWeapon` node reads a `WeaponStats` resource. There is no second gun script.

`Player` calls `HitscanWeapon.update` each frame with the camera ray, trigger, aim button, velocity, and mouse delta. It adds the weapon's recoil pitch to the camera and recoil yaw to the body, then lets that recoil settle back. Aim down sights lowers FOV, slows look, moves the viewmodel inward, and tightens spread. Sprint is suppressed while aiming.

The weapon owns the magazine, reserve ammo, fire rate, semi or auto mode, reload timer, recoil, spread, sway, and bob. A shot decrements the magazine, plays the muzzle flash, plays `fire_sound` when one is set, and casts one or more rays. Each hit still emits `hit_registered` and calls `take_damage`. The room turns that signal into a paper scrap. Spread is a random cone, wider from the hip and while moving, tighter in sights. Recovery lerps recoil toward zero.

Reload (`R`) fills the magazine from reserve after `reload_seconds`. It does not load one shell at a time. An empty trigger plays `empty_sound` and does not fire.

Keys 1, 2, and 3 call `equip` on the pistol, rifle, and shotgun resources. That is a test switch, not an inventory.

| Weapon | Mode | Damage | Rate | Mag / reserve | Notes |
| --- | --- | --- | --- | --- | --- |
| Pistol | Semi | 34 | 4 / s | 10 / 40 | Tight hip spread |
| Rifle | Auto | 16 | 9 / s | 30 / 90 | Holds the trigger |
| Shotgun | Semi | 12 × 8 pellets | 1.1 / s | 6 / 24 | Short range, wide cone |

Placeholder noises live in `audio/sfx/`. The viewmodel is still a cardboard box, tinted per weapon. `AmmoHud` shows the name, mode, magazine, reserve, and reloading.

## What stayed

The dummy is a `PaperCard` on a `BoxShape3D`. Movement is still WASD, mouse look, gravity, jump, and sprint. Impacts and the paper room are unchanged.

## Validation

Godot 4.4.1 stable (`4.4.1.stable.official.49a5bc7b6`).

Exited 0 with no script errors:

- `--headless --path . --import --quit`
- `--headless --path . --quit-after 30`

A headless script, not committed, loaded the room and drove `HitscanWeapon.update` directly:

- Pistol: one centered shot left the dummy at 66 health and the magazine at 9. Holding the trigger did not fire again. A later press did. Recoil rose, then recovered after 2 seconds. Aim blend reached 1. Reload restored the magazine to 10 and reserve to 38.
- Rifle: holding fire for twelve 0.05 s steps left the magazine at 26 (four shots). One more 0.2 s tick fired once more, to 25.
- Shotgun: one close shot spent one shell, spawned at least four paper impacts, and lowered dummy health. After the magazine was emptied, another press did not change health.

This was not a manual playthrough in a window.

## Known limitations

- No inventory, weapon mods, penetration, or bullet drop.
- Reload is one timer, not a per-shell shotgun load.
- Spread is an even random cone.
- Gun art and sounds are placeholders.
- No enemy AI, objectives, extraction, or player health.

## Recommended next

When asked: one enemy that can fight, using `PaperCard` for the picture and a separate 3D body for hits.
