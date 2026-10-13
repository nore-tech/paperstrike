# Game design

## Pitch

Paperstrike is a small single-player first-person shooter. Movement, collision, combat, AI, and levels are fully 3D. Characters and many props are flat 2D sprites on billboards, and rooms are simple geometry, so the world looks built from paper and cardboard.

## Pillars

- Tactical but accessible gunplay. Position, reloads, and cover matter. The first fight should be readable without a manual.
- Paper and cardboard. 3D space, 2D pictures. Flat characters, thick simple shapes, visible edges.
- One job, then leave. Every level has an objective and an extraction. Clearing the room is not the win.

## Player fantasy

You are a runner on a paper battlefield. You go in light, finish one task, and get out before the place closes on you.

## Camera and presentation

- First-person camera on a 3D body.
- Mouse look and WASD movement through 3D space.
- Enemies and most dressings are sprites on billboards.
- Weapons are first-person models or view sprites held in front of the camera, not a billboard of the player.
- Environments are simple meshes: boxes, planes, and a few custom shapes. No skeletal character meshes.

## Gunplay

Accessible first, tactical second.

- Start with hitscan weapons so hits feel immediate. A slow projectile can come later if a weapon needs it.
- A few weapons, each different in fire rate, magazine size, and useful range. No attachment trees and no loot treadmill.
- Reload, aim, and a short delay after sprinting before a shot is accurate.
- Damage is readable. Paper tears. Cardboard dents. Enemies telegraph their shots.
- The player can die. Failure restarts the level at the insert. No meta-progression is required for the first playable slice.

## Enemies

- Billboard characters that move with 3D navigation.
- They see or hear the player, walk the navmesh, and either shoot or close distance.
- States stay readable: patrol, alert, attack, search.
- The first combat slice needs one ranged enemy and one that rushes. More types wait until those two work.

## Level flow

1. **Insert.** The player starts at a safe entrance.
2. **Objective.** One task the level states up front: reach a point, pick up an object, or throw a switch.
3. **Extract.** Completing the objective opens or marks an exit. The level is won by leaving.

Enemies are pressure during the job and on the way out. They are not the objective.

## Scope

In the small game:

- One first-person controller
- Paper and cardboard presentation
- A couple of weapons
- Basic enemy AI
- One objective-and-extract level
- A minimal HUD and a few weapon and footstep sounds

Out of scope:

- Multiplayer
- Inventory grids, shops, or skill trees
- Full 3D character models
- Procedural campaigns
- Dialogue systems and cutscenes
- A large enemy roster

## Tone

Physical and a little toy-like. The world is paper. The danger is straight. No lore bible in this phase.
