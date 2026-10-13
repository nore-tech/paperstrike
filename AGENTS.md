# Agent rules

Read these before changing the project:

- [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md)
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- [docs/CURRENT_STATE.md](docs/CURRENT_STATE.md)
- [docs/TODO.md](docs/TODO.md)

Then follow these rules:

1. Read `GAME_DESIGN.md`, `ARCHITECTURE.md`, `CURRENT_STATE.md`, and `TODO.md` before making changes.
2. Work only on the phase or task the user requested.
3. Inspect existing implementations before changing them.
4. Never rewrite working systems unnecessarily.
5. Keep systems modular.
6. Use Godot Resources for data-driven configuration where appropriate.
7. Validate changes using the Godot CLI whenever it is available.
8. Fix errors introduced by the current work before stopping.
9. Update `CURRENT_STATE.md` and `TODO.md` after completing work.
10. Never claim something was tested if it was not actually tested.
11. Never begin the next development phase without being explicitly asked.
