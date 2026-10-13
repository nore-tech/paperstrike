# Current state

Paperstrike is a Godot 4 project with design docs and an empty scene layout. Gameplay is not implemented.

## Repo

- GitHub: https://github.com/nore-tech/paperstrike
- Account: `nore-tech`
- Branch: `main`

## Engine

- Target: Godot 4.x. `project.godot` sets `config_version=5` and feature `4.4` with the Forward Plus renderer.
- No main scene is set. Opening the project shows an empty editor.
- There are no `.tscn`, `.gd`, or `.tres` files.

## What is in the tree

- `project.godot`, `icon.svg`, `.gitignore`
- `AGENTS.md`, `README.md`
- `docs/GAME_DESIGN.md`, `docs/ARCHITECTURE.md`, `docs/TODO.md`, this file
- Empty directories: `scenes/`, `scripts/`, `resources/`, `assets/`, `audio/`, `ui/`, plus the subfolders named in `ARCHITECTURE.md`

## What is not built

Player movement, weapons, AI, levels, objectives, extraction, HUD, and audio playback.

## Validation

The Godot CLI was not installed on the machine that created this commit (`godot` and `godot4` were not on `PATH`, and no Godot binary was found under `/usr`, `/opt`, or `/home`). The project was not opened headlessly. Do not treat this commit as an editor import test.

## Next

Do not start the player controller until that phase is explicitly requested. See `docs/TODO.md`.
