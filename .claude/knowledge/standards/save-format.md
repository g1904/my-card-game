# Standard — save format (deep dive)

Companion to `.claude/rules/state-save-rules.md` (save/load section). Owned by the **SaveManager** autoload.

## Location & scope
- Persist under `user://` (Godot's per-user writable dir). Offline only — no network sync.
- Separate concerns: **run save** (the in-progress run, resumable) vs **meta/profile** (settings, unlocks, stats). Different lifetimes; consider separate files.

## Atomicity
- Never write in place. Serialize to `user://save.tmp`, flush/close, then rename over `user://save.dat`. A crash mid-write leaves the previous good save intact.
- Optionally keep one backup (`save.bak`) rotated on successful write.

## Versioning & migration
- Every save carries a `version` (int). On load:
  - equal → load directly;
  - older → run migration steps up to current;
  - newer/unknown → refuse gracefully (inform the user) rather than crash.
- Bump `version` whenever the serialized shape changes; add the migration.

## Content references
- Saves reference content by **`Id`** (card/relic/enemy ids), not by index or serialized resource. On load, resolve ids through DataRegistry and validate (see `null-check-rules.md`): an unknown id → clear error/migration, never a silent null.
- Persist the run **seed and RNG sub-stream states** (see `rng-determinism.md`) so a resumed run stays deterministic.

## Format choice
- JSON (via `System.Text.Json` or Godot `JSON`) is readable and migration-friendly; Godot resource serialization is another option. Pick one, record it here, and keep serialization centralized in SaveManager.

## Autosave points
- Define explicit save boundaries (after each map node / encounter / shop). Document them here once implemented so the resume point is predictable.
