# Milestone 3 plan — First playable FPS level

Working title level: **The Cardboard Compound**

Engine: Godot 4.4 · Language: GDScript · Repo: `nore-tech/paperstrike`

## Discovery summary (existing)

| Area | Status |
| --- | --- |
| Player movement (walk/sprint/slide/cancel/jump/crouch/prone) | Done — `Player` + `MovementProfile` |
| Hitscan weapons, ADS, recoil, ammo, reload | Done — `HitscanWeapon` + `WeaponStats` |
| Weapons: pistol, assault rifle, shotgun | Done — need SMG category |
| Firing range `test_room.tscn` | Done — keep as separate mode |
| Target dummies + reset | Done — stationary only |
| Interaction / weapon pickups / ammo crate | Done |
| Cardboard rifle viewmodel | Done — pistol/shotgun still simpler paper |
| Enemy AI | Missing |
| Player health / death / respawn | Missing |
| Checkpoints / objectives / extraction | Missing |
| Menus / pause / completion | Missing |
| Combat level | Missing |

## Design decisions

1. Keep firing range intact; main scene becomes main menu.
2. Add `GameSession` autoload for scene routing, pause, run stats, settings.
3. Enemies are 3D cardboard articulated figures (procedural meshes), not billboards.
4. AI is a finite state machine on `CardboardEnemy` with `EnemyStats` resources.
5. Navigation uses `NavigationRegion3D` baked from compound geometry at load.
6. Assault rifle already covers AR; add SMG; keep shotgun. Pistol stays for range/spawn fallback.
7. Checkpoints store transform, health, owned weapons/ammo, and encounter reset tokens.
8. Cover = designated `Marker3D` points under encounter zones; enemies move there when hurt.

## Checklist

### A. Foundation
- [x] `GameSession` autoload (play / range / menu / pause / settings / stats)
- [x] Main menu scene (Play, Firing Range, Settings, Quit)
- [x] Pause menu (Esc): Resume, Restart checkpoint, Settings, Main menu
- [x] Docs: this plan + progress + context update

### B. Player combat readiness
- [x] Player health (max 100), damage, death, respawn hooks
- [x] Damage vignette + hit feedback
- [x] Death screen → restart checkpoint
- [x] Damage audio hooks (footsteps still lightweight)
- [x] Run statistics (shots, hits, headshots, damage dealt, kills, time)

### C. Weapons & pickups
- [x] SMG `WeaponStats` + number key bind
- [x] Health pickup interactable
- [x] Keep weapon/ammo pickups working in range and compound

### D. Enemies
- [x] `EnemyStats` resource
- [x] Cardboard enemy mesh builder (head/torso/arms/legs/weapon)
- [x] Procedural anims: idle, walk, run, aim, shoot, flinch, death
- [x] AI FSM: Idle, Patrol, Investigate, Alert, Chase, TakeCover, Attack, Search, Dead
- [x] Vision FOV + distance + LOS; hearing for gunshots
- [x] Variants: Standard, Light, Heavy (data-driven)
- [x] Enemy hitscan attacks with imperfect accuracy

### E. Level — The Cardboard Compound
- [x] Procedural cardboard environment builder (5 sections)
- [x] Section 1 Insertion (spawn, storytelling, rifle pickup)
- [x] Section 2 Outer compound (cover, first fights)
- [x] Section 3 Interior facility (corridors, alternate route)
- [x] Section 4 Storage / warehouse (crates, elevation)
- [x] Section 5 Final arena + extraction
- [x] Navigation mesh (hand-authored walkable quads)
- [x] Cover markers + encounter zones
- [x] Lighting / cardboard materials / signs / crates / doors

### F. Progression
- [x] Objective tracker + HUD line
- [x] Checkpoint volumes between sections
- [x] Encounter clear conditions
- [x] Extraction interactable
- [x] Completion screen (stats + Replay / Menu / Range)

### G. Validation
- [x] Godot import + headless load compound + range
- [x] Headless script: spawn, damage enemy, player damage, checkpoint, objective advance
- [x] Update CURRENT_STATE / TODO / PROJECT_CONTEXT / PROGRESS

## Dependency order

1. GameSession + menus (needed for launch path)
2. Player health + HUD
3. Enemy model + stats + AI
4. Compound level geometry + nav
5. Encounters + objectives + checkpoints
6. Pickups + SMG
7. Completion + polish + tests

## Out of scope / simplify if blocked

- Full recorded gun audio library → keep/extend synthesized SFX
- Fancy cover peek animations → move-to-cover + shoot from cover point
- Separate save files → checkpoint memory only for current run
- Cardboard pistol/shotgun mesh parity with rifle → optional polish
