# Current state

Paperstrike has a first playable prototype. Launch the game, walk around the test room, aim, shoot the dummy, and it dies. Enemy AI and the rest of the game loop are not implemented.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Account: `nore-tech`
- Branch: `main`
- Engine: Godot 4.x. `project.godot` targets feature `4.4` and Forward Plus. Main scene: `scenes/levels/test_room.tscn`.

## What this phase added

- A closed test room built at runtime from box meshes and static-body collision (`scripts/levels/test_room.gd`).
- A first-person `CharacterBody3D` with WASD, mouse look, gravity, jump, and sprint (`scripts/player/player.gd`).
- A screen-space crosshair (`scenes/ui/crosshair.tscn`).
- One hitscan sidearm. Stats live in `WeaponStats` (`resources/weapons/sidearm.tres`: 34 damage, 40 m, 0.18 s cooldown). The weapon node plays a short muzzle box and light.
- A stationary target dummy with 100 health. A hit flashes the mesh. At zero health the collision turns off, the mesh scales down, and the dummy leaves the tree.

## Node and script relationships

`TestRoom` (`scenes/levels/test_room.tscn`) is the main scene. On ready it builds the floor and four walls. It instances:

- `Player` (`scenes/player/player.tscn`) at `(0, 0.85, 5)`, facing down -Z.
- `TargetDummy` (`scenes/characters/target_dummy.tscn`) at `(0, 0.8, -4)`.
- `Crosshair`.

`Player` is a `CharacterBody3D`. `Camera3D` is a child, local `(0, 0.55, 0)`. `HitscanWeapon` is a child of the camera, so the placeholder gun follows the look.

On left click, while the mouse is captured, `Player` calls `HitscanWeapon.try_fire` with the camera position, camera forward (`-basis.z`), and the player body RID excluded. The weapon reads `WeaponStats`, waits out its cooldown, shows the muzzle flash, raycasts, emits `fired` and `hit_registered`, and calls `take_damage` on the collider when that method exists. The dummy owns its health and the hit reaction. The weapon does not know it is a dummy.

Input actions (`move_forward`, `move_back`, `move_left`, `move_right`, `jump`, `sprint`, `fire`) are created in `Player._ready` if they are missing. Esc uses Godot's built-in `ui_cancel` to toggle mouse capture.

## Validation

Godot 4.4.1 stable was downloaded for this check (`4.4.1.stable.official.49a5bc7b6`). It was not already on `PATH`.

Commands, from a shell, all exited 0 with no script errors:

- `Godot_v4.4.1-stable_linux.x86_64 --headless --path . --import --quit`
- `Godot_v4.4.1-stable_linux.x86_64 --headless --path . --quit-after 30`

A separate headless SceneTree script loaded `test_room.tscn`, fired the sidearm down the camera ray, and checked the dummy. One shot left health at 66. Three shots left health at 0. The ray origin was `(0, 1.4, 5)` and the aim was `(0, 0, -1)`. That script was not committed.

This was not a manual playthrough in a window. Walking, mouse look, jumping, and sprinting were not exercised by hand.

## Known limitations

- Meshes are plain boxes. No paper sprites, billboards, or finished materials.
- No ammo, reload, recoil, spread, or sprint-accuracy delay. One shot per click.
- Shots come from the camera, not the muzzle mesh, so the crosshair is the aim point.
- No second weapon and no weapon switching.
- The dummy does not move, see, or shoot. It is not enemy AI.
- No player health, objectives, extraction, audio, or HUD beyond the crosshair.
- The death tween was not waited out in the scripted check. The check confirmed health reached 0, which is the branch that disables collision and frees the dummy.

## Do not start next

Enemy AI, more weapons, the objective/extract loop, and the paper presentation are not this phase.

## Recommended next

When asked: replace the placeholder room and dummy with the paper/cardboard presentation, then add the first enemy that can actually fight.
