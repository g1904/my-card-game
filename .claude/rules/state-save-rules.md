# Run-state, RNG & save rules

Deep-dive companions: `.claude/knowledge/standards/rng-determinism.md`, `.claude/knowledge/standards/save-format.md`.

## Run state
- A single **RunState** owns all per-run data (deck, relics, gold, map position, ante/floor, current encounter). Systems read/mutate run data through RunState, not through scattered globals.
- RunState is reset cleanly at run start and torn down at run end — no data bleeding between runs (watch for leftover instanced nodes, static fields, and un-cleared collections).

## Seeded RNG (determinism)
- Every run stores a **seed**. All gameplay randomness (map generation, card draws, shop stock, reward rolls, enemy behavior) derives from that seed — ideally via named sub-streams (e.g. one RNG for the map, one for combat) so unrelated systems don't desync each other.
- A given seed must reproduce the same run. This is a roguelike requirement: it enables daily/seeded runs, bug reproduction, and fair comparison. **Do not** use unseeded `GD.Randi()` / `Random` for gameplay outcomes.
- Persist enough RNG state in the save so a resumed run continues deterministically.

## Save / load
- Offline only: persist under `user://`. No network calls.
- **Write atomically:** serialize to a temp file, then rename over the real file, so a crash mid-write can't corrupt the save.
- **Version the save** with a schema version field and a migration path. When the save shape changes, bump the version and handle old versions on load (migrate or reject gracefully) — never crash on an older save.
- Define explicit autosave points (e.g. after each encounter/map node) so a killed app resumes at a sane boundary.
- On load, validate the save (see `null-check-rules.md`): unknown content ids, version mismatch, or missing fields must be handled with a clear error/migration, not a silent null.
