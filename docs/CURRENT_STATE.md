# Current state

Paperstrike has a first playable prototype with a paper and cardboard look. Launch the game, walk the test room, shoot the billboard dummy, and it dies. Enemy AI is not implemented.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Account: `nore-tech`
- Branch: `main`
- Engine: Godot 4.x. `project.godot` targets feature `4.4` and Forward Plus. Main scene: `scenes/levels/test_room.tscn`.

## What this phase added

Presentation is separate from hit detection.

- `PaperMaterial` resources tint a shared generated fiber texture: `resources/presentation/paper_floor.tres`, `paper_wall.tres`, `cardboard_edge.tres`.
- `PaperBlock` builds each room surface as a cardboard box plus one inset paper face, so the cut edge stays visible. Collision size is unchanged.
- `PaperCard` is a reusable yaw-billboard cutout: a thicker cardboard shell and a generated figure on a quad. It listens for `damaged` and `died`. It does not know about weapons.
- The target dummy keeps its `BoxShape3D` (`0.7 x 1.6 x 0.35`). The old solid `Mesh` is gone. Shots still hit that volume, including from the side, while the card reads flat.
- `PaperImpact` is a short paper-scrap burst. The test room spawns it from `hit_registered`. It is not part of damage.
- The sidearm muzzle is a paper burst node plus a warm, short-range light. The gun body is still a box, recolored as dark cardboard with a lighter edge.
- Lighting is a warm shadowed sun, a dim cool fill, and warm ambient light.

## Node and script relationships

`TestRoom` builds the floor and walls, then connects `Player/Camera3D/HitscanWeapon.hit_registered` to spawn `scenes/presentation/paper_impact.tscn`.

`TargetDummy` owns health, `take_damage`, the collision shape, `damaged`, and `died`. At zero health it turns collision off and frees itself after 0.12 seconds. `PaperCard` is a child and only reacts to those signals (flash, then scale to zero).

`HitscanWeapon.try_fire` is unchanged in behavior. The hit signal now also carries the surface normal so a scrap can sit on the surface. The player script was not changed. Shots still start at the camera.

`PaperTextures` generates the fiber image and the figure. Nothing in gameplay reads those textures.

## Validation

Godot 4.4.1 stable (`4.4.1.stable.official.49a5bc7b6`) at `/tmp/godot-dl/Godot_v4.4.1-stable_linux.x86_64`.

These exited 0 with no script errors:

- `--headless --path . --import --quit`
- `--headless --path . --quit-after 30`

A headless SceneTree script loaded the room, confirmed the dummy still has a `BoxShape3D`, has a `PaperCard`, and no longer has `Mesh`. One camera ray left health at 66 and spawned a `paper_impact`. Three rays left health at 0 and spawned 3 impacts. That script was not committed.

This was not a manual playthrough in a window.

## Known limitations

- The figure, fiber, and scraps are generated placeholders, not finished art.
- The firearm is still a box, not a paper viewmodel.
- Impacts fade in about 0.2 seconds. They do not leave a hole.
- The card yaws toward the camera and stays upright. It does not pitch.
- No ammo, reload, recoil, enemy AI, player health, objectives, extraction, or audio.
- The HUD is still only the crosshair.

## Do not start next

Enemy AI and the objective loop are not this phase.

## Recommended next

When asked: one enemy that moves and shoots, reusing `PaperCard` for its picture and a separate 3D body for hits.
