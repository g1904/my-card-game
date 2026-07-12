# Systems index

Gameplay systems for the roguelike deckbuilder. Each becomes its own `systems/<name>.md` note **once it exists in code** — do not pre-create empty stubs. Status is honest: nothing is implemented yet (fresh scaffold).

| System | File | Status | Responsibility |
|--------|------|--------|----------------|
| Run manager | `run-manager.md` | TODO | Run lifecycle: start (seed), advance, win/loss, teardown; owns high-level flow. |
| Map / progression | `map-progression.md` | TODO | Generate the branching node map per ante; track position; route to node types. |
| Encounter / combat | `encounter-combat.md` | TODO | Turn structure, enemy intents/AI, win/lose resolution. |
| Deck & hand | `deck-hand.md` | TODO | Draw/hand/discard piles, shuffle (seeded), deck mutations. |
| Card resolution | `card-resolution.md` | TODO | Playing a card: cost, targeting, effect pipeline, triggers. |
| Energy / economy | `energy-economy.md` | TODO | Per-turn energy; run currency (gold) earn/spend. |
| Relics / jokers | `relics-jokers.md` | TODO | Passive modifiers hooked into event triggers via EventBus. |
| Scoring | `scoring.md` | TODO | Score model (chips × mult if Balatro-like) — or fold into combat if StS-like. |
| Shop / rewards | `shop-rewards.md` | TODO | Shop stock (seeded), buying, card add/remove/upgrade, post-encounter rewards. |
| Save / load | `save-load.md` | TODO | Autosave points, atomic versioned persistence (see SaveManager autoload). |
| UI / screens | `ui-screens.md` | TODO | Screen flow: menu → run → map → combat → shop → settings. |
| Input / touch | `input-touch.md` | TODO | Drag-drop cards, tap targeting, gestures; portrait touch UX. |
| Audio | `audio.md` | TODO | Music/SFX buses and cues (see AudioManager autoload). |

## How to add a system note
When you implement a system, create `systems/<name>.md` covering: entry points (scenes/scripts), the classes involved, how it reads/writes **RunState**, which **EventBus** signals it emits/consumes, RNG sub-stream (if any), save touchpoints, and known gotchas. Then flip its status here to a short summary.
