# Architecture

High-level map of the MyCardGame project. Load this for a macro view before diving into a system.

## Engine & platform
- **Godot 4.7**, **.NET/C#** enabled. Assembly name: `game-feature-branch`.
- Renderer: **GL Compatibility** (`renderer/rendering_method = gl_compatibility` and `.mobile`). Windows editor uses the `d3d12` device driver; runtime uses GL Compatibility for broad mobile/web support.
- Display: `stretch/mode = canvas_items`, `stretch/aspect = expand`, **portrait**, mobile-first.
- 3D physics engine set to Jolt (scaffold default; this is a 2D game — 3D physics is unused).
- Targets: **Android / iOS (primary), desktop, web**. Gameplay is **offline** — persistence under `user://`, no network.

## Current state (fresh scaffold)
`game-feature-branch/` currently contains only the Godot scaffold: `project.godot`, `icon.svg`, editor/`.godot` cache, and git attribute files. **No gameplay scenes, C# scripts, autoloads, or data resources exist yet.** Everything below under "intended architecture" is the plan to build toward, not a description of existing code.

## Intended architecture

### Autoloads (singletons) — see `autoloads/_index.md`
Long-lived services registered as Godot autoloads:
- **Game** — app-level bootstrap / screen flow.
- **RunState** — all per-run data (deck, relics, gold, map position, ante, seed).
- **EventBus** — decoupled cross-system signals.
- **DataRegistry** — loads/indexes all data resources by `Id`.
- **SaveManager** — atomic, versioned save/load under `user://`.
- **AudioManager** — music/SFX buses.

### Gameplay systems — see `systems/_index.md`
Run lifecycle → map/progression → encounter/combat → deck/hand → card resolution → energy/economy → relics/jokers → scoring → shop/rewards → save/load. Plus cross-cutting UI/screens, input/touch, audio.

### Data — see `data/_index.md`
Content (cards, relics, enemies, encounters, events, blinds/antes, balance) authored as `.tres` custom `Resource` files, indexed by `DataRegistry`.

### Scenes — see `scenes/_index.md`
Screen scenes (main menu, run, combat, map, shop, settings) plus instanced widget scenes (card, enemy, reward tile).

## Data / control flow (target)
```
Input (touch) ──▶ Screen scene ──▶ System/manager ──▶ RunState (mutates)
                                        │
                                        ├─▶ DataRegistry (reads content by Id)
                                        └─▶ EventBus (emits) ──▶ other systems / UI react
SaveManager ◀── autosave points ── RunState        (seeded RNG drives all randomness)
```
