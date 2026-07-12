# Data-resource rules

Game content (cards, relics/jokers, enemies, encounters, events, blinds/antes, balance tables) is **data**, defined as custom `Resource` classes serialized to `.tres`. Deep-dive companion: `.claude/knowledge/data/_index.md`.

## Definitions
- Each content type is a `[GlobalClass] partial class XxxData : Resource` with `[Export]` fields. Instances are authored as `.tres` files under the project's data folders.
- **Every entry has a stable, unique string `Id`.** Ids are the key everything else references (save files, registry lookups, relic→card interactions). Never key content by scene path, array index, or display name.
- Display strings (name, description) are fields on the resource — keep them separate from `Id` so they can change or localize without breaking references.

## Registry / loading
- A single **DataRegistry** autoload loads all `.tres` of each type at startup and indexes them by `Id`. Gameplay code looks content up through the registry, not by ad-hoc `ResourceLoader.Load` calls scattered around.
- **Validate on load** (see `null-check-rules.md`): missing/duplicate `Id`, dangling cross-references (e.g. an encounter listing an unknown enemy id) → `GD.PushError` with the offending id/path at startup, so bad data fails loud and early rather than mid-run.

## Balance & config
- Tunable numbers (costs, damage, drop weights, ante scaling) live in exported fields or dedicated balance resources — **not** hardcoded in system logic. Systems read values from data.
- Keep content additive: adding a new card = adding a `.tres`, not editing a switch statement. Prefer data-driven effect definitions over per-card code where practical.
