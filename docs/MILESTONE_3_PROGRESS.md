# Milestone 3 progress

Updated during the first playable compound implementation.

## Completed

- [x] Project discovery and `docs/MILESTONE_3_PLAN.md`
- [x] `GameSession` autoload (scene routing, pause, settings, run stats, checkpoints)
- [x] Main menu: Play / Firing Range / Settings / Quit
- [x] Pause menu (Esc): Resume / Restart checkpoint / Settings / Main menu
- [x] Player health (100), damage, death, respawn, vignette, health HUD
- [x] SMG weapon resource + key `4`
- [x] Health pickups
- [x] Cardboard enemy mesh (articulated figure + gun)
- [x] Enemy AI FSM (idle/patrol/investigate/alert/chase/cover/attack/search/dead)
- [x] Vision FOV + LOS, hearing for gunshots, imperfect hitscan attacks
- [x] Variants: Standard / Light / Heavy via `EnemyStats`
- [x] The Cardboard Compound level (5 sections, cardboard props, signs, nav quads)
- [x] Encounters, objectives HUD, checkpoints, extraction, completion screen
- [x] Firing range still loadable; gains health HUD + pause
- [x] Headless validation script `scripts/tools/milestone3_check.gd` → `CHECK_OK milestone3`

## Files added (high level)

- `scripts/autoload/game_session.gd`
- `scripts/ai/enemy_stats.gd` + `resources/ai/{standard,light,heavy}.tres`
- `scripts/characters/cardboard_enemy.gd` + mesh builder + scene
- `scripts/levels/compound_level.gd` + `scenes/levels/cardboard_compound.tscn`
- `scripts/interaction/{health_pickup,extract_point}.gd`
- `scripts/ui/{main_menu,pause_menu,death_screen,completion_screen,health_hud,objective_hud,damage_vignette}.gd` + scenes
- `resources/weapons/smg.tres`
- `scripts/tools/milestone3_check.gd`

## Tests performed

```
godot --headless --path . --import --quit
godot --headless --path . -s res://scripts/tools/milestone3_check.gd
```

Result: `CHECK_OK milestone3` (menu, range damage, compound enemies, outer clear, checkpoint, death/respawn, extract complete).

GUI smoke ([GUI smoke test Paperstrike](bc-a0768cef-76c1-54e7-8c69-f554876b078f)): main menu → Play → compound spawn HUD → Esc pause → Resume → WASD move. Screenshots in `media/milestone-3/`.

Not tested: full combat pacing by hand, ADS feel across all sections, audio mix by ear.

## Known limitations / remaining polish

- Navigation uses hand-authored walkable quads, not a full geometry bake; tall platform pathing is approximate.
- Enemy cover is point-based (move to marker), not peek/lean.
- Pistol/shotgun viewmodels remain simpler paper boxes; only rifle (and SMG reusing rifle form) have the detailed cardboard build.
- Footsteps are not yet distinct loops (gun/hurt SFX exist).
- Cannot push to `github.com/nore-tech/paperstrike` from this environment without credentials.

## Manual test checklist

1. Launch → main menu → Play → spawn in insertion bay with pistol; pick up rifle.
2. Clear outer compound; confirm objective text advances and Esc pause works.
3. Die → Restart checkpoint → enemies for uncleared sections return.
4. Finish warehouse + final → extract pad arms → complete screen stats.
5. Main menu → Firing Range still works with pickups and dummy reset.
